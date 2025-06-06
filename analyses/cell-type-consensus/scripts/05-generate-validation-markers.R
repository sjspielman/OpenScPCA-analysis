#!/usr/bin/env Rscript

# This script is used to create a table of marker genes to help validate the consensus cell type assignments 
# markers are obtained from CellMarker2.0 for Human 
# Prior to running this script, the CellMarker file must be downloaded using 00-download-cellmarker-ref.sh

# the output is a the `consensus-validation-groups.tsv` file 
# that contains a list of the top 10 marker genes for each cell ontology ID
# top marker genes are based on the frequency that marker gene shows up in the total tissues that cell type was found in 
# for some cell types the marker gene list is longer than 10 and includes any genes with equivalent percentage to the 10th gene in the list 

# Load libraries ---------------------------------------------------------------

# need for mapping library ids 
library(AnnotationDbi)
library(org.Hs.eg.db)

# File paths -------------------------------------------------------------------
module_base <- rprojroot::find_root(rprojroot::is_renv_project)

# cell marker file 
cellmarker_file <- file.path(module_base, "references", "Cell_marker_Human.xlsx")

# cell consensus ref file 
consensus_validation_file <- file.path("references", "consensus-validation-groups.tsv")

# define output file 
validation_markers_file <- file.path("references", "validation-markers.tsv")

# Prep references --------------------------------------------------------------
# Read in consensus groups
consensus_groups_df <- readr::read_tsv(consensus_validation_file) |>
  dplyr::select(validation_group_annotation, validation_group_ontology) |> 
  unique()

# set consensus group order 
consensus_group_order <- c(
  # lymphocytes
  "B cell",
  "plasma cell",
  "T cell",
  "innate lymphoid cell",
  # myeloid
  "dendritic cell",
  "macrophage",
  "monocyte",
  "myeloid",
  "natural killer cell",
  # hpsc 
  "hematopoietic precursor cell",
  # stem cell
  "stem cell",
  # stromal cells
  "adipocyte",
  "chondrocyte",
  "endothelial cell",
  "epithelial cell",
  "fibroblast",
  "melanocyte",
  "muscle cell",
  "pericyte",
  "stromal cell",
  # neural cells
  "neuron",
  "astrocyte",
  "glial cell",
  # other 
  "mesangial cell"
)

# get list of all ontology IDs that we care about 
group_ontology_ids <- consensus_groups_df |> 
  dplyr::pull(validation_group_ontology) |> 
  unique()

# read in cell marker and filter to relevant ontology IDs
cell_marker_df <- readxl::read_xlsx(cellmarker_file) |> 
  dplyr::mutate(
    cellontology_id = stringr::str_replace(cellontology_id, "_", ":")
  ) |> 
  dplyr::filter(cellontology_id %in% group_ontology_ids) |> 
  # rename for later joining
  dplyr::select(validation_group_ontology = cellontology_id, gene_symbol = Symbol, tissue_type) |> 
  # get rid of any thing that doesn't have a gene symbol 
  tidyr::drop_na() |> 
  unique() # only want one instance of each cell type/gene combo per tissue type 

# get ensembl ids for genes 
mapped_ids <-AnnotationDbi::mapIds(
  org.Hs.eg.db,
  keys = unique(cell_marker_df$gene_symbol),
  keytype = "SYMBOL",
  column = "ENSEMBL",
  multiVals = "first"
) |>
  tibble::enframe(name = 'gene_symbol',
                  value = 'ensembl_gene_id')

# Get top markers -------------------------------------------------------------

# get total number of tissues for each cell type 
total_tissues_df <- cell_marker_df |> 
  dplyr::select(validation_group_ontology, tissue_type) |> 
  unique() |>
  dplyr::count(validation_group_ontology, name = "celltype_total_tissues")

# create data frame with top 10 marker genes per cell type 
# ranking is based on the percentage of tissues the gene shows up in for a given cell type  
top_markers_df <- cell_marker_df |> 
  # first count how many tissues each gene shows up in for each cell type 
  dplyr::count(validation_group_ontology, gene_symbol, sort = TRUE, name = "number_of_tissues") |> 
  # add total possible tissue types 
  dplyr::left_join(total_tissues_df) |> 
  dplyr::mutate(
    # get the total percent of tissues that have that marker gene in that cell type 
    percent_tissues = round((number_of_tissues/celltype_total_tissues) * 100, 2)
  ) |> 
  # get the top 10 for each group, if there's a tie all will be saved
  dplyr::group_by(validation_group_ontology) |> 
  dplyr::top_n(10, percent_tissues) |> 
  dplyr::ungroup() |> 
  # add column for total number of times that gene is observed in the table
  dplyr::add_count(gene_symbol, name = "gene_observed_count") |> 
  # bring in ensembl ids
  dplyr::left_join(mapped_ids, by = c("gene_symbol")) |>
  # match to human readable name for ontology group 
  dplyr::left_join(consensus_groups_df, by = c("validation_group_ontology")) |> 
  dplyr::relocate(
    validation_group_annotation, ensembl_gene_id, .after = validation_group_ontology
  ) |> 
  # ensure validation_group_ontology follows consensus_group_order
  dplyr::mutate(validation_group_annotation = factor(validation_group_annotation, levels = consensus_group_order)) |> 
  # arrange genes by cell type and percentage of tissues 
  dplyr::arrange(validation_group_annotation, desc(percent_tissues))

# save to validation markers 
readr::write_tsv(top_markers_df, validation_markers_file)

