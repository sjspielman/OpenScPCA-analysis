#!/usr/bin/env Rscript

# Script to permute metadata from a project

# load libraries ---------------------------------------------------------------
library(optparse)

# parse options ----------------------------------------------------------------
option_list <- list(
  make_option(
    c("-f", "--metadata_file"),
    type = "character",
    default = NULL,
    help = "Path to the sample metadata file to shuffle."
  ),
  make_option(
    c("-o", "--output_file"),
    type = "character",
    default = NULL,
    help = "The output file path for the permuted metadata file."
  ),
  make_option(
    c("--seed"),
    type = "integer",
    default = 2024,
    help = "Random number seed for simulation."
  )
)

opts <- parse_args(OptionParser(option_list = option_list))

# load and process metadata file -----------------------------------------------

stopifnot(
  "Could not find `metadata_file`" = file.exists(opts$metadata_file)
)

set.seed(opts$seed)

metadata <- readr::read_tsv(opts$metadata_file, col_types = readr::cols(.default = "c"))

# fields that apply at library level
library_fields <- c(
  "scpca_project_id",
  "scpca_library_id",
  "seq_unit",
  "technology",
  "filtered_cell_count",
  "filtered_spots",
  "unfiltered_spots",
  "tissue_spots",
  "submitter",
  "pi_name",
  "project_title",
  "demux_samples",
  "demux_cell_count_estimate"
)

# fields that apply at sample level
sample_fields <- c(
  "scpca_sample_id",
  "submitter_id",
  "participant_id",
  "age",
  "age_timing",
  "sex",
  "diagnosis",
  "subdiagnosis",
  "tissue_location",
  "disease_timing",
  "organism",
  "development_stage_ontology_term_id",
  "sex_ontology_term_id",
  "organism_ontology_id",
  "self_reported_ethnicity_ontology_term_id",
  "disease_ontology_term_id",
  "tissue_ontology_term_id"
)

processing_fields <- c(
  "sample_cell_count_estimate",
  "alevin_fry_version",
  "cell_filtering_method",
  "date_processed",
  "droplet_filtering_method",
  "genome_assembly",
  "has_cellhash",
  "includes_anndata",
  "is_cell_line",
  "is_multiplexed",
  "is_xenograft",
  "has_citeseq",
  "adt_filtering_method",
  "adt_normalization_method",
  "mapped_reads",
  "mapping_index",
  "min_gene_cutoff",
  "normalization_method",
  "prob_compromised_cutoff",
  "processed_cells",
  "salmon_version",
  "spaceranger_version",
  "total_reads",
  "transcript_type",
  "unfiltered_cells",
  "demux_method",
  "workflow",
  "workflow_commit",
  "workflow_version"
)

# get project-specific columns, which should also be sample-specific
project_fields <- setdiff(colnames(metadata), c(library_fields, sample_fields, processing_fields))

# get sample metadata only & reduce to one line per sample
sample_metadata <- metadata[, c(sample_fields, project_fields)] |> dplyr::distinct()

# check that sample data are not repeated
stopifnot(
  "Sample data seem to be repeated, metadata permutation failed" =
    length(unique(sample_metadata$scpca_sample_id)) == nrow(sample_metadata)
)

# permute sample metadata -------------------------------------------------------------
diagnosis_order <- sample(seq(1, nrow(sample_metadata)), nrow(sample_metadata))
age_order <- sample(diagnosis_order)
tissue_order <- sample(diagnosis_order)
sex_order <- sample(diagnosis_order)

sample_metadata <- sample_metadata |>
  dplyr::mutate(
    diagnosis = diagnosis[diagnosis_order],
    subdiagnosis = subdiagnosis[diagnosis_order],
    disease_ontology_term_id = disease_ontology_term_id[diagnosis_order],
    tissue_location = tissue_location[tissue_order],
    age = age[age_order],
    age_timing = age_timing[age_order],
    development_stage_ontology_term_id = development_stage_ontology_term_id[age_order],
    self_reported_ethnicity_ontology_term_id = sample(self_reported_ethnicity_ontology_term_id),
    participant_id = paste0("P", forcats::fct_anon(participant_id)), # anonymize participant_id
    submitter_id = "" # remove submitter_id,
  )

# permute project-specific columns
for (f in project_fields) {
  sample_metadata[[f]] <- sample(sample_metadata[[f]])
}

metadata <- metadata |>
  dplyr::rows_update(sample_metadata, by = "scpca_sample_id")

readr::write_tsv(metadata, opts$output_file)
