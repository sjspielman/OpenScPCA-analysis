FROM continuumio/miniconda3:24.1.2-0

# Set an environment variable to allow checking if we are in an OpenScPCA container
ENV OPENSCPCA_DOCKER=TRUE

# set a name for the conda environment
ARG ENV_NAME=openscpca-gpu-cellassign-testing

# Install conda-lock to enable later package installation
RUN conda install --channel=conda-forge --name=base conda-lock

# Copy the conda-lock.yml file from the host environment to the image
COPY conda-lock.yml conda-lock.yml

# restore from conda-lock.yml file and clean up to reduce image size
RUN conda-lock install -n ${ENV_NAME} && \
  conda clean --all --yes

# Activate conda environment on bash launch
RUN echo "conda activate ${ENV_NAME}" >> ~/.bashrc

# Set CMD to bash to activate the environment when launching
CMD ["/bin/bash"]
