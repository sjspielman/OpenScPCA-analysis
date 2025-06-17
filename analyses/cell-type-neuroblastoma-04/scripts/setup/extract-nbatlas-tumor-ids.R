#!/usr/bin/env Rscript

# This script creates a text file with NBAtlas tumor IDs using the directly-communicated metadata
#  file we received from NBAtlas authors. This script is not meant to be run in CI, but was used
#  to prepare the file `../../references/nbatlas-tumor-ids.txt.gz` which is used in the module workflow


library(optparse)

opts <- list(
  make_option(
    opt_str = "--nbatlas_metadata_file",
    type = "character",
    default = here::here("scratch", "SeuratMeta_Share_TumorZoom_NBAtlas_v20250228.rds"),
    help = "Path to NBAtlas metadata file in `.rds` format received from authors"
  ),
  make_option(
    opt_str = "--output_file",
    type = "character",
    default = here::here("references", "nbatlas-tumor-ids.txt.gz"),
    help = "Path to text file to store tumor ids"
  )
)
opts <- parse_args(OptionParser(option_list = option_list))

stopifnot("nbatlas_metadata_file does not exist" = file.exists(opts$nbatlas_metadata_file))
fs::dir_create(dirname(opts$output_file))

# pull out the tumor cell ids
tumor_cell_ids <- readRDS(opts$nbatlas_metadata_file) |>
  rownames()

# export
readr::write_lines(tumor_cell_ids, opts$output_file)
