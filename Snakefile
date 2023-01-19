#ACCS = ["SRR17730107", "SRR17730108", "SRR17730109", "SRR17730110", "SRR17730111"]

# Here are some rainbow trout accessions that I chose for testing because
# they are small (around 20 Mb)
ACCS = ["SRR23034112", "SRR23034123", "SRR23034124"]

rule all:
    input:
        expand("results/fastq/{a}_{R}.fastq", a = ACCS, R = [1, 2])


rule prefetch_accession:
    output: 
        predir=directory("results/prefetch_dirs/{accession}")
    params:
        ms = "20g",  # in case one must increase the max size
    log:
        out="results/logs/prefetch_accession/{accession}.out",
        err="results/logs/prefetch_accession/{accession}.err"
    conda:
        "sra-tools.yaml"
    shell:
        " prefetch {wildcards.accession} "
        " --max-size {params.ms} "
        " -O {output.predir} "

rule get_fastq_pe_from_prefetch:
    output:
        # the wildcard name must be accession, pointing to an SRA number
        fq1="results/fastq/{accession}_1.fastq",
        fq2="results/fastq/{accession}_2.fastq",
    params:
        extra="--skip-technical"
    threads: 4
    resources:
        time="4-00:00:00",
        mem_mb=24000
    log:
      out="results/logs/get_fastq_pe_from_prefetch/{accession}.out",
      err="results/logs/get_fastq_pe_from_prefetch/{accession}.err",
    conda:
        "sra-tools.yaml"
    shell:
        " cd results/prefetch_dirs;        "  # crazy-crap! fasterq-dump must be in the same dir as the prefetched directory, according to: https://github.com/ncbi/sra-tools/wiki/08.-prefetch-and-fasterq-dump
        " fasterq-dump          "
        " --threads {threads} "
        " {params.extra} "
        " -t /home/eanderson/scratch/tmp/phils-version-{wildcards.accession} "  # write temp files to SSD scratch
        " -O ../../$(dirname {output.fq1})  {wildcards.accession} > ../../{log.out} 2> ../../{log.err}; "
        " cd ../.. "

