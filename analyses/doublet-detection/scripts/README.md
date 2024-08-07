# Scripts

This directory contains all scripts used in the module.

1. `00_format-benchmark-data.R` formats ground-truth datasets used to explore doublet detection methods into SCE and AnnData versions.

Use this command to run the bash script:

```sh
00_format-benchmark-data.R \
    --dataset_name <name of dataset to format> \
    --input_dir <directory with raw data file from Zenodo repository> \
    --output_dir <directory to export formatted files>
```

1. `01a_run-scdblfinder.R` and `01b_run-scrublet.py` detect doublets using R-based `scDblFinder` and Python-based `scrublet`, respectively.
- `01a_run-scdblfinder.R` takes an SCE file and exports a TSV file with `scDblFinder` results
  - Note that the output TSV file will contain all `NA` values if there are fewer than 10 cells in the given `SCE` object
- `01b_run-scrublet.py` takes an AnnData file and exports a TSV files with `scrublet` results

Use these commands to run each script:

```sh
# Run 01a_run-scdblfinder.R
Rscript 01a_run-scdblfinder.R \
    --input_sce_file <input SCE file name> \
    --data_dir <directory with input SCE file> \
    --results_dir <directory to export TSV result file> \
    --cores <optionally, the number of cores to use. Default is 4> \
    --random_seed <optionally, a random seed. Default is 2024>

# Run 01b_run-scrublet.py
python3 01b_run-scrublet.py \
    --input_anndata_file <input AnnData file name> \
    --data_dir <directory with input AnnData file> \
    --results_dir <directory to export TSV result file> \
    --random_seed <optionally, a random seed. Default is 2024>
```
