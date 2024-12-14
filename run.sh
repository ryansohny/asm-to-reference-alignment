snakemake \
    --configfile config_asm20.yaml \
    --cores `nproc` \
    --use-conda \
    chain \
    -p $@

