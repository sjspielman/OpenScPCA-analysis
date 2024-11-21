This directory contains template notebooks whose output HTML files are stored in `results` and not formally tracked in this repository.

- `utils` contains helper functions used in label transfer notebooks
- `00b_characterize_fetal_kidney_reference_Stewart.Rmd`
  - Characterizes and visualizes the Stewart et al fetal kidney reference
- `01_seurat_processing.Rmd`
  - The `_processed.rds` `sce object` is converted to `Seurat` and normalized using `SCTransform`.
  - Dimensionality reduction (`RunPCA` and `RunUMAP`) and clustering (`FindNeighbors` and `FindClusters`) are performed before saving the `Seurat` object.
- `02a_label-transfer_fetal_full_reference_Cao.Rmd`
  - Uses an Azimuth-adapted approach to transfer labels from the Azimuth fetal full reference (Cao et al.)
- `02a_label-transfer_fetal_kidney_reference_Stewart.Rmd`
  - Uses an Azimuth-adapted approach to transfer labels from the fetal kidney reference (Stewart et al.)
- `03_clustering_exploration.Rmd`
    - Explores the clustering results, we look into some marker genes, pathways enrichment, and label transfer.
- `04_annotation_Across_Samples_exploration.Rmd`
  - Explores the label transfer results across all samples in the Wilms tumor dataset `SCPCP000006` in order to identify a few samples that we can begin next analysis steps with.
  - Evaluates the use of `predicted.score` for label transfer interpretation
- `05_copykat_exploration.Rmd`
  - Explores and compares `copyKAT` results run on a subset of samples
- `06_infercnv_exploration.Rmd`
  - Explores and compares `inferCNV` results run on a subset of samples

