#!/bin/bash
#SBATCH --array=1-22
#SBATCH --partition=tier2q
#SBATCH --time=00-01:00:00
#SBATCH --mem=16G
#SBATCH --output=/gpfs/data/im-lab/nas40t2/Vincent/heritability/logs/%x_%j.out
#SBATCH --error=/gpfs/data/im-lab/nas40t2/Vincent/heritability/logs/%x_%j.err

module load gcc/11.3.0
module load intel/2022.2
module load llvm/14.0.5
module load gcc/12.1.0
module load bcftools/1.21
module load plink/1.9

DATADIR=/gpfs/data/im-lab/nas40t2/Vincent/heritability/plink_beds

plink --bfile /gpfs/data/im-lab/nas40t2/Vincent/heritability/plink_beds/agtex_chr${SLURM_ARRAY_TASK_ID} \
  --remove ${DATADIR}/high_missing_inds.txt \
  --maf 0.01 \
  --geno 0.05 \
  --hwe 1e-6 \
  --snps-only just-acgt \
  --make-bed \
  --out /gpfs/data/im-lab/nas40t2/Vincent/heritability/plink_qc_vcf/agtex_chr${SLURM_ARRAY_TASK_ID}_qc_noambig \
  --memory 16000
