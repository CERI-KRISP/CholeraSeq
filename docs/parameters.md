# Parameters

This document provides an overview of the customizable parameters for the CHOLERASEQ pipeline. Each parameter is listed with its default value, description.

> 💡 **Hint**: you may check a full parameters [reference file](https://github.com/CERI-KRISP/CholeraSeq/blob/master/nextflow.config).

---

## Common Parameters

### Input Samplesheet
| Parameter             | Default Value              | Description                                                                                     |
|-----------------------|----------------------------|-------------------------------------------------------------------------------------------------|
| `input`   | `null`  | The input CSV file containing sample information.    |

> 💡 **Hint**: The samplesheet should include the columns `[sample,fastq_1,fastq_2]`.

---

### Output Directory
| Parameter   | Default Value         | Description                                                                 |
|-------------|-----------------------|-----------------------------------------------------------------------------|
| `outdir`    | `null`     | The directory where all output files will be written.                      |


---

## Quality Control Parameters

> ⚠️ **Attention**: Ensure these values are adjusted based on the quality of your input data to avoid processing errors.
> The defaults are set to faciliate a majority of users. Only advanced users are recommended to change these.

| Parameter                | Default Value | Description                                                                                                                                                                                                        |
|--------------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `min_trim_quality`       | 20            | Fastq reads mean quality threshold	20	fastp                                                                                                                                                                  |
| `min_trim_length`        | 50            | Fastq read minimum trim length	50	fastp                                                                                                                                                                      |
| `min_mapping_quality`    | 20            | minimum mapping quality	20	samtools consensus	samtools --min-MQ                                                                                                                                           |
| `min_base_quality`       | 20            | minimum base quality	20	samtools consensus	samtools --min-BQ                                                                                                                                              |
| `min_site_coverage`      | 5             | mimimum site coverage	5	samtools consensus + snippy	samtools --min-depth 5; snippy --mincov 5                                                                                                             |
| `min_allele_fraction`    | 0.75          | minimum fraction supporting allele call	0.75	samtools consensus + snippy	samtools -c 0.75; snippy --minfrac 0.75                                                                                          |
| `max_missing_percentage` | 50            | Percentage of missing data allowed in a sample before it is excluded from the analysis.  max_missing_percentage	0.5	seqcleaner, gubbins	max percentage of undefined sites in any consensus fasta sequence |
| `min_parsimony_coverage` | 0.7           | varcodons.py pi job minimum site coverage for varcodons to keep site when generating pi output                                                                                                                     |


---

## Skipping Pipeline Steps

| Parameter         | Default Value | Description                                                                     |
|-------------------|---------------|---------------------------------------------------------------------------------|
| `skip_clustering` | `false`       | Indicate whether you wish to enable the clustering anlysis.                     |
| `skip_fastbaps`   | `true`        | Indicate whether to skip fastbaps or not.  |

> 💡 **Hint**: Use these flags to customize the pipeline execution based on your specific requirements.

---

## Reference Files

| Parameter     | Default Value              | Description                                                                                                |
|---------------|----------------------------|------------------------------------------------------------------------------------------------------------|
| `ref_genbank` | `GCF_003063785.full.gbk`   | Path to the reference GENBANK file                                                                         |

> ⚠️ **Warning**: It is recommended to use the provided reference files to ensure compatibility with the global core alignment.

---


## Alignment Files

| Parameter               | Default Value | Description                                                                                                                     |
|-------------------------|---------------|---------------------------------------------------------------------------------------------------------------------------------|
| `global_core_alignment` | `null`        | Path to the existing global core alignment fasta file. We publish such an alignment on  https://doi.org/10.5281/zenodo.10984554 |
| `cohort_core_alignment` | `null`        | Path to an existing cohort_core_alignment fasta file.                                                                           |

---
