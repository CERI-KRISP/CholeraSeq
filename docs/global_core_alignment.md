# Global core alignment

:::{.callout-tip}
This document assume that you have already read through the [Usage](./usage.md) document
:::


## Updating Global core alignment dataset

We have created a multi-fasta reference with global cohort available on NCBI, available at [this link](https://doi.org/10.5281/zenodo.10984554)

## Using FASTA sequences

We intend to keep this core alignment updated on a quarterly (or annual ) and are actively looking for funding for long term sustenance.

However, we also want to highlight that it is very straightforward to create custom alignment using the CholeraSeq pipeline.

Essentially, you'd need to

1. Create a samplesheet with the downloaded/precomputed sequences (FASTA files) as shown below


```csv
sample,fastq_1,fastq_2
AHGB01000000.1,https://github.com/CERI-KRISP/CholeraSeq/raw/b0beafcc6c1315e2782667f0306b10f8b3b7e09a/resources/test_fastas/AHGB01.fasta,
AHGB01000000.2,/path/to/your/fasta/file,
```

2. Instruct the pipeline to use the existing global core alignment using the `global_core_alignment` parameter either on the command or through the parameters yaml file.


:::{.callout-tip}
And that's it! The pipline will automatically process the individual FASTA files as per the existing thresholds and then merge them with the global core alignment.
:::


You can now initiate the pipeline with:

```bash
nextflow run https://github.com/CERI-KRISP/CholeraSeq -profile docker -params-file params.yaml
```

with `params.yaml` containing:

```yaml
input: "/path/to/desired/samplesheet.csv"
outdir: "/path/to/desired/output/directory"
global_core_alignment: "/path/to/existing/global_core_alignment"

# other parameters
```



## Using existing local core alignment

In case you have already created a local core alignment (from the initial FASTA files) and you wish to add it to the global core alignment (or any pre-existing alignment), you can make use of the ``

You can now initiate the pipeline with:

```bash
nextflow run https://github.com/CERI-KRISP/CholeraSeq -profile docker -params-file params.yaml
```

with `params.yaml` containing:

```yaml
input: "/path/to/desired/samplesheet.csv"
outdir: "/path/to/desired/output/directory"

# Provide existing core alignments, to be merged
global_core_alignment: "/path/to/existing/global_core_alignment"
cohort_core_alignment : "/path/to/existing/cohort_core_alignment"

# other parameters
```
