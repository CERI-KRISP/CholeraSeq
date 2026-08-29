[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.15167441-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.15167441)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/CERI-KRISP/CholeraSeq)

# CholeraSeq

`CERI-KRISP/CholeraSeq` is a Nextflow DSL2 pipeline for phylogenetic analysis of *Vibrio cholerae* outbreak data.
It converts raw reads or genome assemblies into a recombination-masked core-genome alignment and infers a maximum likelihood tree with `iqtree`.

## What it does

- accepts paired-end or single-end Illumina reads, or FASTA assemblies
- performs QC and trimming on reads with `fastp`
- maps data to a reference genome using `snippy`
- generates consensus FASTA sequences and concatenates them into a cohort alignment
- masks recombination with `gubbins`
- extracts codon-aware variable sites using `varcodons.py`
- infers an ML phylogeny with `iqtree`
- aggregates QC and workflow reports via `MultiQC`

> This pipeline is aimed at phylogenetics and outbreak analysis. It does not provide AMR profiling, MLST typing, serotype prediction, or pangenome analysis.

## Quick start

```bash
nextflow run CERI-KRISP/CholeraSeq \
  -profile docker \
  --input /path/to/samplesheet.csv \
  --outdir results
```

For a full test run:

```bash
nextflow run CERI-KRISP/CholeraSeq -profile test,docker --outdir test_output
```

For Singularity:

```bash
nextflow run CERI-KRISP/CholeraSeq -profile test,singularity --outdir test_output
```

## Input requirements

The pipeline expects an input sample sheet in CSV format with at least these columns:

- `sample`
- `fastq_1`
- `fastq_2`

For single-end or assembly inputs, set `fastq_2` to blank. Assemblies are accepted as FASTA files in `fastq_1`.

## Documentation

The pipeline documentation is available in the `docs/` directory and includes:

- `docs/usage.md`
- `docs/parameters.md`
- `docs/output.md`
- `docs/workflow.md`

## Reference sequence

The pipeline uses a reference GenBank file for mapping and variant extraction. A global reference cohort is available via Zenodo:

[![Zenodo Dataset](http://img.shields.io/badge/DOI-10.5281/zenodo.10984554-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.10984554)

## Contributions and support

If you want to contribute, see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

Please cite the pipeline and underlying tools when using CholeraSeq.
See `CITATIONS.md` for a full list of referenced software and data sources.

## License

This pipeline is released under the MIT License.
