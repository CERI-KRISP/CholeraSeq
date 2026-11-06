# Output

## What this document covers

This page describes the files and directories produced by CholeraSeq. It explains where to find the tree outputs, QC reports, typing and AMR results, and other important result files.

## Result directory structure

By default, the pipeline creates the following top-level directories inside your `--outdir`:

- `fastp/` – trimmed read output and Fastp QC logs
- `fastqc/` – FastQC reports for raw or trimmed reads
- `snippy/` – one sub-directory per sample with `snippy` variant calls, alignments and consensus files
- `samtools/` – one consensus FASTA per sample (`<sample>.fasta`), the inputs to the core alignment
- `run/` – `gubbins` recombination analysis (recombination GFF, per-branch statistics, filtered polymorphic sites, trees)
- `mask/` – recombination-masked alignment produced from the `gubbins` result
- `iqtree/` – final tree files and IQ-TREE reports
- `spades/`, `mlst/`, `abricate/` – de novo assemblies of Illumina reads, MLST types, and AMR/virulence/plasmid gene hits
- `nanoplot/`, `filtlong/`, `flye/` – long-read QC, filtered reads, and long-read assemblies (only with Nanopore or PacBio samples)
- `gunzip/` – uncompressed copies of long-read assemblies and gzipped input assemblies, as passed to variant calling
- `sra/` – reads downloaded from SRA/ENA (only when accessions are used)
- `multiqc/` – aggregated QC report and plots
- `pipeline_info/` – Nextflow and pipeline execution reports
- `cat/` / `python/` / `utils/` – the concatenated alignment, the cleaned alignment, and the `varcodons.py` outputs (see below)
- `r/` / `seqkit/` – FastBAPS clustering outputs (only with `skip_fastbaps = false`)

The exact layout may vary depending on which pipeline steps are executed and whether optional modes such as global core alignment are enabled.

## Key outputs

### Final tree and phylogeny

- `iqtree/*.treefile` – main maximum likelihood tree file in Newick-like format
- `iqtree/*.contree` – consensus tree with bootstrap support values
- `iqtree/*.iqtree` – IQ-TREE run summary and model information
- `iqtree/*.mldist` – likelihood-distance matrix produced by IQ-TREE
- `iqtree/*.log` – IQ-TREE execution log

These files represent the final phylogeny inferred by CholeraSeq from a recombination-masked core-genome SNP alignment.

### Recombination masking

- `run/*.recombination_predictions.gff` – recombination blocks predicted by `gubbins`
- `run/*.final_tree.tre`, `run/*.node_labelled.final_tree.tre` – the `gubbins` tree, without and with node labels
- `run/*.per_branch_statistics.csv` – per-branch substitution and recombination counts
- `run/*.filtered_polymorphic_sites.fasta` – polymorphic sites after recombination filtering
- `mask/*.gub.masked.fasta` – the alignment with recombination blocks masked, used for downstream tree inference

### Consensus and alignment inputs

- `snippy/<sample>/` – per-sample `snippy` output: `<sample>.vcf`, `<sample>.bam`, `<sample>.consensus.fa`, `<sample>.tab` and logs
- `samtools/<sample>.fasta` – per-sample consensus FASTA from `samtools consensus`; these are the sequences that enter the alignment
- `utils/cat_consensus.fasta` – the per-sample consensus sequences concatenated into the cohort alignment
- `cat/merged.core_aln.fasta` – the cohort alignment merged with the global core alignment, when `global_core_alignment` is used
- `python/*.cleaned.fasta` – the merged alignment after cleaning, which is what `gubbins` receives
- `utils/ref_fa.pi.fasta`, `utils/ref_fa.pi.snps.tsv` – the variable-site alignment and SNP table produced by `varcodons.py` from the masked alignment
- `utils/ref_gbk.varcodons.fasta`, `utils/ref_gbk.varcodons.snps.tsv` – the codon-aware report from `varcodons.py` against the GenBank reference (`ref_genbank`)

Samples whose consensus is empty, covers only part of the reference, or has too much missing data are left out of the alignment. Each is named in a warning in the run log.

### Assembly, typing and AMR

- `spades/<sample>.scaffolds.fa.gz`, `spades/<sample>.contigs.fa.gz` – SPAdes assembly of Illumina reads; samples supplied as assemblies, and long-read samples, skip this step
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

Reports are written with a run timestamp in the file name, so repeated or resumed runs into the same `--outdir` do not overwrite each other (`<ts>` below is `yyyy-MM-dd_HH-mm-ss`).

- `pipeline_info/execution_report_<ts>.html` – a Nextflow execution report
- `pipeline_info/execution_timeline_<ts>.html` – timeline of pipeline processes
- `pipeline_info/execution_trace_<ts>.txt` – trace of pipeline tasks
- `pipeline_info/pipeline_dag_<ts>.html` – workflow DAG visualization
- `pipeline_info/software_versions.yml` – list of software versions used in the run
- `pipeline_info/samplesheet.valid.csv` – cleaned or validated sample sheet used by the pipeline

## Interpreting the key tree outputs

The primary phylogeny is stored under `iqtree/`.
Because the pipeline masks recombination and extracts variable sites through `varcodons.py`, the final tree should be interpreted as a recombination-masked phylogeny derived from a reference-guided core alignment.

For additional detail on the workflow and what each directory contains, see [workflow.md](workflow.md).
