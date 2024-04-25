# ACCS = ["SRR2467340", "SRR2467341", "SRR2467342", "SRR2467343", "SRR2467344"]
ACCS = ["ERX10692180"]

rule all:
    input:
        expand("fastq/{a}_{R}.fastq", a = ACCS, R = [1, 2])


rule get_fastq_pe:
    output:
        # the wildcard name must be accession, pointing to an SRA number
        "fastq/{accession}_1.fastq",
        "fastq/{accession}_2.fastq",
    log:
        "logs/get_fastq_pe/{accession}.log"
    params:
        extra="--skip-technical"
    threads: 8
    resources:
        time="12:00:00",
        mem_mb=29920
    conda:
        "sra-tools.yaml"
    shell:
        "fasterq-dump --threads {threads} --skip-technical -O fastq  {wildcards.accession}"
