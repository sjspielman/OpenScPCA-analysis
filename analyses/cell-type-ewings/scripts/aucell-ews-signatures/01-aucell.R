#!/usr/bin/env Rscript

# This script is used to run `AUCell` on a single SCE object for a set of marker gene sets 
# gene sets used are custom gene sets and a set of Ewing specific gene sets from MsigDB
# the results are exported as a single TSV file with the following columns: 
# `gene_set`, `barcodes`, `auc`, and `auc_threshold`

project_root <- here::here()

library(optparse)

option_list <- list(
  make_option(
    opt_str = c("--sce_file"),
    type = "character",
    help = "Path to RDS file containing a processed SingleCellExperiment object from scpca-nf
      to be used to run AUCell."
  ),
  make_option(
    opt_str = c("--custom_geneset_dir"),
    type = "character",
    default = file.path(project_root, "references", "gene_signatures"), 
    help = "Path to directory containing custom gene sets to use with AUCell. 
      All TSV files in the directory will be used and must contain the `ensembl_gene_id` column.
      File names will be used as the name of the gene set."
  ),
  make_option(
    opt_str = c("--msigdb_genesets"),
    type = "character", 
    default = file.path(project_root, "references", "msigdb-gene-sets.tsv"),
    help = "Path to TSV file containing all gene sets from MSigDB to use with AUCell.
      Must contain columns with `name`, `geneset`, `category`, and `subcategory`."
  ), 
  make_option(
    opt_str = c("--max_rank_threshold"),
    type = "double",
    default = 0.01,
    help = "Percentage of genes detected to set as the `aucMaxRank`. 
      Must be a number between 0 and 1."
  ),
  make_option(
    opt_str = c("--is_merged"),
    action = "store_true",
    default = FALSE,
    help = "Indicate whether or not the SCE object is a merged object."
  ),
  make_option(
    opt_str = c("--output_file"),
    type = "character",
    help = "Path to file where results will be saved"
  ),
  make_option(
    opt_str = c("-t", "--threads"),
    type = "integer",
    default = 4,
    help = "Number of multiprocessing threads to use."
  ),
  make_option(
    opt_str = c("--seed"),
    type = "integer",
    default = 2025,
    help = "A random seed for reproducibility."
  )
)

# Parse options
opt <- parse_args(OptionParser(option_list = option_list))

# Set up -----------------------------------------------------------------------

# make sure input files exist
stopifnot(
  "sce file must be specified using `--sce_file`" = !is.null(opt$sce_file)
)

stopifnot(
  "sce file does not exist" = file.exists(opt$sce_file),
  "MSigDB gene set file does not exist" = file.exists(opt$msigdb_genesets),
  "max_rank_threshold must be between 0 and 1" = (opt$max_rank_threshold <= 1 & opt$max_rank_threshold > 0)
)

# load SCE
suppressPackageStartupMessages({
  library(SingleCellExperiment)
})


# set up multiprocessing params
if (opt$threads > 1) {
  bp_param <- BiocParallel::MulticoreParam(opt$threads)
} else {
  bp_param <- BiocParallel::SerialParam()
}

# check that max rank is number between 0-1

# make sure directory exists for writing output
output_dir <- dirname(opt$output_file)
fs::dir_create(output_dir)

# read in SCE
sce <- readr::read_rds(opt$sce_file)

# remove genes that are not detected from SCE object 
if(!opt$is_merged){
  genes_to_keep <- rowData(sce)$detected > 0 
} else {
  
  # if merged object then need to sum all columns to find genes not present in the object at all 
  genes_to_keep <- rowData(sce) |> 
    as.data.frame() |>
    dplyr::select(ends_with("detected")) |> 
    rowSums() > 0
  
}

filtered_sce <- sce[genes_to_keep , ] 

# read in gene sets to use with msigdb
genesets_df <- readr::read_tsv(opt$msigdb_genesets)

# Prep gene sets ---------------------------------------------------------------

# get list of files with custom gene sets to use 
gene_set_files <- list.files(opt$custom_geneset_dir, recursive = TRUE, full.names = TRUE)
# get names of gene sets using name of the files 
gene_set_names <- stringr::str_replace(basename(gene_set_files), ".tsv", "")

# read in custom gene sets
custom_genes_list <- gene_set_files |> 
  purrr::set_names(gene_set_names) |> 
  purrr::map(\(file) {
    gene_ids <- readr::read_tsv(file) |> 
      dplyr::pull(ensembl_gene_id) |>
      unique()
  })

# get list of categories that we need to grab from msigdb
category_list <- genesets_df |> 
  dplyr::select(category, subcategory) |>
  unique() |>
  purrr::transpose()

# list of genesets and names 
geneset_list <- genesets_df$geneset |> 
  purrr::set_names(genesets_df$name)

# pull gene sets from msigbdr
# first pull out info for each category and then pull out specific genes for geneset 
msig_genes_df <- category_list |> 
  purrr::map(\(category_list){
    
    # replace subcategory with default NULL 
    # can't use NULL in tsv since it gets read in as a character 
    if(is.na(category_list$subcategory)){
      subcategory <- NULL
    } else {
      subcategory <- category_list$subcategory
    }
    
    msigdbr::msigdbr(
      species = "Homo sapiens",
      category = category_list$category,
      subcategory = subcategory
    )
  }) |>
  dplyr::bind_rows() |>
  # only keep relevant gene sets
  dplyr::filter(gs_name %in% geneset_list)

# create named list of genes in each gene set
msig_genes_list <- geneset_list |>
  purrr::map(\(name){
    genes <- msig_genes_df |>
      dplyr::filter(gs_name == name) |>
      dplyr::pull(ensembl_gene) |> 
      unique()
  })

# combine custom and msig
all_genes_list <- c(custom_genes_list, msig_genes_list)

# build GeneSetCollection for AUCell
collection <- all_genes_list |>
  purrr::imap(\(genes, name) GSEABase::GeneSet(genes, setName = name)) |> 
  GSEABase::GeneSetCollection()

# Run AUCell -------------------------------------------------------------------

# extract counts matrix
counts_mtx <- counts(filtered_sce) |>
  as("dgCMatrix") # account for merged objects not being sparse

# check intersection with gene sets
overlap_pct <- all_genes_list |> 
  purrr::map_dbl(\(list){
    num_genes <- length(list)
    intersect(rownames(counts_mtx), list) |>
      length()/num_genes 
  })

# if any gene sets don't have enough overlap (cutoff is 20%)
# print a message and quit
if(any(overlap_pct <= 0.20)){
  message("Gene sets do not have at least 20% of genes present in SCE. 
          AUCell will not be run.")
  quit(save = "no")
}

max_rank <- ceiling(opt$max_rank_threshold*nrow(counts_mtx))

# run aucell 
auc_results <- AUCell::AUCell_run(
  counts_mtx, 
  collection, 
  aucMaxRank = max_rank,
  BPPARAM = bp_param
)

# Get threshold ----------------------------------------------------------------

# get auc threshold for each geneset 
auc_thresholds <- AUCell::AUCell_exploreThresholds(
  auc_results,
  assign = TRUE,
  plotHist = FALSE
) |> 
  # extract select auc threshold 
  purrr::map_dbl(\(results){
    results$aucThr$selected
  })

# put into a data frame for easy joining with all auc values 
threshold_df <- data.frame(
  gene_set = names(auc_thresholds),
  auc_threshold = auc_thresholds
)

# Combine and export results ---------------------------------------------------

# create data frame with auc for each cell and each geneset 
auc_df <- auc_results@assays@data$AUC |>
  as.data.frame() |>
  tibble::rownames_to_column("gene_set") |> 
  tidyr::pivot_longer(!"gene_set",
                      names_to = "barcodes",
                      values_to = "auc"
  ) |> 
  # add in threshold column 
  dplyr::left_join(threshold_df, by = "gene_set") |> 
  dplyr:::relocate(gene_set, .after = barcodes)

# export results as table
readr::write_tsv(auc_df, opt$output_file)
