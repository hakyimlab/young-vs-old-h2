#!/bin/bash
#SBATCH --job-name=skin_sun_exposed_lower_leg
#SBATCH --array=1-44
#SBATCH --account=im-lab
#SBATCH --partition=tier1q
#SBATCH --time=00-12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --output=/gpfs/data/im-lab/nas40t2/Vincent/heritability/logs/fresh_gemma_h2.out
#SBATCH --error=/gpfs/data/im-lab/nas40t2/Vincent/heritability/logs/fresh_gemma_h2.err
#SBATCH --open-mode=append

module load gcc/12.1.0
module load intel/2022.2
module load llvm/14.0.5
module load gemma/0.98.5
module load plink/1.9

tissue=skin_sun_exposed_lower_leg
base_dir=/gpfs/data/im-lab/nas40t2/Vincent/heritability
pheno_dir=/gpfs/data/im-lab/nas40t2/Vincent/heritability/pheno_files
mapping_dir=/gpfs/data/im-lab/nas40t2/Vincent/heritability/gene_column_mappings
thresh_dir=/gpfs/data/im-lab/nas40t2/Vincent/heritability/gemma_fresh/${tissue}/gene_batch_${SLURM_ARRAY_TASK_ID}
age_dir=/gpfs/data/im-lab/nas40t2/Vincent/heritability/age_ids/${tissue}
map_file=${mapping_dir}/gene_col_map_${SLURM_ARRAY_TASK_ID}.txt
gene_count=$(cat ${map_file} | wc -l)
chunk_size=400   # genes per batch; must match the chunking used to write gene_col_map_N.txt

mkdir -p ${thresh_dir}

# A GEMMA BSLMM run counts as finished if its final output files exist and are non-empty
gemma_done() {
    local outdir=$1
    [[ -s ${outdir}/result.hyp.txt && -s ${outdir}/result.param.txt ]]
}

for gene_index in $(seq 1 $gene_count); do
    gene=$(cut -f 1 ${map_file} | sed -n ${gene_index}p | tr -d '\r')

    # Column of this gene in the pheno file (global, 1-based; FID/IID not counted).
    # NB: this is NOT gene_index, which is only the line number within this batch.
    pheno_col=$(cut -f 2 ${map_file} | sed -n ${gene_index}p | tr -d '\r')   # tr: mapping files may have Windows (CRLF) line endings

    # Sanity check: with 400-gene chunks and 1-based numbering, the expected column is fixed
    expected_col=$(( (SLURM_ARRAY_TASK_ID - 1) * chunk_size + gene_index ))
    if [[ "${pheno_col}" != "${expected_col}" ]]; then
        echo "ERROR: ${gene} (batch ${SLURM_ARRAY_TASK_ID}, line ${gene_index}) has pheno column '${pheno_col}', expected ${expected_col}. Check gene_col_map numbering." >&2
        exit 1
    fi

    young_done=false
    old_done=false
    gemma_done ${thresh_dir}/${gene}_young && young_done=true
    gemma_done ${thresh_dir}/${gene}_old && old_done=true

    if $young_done && $old_done; then
        echo "Skipping ${gene} (batch ${SLURM_ARRAY_TASK_ID}): young and old already complete"
        continue
    fi

    cp ${base_dir}/cis_windows/${gene}_agtex.* ${thresh_dir}

    if ! $young_done; then
        # clear any partial output from an interrupted run
        rm -rf ${thresh_dir}/${gene}_young
        plink --bfile ${thresh_dir}/${gene}_agtex --keep ${age_dir}/agtex_young_ids_40.txt --pheno ${pheno_dir}/${tissue}_agtex_pheno.txt --mpheno ${pheno_col} --make-bed --out ${thresh_dir}/${gene}_agtex_young
        gemma -bfile ${thresh_dir}/${gene}_agtex_young -bslmm 1 -s 100000 -outdir ${thresh_dir}/${gene}_young
    fi

    if ! $old_done; then
        rm -rf ${thresh_dir}/${gene}_old
        plink --bfile ${thresh_dir}/${gene}_agtex --keep ${age_dir}/agtex_old_ids_60.txt --pheno ${pheno_dir}/${tissue}_agtex_pheno.txt --mpheno ${pheno_col} --make-bed --out ${thresh_dir}/${gene}_agtex_old
        gemma -bfile ${thresh_dir}/${gene}_agtex_old -bslmm 1 -s 100000 -outdir ${thresh_dir}/${gene}_old
    fi

    rm -f ${thresh_dir}/*.bed
    rm -f ${thresh_dir}/*.bim
    rm -f ${thresh_dir}/*.log
    rm -f ${thresh_dir}/*.nosex
    rm -f ${thresh_dir}/*.fam
done
