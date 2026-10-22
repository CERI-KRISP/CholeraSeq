[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.15167441-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.15167441)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/CERI-KRISP/CholeraSeq)

## Introduction

**CERI-KRISP/CholeraSeq** is a Nextflow pipeline for genomic analysis of Cholera outbreaks: quality control, reference-based variant calling and core-genome alignment, de novo assembly, MLST typing, AMR/virulence/plasmid screening, FastBAPS clustering, recombination filtering (Gubbins), and phylogenetic reconstruction (IQ-TREE).

It accepts Illumina reads, Oxford Nanopore and PacBio (HiFi or CLR) long reads, and finished assemblies, in any mix. Input can be given as a samplesheet, found automatically in folders, or downloaded from SRA/ENA by accession - see [Usage](#usage) below.

## Reference sequence

We have created a multi-fasta reference with global cohort available on NCBI, available at the link below.

[![Zenodo Dataset](http://img.shields.io/badge/DOI-10.5281/zenodo.10984554-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.10984554)

## Documentation

The documentation for the pipeline is hosted at https://ceri-krisp.github.io/CholeraSeq/

## Usage

### Input

Samples can be given in a samplesheet (`--input`), or found automatically from folders and accession lists. `--input` cannot be combined with the folder and list flags; the folder and list flags can all be combined in one run. A reference GenBank file (`--ref_genbank`) is always required - the repository includes `resources/reference/GCF_003063785.full.gbk`. Full details are on the [Usage](docs/usage.md#input) page.

**Samplesheet** - one row per sample; the `sra_id` and `platform` columns are optional:

```csv
sample,fastq_1,fastq_2,sra_id,platform
ILL_A,ILL_A_R1.fastq.gz,ILL_A_R2.fastq.gz,,illumina
ILL_B,ILL_B.fastq.gz,,,illumina
ONT_A,ONT_A.fastq.gz,,,nanopore
HIFI_A,HIFI_A.fastq.gz,,,pacbio_hifi
CLR_A,CLR_A.fastq.gz,,,pacbio_clr
DL_A,,,SRR8364252,illumina
ASM_A,ASM_A_genomic.fna.gz,,,
```

- `fastq_1` takes reads or an assembly (`.fasta`/`.fna`/`.fa`, optionally gzipped). Assemblies are detected by their extension and aligned straight to the reference.
- `sra_id` downloads the sample from SRA/ENA instead of using local files. Fill either `sra_id` or `fastq_1`, not both.
- `platform` is `illumina` (default), `nanopore`, `pacbio_hifi`, `pacbio_clr`, or `pacbio` (chemistry taken from `--pacbio_mode`). Long-read rows are single-end.

**Folders and accession lists** - no samplesheet needed:

| Flag | Contents |
|---|---|
| `--reads_dir` | Illumina fastq: paired (`<id>_R1/_R2` or `<id>_1/_2`) and single-end (`<id>.fastq.gz`) |
| `--ont_reads_dir` | Nanopore reads, one `.fastq.gz`/`.fq.gz` file per sample |
| `--pacbio_hifi_reads_dir` | PacBio HiFi reads, one file per sample |
| `--pacbio_clr_reads_dir` | PacBio CLR reads, one file per sample |
| `--contigs_dir` | Assemblies (`.fasta`/`.fna`/`.fa`, optionally gzipped); every matching file is a sample |
| `--sra_list` | Text file of Illumina SRA/ENA accessions, one per line |
| `--ont_sra_list` | Text file of Nanopore accessions |
| `--pacbio_sra_list` | Text file of PacBio accessions (chemistry from `--pacbio_mode`) |

```bash
nextflow run CERI-KRISP/CholeraSeq -profile docker --outdir results \
  --reads_dir illumina/ --ont_reads_dir ont/ --pacbio_clr_reads_dir clr/ --contigs_dir assemblies/ \
  --ref_genbank resources/reference/GCF_003063785.full.gbk
```

### Long-read samples

Nanopore and PacBio samples are quality-checked (NanoPlot), filtered (Filtlong) and assembled (Flye). Each assembly then follows the same path as any other assembly: alignment to the reference, typing and AMR screening, clustering and the phylogeny.

- **PacBio chemistry matters.** HiFi and CLR data use different Flye modes, and the wrong mode can fail after hours of work. The pipeline does not detect the chemistry - set it per folder or per samplesheet row.
- **`--long_read_target_bases`** caps the reads used per sample (for example `400000000`, about 100x of a 4 Mb genome), which shortens assembly on high-coverage data.
- **A sample that fails to assemble is skipped** with a `NOTE`, and the run continues. Skipped samples are listed as `FAILED` in `pipeline_info/execution_trace_*.txt`.

### Key analysis-step flags

| Flag | Default | Purpose |
|---|---|---|
| `--skip_assembly` | `false` | Skip SPAdes, MLST and ABRicate entirely |
| `--skip_mlst` | `false` | Skip MLST typing only |
| `--skip_amr` | `false` | Skip ABRicate screening only |
| `--skip_clustering` | `false` | Skip clustering, recombination filtering and the phylogeny |
| `--skip_fastbaps` | `true` | Skip FastBAPS, so Gubbins runs on the whole alignment. With `false`, Gubbins runs per FastBAPS cluster; clusters smaller than `--min_partition_size` (default 4) are skipped and their samples are not in the final tree |
| `--max_missing_percentage` | `50` | Samples with more missing data than this are excluded before clustering |

> **Command-line values on Nextflow 26.** A value typed after a flag arrives as text: `--skip_fastbaps false` does not switch a step on, and `--max_cpus 8` fails validation. Put such values in a params file instead and pass it with `-params-file params.yaml`:
>
> ```yaml
> skip_fastbaps: false
> max_cpus: 8
> ```

### Computing resources

By default a task may use up to 16 CPUs, 128 GB and 240 h. On a smaller machine lower these, for example `--max_memory 20.GB`. IQ-TREE is allowed up to 72 h because large datasets need it, so keep `--max_time` at or above `72.h`. Gubbins deliberately runs single-threaded: its recombination output is not thread-safe. For long runs use `tmux`, `screen` or `nohup`, so a closed terminal does not stop the run.

Run `nextflow run CERI-KRISP/CholeraSeq --help` for the full parameter list.

## Testing

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
