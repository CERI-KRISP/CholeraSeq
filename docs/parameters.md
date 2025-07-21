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

## Additional Parameters

| Parameter         | Default Value | Description                                                 |
|-------------------|---------------|-------------------------------------------------------------|
| `skip_clustering` | `false`       | Indicate whether you wish to enable the clustering anlysis. |

> 💡 **Hint**: Use this feature if your dataset has low genetic diversity (e.g., clonal or fewer than 20 samples).

---

## Quality Control Parameters

| Parameter         | Default Value | Description |
|-------------------|---------------|-------------|
| `fasta_threshold` | `75`          | FIXME       |
| `vcf_threshold`                  | `27`              | FIXME            |

> ⚠️ **Attention**: Ensure these values are adjusted based on the quality of your input data to avoid processing errors.

---

## Skipping Pipeline Steps

| Parameter         | Default Value | Description                                                                     |
|-------------------|---------------|---------------------------------------------------------------------------------|
| `skip_clustering` | `false`       | Indicate whether you wish to enable the clustering anlysis.                     |
| `skip_fastbaps`   | `true`        | Indicate whether to skip fastbaps or not. (Previously called `enable_fastbaps`) |

> 💡 **Hint**: Use these flags to customize the pipeline execution based on your specific requirements.

---

## Reference Files

| Parameter               | Default Value                                              | Description                                                                                     |
|-------------------------|------------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| `fasta`           | `null`        | Path to the reference fasta file.                           |

> ⚠️ **Warning**: It is recommended to use the provided reference files to ensure compatibility with the global core alignment.

---
