fasterq-dump-snakemake-example
================

This is a super small example that uses Snakemake to get fastq files
from the Short Read Archive using `fasterq-dump`.

This version in the `phils-version-with-prefetch` was tailored to use
the prefetch utility.

It is fairly straightforward, but, due to fasterq-dump needing to be run
in the same directory as the prefetched accession, it required a little
`cd` chicanery, etc.

If you are going to use this, note that you have to rename the temp
directory in the line that looks like this:

``` python
-t /home/eanderson/scratch/tmp/phils-version-{wildcards.accession}
```

to be a location that you have access to. Like:

``` python
-t /home/pmorin/scratch/tmp/phils-version-{wildcards.accession}
```

To run it on the example ACCS list, I did this on a node with 20 cores:

``` sh
snakemake --cores 20 --use-conda
```

It ran without any hitches in just a couple of minutes.

It is set up so that the prefetched accessions get deleted once the
fastq files have been extracted from them (Snakemake takes care of
that).

Phil, to run this under SLURM you will want to use the sedna profile.

## Update

Just to be explicit about how to run this under SLURM, using sbatch on
SEDNA: you run it like this:

``` sh
snakemake  --profile hpcc-profiles/slurm/sedna
```

There is no need to submit jobs yourself via sbatch (and write a new
Snakefile within each one). That is what the hpcc-profiles/slurm/sedna
profile does. Study the `config.yaml` file in the profile:

``` yaml
cluster:
  mkdir -p results/slurm_logs/{rule} &&
  sbatch
    --exclude=node[29-36]
    --cpus-per-task={threads}
    --mem={resources.mem_mb}
    --time={resources.time}
    --job-name=smk-{rule}-{wildcards}
    --output=results/slurm_logs/{rule}/{rule}-{wildcards}-%j.out
    --error=results/slurm_logs/{rule}/{rule}-{wildcards}-%j.err
    --parsable
default-resources:
  - time="08:00:00"
  - mem_mb=4800
  - disk_mb=1000000
restart-times: 0
max-jobs-per-second: 10
max-status-checks-per-second: 50
local-cores: 1
latency-wait: 60
cores: 600
jobs: 1200
keep-going: True
rerun-incomplete: True
printshellcmds: True
use-conda: True
cluster-status: status-sacct.sh
cluster-cancel: scancel
cluster-cancel-nargs: 1000
```

That YAML file basically lists a lot of command line arguments that
snakemake gets run with. (for example, `use-conda: True` translates to a
command line option of `--use-conda`).

The key one here is the `cluster` option. The way it is set up it shows
that snakemake will submit jobs to SLURM using the `sbatch` command with
options filled in by Snakemake as shown:

``` sh
sbatch
    --exclude=node[29-36]
    --cpus-per-task={threads}
    --mem={resources.mem_mb}
    --time={resources.time}
    --job-name=smk-{rule}-{wildcards}
    --output=results/slurm_logs/{rule}/{rule}-{wildcards}-%j.out
    --error=results/slurm_logs/{rule}/{rule}-{wildcards}-%j.err
```

So, to test it, I updated the Snakefile to include 40 accessions from
our Chinook project.

``` sh
conda activate snakemake-7.7.0

# do a dry run
snakemake  -np --profile hpcc-profiles/slurm/sedna

# it shows this, as it should:
Job stats:
job                           count    min threads    max threads
--------------------------  -------  -------------  -------------
all                               1              1              1
get_fastq_pe_from_prefetch       40              4              4
prefetch_accession               40              1              1
total                            81              1              4

This was a dry-run (flag -n). The order of jobs does not reflect the order of execution.
```

If we want to just run all 40 at once, we can do that with:

``` sh
snakemake  --profile hpcc-profiles/slurm/sedna
```

While that is running, we can look at our jobs with sinfo wrapped up in
`myjobs`
(<https://eriqande.github.io/nmfs-bioinf-2022/slurm.html#just-tell-me-about-my-jobs>)
to see them all running (showing just the first few here…)

``` sh
 myjobs
       JOBID PARTITION       NAME       USER ST            TIME  NODES   NODELIST(REASON)  CPUS   MIN_MEMORY   TIME_LIMIT    TIME_LEFT PRIORITY
      480647      node smk-prefet  eanderson  R            2:24      1             node05     1        4800M      8:00:00      7:57:36 0.99993431475012
      480648      node smk-prefet  eanderson  R            2:24      1             node05     1        4800M      8:00:00      7:57:36 0.99993431451729
      480649      node smk-prefet  eanderson  R            2:24      1             node05     1        4800M      8:00:00      7:57:36 0.99993431428446
      480650      node smk-prefet  eanderson  R            2:24      1             node05     1        4800M      8:00:00      7:57:36 0.99993431405163
      480651      node smk-prefet  eanderson  R            2:24      1             node05     1        4800M      8:00:00      7:57:36 0.99993431381880
      480652      node smk-prefet  eanderson  R            2:24      1             node05     1        4800M      8:00:00      7:57:36 0.99993431358597

...
```

This is where it is really nice to see more of the job name:

``` sh
 myjobs 55
       JOBID PARTITION                                                    NAME       USER ST            TIME  NODES   NODELIST(REASON)  CPUS   MIN_MEMORY   TIME_LIMIT    TIME_LEFT PRIORITY
      480647      node            smk-prefetch_accession-accession=SRR12798283  eanderson  R            3:11      1             node05     1        4800M      8:00:00      7:56:49 0.99993431475012
      480648      node            smk-prefetch_accession-accession=SRR12798313  eanderson  R            3:11      1             node05     1        4800M      8:00:00      7:56:49 0.99993431451729
      480649      node            smk-prefetch_accession-accession=SRR12798298  eanderson  R            3:11      1             node05     1        4800M      8:00:00      7:56:49 0.99993431428446
      480650      node            smk-prefetch_accession-accession=SRR12798287  eanderson  R            3:11      1             node05     1        4800M      8:00:00      7:56:49 0.99993431405163
      480651      node            smk-prefetch_accession-accession=SRR12798302  eanderson  R            3:11      1             node05     1        4800M      8:00:00      7:56:49 0.99993431381880
      480652      node            smk-prefetch_accession-accession=SRR12798306  eanderson  R            3:11      1             node05     1        4800M      8:00:00      7:56:49 0.99993431358597

...
```

As the prefetch steps get done, you will start to see the other steps:

``` sh
    480689      node    smk-get_fastq_pe_from_prefetch-accession=SRR12798302  eanderson  R           12:15      1             node07     4       24000M   4-00:00:00   3-23:47:45 0.99993430497123
      480690      node    smk-get_fastq_pe_from_prefetch-accession=SRR12798293  eanderson  R           11:58      1             node08     4       24000M   4-00:00:00   3-23:48:02 0.99993430473840
      480691      node    smk-get_fastq_pe_from_prefetch-accession=SRR12798298  eanderson  R           11:05      1             node08     4       24000M   4-00:00:00   3-23:48:55 0.99993430450557
      480692      node    smk-get_fastq_pe_from_prefetch-accession=SRR12798312  eanderson  R           10:49      1             node08     4       24000M   4-00:00:00   3-23:49:11 0.99993430427274
      480693      node    smk-get_fastq_pe_from_prefetch-accession=SRR12798313  eanderson  R           10:38      1             node09     4       24000M   4-00:00:00   3-23:49:22 0.99993430403991
      480694      node    smk-get_fastq_pe_from_prefetch-accession=SRR12798310  eanderson  R           10:24      1             node05     4       24000M   4-00:00:00   3-23:49:36 0.99993430380708
```

See how the rule name and the wildcard names and values go into making
the job name! The snakemake sedna profile does that.

By the way, all of the slurm logs go into a separate directory with
well-formed names:

``` sh
(base) [sedna: fasterq-dump-snakemake-example]--% ls results/slurm_logs/*
results/slurm_logs/get_fastq_pe_from_prefetch:
'get_fastq_pe_from_prefetch-accession=SRR12798274-480699.err'  'get_fastq_pe_from_prefetch-accession=SRR12798287-480697.out'  'get_fastq_pe_from_prefetch-accession=SRR12798301-480687.err'
'get_fastq_pe_from_prefetch-accession=SRR12798274-480699.out'  'get_fastq_pe_from_prefetch-accession=SRR12798288-480723.err'  'get_fastq_pe_from_prefetch-accession=SRR12798301-480687.out'
'get_fastq_pe_from_prefetch-accession=SRR12798275-480721.err'  'get_fastq_pe_from_prefetch-accession=SRR12798288-480723.out'  'get_fastq_pe_from_prefetch-accession=SRR12798302-480689.err'
'get_fastq_pe_from_prefetch-accession=SRR12798275-480721.out'  'get_fastq_pe_from_prefetch-accession=SRR12798289-480708.err'  'get_fastq_pe_from_prefetch-accession=SRR12798302-480689.out'
'get_fastq_pe_from_prefetch-accession=SRR12798276-480716.err'  'get_fastq_pe_from_prefetch-accession=SRR12798289-480708.out'  'get_fastq_pe_from_prefetch-accession=SRR12798303-480718.err'
'get_fastq_pe_from_prefetch-accession=SRR12798276-480716.out'  'get_fastq_pe_from_prefetch-accession=SRR12798290-480704.err'  'get_fastq_pe_from_prefetch-accession=SRR12798303-480718.out'
'get_fastq_pe_from_prefetch-accession=SRR12798277-480719.err'  'get_fastq_pe_from_prefetch-accession=SRR12798290-480704.out'  'get_fastq_pe_from_prefetch-accession=SRR12798305-480707.err'
'get_fastq_pe_from_prefetch-accession=SRR12798277-480719.out'  'get_fastq_pe_from_prefetch-accession=SRR12798291-480702.err'  'get_fastq_pe_from_prefetch-accession=SRR12798305-480707.out'
'get_fastq_pe_from_prefetch-accession=SRR12798278-480720.err'  'get_fastq_pe_from_prefetch-accession=SRR12798291-480702.out'  'get_fastq_pe_from_prefetch-accession=SRR12798306-480688.err'
'get_fastq_pe_from_prefetch-accession=SRR12798278-480720.out'  'get_fastq_pe_from_prefetch-accession=SRR12798293-480690.err'  'get_fastq_pe_from_prefetch-accession=SRR12798306-480688.out'
'get_fastq_pe_from_prefetch-accession=SRR12798279-480706.err'  'get_fastq_pe_from_prefetch-accession=SRR12798293-480690.out'  'get_fastq_pe_from_prefetch-accession=SRR12798307-480710.err'
'get_fastq_pe_from_prefetch-accession=SRR12798279-480706.out'  'get_fastq_pe_from_prefetch-accession=SRR12798294-480700.err'  'get_fastq_pe_from_prefetch-accession=SRR12798307-480710.out'
'get_fastq_pe_from_prefetch-accession=SRR12798280-480709.err'  'get_fastq_pe_from_prefetch-accession=SRR12798294-480700.out'  'get_fastq_pe_from_prefetch-accession=SRR12798308-480722.err'
'get_fastq_pe_from_prefetch-accession=SRR12798280-480709.out'  'get_fastq_pe_from_prefetch-accession=SRR12798295-480713.err'  'get_fastq_pe_from_prefetch-accession=SRR12798308-480722.out'
'get_fastq_pe_from_prefetch-accession=SRR12798281-480695.err'  'get_fastq_pe_from_prefetch-accession=SRR12798295-480713.out'  'get_fastq_pe_from_prefetch-accession=SRR12798309-480701.err'
'get_fastq_pe_from_prefetch-accession=SRR12798281-480695.out'  'get_fastq_pe_from_prefetch-accession=SRR12798296-480715.err'  'get_fastq_pe_from_prefetch-accession=SRR12798309-480701.out'
'get_fastq_pe_from_prefetch-accession=SRR12798282-480717.err'  'get_fastq_pe_from_prefetch-accession=SRR12798296-480715.out'  'get_fastq_pe_from_prefetch-accession=SRR12798310-480694.err'
'get_fastq_pe_from_prefetch-accession=SRR12798282-480717.out'  'get_fastq_pe_from_prefetch-accession=SRR12798297-480711.err'  'get_fastq_pe_from_prefetch-accession=SRR12798310-480694.out'
'get_fastq_pe_from_prefetch-accession=SRR12798283-480712.err'  'get_fastq_pe_from_prefetch-accession=SRR12798297-480711.out'  'get_fastq_pe_from_prefetch-accession=SRR12798311-480696.err'
'get_fastq_pe_from_prefetch-accession=SRR12798283-480712.out'  'get_fastq_pe_from_prefetch-accession=SRR12798298-480691.err'  'get_fastq_pe_from_prefetch-accession=SRR12798311-480696.out'
'get_fastq_pe_from_prefetch-accession=SRR12798285-480714.err'  'get_fastq_pe_from_prefetch-accession=SRR12798298-480691.out'  'get_fastq_pe_from_prefetch-accession=SRR12798312-480692.err'
'get_fastq_pe_from_prefetch-accession=SRR12798285-480714.out'  'get_fastq_pe_from_prefetch-accession=SRR12798299-480703.err'  'get_fastq_pe_from_prefetch-accession=SRR12798312-480692.out'
'get_fastq_pe_from_prefetch-accession=SRR12798286-480705.err'  'get_fastq_pe_from_prefetch-accession=SRR12798299-480703.out'  'get_fastq_pe_from_prefetch-accession=SRR12798313-480693.err'
'get_fastq_pe_from_prefetch-accession=SRR12798286-480705.out'  'get_fastq_pe_from_prefetch-accession=SRR12798300-480698.err'  'get_fastq_pe_from_prefetch-accession=SRR12798313-480693.out'
'get_fastq_pe_from_prefetch-accession=SRR12798287-480697.err'  'get_fastq_pe_from_prefetch-accession=SRR12798300-480698.out'

results/slurm_logs/prefetch_accession:
'prefetch_accession-accession=SRR12798274-480668.err'  'prefetch_accession-accession=SRR12798287-480650.err'  'prefetch_accession-accession=SRR12798301-480680.err'
'prefetch_accession-accession=SRR12798274-480668.out'  'prefetch_accession-accession=SRR12798287-480650.out'  'prefetch_accession-accession=SRR12798301-480680.out'
'prefetch_accession-accession=SRR12798275-480683.err'  'prefetch_accession-accession=SRR12798288-480660.err'  'prefetch_accession-accession=SRR12798302-480651.err'
'prefetch_accession-accession=SRR12798275-480683.out'  'prefetch_accession-accession=SRR12798288-480660.out'  'prefetch_accession-accession=SRR12798302-480651.out'
'prefetch_accession-accession=SRR12798276-480653.err'  'prefetch_accession-accession=SRR12798289-480671.err'  'prefetch_accession-accession=SRR12798303-480661.err'
'prefetch_accession-accession=SRR12798276-480653.out'  'prefetch_accession-accession=SRR12798289-480671.out'  'prefetch_accession-accession=SRR12798303-480661.out'
'prefetch_accession-accession=SRR12798277-480662.err'  'prefetch_accession-accession=SRR12798290-480681.err'  'prefetch_accession-accession=SRR12798304-480672.err'
'prefetch_accession-accession=SRR12798277-480662.out'  'prefetch_accession-accession=SRR12798290-480681.out'  'prefetch_accession-accession=SRR12798304-480672.out'
'prefetch_accession-accession=SRR12798278-480673.err'  'prefetch_accession-accession=SRR12798291-480654.err'  'prefetch_accession-accession=SRR12798305-480643.err'
'prefetch_accession-accession=SRR12798278-480673.out'  'prefetch_accession-accession=SRR12798291-480654.out'  'prefetch_accession-accession=SRR12798305-480643.out'
'prefetch_accession-accession=SRR12798279-480685.err'  'prefetch_accession-accession=SRR12798292-480664.err'  'prefetch_accession-accession=SRR12798305-480682.err'
'prefetch_accession-accession=SRR12798279-480685.out'  'prefetch_accession-accession=SRR12798292-480664.out'  'prefetch_accession-accession=SRR12798305-480682.out'
'prefetch_accession-accession=SRR12798280-480656.err'  'prefetch_accession-accession=SRR12798293-480645.err'  'prefetch_accession-accession=SRR12798306-480652.err'
'prefetch_accession-accession=SRR12798280-480656.out'  'prefetch_accession-accession=SRR12798293-480645.out'  'prefetch_accession-accession=SRR12798306-480652.out'
'prefetch_accession-accession=SRR12798281-480665.err'  'prefetch_accession-accession=SRR12798293-480675.err'  'prefetch_accession-accession=SRR12798307-480663.err'
'prefetch_accession-accession=SRR12798281-480665.out'  'prefetch_accession-accession=SRR12798293-480675.out'  'prefetch_accession-accession=SRR12798307-480663.out'
'prefetch_accession-accession=SRR12798282-480644.err'  'prefetch_accession-accession=SRR12798294-480686.err'  'prefetch_accession-accession=SRR12798308-480674.err'
'prefetch_accession-accession=SRR12798282-480644.out'  'prefetch_accession-accession=SRR12798294-480686.out'  'prefetch_accession-accession=SRR12798308-480674.out'
'prefetch_accession-accession=SRR12798282-480677.err'  'prefetch_accession-accession=SRR12798295-480657.err'  'prefetch_accession-accession=SRR12798309-480684.err'
'prefetch_accession-accession=SRR12798282-480677.out'  'prefetch_accession-accession=SRR12798295-480657.out'  'prefetch_accession-accession=SRR12798309-480684.out'
'prefetch_accession-accession=SRR12798283-480647.err'  'prefetch_accession-accession=SRR12798296-480667.err'  'prefetch_accession-accession=SRR12798310-480655.err'
'prefetch_accession-accession=SRR12798283-480647.out'  'prefetch_accession-accession=SRR12798296-480667.out'  'prefetch_accession-accession=SRR12798310-480655.out'
'prefetch_accession-accession=SRR12798284-480658.err'  'prefetch_accession-accession=SRR12798297-480678.err'  'prefetch_accession-accession=SRR12798311-480666.err'
'prefetch_accession-accession=SRR12798284-480658.out'  'prefetch_accession-accession=SRR12798297-480678.out'  'prefetch_accession-accession=SRR12798311-480666.out'
'prefetch_accession-accession=SRR12798285-480669.err'  'prefetch_accession-accession=SRR12798298-480649.err'  'prefetch_accession-accession=SRR12798312-480646.err'
'prefetch_accession-accession=SRR12798285-480669.out'  'prefetch_accession-accession=SRR12798298-480649.out'  'prefetch_accession-accession=SRR12798312-480646.out'
'prefetch_accession-accession=SRR12798286-480679.err'  'prefetch_accession-accession=SRR12798299-480659.err'  'prefetch_accession-accession=SRR12798312-480676.err'
'prefetch_accession-accession=SRR12798286-480679.out'  'prefetch_accession-accession=SRR12798299-480659.out'  'prefetch_accession-accession=SRR12798312-480676.out'
'prefetch_accession-accession=SRR12798287-480642.err'  'prefetch_accession-accession=SRR12798300-480670.err'  'prefetch_accession-accession=SRR12798313-480648.err'
'prefetch_accession-accession=SRR12798287-480642.out'  'prefetch_accession-accession=SRR12798300-480670.out'  'prefetch_accession-accession=SRR12798313-480648.out'
```

All of that is specified in the `config.yaml` file in the slurm profile.

If you wanted snakemake to ensure that didn’t send too many jobs off at
once, you could ensure that it would pause itself so that there were no
more than 10 jobs running at any one time by doing:

``` sh
snakemake  --profile hpcc-profiles/slurm/sedna --jobs 10
```

When you run this, you will see that Snakemake uses the `threads`
parameters for each rule to determine how many cores to request. This
happens because of the `--cpus-per-task={threads}` line in the profile,
as seen above.

Notice also in the slurm profile the lines that say:

``` yaml
default-resources:
  - time="08:00:00"
  - mem_mb=4800
  - disk_mb=1000000
```

Those set the default job resources that Snakemake asks SLURM for.

If you need something different for a particular rule, you set that in
the rule definition in the Snakefile with a `resources` block, like in
the Snakefile in this repo:

``` python
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
 
 ...
```
