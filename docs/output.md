# Output

## What this document covers

This page describes the files and directories produced by CholeraSeq. It explains where to find the tree outputs, QC reports, and other important result files.

## Result directory structure

By default, the pipeline creates the following top-level directories inside your `--outdir`:

- `fastp/` – trimmed read output and Fastp QC logs
- `fastqc/` – FastQC reports for raw or trimmed reads
- `snippy/` – `snippy` individual sample results and consensus FASTA input files
- `mask/` – recombination masking outputs from `gubbins`
- `iqtree/` – final tree files and IQ-TREE reports
- `multiqc/` – aggregated QC report and plots
- `pipeline_info/` – Nextflow and pipeline execution reports
- `cat/` / `utils/` / `python/` / `r/` / `seqkit/` / `run/` – workflow step-specific directories for intermediate outputs

The exact layout may vary depending on which pipeline steps are executed and whether optional modes such as global core alignment are enabled.

## Key outputs

### Final tree and phylogeny

- `iqtree/*.treefile` – main maximum likelihood tree file in Newick-like format
- `iqtree/*.iqtree` – IQ-TREE run summary and model information
- `iqtree/*.mldist` – likelihood-distance matrix produced by IQ-TREE
- `iqtree/*.log` – IQ-TREE execution log

These files represent the final phylogeny inferred by CholeraSeq from a recombination-masked core-genome SNP alignment.

### Recombination masking

- `mask/*` – outputs from `gubbins` and masking scripts
- `mask/*.gff` – recombination annotation for the input alignment
- `mask/*.masked.fasta` – recombination-masked alignments used for downstream tree inference

### Consensus and alignment inputs

- `snippy/*` – consensus FASTA files and variant calling outputs from `snippy`
- `snippy/*.vcf` – variant call files
- `snippy/*.bam` – read alignments used to generate consensus sequences
- `snippy/*.consensus.fa` – per-sample consensus FASTA sequences
- `cat/*` – concatenated consensus alignments

### MultiQC report

- `multiqc/multiqc_report.html` – interactive summary report for QC and workflow metrics
- `multiqc/multiqc_data/` – parsed statistics from supported tools
- `multiqc/multiqc_plots/` – static plot images

### Workflow metadata

- `pipeline_info/execution_report.html` – a Nextflow execution report
- `pipeline_info/execution_timeline.html` – timeline of pipeline processes
- `pipeline_info/execution_trace.txt` – trace of pipeline tasks
- `pipeline_info/pipeline_dag.html` – workflow DAG visualization
- `pipeline_info/software_versions.yml` – list of software versions used in the run
- `pipeline_info/samplesheet.valid.csv` – cleaned or validated sample sheet used by the pipeline

## Interpreting the key tree outputs

The primary phylogeny is stored under `iqtree/`.
Because the pipeline masks recombination and extracts variable sites through `varcodons.py`, the final tree should be interpreted as a recombination-masked phylogeny derived from a reference-guided core alignment.

For additional detail on the workflow and what each directory contains, see [workflow.md](workflow.md).
