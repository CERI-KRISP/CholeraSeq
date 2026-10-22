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

<<<<<<< HEAD
```
├── abricate
├── cat
├── fastp
├── fastqc
├── filtlong
├── flye
├── gunzip
├── iqtree
├── mask
├── mlst
├── multiqc
│   ├── multiqc_data
│   └── multiqc_plots
├── nanoplot
├── pipeline_info
├── python
├── r
├── run
├── samtools
├── seqkit
├── snippy
├── spades
├── sra
└── utils
=======
- `iqtree/*.treefile` – main maximum likelihood tree file in Newick-like format
- `iqtree/*.iqtree` – IQ-TREE run summary and model information
- `iqtree/*.mldist` – likelihood-distance matrix produced by IQ-TREE
- `iqtree/*.log` – IQ-TREE execution log
>>>>>>> upstream/dev

These files represent the final phylogeny inferred by CholeraSeq from a recombination-masked core-genome SNP alignment.

<<<<<<< HEAD
> 💡 **Hint**: `abricate`, `mlst`, and `spades` are only present if `--skip_amr`/`--skip_mlst`/`--skip_assembly` are `false` (the default). `sra` is only present when accessions are downloaded. `nanoplot`, `filtlong` and `flye` are only present when there are long-read samples; `gunzip` when there are long-read samples or gzipped assemblies.

### Assembly, typing & AMR

<details markdown="1">
<summary>Output files</summary>

- `spades/`
  - `<sample>.scaffolds.fa.gz`: SPAdes assembly (skipped for samples that were already contigs on input).
  - `<sample>.spades.log`: SPAdes run log.
- `mlst/`
  - `<sample>.tsv`: MLST sequence type call.
- `abricate/`
  - `<sample>.txt`: AMR/virulence/plasmid gene hits.

</details>

[SPAdes](https://github.com/ablab/spades) performs de novo genome assembly for samples supplied as reads (samples already supplied as contigs skip this step). [MLST](https://github.com/tseemann/mlst) and [ABRicate](https://github.com/tseemann/abricate) then run on the resulting assembly (or the original contigs).

### Long-read QC and assembly

<details markdown="1">
<summary>Output files</summary>

- `nanoplot/`
  - `<sample>_NanoPlot-report.html`, `<sample>_NanoStats.txt` and plots: read-length and quality QC for each Nanopore/PacBio sample (on the unfiltered reads).
- `filtlong/`
  - `<sample>.fastq.gz`: the filtered reads used for assembly. These can be large.
  - `<sample>.log`: Filtlong log.
- `flye/`
  - `<sample>.assembly.fasta.gz`: the Flye assembly.
  - `<sample>.assembly_info.txt`: contig lengths, coverage and circularity.
- `gunzip/`
  - Uncompressed copies of the long-read assemblies and of any gzipped input assemblies, as passed to variant calling.

</details>

[NanoPlot](https://github.com/wdecoster/NanoPlot), [Filtlong](https://github.com/rrwick/Filtlong) and [Flye](https://github.com/mikolmogorov/Flye) handle Nanopore and PacBio samples. Each assembly then follows the same path as any other assembly. A sample whose assembly fails has no files here; see `pipeline_info/execution_trace_*.txt`, where it is listed as `FAILED`.

### SRA download

<details markdown="1">
<summary>Output files</summary>

- `sra/`
  - `<sample>*.fastq.gz`: reads downloaded for samplesheet rows using the `sra_id` column, or accessions supplied via `--sra_list`.

</details>

### MultiQC
=======
### Recombination masking
>>>>>>> upstream/dev

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

<<<<<<< HEAD
</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
=======
For additional detail on the workflow and what each directory contains, see [workflow.md](workflow.md).
>>>>>>> upstream/dev
