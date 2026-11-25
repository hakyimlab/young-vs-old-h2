#!/bin/bash
#SBATCH --partition=tier2q
#SBATCH --time=00-01:00:00
#SBATCH --mem=32G
#SBATCH --output=/gpfs/data/im-lab/nas40t2/Vincent/heritability/logs/%x_%j.out
#SBATCH --error=/gpfs/data/im-lab/nas40t2/Vincent/heritability/logs/%x_%j.err

module load gcc/11.3.0
module load intel/2022.2
module load llvm/14.0.5
module load gcc/12.1.0
module load plink/1.9

DATADIR=/gpfs/data/im-lab/nas40t2/Vincent/heritability/plink_beds

# Write a list of all per-chromosome plink files to merge
for chr in $(seq 1 22); do
    echo ${DATADIR}/dgtex_chr${chr}
done > ${DATADIR}/d_merge_list.txt

# Merge all chromosomes into one temporary dataset (no QC yet, just for missingness)
plink --merge-list ${DATADIR}/d_merge_list.txt \
  --make-bed \
  --out ${DATADIR}/dgtex_all_chr_merged \
  --memory 30000

# Compute per-individual missingness genome-wide
plink --bfile ${DATADIR}/dgtex_all_chr_merged \
  --missing \
  --out ${DATADIR}/dgtex_all_chr_merged \
  --memory 30000

# Extract IDs with F_MISS > 0.05 -- exclusion list
awk 'NR>1 && $6 > 0.05 {print $1, $2}' ${DATADIR}/dgtex_all_chr_merged.imiss \
  > ${DATADIR}/d_high_missing_inds.txt

echo "Individuals to exclude (>5% missing genome-wide):"
wc -l ${DATADIR}/d_high_missing_inds.txt
