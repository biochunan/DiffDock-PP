#!/bin/zsh

set -e

# Aim:
# Input:
# Output:
# Usage:
# Example:
# Dependencies:

##############################################################################
# FUNCTION                                                                   #
##############################################################################
function usage() {
  # echo "Usage: $(basename $0) --jobname <jobname> --outdir <outdir> --config <config> [--level <level>]"
  # echo "Options:"
  # echo "  --jobname, -n  <jobname>  Name of the job"
  # echo "  --outdir, -o  <outdir>  Output directory"
  # echo "  --config, -c  <config>  Config file"
  # echo "  --level  <level>  Log level (DEBUG, INFO, WARNING, ERROR)"
  # echo "  --help, -h  Display this help and exit"
  # echo "Example:"
  # echo "$(basename $0) --abdbid 7djz_0P --ab_chain 'H L' --ag_chain C --abdb /mnt/Data/AbDb/abdb_newdata_20220926 --outdir ./test  --esm2_ckpt_host_path /mnt/Data/trained_models/ESM2"
  exit 1
}

# Function to print timestamp
print_timestamp() {
  date +"%Y%m%d-%H%M%S"  # e.g. 20240318-085729
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
    >&2 echo "[$level] $(print_timestamp): $1"        # showing messages
  else
    echo "[$level] $(print_timestamp): $message" >&2  # NOT showing messages
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
      [Yy]* )
        return 1
        break
        ;;
      [Nn]* )
        return 0
        break
        ;;
      * )
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

##############################################################################
# CONFIG                                                                     #
##############################################################################
# Set configuration variables
logFile="script.log"
verbose=true
BASE=$(dirname $(realpath $0))

# Run static config [DO NOT CHANGE]
NUM_FOLDS=1  # number of seeds to try, default 5
SEED=0  # initial seed
CUDA=0  # will use GPUs from CUDA to CUDA + NUM_GPU - 1
NUM_GPU=1
BATCH_SIZE=1  # split across all GPUs
NUM_SAMPLES=40

REPO_BASE=$(dirname $(dirname $(realpath $0)))  # path to DiffDock-PP
FILTERING_PATH="${REPO_BASE}/checkpoints/confidence_model_dips/fold_0/"
SCORE_PATH="${REPO_BASE}/checkpoints/large_model_dips/fold_0/"
# CONFIG="${REPO_BASE}/config/single_pair_inference.yaml"

##############################################################################
# INPUT                                                                      #
##############################################################################
# Parse command line options
while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    --jobname|-n)
      jobName="$2"
      shift 2;; # past argument and value
    --outdir|-o)
      outDir="$2"
      shift 2;; # past argument and value
    --config|-c)
      configFile="$2"
      shift 2;; # past argument and value
    --level)
      MINLOGLEVEL="$2"
      shift 2;; # past argument and value
    --help|-h)
      usage
      shift # past argument
      exit 1;;
    *)
      echo "Illegal option: $key"
      usage
      exit 1;;
  esac
done
mkdir -p $outDir

# assert config file exists
if [[ ! -f $configFile ]]; then
  print_msg "Config file not found: $configFile" "ERROR"
  exit 1
fi

##############################################################################
# MAIN                                                                       #
##############################################################################
# dynamic config
# RUN_NAME=${$jobName:-"single_pair_inference"}  # change to name of run
# OUTDIR=${$outDir:-"out/${RUN_NAME}"}
RUN_NAME=$jobName
OUTDIR=$outDir

SAVE_PATH="$OUTDIR/ckpts/${RUN_NAME}"
VISUALIZATION_PATH="$OUTDIR/visualization/${RUN_NAME}"
STORAGE_PATH="$OUTDIR/storage/${RUN_NAME}.pkl"
mkdir -p $OUTDIR
mkdir -p $OUTDIR/ckpts
mkdir -p $OUTDIR/visualization
mkdir -p $OUTDIR/storage

echo SCORE_MODEL_PATH: $SCORE_PATH
echo CONFIDENCE_MODEL_PATH: $SCORE_PATH
echo SAVE_PATH: $SAVE_PATH

python src/main_inf.py \
    --mode "test" \
    --config_file $configFile \
    --run_name $RUN_NAME \
    --save_path $SAVE_PATH \
    --batch_size $BATCH_SIZE \
    --num_folds $NUM_FOLDS \
    --num_gpu $NUM_GPU \
    --gpu $CUDA \
    --seed $SEED \
    --logger "wandb" \
    --project "DiffDock Tuning" \
    --visualize_n_val_graphs 25 \
    --visualization_path $VISUALIZATION_PATH \
    --filtering_model_path $FILTERING_PATH \
    --score_model_path $SCORE_PATH \
    --num_samples $NUM_SAMPLES \
    --prediction_storage $STORAGE_PATH \
    #--entity coarse-graining-mit \
    #--debug True # load small dataset