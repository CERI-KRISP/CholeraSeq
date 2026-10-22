# Usage

`CholeraSeq`: a pipeline for data analysis Cholera outbreaks.

## Introduction

**CERI-KRISP/CholeraSeq** is a Nextflow pipeline for genomic data analysis of Cholera outbreaks: quality control, reference-based variant calling and core-genome alignment, de novo assembly, MLST typing, AMR/virulence/plasmid screening, FastBAPS clustering, per-cluster recombination filtering (Gubbins), and phylogenetic reconstruction (IQ-TREE).

## Dataset

We have created a multi-fasta reference with global cohort available on NCBI, available at the link below.

[![Zenodo Dataset](http://img.shields.io/badge/DOI-10.5281/zenodo.10984554-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.10984554)

## Input

CholeraSeq accepts Illumina reads, Oxford Nanopore and PacBio long reads, and finished assemblies, in any mix. Samples can be listed in a samplesheet (`--input`), or found automatically from folders and accession lists. `--input` cannot be combined with the folder and list flags; the folder and list flags can all be combined in one run.

A reference GenBank file is always required: `--ref_genbank /path/to/reference.gbk`. The repository includes `resources/reference/GCF_003063785.full.gbk`. Use it to stay compatible with the published global core alignment.

### 1. Samplesheet (`--input`)

A comma-separated file with a header row, one row per sample. `sra_id` and `platform` are optional columns.

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

## Running the pipeline

### Test profiles

A built-in test profile are available in the choleraseq pipeline with different size of datasets. This profile can be used to run tests on the relevant infrastructure using the `test` profile, to help users identify and resolve any infrastructural issue before the analysis stage.

**NOTE**: The snippets below assumes you have `docker` on the sever/machine you wish to test the pipeline. For other institutional configs please refer [nf-core/configs](https://nf-co.re/docs/usage/configuration#max-resources) project, which are all applicable to this pipeline.

```bash

$ nextflow run CERI-KRISP/CholeraSeq \
  -profile test,docker --outdir test_output

```

### Using your own dataset

The command for running the pipeline is as follows:

```bash
nextflow run CERI-KRISP/CholeraSeq \
         -profile docker \
         --input /path/to/samplesheet.csv \
         --outdir results

```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

> ⚠️ **Note**: running against `-profile docker` alone (without `test`) means none of `test.config`'s defaults apply - in particular you'll need to supply `--ref_genbank` yourself (variant calling always needs a reference, regardless of which input mode you use), and you may want to set `--max_memory`/`--max_cpus`/`--max_time` explicitly to match your machine, since the pipeline's own defaults (128.GB / 16 cpus / 240h) are sized for a shared cluster, not a laptop.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

### Use of `YAML` file for parameters

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

```bash
nextflow run ceri-krisp/choleraseq -profile docker -params-file params.yaml
```

with `params.yaml` containing:

```yaml
input: "./samplesheet.csv"
outdir: "./results/"
genome: "GRCh37"
# other parameters
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull ceri-krisp/choleraseq
```

> 💡 **Hint**: if you're developing against a local fork or clone, run the pipeline with `nextflow run . -profile ...` from inside the repository directory instead of `nextflow run CERI-KRISP/CholeraSeq ...` - the latter always pulls the upstream repository from GitHub, bypassing any local changes you haven't pushed.

### Reproducibility

It is a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [ceri-krisp/choleraseq releases page](https://github.com/ceri-krisp/choleraseq/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducbility, you can use share and re-use [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

> 💡 If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.

## Core Nextflow arguments

> **NB:** These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer enviroment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher requests (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases you may wish to change which container or conda environment a step of the pipeline uses for a particular tool. By default nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Azure Resource Requests

To be used with the `azurebatch` profile by specifying the `-profile azurebatch`.
We recommend providing a compute `params.vm_type` of `Standard_D16_v3` VMs by default but these options can be changed if required.

Note that the choice of VM size depends on your quota and the overall workload during the analysis.
For a thorough list, please refer the [Azure Sizes for virtual machines in Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
