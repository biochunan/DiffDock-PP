REPO_BASE=$(dirname $(dirname $(realpath $0)))  # path to DiffDock-PP

CONFIG="${REPO_BASE}/config/${NAME}.yaml"

NUM_FOLDS=1  # number of seeds to try, default 5
SEED=0  # initial seed
CUDA=0  # will use GPUs from CUDA to CUDA + NUM_GPU - 1
NUM_GPU=1
BATCH_SIZE=1  # split across all GPUs
NUM_SAMPLES=40

NAME="single_pair_inference"  # change to name of config file
RUN_NAME=${1:-"single_pair_inference"}  # change to name of run

OUTDIR="out/${RUN_NAME}"
mkdir -p $OUTDIR

SAVE_PATH="$OUTDIR/ckpts/${RUN_NAME}"
VISUALIZATION_PATH="visualization/${RUN_NAME}"
STORAGE_PATH="/workspaces/DiffDock-PP/out/storage/${RUN_NAME}.pkl"
mkdir -p $(dirname $STORAGE_PATH)

FILTERING_PATH="checkpoints/confidence_model_dips/fold_0/"
SCORE_PATH="checkpoints/large_model_dips/fold_0/"

echo SCORE_MODEL_PATH: $SCORE_PATH
echo CONFIDENCE_MODEL_PATH: $SCORE_PATH
echo SAVE_PATH: $SAVE_PATH

python src/main_inf.py \
    --mode "test" \
    --config_file $CONFIG \
    --run_name $RUN_NAME \
    --save_path $SAVE_PATH \
    --batch_size $BATCH_SIZE \
    --num_folds $NUM_FOLDS \
    --num_gpu $NUM_GPU \
    --gpu $CUDA --seed $SEED \
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

