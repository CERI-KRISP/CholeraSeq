[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.15167441-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.15167441)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/CERI-KRISP/CholeraSeq)

## Introduction

**CERI-KRISP/CholeraSeq** is a Nextflow pipeline for genomic analysis of Cholera outbreaks: quality control, reference-based variant calling and core-genome alignment, de novo assembly, MLST typing, AMR/virulence/plasmid screening, FastBAPS clustering, per-cluster recombination filtering (Gubbins), and phylogenetic reconstruction (IQ-TREE).

Input can be provided as a samplesheet, or auto-discovered directly from a directory of fastq files, a directory of pre-assembled contigs, or a list of SRA/ENA accessions to download - see [Usage](#usage) below.

## Reference sequence

We have created a multi-fasta reference with global cohort available on NCBI, available at the link below.

[![Zenodo Dataset](http://img.shields.io/badge/DOI-10.5281/zenodo.10984554-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.10984554)

## Documentation

The documentation for the pipeline is hosted at https://ceri-krisp.github.io/CholeraSeq/

## Usage

### Input modes

CholeraSeq accepts input in one of four ways. `--input` is mutually exclusive with the other three; `--reads_dir`/`--contigs_dir`/`--sra_list` can be freely combined with each other in a single run.

**1. Samplesheet (`--input`)** - the standard nf-core-style CSV, one row per sample:

```csv
sample,fastq_1,fastq_2
SAMPLE_1,SAMPLE_1_R1.fastq.gz,SAMPLE_1_R2.fastq.gz
SAMPLE_2,SAMPLE_2.fastq.gz,
SAMPLE_3,SAMPLE_3.fasta,
```

`fastq_1` accepts either fastq (single- or paired-end, via `fastq_2`) or a pre-assembled contigs fasta - contig inputs are detected automatically from the file extension and skip assembly/variant-calling steps that don't apply.

A samplesheet row can alternatively populate `sra_id` instead of `fastq_1`/`fastq_2`, to download that sample from SRA/ENA rather than supplying local files:

```csv
sample,fastq_1,fastq_2,sra_id
SAMPLE_1,,,SRR8364252
```

```bash
nextflow run CERI-KRISP/CholeraSeq -profile docker --outdir results --input samplesheet.csv
```

**2. Directory auto-discovery (`--reads_dir` / `--contigs_dir`)** - no samplesheet needed:

```bash
nextflow run CERI-KRISP/CholeraSeq -profile docker --outdir results \
  --reads_dir /path/to/fastqs --contigs_dir /path/to/contigs
```

`--reads_dir` picks up both paired-end (`<id>_R1/_R2.fastq.gz` or `<id>_1/_2.fastq.gz`) and single-end (`<id>.fastq.gz`) files. `--contigs_dir` picks up pre-assembled genomes (`.fasta`/`.fna`/`.fa`, optionally gzipped - e.g. NCBI's `<acc>_genomic.fna.gz`); each assembly is aligned to the reference genome and carried through the downstream analysis. Every matching fasta in the directory is treated as a sample.

**3. SRA/ENA accession list (`--sra_list`)** - a plain text file, one accession per line:

```bash
nextflow run CERI-KRISP/CholeraSeq -profile docker --outdir results --sra_list accessions.txt
```

Downloads currently go via `sra-tools` (`--download_method sratools`, the default and only implemented method - `ftp`/`aspera` are scaffolded for future use and will fail fast with a clear message if selected).

### Key analysis-step flags

| Flag | Default | Purpose |
|---|---|---|
| `--skip_assembly` | `false` | Skip SPAdes/MLST/ABRicate entirely |
| `--skip_mlst` | `false` | Skip MLST typing only |
| `--skip_amr` | `false` | Skip ABRicate AMR/virulence/plasmid screening only |
| `--skip_fastbaps` | `true` | Skip FastBAPS clustering (whole-alignment Gubbins if `false`... see `--skip_clustering`) |
| `--skip_clustering` | `false` | Skip clustering/recombination/phylogeny entirely |
| `--min_partition_size` | `4` | Minimum sequences per FastBAPS cluster to run Gubbins/RAxML on |

Run `nextflow run CERI-KRISP/CholeraSeq --help` for the full parameter list.



A built-in test profile are available in the choleraseq pipeline with different size of datasets. This profile can be used to run tests on the relevant infrastructure using the `test` profile, to help users identify and resolve any infrastructural issue before the analysis stage.

**NOTE**: The snippets below assumes you have `docker` on the sever/machine you wish to test the pipeline. For other institutional configs please refer [nf-core/configs](https://nf-co.re/docs/usage/configuration#max-resources) project, which are all applicable to this pipeline.

```bash

$ nextflow run CERI-KRISP/CholeraSeq \
  -profile test,docker --outdir test_output

```

For `singularity` please use the following command

```bash

$ nextflow run CERI-KRISP/CholeraSeq \
  -profile test,singularity --outdir test_output

```

## Credits

CERI-KRISP/CholeraSeq was originally written by the CholeraSeq publication authors.

<!-- FIXME add publication -->

De novo assembly (SPAdes), MLST typing, AMR/virulence/plasmid screening (ABRicate), and the SRA download / directory auto-discovery input modes were integrated from [ottovon-dakurah/Cholera_genomics](https://github.com/ottovon-dakurah/Cholera_genomics).

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use  CERI-KRISP/CholeraSeq for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
