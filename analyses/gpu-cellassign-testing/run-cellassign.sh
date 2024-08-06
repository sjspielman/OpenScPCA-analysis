#!/bin/bash

set -euo pipefail

cd $(dirname "$0")
module_dir=$(pwd)

script=../cell-type-ewings/scripts/cnv-workflow/02-run-cellassign.py
data_dir="${module_dir}/../../data/test/SCPCP000001/SCPCS000001/"
input_anndata="${data_dir}/SCPCL000001_processed_rna.h5ad"
reference_file="./brain-compartment_PanglaoDB_2020-03-27.tsv"
output_file="./cellassign-predictions.tsv"

conda activate openscpca-gpu-cellassign-testing

python3 ${script} \
    --anndata_file ${input_anndata} \
    --output_predictions ${output_file} \
    --reference ${reference_file} \
    --seed 2024 # --threads TBD?
