# Output

## What this document covers

This page describes the files and directories produced by CholeraSeq. It explains where to find the tree outputs, QC reports, typing and AMR results, and other important result files.

## Result directory structure

By default, the pipeline creates the following top-level directories inside your `--outdir`:

- `fastp/` – trimmed read output and Fastp QC logs
- `fastqc/` – FastQC reports for raw or trimmed reads
- `snippy/` – `snippy` individual sample results and consensus FASTA input files
- `mask/` – recombination masking outputs from `gubbins`
- `iqtree/` – final tree files and IQ-TREE reports
- `spades/`, `mlst/`, `abricate/` – de novo assemblies of Illumina reads, MLST types, and AMR/virulence/plasmid gene hits
- `nanoplot/`, `filtlong/`, `flye/` – long-read QC, filtered reads, and long-read assemblies (only with Nanopore or PacBio samples)
- `gunzip/` – uncompressed copies of long-read assemblies and gzipped input assemblies, as passed to variant calling
- `sra/` – reads downloaded from SRA/ENA (only when accessions are used)
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

Samples whose consensus is empty, covers only part of the reference, or has too much missing data are left out of the alignment. Each is named in a warning in the run log.

### Assembly, typing and AMR

- `spades/<sample>.scaffolds.fa.gz` – SPAdes assembly of Illumina reads; samples supplied as assemblies, and long-read samples, skip this step
- `spades/<sample>.spades.log` – SPAdes run log
- `mlst/<sample>.tsv` – MLST sequence type call for one sample
- `mlst/mlst_summary.tsv` – one row per sample: MLST scheme, sequence type (ST) and allele calls
- `abricate/<sample>.<db>.txt` – gene hits for one sample in one database: `ncbi` and `resfinder` (AMR), `vfdb` (virulence) and `plasmidfinder` (plasmid replicons) by default
- `abricate/abricate_summary_<db>.tsv` – one row per sample and one column per gene for that database; each cell is the gene's % coverage, and `.` means not found
- `abricate/abricate_hits_<db>.tsv` – every hit from every sample in that database, with % identity, % coverage and gene product

### Long-read QC and assembly

- `nanoplot/<sample>_NanoPlot-report.html`, `nanoplot/<sample>_NanoStats.txt` and plots – read-length and quality QC for each Nanopore or PacBio sample, on the unfiltered reads
- `filtlong/<sample>.fastq.gz` – filtered reads used for assembly (these can be large)
- `filtlong/<sample>.log` – Filtlong log
- `flye/<sample>.assembly.fasta.gz` – Flye assembly
- `flye/<sample>.assembly_info.txt` – contig lengths, coverage and circularity

A sample whose assembly fails has no files under `flye/`. It is listed as `FAILED` in the execution trace under `pipeline_info/`.

### Downloaded reads

- `sra/<sample>*.fastq.gz` – reads downloaded for `sra_id` sample sheet rows or accession lists

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
