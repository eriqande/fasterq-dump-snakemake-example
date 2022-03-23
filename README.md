fasterq-dump-snakemake-example
================

This is a super small example that uses Snakemake to get fastq files
from the Short Read Archive using `fasterq-dump`. We originally tried to
use the Snakemake wrapper for this, but that seemed to make SUMMIT
unhappy, so we just went minimal and do it with a simple shell block.

Note that the output file names can’t be changed without messing with
the shell script (i.e., the `-O` option to fasterq-dump). So, this isn’t
super general, but it will work.

It is configured so that rule all downloads the first five pearl millet
accessions from the SRA.

To run this on SUMMIT, you should be on `scompile` by doing
`ssh scompile`.

First you need to clone this repository. SUMMIT has some issues with its
ssh agent so you probably have to do this to get things from GitHub
(assuming that you have your SSH keys set up in \`id\_ed25519’)

``` sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# enter your passphrase if you have one

# then do this IN YOUR scratch DIRECTORY
git clone git@github.com:eriqande/fasterq-dump-snakemake-example.git
```

Then, you have to have a snakemake conda environment. If you don’t have
that you can install it with mamba.

Then `cd` into the `fasterq-dump-snakemake-example` and issue the
following commands to install the programs that are needed.

``` sh
conda activate snakemake
snakemake --use-conda --conda-create-envs-only --cores 1
```

Once that is done, from `scompile` (and also logged in via a TMUX
session so that things don’t die after you logout), do this command from
within your snakemake conda environment

``` sh
snakemake --use-conda --profile slurm_profile --jobs 10
```

That starts each of the jobs using `sbatch`, and the run simultaneously.

From another shell you can say:

``` sh
squeue -u $(whoami)
```

to see you currently running jobs.
