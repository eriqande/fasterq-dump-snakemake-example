#ACCS = ["SRR17730107", "SRR17730108", "SRR17730109", "SRR17730110", "SRR17730111"]

# here are five paired end accessions for testing
#ACCS = ["SRR2467340", "SRR2467341", "SRR2467342", "SRR2467343", "SRR2467344"]


# here are 40 paired end chinook sequences:
ACCS=[
"SRR12798274",
"SRR12798275",
"SRR12798276",
"SRR12798277",
"SRR12798278",
"SRR12798279",
"SRR12798280",
"SRR12798281",
"SRR12798282",
"SRR12798283",
"SRR12798284",
"SRR12798285",
"SRR12798286",
"SRR12798287",
"SRR12798288",
"SRR12798289",
"SRR12798290",
"SRR12798291",
"SRR12798292",
"SRR12798293",
"SRR12798294",
"SRR12798295",
"SRR12798296",
"SRR12798297",
"SRR12798298",
"SRR12798299",
"SRR12798300",
"SRR12798301",
"SRR12798302",
"SRR12798303",
"SRR12798304",
"SRR12798305",
"SRR12798306",
"SRR12798307",
"SRR12798308",
"SRR12798309",
"SRR12798310",
"SRR12798311",
"SRR12798312",
"SRR12798313"
]


rule all:
    input:
        expand("results/fastq/{a}_{R}.fastq.gz", a = ACCS, R = [1, 2])


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
        " -O {output.predir} > {log.out} 2> {log.err} "

rule get_fastq_pe_from_prefetch:
    input:
        pred="results/prefetch_dirs/{accession}"
    output:
        # the wildcard name must be accession, pointing to an SRA number
        fq1=temp("results/fastq/{accession}_1.fastq"),
        fq2=temp("results/fastq/{accession}_2.fastq"),
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



rule gzip_fastq:
    input:
        fq="results/fastq/{accession}_{read}.fastq",
    output:
        "results/fastq/{accession}_{read}.fastq.gz"
    threads: 4
    log:
        "results/logs/gzip_fastq/{accession}_{read}.log"
    shell:
        "pigz -k -p {threads} {input} > {log} 2> &1 "