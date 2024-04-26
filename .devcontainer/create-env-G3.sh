#!/bin/zsh
#!/bin/zsh

# Aim: prepare running environment for AWS EC2 G3 instances
# Specs:
#   EC2: `g3s.xlarge`
#   GPU: `NVIDIA Tesla M60`
#   CUDA driver: `510.47.03`
#   CUDA: `11.6`

# init conda
conda init zsh

# source .zshrc to activate conda
source $HOME/.zshrc

# keep a copy of current working directory
cwd=$(pwd)

# define the environment name e.g. "esm2", "wwpdb", etc.
envname=diffdockpp

# if conda env doesn't exist, create it
conda env list | grep -q $envname || conda create -n $envname python=3.10 -y && conda activate $envname

# if its environment config file exists, install it from config else build from scratch
if [ -f "${envname}-environment.yaml" ]; then
    conda env update --file "${envname}-environment.yaml" --name $envname
else
    # install pytorch 2.1.1
    conda install -y pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch==2.1.1 -c nvidia

    # install torch_geometric
    pip install torch_geometric
    # Optional dependencies:
    pip install pyg_lib torch_scatter torch_sparse torch_cluster torch_spline_conv \
        -f https://data.pyg.org/whl/torch-2.1.1+cu121.html

    # extra pakcages
    conda install -y -c conda-forge openmm pdbfixer
    conda install -y -c bioconda abnumber
    conda install -y -c salilab dssp  # requires libboost 1.73.0 explicitly, installs mkdssp version 3.0.0, executable at /home/vscode/.conda/envs/walle/bin/mkdssp
    conda install -y -c anaconda libboost==1.73.0  # required by dssp
    conda install -y -c bioconda clustalo  # clustal omega for pairwise alignment
    pip install loguru biopandas omegaconf pyyaml tqdm wandb \
        torcheval torchmetrics gdown 'graphein[extras]' docker \
        seaborn matplotlib \
        numpy dill pandas biopandas scikit-learn biopython e3nn tensorboard tensorboardX
    # ****************************************************************
fi

# save a copy to "${envname}-environment.yaml"
conda env export --name $envname --no-builds > /home/vscode/"${envname}-environment.yaml"

# cleanup
conda clean -a -y && \
pip cache purge && \
sudo apt autoremove -y
