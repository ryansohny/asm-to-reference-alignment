snakemake \
    --configfile config.yaml \
    --cores `nproc` \
    --use-conda \
    ideogram \
    -p $@

