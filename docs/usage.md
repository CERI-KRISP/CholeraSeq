# Usage

This page explains how to run the `CERI-KRISP/CholeraSeq` pipeline, what inputs it requires, and how to configure a typical analysis.

## What CholeraSeq does

CholeraSeq is a Nextflow DSL2 pipeline for *Vibrio cholerae* outbreak phylogenetics.
It processes Illumina reads, Oxford Nanopore and PacBio long reads, or FASTA assemblies, in any mix. It performs QC and reference-based variant calling, generates a recombination-masked core alignment, and infers a tree with `iqtree`. Alongside the phylogeny, it assembles read data and screens assemblies for sequence type and for AMR, virulence and plasmid genes.

For a detailed explanation of workflow stages, see [workflow.md](workflow.md).

## Inputs

Samples can be listed in a sample sheet (`--input`), found in folders, or downloaded from SRA/ENA accession lists. `--input` cannot be combined with the folder and list options; the folder and list options can all be combined in one run.

### Sample sheet

The sample sheet is a CSV file with a header row. Required columns are:

- `sample`
- `fastq_1`
- `fastq_2`

Each row can represent:

- paired-end Illumina reads (`fastq_1` and `fastq_2` present)
- single-end reads (`fastq_1` present, `fastq_2` blank)
- an assembly or contig FASTA (`fastq_1` contains a `.fasta`/`.fna`/`.fa` path, optionally gzipped; `fastq_2` blank). Assemblies skip de novo assembly and are aligned straight to the reference.

Two optional columns are supported:

| Column | Meaning |
| --- | --- |
| `sra_id` | An SRA/ENA run accession (SRR/ERR/DRR) to download instead of local files. Fill either `sra_id` or `fastq_1`, not both. |
| `platform` | `illumina` (default when empty), `nanopore`, `pacbio_hifi`, `pacbio_clr`, or `pacbio` (chemistry taken from `--pacbio_mode`). Long-read rows must be single-end. |

Example sample sheet:

```csv
sample,fastq_1,fastq_2,sra_id,platform
SRR8364252,https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR836/002/SRR8364252/SRR8364252_1.fastq.gz,https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR836/002/SRR8364252/SRR8364252_2.fastq.gz,,illumina
SRR771360,https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR771/SRR771360/SRR771360.fastq.gz,,,illumina
AHGB01000000.1,https://github.com/CERI-KRISP/CholeraSeq/raw/b0beafcc6c1315e2782667f0306b10f8b3b7e09a/resources/test_fastas/AHGB01.fasta,,,
ONT_A,/data/ONT_A.fastq.gz,,,nanopore
CLR_A,/data/CLR_A.fastq.gz,,,pacbio_clr
SRR12345678,,,SRR12345678,illumina
```

> **Tip:** for EBI-hosted files, use `https://` URLs rather than `ftp://`; `https://` has proven more reliable for staging large files.

### Folders

No sample sheet is needed when samples are found in folders:

| Option | Contents |
| --- | --- |
| `--reads_dir` | Illumina fastq. Paired files (`<id>_R1/_R2.fastq.gz` or `<id>_1/_2.fastq.gz`) are paired up; any other `<id>.fastq.gz` is single-end. Tagged with `--platform` (default `illumina`). |
| `--ont_reads_dir` | Nanopore reads: each `.fastq.gz`/`.fq.gz` file is one sample. |
| `--pacbio_hifi_reads_dir` | PacBio HiFi reads: each file is one sample. |
| `--pacbio_clr_reads_dir` | PacBio CLR reads: each file is one sample. |
| `--contigs_dir` | Assemblies (`.fasta`/`.fna`/`.fa`, optionally gzipped, e.g. NCBI's `<acc>_genomic.fna.gz`). Every matching file is a sample. |

```bash
nextflow run CERI-KRISP/CholeraSeq -profile docker --outdir results \
  --reads_dir illumina/ --ont_reads_dir ont/ \
  --pacbio_hifi_reads_dir hifi/ --pacbio_clr_reads_dir clr/ \
  --contigs_dir assemblies/ \
  --ref_genbank resources/reference/GCF_003063785.full.gbk
```

Things to know:

- **The sample name is the file name** without its extension. In `--contigs_dir`, a trailing `_contigs` is also removed. Keep names unique across folders.
- **Keep unrelated FASTA files, such as the reference, out of `--contigs_dir`.**
- **Long-read folders only pick up `.fastq.gz`/`.fq.gz` files.** PacBio data delivered as BAM (e.g. `*.hifi_reads.bam`) or as uncompressed fastq is ignored without an error. Convert it first, e.g. `samtools fastq x.bam | gzip > x.fastq.gz`.
- **In `--reads_dir`, a `_1`/`_R1` file without its mate is skipped without a warning.** Use a sample sheet to include it as single-end.

### SRA/ENA accession lists

Plain text files, one run accession per line:

| Option | Platform |
| --- | --- |
| `--sra_list` | Illumina |
| `--ont_sra_list` | Nanopore |
| `--pacbio_sra_list` | PacBio, with the chemistry from `--pacbio_mode` (`hifi` or `raw`) applied to the whole list |

For PacBio accessions of mixed chemistry, use a sample sheet with `sra_id` and `pacbio_hifi`/`pacbio_clr` rows instead. Downloads use `sra-tools` (`--download_method sratools`, the only implemented method; `ftp` and `aspera` stop with a clear message).

### Reference genome

The pipeline uses a GenBank reference for mapping and variant extraction, given with `--ref_genbank`. It has no default and must be set for every run except the `test` profile, which sets it. Use the included `resources/reference/GCF_003063785.full.gbk` for compatibility with the published global core alignment.

## Long-read samples

Nanopore and PacBio samples are quality-checked with NanoPlot, filtered with Filtlong, and assembled with Flye. Each assembly then follows the same path as any other assembly: alignment to the reference, typing and AMR screening, clustering and the phylogeny.

- **PacBio chemistry matters.** HiFi and CLR reads use different Flye modes (`--pacbio-hifi` and `--pacbio-raw`). The wrong mode can fail only after hours; for example, CLR data run in HiFi mode produced `No overlaps found!`. The pipeline does not detect the chemistry, so choose the right folder option or sample sheet value, and check the data's provenance when in doubt.
- **Capping coverage.** `--long_read_target_bases` keeps only the best reads up to that many bases per sample (Filtlong `--target_bases`). For example, `400000000` is about 100x of a 4 Mb genome, which shortens assembly on high-coverage data considerably.
- **Failed assemblies.** A sample that fails to assemble (too little data, non-genomic data, or a different organism) is skipped with a `NOTE`, and the run continues. Such samples are listed as `FAILED` in `pipeline_info/execution_trace_*.txt`. They are re-attempted on every `-resume`, because failed tasks are not cached.

## Samples excluded before clustering

Some samples cannot contribute to a core-genome alignment. They are left out before clustering, with a warning naming each one:

- **No consensus sequence**, for example an assembly of a different organism that aligns to nothing.
- **Only part of the reference covered**, for example no reads on one chromosome. Every sequence in the alignment must be the reference's full length.
- **More missing data than `--max_missing_percentage`** (default 50%).

If nothing is left after these checks, the run stops with a clear message.

## Running the pipeline

### Example command

```bash
nextflow run CERI-KRISP/CholeraSeq \
  -profile docker \
  --input /path/to/samplesheet.csv \
  --ref_genbank resources/reference/GCF_003063785.full.gbk \
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

> **Command-line values on Nextflow 26.** A value typed after a parameter on the command line arrives as text, not as a number or true/false. `--skip_x true` works, but `--skip_x false` does **not** switch a step on, and `--max_cpus 8` fails validation. Values in a params file keep their proper types, so use one for booleans set to `false` and for numbers such as `max_cpus`.

### Reproducibility

Specifying a pipeline release tag ensures the same code version is used:

```bash
nextflow run CERI-KRISP/CholeraSeq -r 1.2.0 -profile docker --input samplesheet.csv --outdir results
```

### Output locations

The pipeline writes results into the specified `--outdir` and creates a `work/` directory in the current working directory.
Nextflow also writes log and metadata files such as `.nextflow_log`.

### Computing resources and long runs

- By default a task may use up to 16 CPUs, 128 GB and 240 h (`max_cpus`, `max_memory`, `max_time`). On a smaller machine, lower them, for example `--max_memory 20.GB`.
- IQ-TREE is allowed up to 72 h, because large datasets need it. Keep `max_time` at or above `72.h`.
- Gubbins deliberately runs single-threaded: with several threads its recombination output (GFF) can be corrupted.
- For long runs, use `tmux`, `screen` or `nohup`, so a closed terminal or a dropped SSH connection does not stop the run.

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
- `reads_dir`, `ont_reads_dir`, `pacbio_hifi_reads_dir`, `pacbio_clr_reads_dir`, `contigs_dir`: folders to find samples in
- `sra_list`, `ont_sra_list`, `pacbio_sra_list`: accession lists to download
- `outdir`: output directory
- `ref_genbank`: reference GenBank file (required)
- `global_core_alignment`: input global core alignment file
- `cohort_core_alignment`: input cohort core alignment file
- `skip_fastbaps`: skip FastBAPS clustering
- `skip_clustering`: skip the clustering and tree workflow
- `skip_assembly`, `skip_mlst`, `skip_amr`: skip assembly, typing or AMR screening
- `max_missing_percentage`: missing-data filter threshold
- `pacbio_mode`, `long_read_target_bases`: long-read assembly settings

## Profiles and containers

This pipeline supports containerized execution through Docker, Singularity, Podman, and Conda. For reproducibility, use Docker or Singularity whenever possible.

If your environment requires a custom cluster profile, test it with `-c` and consult [nf-core/configs](https://github.com/nf-core/configs).

## Getting help

- [workflow.md](workflow.md) — how the pipeline stages connect
- [parameters.md](parameters.md) — parameter reference
- [output.md](output.md) — result files and locations

If you encounter errors, inspect `.nextflow_log` and the generated `pipeline_info/` reports.
