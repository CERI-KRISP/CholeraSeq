# Parameters

This document provides an overview of the customizable parameters for the CHOLERASEQ pipeline. Each parameter is listed with its default value, description.

> 💡 **Hint**: you may check a full parameters [reference file](https://github.com/CERI-KRISP/CholeraSeq/blob/master/nextflow.config).

---

## Common Parameters

### Input options

Samples come from a samplesheet (`input`), or from folders and accession lists. `input` cannot be combined with the others; all folder and list options can be combined in one run. See [Usage](./usage.md#input) for examples.

| Parameter | Default | Description |
| --- | --- | --- |
| `input` | `null` | Samplesheet CSV: columns `sample,fastq_1,fastq_2`, plus optional `sra_id` and `platform` |
| `reads_dir` | `null` | Folder of Illumina fastq: paired (`<id>_R1/_R2` or `<id>_1/_2`) and single-end (`<id>.fastq.gz`) |
| `ont_reads_dir` | `null` | Folder of Nanopore reads, one `.fastq.gz`/`.fq.gz` per sample |
| `pacbio_hifi_reads_dir` | `null` | Folder of PacBio HiFi reads, one file per sample |
| `pacbio_clr_reads_dir` | `null` | Folder of PacBio CLR reads, one file per sample |
| `contigs_dir` | `null` | Folder of assemblies (`.fasta`/`.fna`/`.fa`, optionally gzipped); every matching file is a sample |
| `sra_list` | `null` | Text file of Illumina SRA/ENA accessions, one per line |
| `ont_sra_list` | `null` | Text file of Nanopore accessions |
| `pacbio_sra_list` | `null` | Text file of PacBio accessions; chemistry from `pacbio_mode` |
| `platform` | `illumina` | Platform for samples found in `reads_dir`: `illumina`, `nanopore`, `pacbio`, `pacbio_hifi` or `pacbio_clr` |
| `download_method` | `sratools` | How accessions are downloaded. Only `sratools` is implemented; `ftp` and `aspera` stop with a clear message |

---

### Output Directory

| Parameter | Default Value | Description                                           |
| --------- | ------------- | ----------------------------------------------------- |
| `outdir`  | `null`        | The directory where all output files will be written. |

---

## Quality Control Parameters

> ⚠️ **Attention**: Ensure these values are adjusted based on the quality of your input data to avoid processing errors.
> The defaults are set to faciliate a majority of users. Only advanced users are recommended to change these.

| Parameter                | Default Value | Description                                                                                                                                                                                              |
| ------------------------ | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `min_trim_quality`       | 20            | Fastq reads mean quality threshold 20 fastp                                                                                                                                                              |
| `min_trim_length`        | 35            | Fastq read minimum trim length (fastp)                                                                                                                                                                   |
| `min_mapping_quality`    | 20            | minimum mapping quality 20 samtools consensus samtools --min-MQ                                                                                                                                          |
| `min_base_quality`       | 20            | minimum base quality 20 samtools consensus samtools --min-BQ                                                                                                                                             |
| `min_site_coverage`      | 5             | mimimum site coverage 5 samtools consensus + snippy samtools --min-depth 5; snippy --mincov 5                                                                                                            |
| `min_allele_fraction`    | 0.75          | minimum fraction supporting allele call 0.75 samtools consensus + snippy samtools -c 0.75; snippy --minfrac 0.75                                                                                         |
| `snippy_minqual`         | 100           | minimum variant call quality; snippy --minqual                                                                                                                                                           |
| `max_missing_percentage` | 50            | Most missing data (as a percentage of the genome) a sample may have; samples above it are excluded before clustering (seqcleaner) and by Gubbins |
| `min_parsimony_coverage` | 0.7           | varcodons.py pi job minimum site coverage for varcodons to keep site when generating pi output                                                                                                           |

---

## Assembly, Typing & AMR Parameters

De novo assembly (SPAdes), MLST typing, and AMR/virulence/plasmid screening (ABRicate). Skipped automatically for samples that are already contigs (assembly only).

| Parameter          | Default Value | Description                                                                 |
| -------------------- | -------------- | ----------------------------------------------------------------------------- |
| `skip_assembly`      | `false`        | Skip the whole assembly/typing/AMR subworkflow (SPAdes + MLST + ABRicate).    |
| `skip_mlst`          | `false`        | Skip MLST typing only.                                                        |
| `skip_amr`           | `false`        | Skip ABRicate AMR/virulence/plasmid screening only.                           |
| `spades_mode`        | `careful`      | SPAdes assembly mode (`careful`, `isolate`, `meta`, `rna`, or `""` for default). |
| `spades_cov`         | `auto`         | SPAdes `--cov-cutoff` value (`auto`, `off`, or a number).                     |
| `abricate_minid`     | 80             | ABRicate minimum %identity to report a hit.                                   |
| `abricate_mincov`    | 80             | ABRicate minimum %coverage to report a hit.                                   |

---

## Skipping Pipeline Steps

| Parameter           | Default Value | Description                                                                                          |
| --------------------- | -------------- | ------------------------------------------------------------------------------------------------------ |
| `skip_clustering`     | `false`        | Skip clustering, recombination filtering and the phylogeny.                                            |
| `skip_fastbaps`       | `true`         | Skip FastBAPS, so Gubbins runs on the whole alignment. With `false`, Gubbins runs per FastBAPS cluster. Set `false` in a params file, not on the command line (see below). |
| `min_partition_size`  | 4              | Minimum sequences a FastBAPS cluster/partition must have to run Gubbins/RAxML on - smaller clusters are skipped rather than causing RAxML to fail with "TOO FEW SPECIES". |
| `skip_assembly`       | `false`        | See [Assembly, Typing & AMR Parameters](#assembly-typing--amr-parameters) above.                       |
| `skip_mlst`           | `false`        | See [Assembly, Typing & AMR Parameters](#assembly-typing--amr-parameters) above.                       |
| `skip_amr`            | `false`        | See [Assembly, Typing & AMR Parameters](#assembly-typing--amr-parameters) above.                       |

> ⚠️ **Command-line values on Nextflow 26** arrive as text: `--skip_x true` works, but `--skip_x false` does not switch a step on, and numbers such as `--max_cpus 8` fail validation. Put such values in a params file (`-params-file params.yaml`).

---

## Long-read Parameters

Nanopore and PacBio samples are quality-checked (NanoPlot), filtered (Filtlong) and assembled (Flye). A sample whose assembly fails is skipped with a `NOTE` and the run continues.

| Parameter | Default | Description |
| --- | --- | --- |
| `pacbio_mode` | `hifi` | Flye mode for samples tagged plain `pacbio` (and for `pacbio_sra_list`): `hifi` (`--pacbio-hifi`) or `raw` (`--pacbio-raw`, for CLR). Not auto-detected |
| `long_read_min_length` | `1000` | Filtlong `--min_length` |
| `long_read_keep_percent` | `90` | Filtlong `--keep_percent` |
| `long_read_target_bases` | none | Optional Filtlong `--target_bases`: keep the best reads up to this many bases per sample (e.g. `400000000`, about 100x of a 4 Mb genome) |

---

## Resource Limits

| Parameter | Default | Description |
| --- | --- | --- |
| `max_cpus` | `16` | Most CPUs any single task may use. Set it in a params file, not on the command line |
| `max_memory` | `128.GB` | Most memory any single task may use. Lower it on smaller machines, e.g. `--max_memory 20.GB` |
| `max_time` | `240.h` | Most time any single task may run. IQ-TREE is allowed up to 72 h, so keep this at or above `72.h` |

Gubbins always runs single-threaded on purpose: with several threads its recombination output (GFF) can be corrupted.

---

## Reference Files

| Parameter | Default | Description |
| --- | --- | --- |
| `ref_genbank` | none (required) | Path to the reference GenBank file. The repository includes `resources/reference/GCF_003063785.full.gbk` |

> ⚠️ **Warning**: It is recommended to use the provided reference file to ensure compatibility with the global core alignment.

---

## Alignment Files

| Parameter               | Default Value | Description                                                                                                                    |
| ------------------------- | -------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `global_core_alignment`   | `null`         | Path to the existing global core alignment fasta file. We publish such an alignment on https://doi.org/10.5281/zenodo.10984554 |
| `cohort_core_alignment`   | `null`         | Path to an existing cohort_core_alignment fasta file.                                                                        |

---
