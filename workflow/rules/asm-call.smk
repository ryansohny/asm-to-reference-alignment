include: "reference_alignment.smk"


rule pav_bam:
    input:
        paf=rules.trim_and_break_paf.output.paf,
    output:
        bam="results/{ref}/pav_input_bam/{sm}.bam",
    conda:
        "../envs/env.yml"
    threads: 4
    resources:
        mem=8,
    shell:
        """
        rb paf-to-sam {input.paf} \
            | samtools sort -@ {threads} -m {resources.mem}G \
        > {output.bam}
        """


rule dip_sort:
    input:
        paf=rules.trim_and_break_paf.output.paf,
        query=get_asm,
    output:
        bam=temp("temp/{ref}/bam/sorted.{sm}.bam"),
    conda:
        "../envs/env.yml"
    threads: 4
    resources:
        mem=8,
    shell:
        """
        rb paf-to-sam {input.paf} -f {input.query} \
            | samtools sort -@ {threads} -m {resources.mem}G \
        > {output.bam}
        """


# used as a test only
rule dip_sort_bam:
    input:
        aln=rules.compress_sam.output.aln,
    output:
        bam=temp("temp/{ref}/bam/bam.sorted.{sm}.bam"),
    conda:
        "../envs/env.yml"
    threads: 4
    resources:
        mem=8,
    shell:
        """
        samtools sort -@ {threads} -m {resources.mem}G {input.aln} > {output.bam}
        """


rule dip_make_vcf:
    input:
        bam=lambda wc: expand(
            rules.dip_sort.output.bam,
            sm=[f"{wc.sm}_{i}" for i in [1, 2]],
            allow_missing=True,
        ),
        ref=get_ref,
    output:
        vcf=temp("temp/{ref}/vcf/{sm}.vcf"),
    conda:
        "../envs/dipcall.yml"
    threads: 1
    shell:
        """
        htsbox pileup -q0 -evcf {input.ref} {input.bam}  > {output.vcf}
        """


rule dip_phase_vcf:
    input:
        vcf=rules.dip_make_vcf.output.vcf,
        ref=get_ref,
    output:
        vcf="results/{ref}/vcf/{sm}.vcf.gz",
    conda:
        "../envs/dipcall.yml"
    threads: 1
    shell:
        """
        dipcall-aux.js vcfpair -s {wildcards.sm} -a {input.vcf} \
            | bcftools norm -Ov -m-any \
            | bcftools norm -Ov -d exact \
            | bcftools norm -Ov -m-any --fasta-ref {input.ref} --check-ref w \
            | htsbox bgzip > {output.vcf}
        """


rule callable_regions:
    input:
        paf=rules.trim_and_break_paf.output.paf,
    output:
        bed="results/{ref}/callable/{sm}_callable_regions.bed.gz",
    conda:
        "../envs/env.yml"
    threads: 1
    shell:
        """
        csvtk cut  -tT -f 6,8,9,1,3,4 {input.paf} \
            | bgzip > {output.bed}
        """


rule vcf_bed:
    input:
        vcf=rules.dip_phase_vcf.output.vcf,
        ref=get_ref,
    output:
        bed="results/{ref}/vcf_bed/{sm}.bed.gz",
    conda:
        "../envs/env.yml"
    threads: 1
    params:
        header="#CHROM\tPOS\tEND\tID\tTYPE\tREF\tALT\tSAMPLE\tHAP\tGT",
    shell:
        """
        #CHROM  POS0     END         ID           SVTYPE  SVLEN
        #REF    ALT     TIG_REGION  QUERY_STRAND CI      ALIGN_INDEX 
        #CLUSTER_MATCH   CALL_SOURCE     HAP     HAP_VARIANTS    GT
        ( echo '{params.header}'; \
            bcftools query \
                    -f '%CHROM\t%POS0\t%END\t%CHROM-%POS-%TYPE-%REF-%ALT\t%TYPE\t%REF\t%ALT\t{wildcards.sm}\th1;h2\t[ %GT]\n' \
                    {input.vcf} \
        ) \
            |  sed "s/[[:<:]]SNP[[:>:]]/SNV/g" \
            | bgzip > {output.bed}
        """