# Parameters

This document lists the main configuration parameters used by the CholeraSeq pipeline. For full parameter discovery, see `nextflow.config`.

## Required parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `input` | `null` | Path to the sample sheet CSV file containing sample metadata and input paths. |
| `outdir` | `null` | Output directory for pipeline results. |

> The sample sheet should contain at least `sample`, `fastq_1`, and `fastq_2`. For single-end or assembly input, leave `fastq_2` blank.

## Reference and alignment parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `ref_genbank` | `GCF_003063785.full.gbk` | Path to the reference GenBank file used by `snippy` and `varcodons.py`. |
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
| `max_missing_percentage` | `50` | Maximum allowed percentage of missing data in a consensus sequence before it is filtered. |
| `min_parsimony_coverage` | `0.7` | Minimum fraction of non-missing bases required for a variable site to be retained by `varcodons.py`. |

## Clustering and tree options

| Parameter | Default | Description |
| --- | --- | --- |
| `skip_fastbaps` | `true` | Skip the optional FastBAPS clustering step. |
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
| `max_memory` | `128.GB` | Maximum memory limit applied to pipeline processes. |
| `max_cpus` | `16` | Maximum CPU limit for pipeline processes. |
| `max_time` | `240.h` | Maximum runtime limit for pipeline processes. |

## Notes

- The pipeline is designed for phylogenetic analysis, not for broad genome characterization.
- It does not perform AMR profiling, MLST, serotyping, or gene presence/absence analysis.
- The final tree is built from a reference-guided, recombination-masked core-genome SNP alignment.
- If you want full details of available parameters, inspect `nextflow.config` and the `schema` definitions in the repository.
