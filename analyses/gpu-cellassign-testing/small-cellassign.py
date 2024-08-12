import anndata as adata
import pandas as pd
import numpy as np
import scvi
from scvi.external import CellAssign


scvi.settings.seed = 2024

# read in marker gene reference
ref_matrix = pd.read_csv(
    "small-brain.tsv", sep="\t", index_col="ensembl_gene_id"
)

# read in anndata
adata = adata.read_h5ad("../../data/current/SCPCP000001/SCPCS000001/SCPCL000001_processed_rna.h5ad")

# subset anndata to contain only genes in the reference file
shared_genes = list(set(ref_matrix.index) & set(adata.var_names))
subset_adata = adata[:, shared_genes].copy()
subset_adata.X = subset_adata.X.tocsr()

# add size factor to subset adata (calculated from full data)
lib_size = adata.X.sum(1)
subset_adata.obs["size_factor"] = lib_size / np.mean(lib_size)

# CellAssign inference
scvi.external.CellAssign.setup_anndata(subset_adata, size_factor_key="size_factor")
model = CellAssign(subset_adata, ref_matrix)
model.train(accelerator="gpu")
predictions = model.predict()
