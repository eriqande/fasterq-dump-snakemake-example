ACCS = ["SRR17730107", "SRR17730108", "SRR17730109", "SRR17730110", "SRR17730111"]


rule all:
    input:
        expand("results/fastq/{a}_{R}.fastq", a = ACCS, R = [1, 2])


rule get_fastq_pe:
    output:
        # the wildcard name must be accession, pointing to an SRA number
        "results/fastq/{accession}_1.fastq",
        "results/fastq/{accession}_2.fastq",
    log:
        "logs/get_fastq_pe/{accession}.log"
    params:
        extra="--skip-technical"
    threads: 5
    resources:
        time="4-00:00:00",
        mem_mb=24000
    conda:
        "sra-tools.yaml"
    shell:
        "fasterq-dump          "
        " --threads {threads} "
        " --skip-technical "
        " -t /home/eanderson/scratch/tmp/phils-version-{wildcards.accession} "  # write temp files SSD scratch
        " -O results/fastq  {wildcards.accession}"
