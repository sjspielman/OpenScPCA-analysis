import anndata
import scvi


scvi.settings.seed = 2024

# read in the merged anndata file for SCPCP000001
data_path = "../../data/test/results/merge-sce/SCPCP000001/SCPCP000001_merged_rna.h5ad"
adata = anndata.read_h5ad(data_path)

# add counts layer
adata.layers["counts"] = adata.raw.X.copy()


scvi.model.SCVI.setup_anndata(adata, layer="counts", batch_key="sample_id")
# params from https://docs.scvi-tools.org/en/stable/tutorials/notebooks/scrna/harmonization.html#integration-with-scvi
model = scvi.model.SCVI(adata, n_layers=2, n_latent=30, gene_likelihood="nb")
model.train()
