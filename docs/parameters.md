# Parameters

This document provides an overview of the customizable parameters for the CHOLERASEQ pipeline. Each parameter is listed with its default value, description.

> 💡 **Hint**: you may check a full parameters [reference file](https://github.com/CERI-KRISP/CholeraSeq/blob/master/nextflow.config).

---

## Common Parameters

### Input options

CholeraSeq accepts input in one of four ways - see the [Usage](./usage.md#input) page for full examples. `input` is mutually exclusive with the other three; `reads_dir`/`contigs_dir`/`sra_list` can be combined with each other.

| Parameter         | Default Value | Description                                                                                   |
| ------------------ | -------------- | ---------------------------------------------------------------------------------------------- |
| `input`             | `null`         | The input CSV file containing sample information.                                              |
| `reads_dir`         | `null`         | Directory of fastq files to auto-discover (paired `<id>_R1/_R2.fastq.gz`/`<id>_1/_2.fastq.gz`, or single-end `<id>.fastq.gz`). |
| `contigs_dir`       | `null`         | Directory of pre-assembled genomes (`.fasta`/`.fna`/`.fa`, optionally `.gz`) to auto-discover; each is aligned to the reference and carried through the downstream analysis. |
| `sra_list`          | `null`         | Text file, one SRA/ENA accession (SRR/ERR/DRR) per line, to download and process.              |
| `download_method`   | `sratools`     | Method used to download `sra_list`/`sra_id` accessions. Only `sratools` is currently implemented - `ftp` and `aspera` are scaffolded for future use and will fail fast with a clear message if selected. |

> 💡 **Hint**: The samplesheet should include the columns `[sample,fastq_1,fastq_2]`, and may optionally include an `sra_id` column (populated instead of `fastq_1`/`fastq_2`, not alongside them) to download that sample rather than supplying local files.

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
| `min_trim_length`        | 50            | Fastq read minimum trim length 50 fastp                                                                                                                                                                  |
| `min_mapping_quality`    | 20            | minimum mapping quality 20 samtools consensus samtools --min-MQ                                                                                                                                          |
| `min_base_quality`       | 20            | minimum base quality 20 samtools consensus samtools --min-BQ                                                                                                                                             |
| `min_site_coverage`      | 5             | mimimum site coverage 5 samtools consensus + snippy samtools --min-depth 5; snippy --mincov 5                                                                                                            |
| `min_allele_fraction`    | 0.75          | minimum fraction supporting allele call 0.75 samtools consensus + snippy samtools -c 0.75; snippy --minfrac 0.75                                                                                         |
| `snippy_minqual`         | 100           | minimum variant call quality; snippy --minqual                                                                                                                                                           |
| `max_missing_percentage` | 50            | Percentage of missing data allowed in a sample before it is excluded from the analysis. max_missing_percentage 0.5 seqcleaner, gubbins max percentage of undefined sites in any consensus fasta sequence |
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
| `skip_clustering`     | `false`        | Indicate whether you wish to enable the clustering anlysis.                                            |
| `skip_fastbaps`       | `true`         | Indicate whether to skip fastbaps or not.                                                              |
| `min_partition_size`  | 4              | Minimum sequences a FastBAPS cluster/partition must have to run Gubbins/RAxML on - smaller clusters are skipped rather than causing RAxML to fail with "TOO FEW SPECIES". |
| `skip_assembly`       | `false`        | See [Assembly, Typing & AMR Parameters](#assembly-typing--amr-parameters) above.                       |
| `skip_mlst`           | `false`        | See [Assembly, Typing & AMR Parameters](#assembly-typing--amr-parameters) above.                       |
| `skip_amr`            | `false`        | See [Assembly, Typing & AMR Parameters](#assembly-typing--amr-parameters) above.                       |

> 💡 **Hint**: Use these flags to customize the pipeline execution based on your specific requirements.

---

## Reference Files

| Parameter     | Default Value            | Description                        |
| ------------- | ------------------------ | ----------------------------------- |
| `ref_genbank` | `GCF_003063785.full.gbk` | Path to the reference GENBANK file |

> ⚠️ **Warning**: It is recommended to use the provided reference files to ensure compatibility with the global core alignment.

---

## Alignment Files

| Parameter               | Default Value | Description                                                                                                                    |
| ------------------------- | -------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `global_core_alignment`   | `null`         | Path to the existing global core alignment fasta file. We publish such an alignment on https://doi.org/10.5281/zenodo.10984554 |
| `cohort_core_alignment`   | `null`         | Path to an existing cohort_core_alignment fasta file.                                                                        |

---
