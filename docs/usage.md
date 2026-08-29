# Usage

This page explains how to run the `CERI-KRISP/CholeraSeq` pipeline, what inputs it requires, and how to configure a typical analysis.

## What CholeraSeq does

CholeraSeq is a Nextflow DSL2 pipeline for *Vibrio cholerae* outbreak phylogenetics.
It processes either raw Illumina reads or FASTA assemblies, performs QC and reference-based variant calling, generates a recombination-masked core alignment, and infers a tree with `iqtree`.

For a detailed explanation of workflow stages, see [workflow.md](workflow.md).

## Required inputs

### Sample sheet

CholeraSeq requires an input sample sheet in CSV format with a header row. Required columns are:

- `sample`
- `fastq_1`
- `fastq_2`

Each row can represent:

- paired-end reads (`fastq_1` and `fastq_2` present)
- single-end reads (`fastq_1` present, `fastq_2` blank)
- an assembly or contig FASTA (`fastq_1` contains a FASTA path, `fastq_2` blank)

Example sample sheet:

```csv
sample,fastq_1,fastq_2
SRR8364252,ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR836/002/SRR8364252/SRR8364252_1.fastq.gz,ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR836/002/SRR8364252/SRR8364252_2.fastq.gz
SRR771360,ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR771/SRR771360/SRR771360.fastq.gz,
AHGB01000000.1,https://github.com/CERI-KRISP/CholeraSeq/raw/b0beafcc6c1315e2782667f0306b10f8b3b7e09a/resources/test_fastas/AHGB01.fasta,
```

### Reference genome

The pipeline uses a GenBank reference for mapping and variant extraction.
The default reference is `GCF_003063785.full.gbk` and can be overridden with `--ref_genbank`.

## Running the pipeline

### Example command

```bash
nextflow run CERI-KRISP/CholeraSeq \
  -profile docker \
  --input /path/to/samplesheet.csv \
  --outdir results
```

### Test run

A built-in `test` profile is available for validation:

```bash
nextflow run CERI-KRISP/CholeraSeq -profile test,docker --outdir test_output
```

### Use a params file

To reuse the same configuration across multiple runs, provide a parameter file:

```bash
nextflow run CERI-KRISP/CholeraSeq -profile docker -params-file params.yaml
```

Example `params.yaml`:

```yaml
input: ./samplesheet.csv
outdir: ./results/
ref_genbank: ./resources/reference/GCF_003063785.full.gbk
skip_fastbaps: true
```

### Reproducibility

Specifying a pipeline release tag ensures the same code version is used:

```bash
nextflow run CERI-KRISP/CholeraSeq -r 1.2.0 -profile docker --input samplesheet.csv --outdir results
```

### Output locations

The pipeline writes results into the specified `--outdir` and creates a `work/` directory in the current working directory.
Nextflow also writes log and metadata files such as `.nextflow_log`.

## Nextflow command-line options

> **Note:** these options are part of Nextflow and use a single hyphen. Pipeline parameters use double hyphens.

### `-profile`

Choose a configuration profile for software execution.
Common pipeline-supported profiles include:

- `docker`
- `singularity`
- `podman`
- `conda`
- `test`

Example:

```bash
nextflow run CERI-KRISP/CholeraSeq -profile test,docker --outdir test_output
```

### `-resume`

Resume a previous run using cached results when input files and parameters are unchanged.

### `-params-file`

Provide a YAML or JSON file with pipeline parameters.

### `-c`

Use this to load a custom Nextflow config file (typically for cluster or resource settings), not for pipeline parameters.

## Key parameters

See [parameters.md](parameters.md) for the full parameter reference. Common settings include:

- `input`: path to the sample sheet
- `outdir`: output directory
- `ref_genbank`: reference GenBank file
- `global_core_alignment`: input global core alignment file
- `cohort_core_alignment`: input cohort core alignment file
- `skip_fastbaps`: skip FastBAPS clustering
- `skip_clustering`: skip the clustering and tree workflow
- `max_missing_percentage`: missing-data filter threshold

## Profiles and containers

This pipeline supports containerized execution through Docker, Singularity, Podman, and Conda. For reproducibility, use Docker or Singularity whenever possible.

If your environment requires a custom cluster profile, test it with `-c` and consult [nf-core/configs](https://github.com/nf-core/configs).

## Getting help

- [workflow.md](workflow.md) — how the pipeline stages connect
- [parameters.md](parameters.md) — parameter reference
- [output.md](output.md) — result files and locations

If you encounter errors, inspect `.nextflow_log` and the generated `pipeline_info/` reports.
