#!/bin/bash

# This script runs the module workflow for SCPCP000015 and is meant to be called from ./run-analysis.sh.
# It can be run as follows, optionally specifying the following variables:
#
# testing=<0 or 1> threads=<number of threads for inferCNV> seed=<random seed to set for inferCNV> ./run-SCPCP000015.sh

set -euo pipefail

# Ensure script is being run from _one directory up_, which represents the root directory of the module
# This is so `renv` loads properly, without needing to call `renv::load()` in scripts since code run in Docker containers won't use `renv`
module_dir=$(dirname "${BASH_SOURCE[0]}")/..
cd ${module_dir}

# This script processes samples from SCPCP000015
project_id="SCPCP000015"

# Define library to exclude from analysis
exclude_library="SCPCL001111"

# Whether to use a subset of references with inferCNV
testing=${testing:-0}

# inferCNV settings
threads=${threads:-4}
seed=${seed:-2025}

# Define input directories and files
# These should all be relative to `../`
top_data_dir="../../data/current"
data_dir="../../data/current/${project_id}"
script_dir="scripts"
notebook_dir="template-notebooks"
results_dir="results/${project_id}"
normal_ref_dir="references/normal-references/${project_id}"
merged_sce_file="${top_data_dir}/results/merge-sce/${project_id}/${project_id}_merged.rds"
cell_type_ewings_dir="${top_data_dir}/results/cell-type-ewings/${project_id}"
metadata_file="${data_dir}/single_cell_metadata.tsv"

mkdir -p ${normal_ref_dir}

# Define pooled normal reference files
ref_celltypes_tsv="${normal_ref_dir}/reference-celltypes.tsv"
immune_ref_file="${normal_ref_dir}/immune.rds"
endo_ref_file="${normal_ref_dir}/endo.rds"
endo_immune_ref_file="${normal_ref_dir}/endo-immune.rds"

# Define array of references to run across based on $testing
# Use reference names (not file names) since these will be used to create directories below
if [[ $testing -eq 1 ]]; then
    # Use only the immune references for testing
    normal_refs=("immune")
    test_flag="--testing"
else
    # Use all references for full analysis
    normal_refs=("immune" "endo" "endo-immune")
    test_flag=""
fi

# Define all sample ids
sample_ids=$(basename -a ${data_dir}/SCPCS*)

### Perform the analysis ###

# Build the SCPCP000015 reference files
Rscript ${script_dir}/build-reference-SCPCP000015.R \
    --merged_sce_file ${merged_sce_file} \
    --cell_type_ewings_dir ${cell_type_ewings_dir} \
    --metadata_file ${metadata_file} \
    --reference_immune ${immune_ref_file} \
    --reference_endo ${endo_ref_file} \
    --reference_endo_immune ${endo_immune_ref_file} \
    --reference_tsv ${ref_celltypes_tsv}


# Run inferCNV with all samples across references of interest
for sample_id in $sample_ids; do

    # There is only one library per sample for this project, so we can right away define the SCE
    sce_file=`ls ${data_dir}/${sample_id}/*_processed.rds`

    # skip the `exclude_library`
    library_id=$(basename $sce_file | sed 's/_processed.rds$//')
    if [[ $library_id == $exclude_library ]]; then
        continue
    fi

    # define exploratory notebook name for this library
    # the name is be the same for all references, organized into different directories
    html_name="${library_id}_infercnv-results.nb.html"

    # Define TSV file with cell type information, used when running with internal references
    celltype_tsv="${cell_type_ewings_dir}/${sample_id}/${library_id}_ewing-celltype-assignments.tsv"

    # Loop over normal references of interest
    for normal_ref in "${normal_refs[@]}"; do

        ####### First, run with the pooled reference #######

        # add _pooled suffix for output directory
        ref_name="${normal_ref}_pooled"

        # create sample results directory
        sample_results_dir="${results_dir}/${sample_id}/${ref_name}"
        mkdir -p ${sample_results_dir}

        # define normal reference SCE file with
        normal_ref_file="${normal_ref_dir}/${normal_ref}.rds"

        # run inferCNV with the pooled reference
        Rscript ${script_dir}/01_run-infercnv.R \
            --sce_file $sce_file \
            --reference_type "pooled" \
            --reference_celltype_group $normal_ref \
            --pooled_reference_sce $normal_ref_file \
            --output_dir $sample_results_dir \
            --threads $threads \
            --seed $seed

        # run inferCNV results through exploratory notebook
        html_name="${library_id}_infercnv-results.nb.html"
        Rscript -e "rmarkdown::render('${notebook_dir}/SCPCP000015_explore-infercnv-results.Rmd',
            params = list(library_id = '${library_id}', sample_id = '${sample_id}', reference_name = '${ref_name}'),
            output_dir = '${sample_results_dir}',
            output_file = '${html_name}')"

        ####### Second, run with the internal reference #######
        # See https://github.com/AlexsLemonade/OpenScPCA-analysis/issues/1125
        if [[ $sample_id == "SCPCS000490" || $sample_id == "SCPCS000492" || $sample_id == "SCPCS000750" ]]; then

            # Only run SCPCS000750 with the endo reference; continue otherwise
            if [[ ${sample_id} == "SCPCS000750" && ${normal_ref} != "endo" ]]; then
                continue
            fi

            # update variables to have _internal suffix
            ref_name="${normal_ref}_internal"
            sample_results_dir="${results_dir}/${sample_id}/${ref_name}"

            # run inferCNV with the internal reference
            Rscript ${script_dir}/01_run-infercnv.R \
                --sce_file $sce_file \
                --reference_type "internal" \
                --reference_celltype_group $normal_ref \
                --celltype_tsv $celltype_tsv \
                --reference_celltype_tsv $ref_celltypes_tsv \
                --output_dir $sample_results_dir \
                --threads $threads \
                --seed $seed \
                ${test_flag}

            Rscript -e "rmarkdown::render('${notebook_dir}/SCPCP000015_explore-infercnv-results.Rmd',
                params = list(library_id = '${library_id}', sample_id = '${sample_id}', reference_name = '${ref_name}'),
                output_dir = '${sample_results_dir}',
                output_file = '${html_name}')"
        fi
    done
done
