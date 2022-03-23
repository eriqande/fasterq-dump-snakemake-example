rule get_fastq_pe:
    output:
        # the wildcard name must be accession, pointing to an SRA number
        "fastq/{accession}_R1.fq.gz",
        "fastq/{accession}_R2.fq.gz",
    log:
        "logs/get_fastq_pe/{accession}.log"
    params:
        extra="--skip-technical"
    threads: 1  # defaults to 6
    wrapper:
        "v1.3.1/bio/sra-tools/fasterq-dump"
