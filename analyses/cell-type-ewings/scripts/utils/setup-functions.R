# This function is used in `exploratory-anaysis/08-merged-celltypes.Rmd`
# It is used for reading in and setting up the cell type results

#' Combine workflow results into a single data frame
#'
#' Note that this function will only include clustering results from Leiden with modularity in the output
#'
#' @param sce Processed SingleCellExperiment object with UMAP embeddings
#' @param singler_df Data frame with results from `aucell-singler-annotation.sh` workflow
#' @param cluster_df Data frame with results from `evaluate-clusters.sh` workflow
#' @param aucell_df Data frame with results from `run-aucell-ews-signatures.sh` workflow
#' @param consensus_df Data frame with results from `cell-type-consensus` module
#' @param cluster_nn Value of nearest neighbors to use for cluster results. Default is 20.
#' @param cluster_res Value of resolution to use for cluster results. Default is 20.
#' @param join_columns Character vector indicating which columns to use for joining all tables.
#'   Default is "barcodes", for merged objects use c("barcodes", "library_id")
#'
prep_results <- function(
    sce,
    singler_df = NULL,
    cluster_df = NULL,
    aucell_df = NULL,
    consensus_df = NULL,
    cluster_nn = 20,
    cluster_res = 0.5,
    join_columns = c("barcodes")
) {

  ## grab UMAP
  umap_df <- sce |>
    scuttle::makePerCellDF(use.dimred = "UMAP") |>
    # replace UMAP.1 with UMAP1 and get rid of excess columns
    dplyr::select(all_of(join_columns), UMAP1 = UMAP.1, UMAP2 = UMAP.2)


  if(!is.null(cluster_df)){
    ## prep cluster data
    cluster_df <- cluster_df |>
      # filter to the clustering results we want to use
      dplyr::filter(
        cluster_method == "leiden_mod",
        nn == cluster_nn,
        resolution == cluster_res
      ) |>
      dplyr::select(
        barcodes = cell_id,
        cluster
      ) |>
      dplyr::mutate(cluster = as.factor(cluster))

    umap_df <- umap_df |>
      dplyr::left_join(cluster_df, by = join_columns)
  }

  if(!is.null(aucell_df)){

    ## prep aucell
    aucell_wide_df <- aucell_df |>
      dplyr::rename(
        threshold_auc = auc_threshold
      ) |>
      tidyr::pivot_wider(
        id_cols = all_of(join_columns),
        names_from = "gene_set",
        values_from = c(auc, threshold_auc)
      )

    umap_df <- umap_df |>
      dplyr::left_join(aucell_wide_df, by = join_columns)

  }

  if(!is.null(consensus_df)){
    ## prep singler data
    consensus_df <- consensus_df |>
      dplyr::mutate(
        # get the top cell types for plotting later
        consensus_lumped = consensus_annotation |>
          forcats::fct_lump_n(7, other_level = "All remaining cell types", ties.method = "first") |>
          forcats::fct_infreq() |>
          forcats::fct_relevel("All remaining cell types", after = Inf)
      )

    umap_df <- umap_df |>
      dplyr::left_join(consensus_df, by = join_columns)
  }

  if(!is.null(singler_df)){
    ## prep singler data
    singler_df <- singler_df |>
      dplyr::mutate(
        # first grab anything that is tumor and label it tumor
        # NA should be unknown
        singler_annotation = dplyr::case_when(
          stringr::str_detect(singler_annotation, "tumor") ~ "tumor",
          is.na(singler_annotation) ~ "unknown", # make sure to separate out unknown labels
          .default = singler_annotation
        ) |>
          forcats::fct_relevel("tumor", after = 0),
        # get the top cell types for plotting later
        singler_lumped = singler_annotation |>
          forcats::fct_lump_n(7, other_level = "All remaining cell types", ties.method = "first") |>
          forcats::fct_infreq() |>
          forcats::fct_relevel("All remaining cell types", after = Inf)
      )

    umap_df <- umap_df |>
      dplyr::left_join(singler_df, by = join_columns) |>
      dplyr::mutate(
        # account for any remaining NAs that might be present from joining
        singler_lumped = dplyr::if_else(is.na(singler_lumped), "unknown", singler_lumped) |>
          forcats::fct_relevel("All remaining cell types", after = Inf)
      )
  }

  return(umap_df)

}
