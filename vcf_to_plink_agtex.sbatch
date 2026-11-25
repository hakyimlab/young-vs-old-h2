#!/bin/bash
#SBATCH --array=1-22
#SBATCH --partition=tier2q
#SBATCH --time=00-01:00:00
#SBATCH --cpus-per-task=8
#SBATCH --output=/gpfs/data/im-lab/nas40t2/Vincent/heritability/logs/%x_%j.out
#SBATCH --error=/gpfs/data/im-lab/nas40t2/Vincent/heritability/logs/%x_%j.err

module load gcc/11.3.0
module load intel/2022.2
module load llvm/14.0.5
module load atlas/3.10.3
module load lapack/3.11.0

plink --vcf /gpfs/data/im-lab/nas40t2/Data/dGTEx/genotypes/vcf/dGTEx_Analysis_2026-02-20_v1_WGS_37Indiv_SHAPEIT4_phased.vcf.gz \
  --make-bed \
  --chr ${SLURM_ARRAY_TASK_ID} \
  --out /gpfs/data/im-lab/nas40t2/Vincent/heritability/plink_beds/dgtex_chr${SLURM_ARRAY_TASK_ID} \
  --vcf-half-call missing \
  --threads 8 \
  --memory 16000
