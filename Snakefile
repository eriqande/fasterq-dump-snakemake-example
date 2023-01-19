#ACCS = ["SRR17730107", "SRR17730108", "SRR17730109", "SRR17730110", "SRR17730111"]

# here are five paired end accessions for testing
ACCS = ["SRR2467340", "SRR2467341", "SRR2467342", "SRR2467343", "SRR2467344"]

rule all:
    input:
        expand("results/fastq/{a}_{R}.fastq", a = ACCS, R = [1, 2])


rule prefetch_accession:
    output: 
        predir=temp(directory("results/prefetch_dirs/{accession}"))
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
    input:
        pred="results/prefetch_dirs/{accession}"
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
        " cd $(dirname {input.pred});  "  # crazy-crap! fasterq-dump must be in the same dir as the prefetched directory, according to: https://github.com/ncbi/sra-tools/wiki/08.-prefetch-and-fasterq-dump
        " fasterq-dump          "
        " --threads {threads} "
        " {params.extra} "
        " -t /home/eanderson/scratch/tmp/phils-version-{wildcards.accession} "  # write temp files to SSD scratch
        " -O ../../$(dirname {output.fq1})  {wildcards.accession} > ../../{log.out} 2> ../../{log.err}; "
        " cd ../.. "

