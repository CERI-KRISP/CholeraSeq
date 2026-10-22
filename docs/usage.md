# Usage

This page explains how to run the `CERI-KRISP/CholeraSeq` pipeline, what inputs it requires, and how to configure a typical analysis.

## What CholeraSeq does

<<<<<<< HEAD
**CERI-KRISP/CholeraSeq** is a Nextflow pipeline for genomic data analysis of Cholera outbreaks: quality control, reference-based variant calling and core-genome alignment, de novo assembly, MLST typing, AMR/virulence/plasmid screening, FastBAPS clustering, per-cluster recombination filtering (Gubbins), and phylogenetic reconstruction (IQ-TREE).
=======
CholeraSeq is a Nextflow DSL2 pipeline for *Vibrio cholerae* outbreak phylogenetics.
It processes either raw Illumina reads or FASTA assemblies, performs QC and reference-based variant calling, generates a recombination-masked core alignment, and infers a tree with `iqtree`.
>>>>>>> upstream/dev

For a detailed explanation of workflow stages, see [workflow.md](workflow.md).

## Required inputs

### Sample sheet

<<<<<<< HEAD
## Input

CholeraSeq accepts Illumina reads, Oxford Nanopore and PacBio long reads, and finished assemblies, in any mix. Samples can be listed in a samplesheet (`--input`), or found automatically from folders and accession lists. `--input` cannot be combined with the folder and list flags; the folder and list flags can all be combined in one run.

A reference GenBank file is always required: `--ref_genbank /path/to/reference.gbk`. The repository includes `resources/reference/GCF_003063785.full.gbk`. Use it to stay compatible with the published global core alignment.

### 1. Samplesheet (`--input`)

A comma-separated file with a header row, one row per sample. `sra_id` and `platform` are optional columns.
=======
CholeraSeq requires an input sample sheet in CSV format with a header row. Required columns are:

- `sample`
- `fastq_1`
- `fastq_2`

Each row can represent:

- paired-end reads (`fastq_1` and `fastq_2` present)
- single-end reads (`fastq_1` present, `fastq_2` blank)
- an assembly or contig FASTA (`fastq_1` contains a FASTA path, `fastq_2` blank)

Example sample sheet:
>>>>>>> upstream/dev

```csv
sample,fastq_1,fastq_2,sra_id,platform
SRR8364252,SRR8364252_1.fastq.gz,SRR8364252_2.fastq.gz,,illumina
SRR771360,SRR771360.fastq.gz,,,illumina
ONT_A,ONT_A.fastq.gz,,,nanopore
HIFI_A,HIFI_A.fastq.gz,,,pacbio_hifi
CLR_A,CLR_A.fastq.gz,,,pacbio_clr
SRR12345678,,,SRR12345678,illumina
AHGB01000000.1,AHGB01.fasta,,,
GCF_EXAMPLE,GCF_EXAMPLE_genomic.fna.gz,,,
```

<<<<<<< HEAD
| Column | Meaning |
|---|---|
| `sample` | Sample name |
| `fastq_1` | Reads (`.fastq.gz`/`.fq.gz`), or an assembly (`.fasta`/`.fna`/`.fa`, optionally gzipped). Assemblies are detected by their extension; they skip de novo assembly and are aligned straight to the reference |
| `fastq_2` | Second read file for paired-end Illumina data; leave empty otherwise |
| `sra_id` | An SRA/ENA run accession (SRR/ERR/DRR) to download instead of local files. Fill either `sra_id` or `fastq_1`, not both |
| `platform` | `illumina` (default when empty), `nanopore`, `pacbio_hifi`, `pacbio_clr`, or `pacbio` (chemistry taken from `--pacbio_mode`). Long-read rows must be single-end |

> 💡 **Hint**: for EBI-hosted files, use `https://` URLs rather than `ftp://`; `https://` has proven more reliable for staging large files.

### 2. Folders (no samplesheet)

| Flag | Contents |
|---|---|
| `--reads_dir` | Illumina fastq. Paired files (`<id>_R1/_R2.fastq.gz` or `<id>_1/_2.fastq.gz`) are paired up; any other `<id>.fastq.gz` is single-end. Tagged with `--platform` (default `illumina`) |
| `--ont_reads_dir` | Nanopore reads: each `.fastq.gz`/`.fq.gz` file is one sample |
| `--pacbio_hifi_reads_dir` | PacBio HiFi reads: each file is one sample |
| `--pacbio_clr_reads_dir` | PacBio CLR reads: each file is one sample |
| `--contigs_dir` | Assemblies (`.fasta`/`.fna`/`.fa`, optionally gzipped, e.g. NCBI's `<acc>_genomic.fna.gz`) |

```bash
nextflow run CERI-KRISP/CholeraSeq -profile docker --outdir results \
  --reads_dir illumina/ --ont_reads_dir ont/ \
  --pacbio_hifi_reads_dir hifi/ --pacbio_clr_reads_dir clr/ \
  --contigs_dir assemblies/ \
  --ref_genbank resources/reference/GCF_003063785.full.gbk
```

Things to know:

- **The sample name is the file name** without its extension. In `--contigs_dir`, a trailing `_contigs` is also removed. Keep names unique across folders.
- **Every matching file in `--contigs_dir` is a sample**, so keep unrelated fasta files, such as the reference, out of it.
- **Long-read folders only pick up `.fastq.gz`/`.fq.gz` files.** PacBio data delivered as BAM (e.g. `*.hifi_reads.bam`) or as uncompressed fastq is ignored without an error - convert it first, e.g. `samtools fastq x.bam | gzip > x.fastq.gz`.
- **In `--reads_dir`, a `_1`/`_R1` file without its mate is skipped.** Use a samplesheet to include it as single-end.

### 3. SRA/ENA accession lists (no samplesheet)

Plain text files, one run accession per line:

| Flag | Platform |
|---|---|
| `--sra_list` | Illumina |
| `--ont_sra_list` | Nanopore |
| `--pacbio_sra_list` | PacBio, with the chemistry from `--pacbio_mode` (`hifi` or `raw`) for the whole list |

For PacBio accessions of mixed chemistry, use a samplesheet with `sra_id` and `pacbio_hifi`/`pacbio_clr` rows instead. Downloads use `sra-tools` (`--download_method sratools`, the only implemented method; `ftp` and `aspera` stop with a clear message).

## Long-read samples

Nanopore and PacBio samples are quality-checked with NanoPlot, filtered with Filtlong, and assembled with Flye. Each assembly then follows the same path as any other assembly: alignment to the reference, typing and AMR screening, clustering and the phylogeny.

- **PacBio chemistry matters.** HiFi and CLR reads use different Flye modes (`--pacbio-hifi` and `--pacbio-raw`). The wrong mode can fail only after hours - for example, CLR data run in HiFi mode produced `No overlaps found!`. The pipeline does not detect the chemistry: choose the right folder flag or samplesheet value, and check the data's provenance when in doubt.
- **Capping coverage.** `--long_read_target_bases` keeps only the best reads up to that many bases per sample (Filtlong `--target_bases`). For example, `400000000` is about 100x of a 4 Mb genome, which shortens assembly on high-coverage data considerably.
- **Failed assemblies.** A sample that fails to assemble (too little data, non-genomic data, or a different organism) is skipped with a `NOTE`, and the run continues. Such samples are listed as `FAILED` in `pipeline_info/execution_trace_*.txt`. They are re-attempted on every `-resume`, because failed tasks are not cached.

## Samples excluded before clustering

Some samples cannot contribute to a core-genome alignment. They are dropped before clustering, with a warning naming each one:

- **No consensus sequence**, for example an assembly of a different organism that aligns to nothing.
- **Only part of the reference covered**, for example no reads on one chromosome. Every sequence in the alignment must be the reference's full length.
- **More missing data than `--max_missing_percentage`** (default 50%).

If nothing is left after these checks, the run stops with a clear message.
=======
### Reference genome

The pipeline uses a GenBank reference for mapping and variant extraction.
The default reference is `GCF_003063785.full.gbk` and can be overridden with `--ref_genbank`.
>>>>>>> upstream/dev

## Running the pipeline

### Example command

```bash
nextflow run CERI-KRISP/CholeraSeq \
<<<<<<< HEAD
         -profile docker \
         --input /path/to/samplesheet.csv \
         --outdir results

=======
  -profile docker \
  --input /path/to/samplesheet.csv \
  --outdir results
>>>>>>> upstream/dev
```

### Test run

<<<<<<< HEAD
> ⚠️ **Note**: running against `-profile docker` alone (without `test`) means none of `test.config`'s defaults apply - in particular you'll need to supply `--ref_genbank` yourself (variant calling always needs a reference, regardless of which input mode you use), and you may want to set `--max_memory`/`--max_cpus`/`--max_time` explicitly to match your machine, since the pipeline's own defaults (128.GB / 16 cpus / 240h) are sized for a shared cluster, not a laptop.

Note that the pipeline will create the following files in your working directory:
=======
A built-in `test` profile is available for validation:
>>>>>>> upstream/dev

```bash
nextflow run CERI-KRISP/CholeraSeq -profile test,docker --outdir test_output
```

### Use a params file

<<<<<<< HEAD
> ⚠️ **Command-line values on Nextflow 26.** A value typed after a flag arrives as text, not as a number or true/false. `--skip_x true` works, but `--skip_x false` does **not** switch a step on, and `--max_cpus 8` fails validation. Values in a params file keep their proper types, so use one for booleans set to `false` and for numbers such as `max_cpus`:
>
> ```yaml
> skip_fastbaps: false
> max_cpus: 8
> ```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

> ⚠️ Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).

The above pipeline run specified with a params file in yaml format:
=======
To reuse the same configuration across multiple runs, provide a parameter file:
>>>>>>> upstream/dev

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

> 💡 **Hint**: if you're developing against a local fork or clone, run the pipeline with `nextflow run . -profile ...` from inside the repository directory instead of `nextflow run CERI-KRISP/CholeraSeq ...` - the latter always pulls the upstream repository from GitHub, bypassing any local changes you haven't pushed.

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
