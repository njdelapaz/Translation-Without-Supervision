#!/bin/bash
#SBATCH --job-name=base_run_1
#SBATCH -A cs4770_fa25
#SBATCH --output=output.txt # Output file
#SBATCH -p gpu                     # << required: choose a partition
#SBATCH --gres=gpu:4               # request 4 GPUs (ensure this is allowed)
#SBATCH --cpus-per-task=8          # give your job some CPUs for dataloaders, etc.
#SBATCH --mem=64G
#SBATCH --time=10:00:00           # 7 days; adjust to the partition’s max
#SBATCH --output=output.txt
#SBATCH --error=error.txt

# Your command to run
python3 train.py --src newstest2009.en-es.en --src-lang en \
                 --trg newstest2009.en-es.es --trg-lang es \
                 --working ./projectgroup/Translation-Without-Supervision/model

