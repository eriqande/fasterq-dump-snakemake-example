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
