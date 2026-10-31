# Parameters

This document lists the main configuration parameters used by the CholeraSeq pipeline. For full parameter discovery, see `nextflow.config`.

> **Command-line values on Nextflow 26** arrive as text: `--skip_x true` works, but `--skip_x false` does not switch a step on, and numbers such as `--max_cpus 8` fail validation. Put such values in a params file (`-params-file params.yaml`).

## Input and output

Give either `input`, or one or more of the folder and accession-list options (these can be combined). `outdir` is always required.

| Parameter | Default | Description |
| --- | --- | --- |
| `input` | `null` | Sample sheet CSV: columns `sample`, `fastq_1`, `fastq_2`, plus optional `sra_id` and `platform`. |
| `reads_dir` | `null` | Folder of Illumina fastq: paired (`<id>_R1/_R2` or `<id>_1/_2`) and single-end (`<id>.fastq.gz`). |
| `ont_reads_dir` | `null` | Folder of Nanopore reads, one `.fastq.gz`/`.fq.gz` per sample. |
| `pacbio_hifi_reads_dir` | `null` | Folder of PacBio HiFi reads, one file per sample. |
| `pacbio_clr_reads_dir` | `null` | Folder of PacBio CLR reads, one file per sample. |
| `contigs_dir` | `null` | Folder of assemblies (`.fasta`/`.fna`/`.fa`, optionally gzipped); every matching file is a sample. |
| `sra_list` | `null` | Text file of Illumina SRA/ENA accessions, one per line. |
| `ont_sra_list` | `null` | Text file of Nanopore accessions. |
| `pacbio_sra_list` | `null` | Text file of PacBio accessions; chemistry from `pacbio_mode`. |
| `platform` | `illumina` | Platform for samples found in `reads_dir`: `illumina`, `nanopore`, `pacbio`, `pacbio_hifi` or `pacbio_clr`. |
| `download_method` | `sratools` | How accessions are downloaded. Only `sratools` is implemented; `ftp` and `aspera` stop with a clear message. |
| `outdir` | `null` | Output directory for pipeline results. |
| `trace_timestamp` | run start time | Timestamp (`yyyy-MM-dd_HH-mm-ss`) added to the `pipeline_info/` report file names. Set automatically; there is normally no reason to change it. |

> In the sample sheet, leave `fastq_2` blank for single-end, long-read or assembly input. Fill either `sra_id` or `fastq_1`, not both.

## Reference and alignment parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `ref_genbank` | none (required) | Path to the reference GenBank file used by `snippy` and `varcodons.py`. The repository includes `resources/reference/GCF_003063785.full.gbk`, which is recommended for compatibility with the published global core alignment. The `test` profile sets it. |
| `global_core_alignment` | `null` | Path to an existing global core-genome alignment FASTA to merge with cohort sequences. |
| `cohort_core_alignment` | `null` | Path to an existing cohort core-genome alignment FASTA to merge into a global core alignment. |

## Quality control and variant calling

| Parameter | Default | Description |
| --- | --- | --- |
| `min_trim_quality` | `20` | Minimum average base quality for `fastp` trimming. |
| `min_trim_length` | `35` | Minimum read length after trimming. |
| `min_mapping_quality` | `20` | Minimum mapping quality used by `samtools consensus`. |
| `min_base_quality` | `20` | Minimum base quality used by `samtools consensus`. |
| `min_site_coverage` | `5` | Minimum depth required to call a site. |
| `min_allele_fraction` | `0.75` | Minimum allele frequency required to make a variant call. |
| `snippy_minqual` | `100` | Minimum variant call quality (`snippy --minqual`). |
| `max_missing_percentage` | `50` | Maximum allowed percentage of missing data in a consensus sequence before it is filtered. |
| `min_parsimony_coverage` | `0.7` | Minimum fraction of non-missing bases required for a variable site to be retained by `varcodons.py`. |

## Assembly, typing and AMR

De novo assembly of Illumina reads (`SPAdes`), MLST typing (`mlst`) and AMR, virulence and plasmid screening (`ABRicate`). Samples supplied as assemblies, and long-read samples (assembled by Flye), skip SPAdes.

| Parameter | Default | Description |
| --- | --- | --- |
| `skip_assembly` | `false` | Skip SPAdes, MLST and ABRicate entirely. |
| `skip_mlst` | `false` | Skip MLST typing only. |
| `skip_amr` | `false` | Skip ABRicate screening only. |
| `spades_mode` | `careful` | SPAdes mode (`careful`, `isolate`, `meta`, `rna`, or empty for the default). |
| `spades_cov` | `auto` | SPAdes `--cov-cutoff` (`auto`, `off`, or a number). |
| `abricate_minid` | `80` | ABRicate minimum % identity to report a hit. |
| `abricate_mincov` | `80` | ABRicate minimum % coverage to report a hit. |
| `abricate_dbs` | `ncbi,resfinder,vfdb,plasmidfinder` | Comma-separated ABRicate databases to screen: `ncbi` and `resfinder` (AMR), `vfdb` (virulence), `plasmidfinder` (plasmid replicons). Also available: `card`, `argannot`, `megares`, `ecoli_vf`, `ecoh`. Each gets its own reports and summary tables. |

## Long-read parameters

Nanopore and PacBio samples are quality-checked (NanoPlot), filtered (Filtlong) and assembled (Flye). A sample whose assembly fails is skipped with a `NOTE` and the run continues.

| Parameter | Default | Description |
| --- | --- | --- |
| `pacbio_mode` | `hifi` | Flye mode for samples tagged plain `pacbio` (and for `pacbio_sra_list`): `hifi` (`--pacbio-hifi`) or `raw` (`--pacbio-raw`, for CLR). Not auto-detected. |
| `long_read_min_length` | `1000` | Filtlong `--min_length`. |
| `long_read_keep_percent` | `90` | Filtlong `--keep_percent`. |
| `long_read_target_bases` | none | Optional Filtlong `--target_bases`: keep the best reads up to this many bases per sample (e.g. `400000000`, about 100x of a 4 Mb genome). |

## Clustering and tree options

| Parameter | Default | Description |
| --- | --- | --- |
| `skip_fastbaps` | `true` | Skip the optional FastBAPS clustering step; Gubbins then runs on the whole alignment. With `false`, Gubbins runs per FastBAPS cluster. Set `false` in a params file, not on the command line. |
| `min_partition_size` | `4` | With FastBAPS on: clusters with fewer samples than this skip Gubbins (RAxML cannot build a tree from them), and their samples are not in the final tree. |
| `skip_clustering` | `false` | Skip the clustering and tree inference workflow. This also skips the `iqtree` tree step. |

## Reporting and MultiQC

| Parameter | Default | Description |
| --- | --- | --- |
| `multiqc_config` | `null` | Custom MultiQC configuration file. |
| `multiqc_logo` | `${projectDir}/assets/CERI_logo_b.png` | Optional logo file to include in MultiQC reports. |
| `multiqc_methods_description` | `null` | Optional YAML or text file with method descriptions for MultiQC. |
| `email` | `null` | Email address to notify on successful completion. |
| `email_on_fail` | `null` | Email address to notify if the pipeline fails. |
| `hook_url` | `null` | Webhook URL for completion notification. |

## Execution and environment

| Parameter | Default | Description |
| --- | --- | --- |
| `custom_config_version` | `'master'` | nf-core config repository version to use. |
| `config_profile_description` | `null` | Optional profile description. |
| `config_profile_name` | `null` | Optional profile name to expose to readers. |
| `max_memory` | `128.GB` | Maximum memory limit applied to pipeline processes. Lower it on smaller machines, e.g. `--max_memory 20.GB`. |
| `max_cpus` | `16` | Maximum CPU limit for pipeline processes. Set it in a params file, not on the command line. |
| `max_time` | `240.h` | Maximum runtime limit for pipeline processes. IQ-TREE is allowed up to 72 h, so keep this at or above `72.h`. |

Gubbins always runs single-threaded on purpose: with several threads its recombination output (GFF) can be corrupted.

## Notes

- The pipeline is designed for phylogenetic analysis. Alongside the tree, it provides de novo assembly, MLST typing and AMR, virulence and plasmid gene screening.
- It does not perform serotyping or gene presence/absence (pangenome) analysis.
- The final tree is built from a reference-guided, recombination-masked core-genome SNP alignment.
- If you want full details of available parameters, inspect `nextflow.config` and the `schema` definitions in the repository.
