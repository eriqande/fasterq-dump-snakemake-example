ACCS = ["SRR17730107", "SRR17730108", "SRR17730109", "SRR17730110", "SRR17730111"]


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
    threads: 1  # defaults to 6
    resources:
        time="01:00:00"
    conda:
        "sra-tools.yaml"
    shell:
        "fasterq-dump --threads 1 --skip-technical -O fastq  {wildcards.accession}"
