#!/bin/zsh

# Aim: run docker image on a pair of abag input

mode=$1
if [[ -z $mode ]]; then
  echo "Usage: $0 <mode>"
  echo "  mode: choices - 'dev', 'prod'"
  exit 1
fi

imgName="lilian/diffdock-pp:dev"
# host machine paths
DATA=/mnt/bob/shared/DockingDecoySet/out/examples/
OUTDIR=$(realpath $(dirname $(dirname $0)))/tmp
mkdir -p $OUTDIR

# ------------------------------------------------------------------------------
# prod
# ------------------------------------------------------------------------------
if [[ $mode == "prod" ]]; then
  docker run --rm \
    -v $DATA:/data \
    -v $OUTDIR:/output \
    --gpus all \
    $imgName \
    -n 1c08_0P \
    -i /data/1c08_0P.ab.randomized.pdb \
    -j /data/1c08_0P.ag.randomized.pdb \
    -o /output/1c08_0P \
    -s /diffdock-pp/src/db5_inference-chunan.sh \
    -c /diffdock-pp/config/single_pair_inference.yaml \
    --save_log
fi

# ------------------------------------------------------------------------------
# dev
# ------------------------------------------------------------------------------
# dev mode: run the container and get a shell
if [[ $mode == "dev" ]]; then
  docker run --rm -it \
    -v $DATA:/data \
    -v $OUTDIR:/output \
    --gpus all \
    --entrypoint zsh \
    $imgName
fi

# cd /diffdock-pp
# conda activate diffdock
# python run_one_abdb.py \
#   -n 1c08_0P \
#   -i /data/1c08_0P.ab.randomized.pdb \
#   -j /data/1c08_0P.ag.randomized.pdb \
#   -o /output/ \
#   -s /diffdock-pp/src/db5_inference-chunan.sh \
#   -c /diffdock-pp/config/single_pair_inference.yaml
