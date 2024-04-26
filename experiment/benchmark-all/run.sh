#!/bin/zsh

set -e

# Aim: use Docker image lilian/diffdock-pp:dev to run benchmark-all.py

##############################################################################
# FUNCTION                                                                   #
##############################################################################
function usage() {
  echo "Usage: $(basename $0) --gpu|-g GPU_INDEX|all --abdbid_file|-f ABDBID_FILE"
  echo "Options:"
  echo "  --gpu|-g GPU_INDEX|all      : GPU index or 'all' to use all GPUs"
  echo "  --abdbid_file|-f ABDBID_FILE: a file containing a list of abdbIds"
  echo "  --help|-h                   : help"
  # add example
  # echo "Example:"
  #echo "$(basename $0) --abdbid 7djz_0P --ab_chain 'H L' --ag_chain C --abdb /mnt/Data/AbDb/abdb_newdata_20220926 --outdir ./test  --esm2_ckpt_host_path /mnt/Data/trained_models/ESM2"
  exit 1
}

# Function to print timestamp
print_timestamp() {
  date +"%Y%m%d-%H%M%S" # e.g. 20240318-085729
}

# Define severity levels
declare -A severity_levels
severity_levels=(
  [DEBUG]=10
  [INFO]=20
  [WARNING]=30
  [ERROR]=40
)

# Print message with time only if level is greater than INFO, to stderr
MINLOGLEVEL="INFO"
print_msg() {
  local message="$1"
  local level=${2:-INFO}

  if [[ ${severity_levels[$level]} -ge ${severity_levels[$MINLOGLEVEL]} ]]; then
    echo >&2 "[$level] $(print_timestamp): $1" # showing messages
  else
    echo "[$level] $(print_timestamp): $message" >&2 # NOT showing messages
  fi
}

# read input (non-silent)
read_input() {
  echo -n "$1"
  read $2
}

# read input silently
read_input_silent() {
  echo -n "$1"
  read -s $2
  echo
}

ask_reset() {
  local varName=${1:-"it"}
  # do you want to reset?
  while true; do
    read_input "Do you want to reset ${varName}? [y/n]: " reset
    case $reset in
    [Yy]*)
      return 1
      break
      ;;
    [Nn]*)
      return 0
      break
      ;;
    *)
      echo "Please answer yes or no."
      ;;
    esac
  done
}

# a function to get file name without the extension
function getStemName() {
  local file=$1
  baseName=$(basename $file)
  echo ${baseName%.*}
}

# Validate GPU option
validate_gpu_option() {
  local gpu_opt=$1
  if [[ $gpu_opt =~ ^[0-9]+$ ]]; then # if input is a number
    if ((gpu_opt >= 0 && gpu_opt < gpuCount)); then
      gpuDevices="device=$gpu_opt"
    else
      echo "Invalid GPU index: $gpu_opt. Available GPUs: 0 to $((gpuCount - 1))."
      exit 1
    fi
  elif [[ $gpu_opt == "all" ]]; then
    gpuDevices="all"
  else
    echo "Invalid GPU option: $gpu_opt"
    echo "Usage: cmd [-g GPU_INDEX|all]"
    exit 1
  fi
}

##############################################################################
# CONFIG                                                                     #
##############################################################################
# --------------------
# host machine
# --------------------
imageName="lilian/diffdock-pp:latest"
BASE=$(dirname $(realpath $0))
OUTDIR=$BASE/out
DATA=/mnt/bob/shared/DockingDecoySet/out/split-abag

# --------------------
# Task configuration
# --------------------
nProcesses=2
abSuffix='.ab.randomized.pdb'
agSuffix='.ag.randomized.pdb'

# --------------------
# run Docker image
# --------------------
dockerOutDir=/out
dockerDataDir=/data
dockerShellScript=/diffdock-pp/src/db5_inference-chunan.sh
dockerConfigTemplate=/diffdock-pp/config/single_pair_inference.yaml

##############################################################################
# INPUT                                                                      #
##############################################################################
# GPU Count
gpuCount=$(nvidia-smi -L | wc -l)

# default all GPUs
gpuOption="all"

# Parse command line options
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  --gpu | -g)
    gpuOption="$2"
    validate_gpu_option $gpuOption
    shift 2
    ;; # past argument and value
  --abdbid_file | -f)
    abdbidFile="$2" # a file containing a list of abdbIds
    shift 2
    ;; # past argument and value
  --help | -h)
    usage
    shift # past argument
    exit 0
    ;;
  *)
    echo "Illegal option: $key"
    usage
    exit 1
    ;;
  esac
done

# adjust GPU option
validate_gpu_option $gpuOption

# assert abdbidFile is provided and exists
if [[ -z $abdbidFile ]]; then
  echo "Missing argument: --abdbid_file|-f"
  exit 1
fi
if [[ ! -f $abdbidFile ]]; then
  echo "File not found: $abdbidFile"
  exit 1
fi

##############################################################################
# MAIN                                                                       #
##############################################################################
# load abdbIds
abdbIds=$(cat $abdbidFile)

# if length is 0, exit
if [[ ${#abdbIds} -eq 0 ]]; then
  echo "No abdbIds found in $abdbidFile"
  exit 1
fi

# --------------------
# Option 2: parallel
# --------------------
parallel -j $nProcesses --eta --progress \
  docker run --rm \
  -v ${OUTDIR}:${dockerOutDir} \
  -v ${DATA}:${dockerDataDir} \
  $([[ $gpuDevices != "" ]] && echo "--gpus $gpuDevices") \
  ${imageName} \
  -n {1} \
  -i ${dockerDataDir}/{1}${abSuffix} \
  -j ${dockerDataDir}/{1}${agSuffix} \
  -o ${dockerOutDir}/{1} \
  -s ${dockerShellScript} \
  -c ${dockerConfigTemplate} \
  --save_log ::: $abdbIds

# ------------------------------------------------------------------------------
# Option 1: for loop
# ------------------------------------------------------------------------------
# for abdbid in $abdbIds; do
#   docker run --rm \
#     -v ${OUTDIR}:${dockerOutDir} \
#     -v ${DATA}:${dockerDataDir} \
#     --gpus "device=1"
#     ${imageName} \
#     -n ${abdbid} \
#     -i ${dockerDataDir}/${abdbid}${abSuffix} \
#     -j ${dockerDataDir}/${abdbid}${agSuffix} \
#     -o ${dockerOutDir}/${abdbid} \
#     -s ${dockerShellScript} \
#     -c ${dockerConfigTemplate} \
#     --save_log
# done
