# CholeraSeq workflow

This document explains how the CholeraSeq pipeline works, the methods it uses, and the key decisions baked into the workflow.

## What CholeraSeq does

CholeraSeq is a phylogenomics pipeline for *Vibrio cholerae* that:

- accepts Illumina reads, Oxford Nanopore and PacBio long reads, or FASTA assemblies, in any mix
- performs QC and trimming on Illumina reads, and QC, filtering and assembly on long reads
- maps data to a reference genome using `snippy`
- generates consensus sequences and a cohort alignment
- masks recombination using `gubbins`
- extracts codon-aware variable sites with `varcodons.py`
- infers an ML tree with `iqtree`
- assembles Illumina reads and screens assemblies for MLST type and AMR, virulence and plasmid genes
- aggregates QC and workflow metadata in `MultiQC`

It is not a general genome characterization pipeline. It does not include serotype prediction or pangenome analysis.

## High-level workflow

1. **Input**
   - sample sheet parsing and input file checking, or discovery of samples in folders, or download from SRA/ENA accession lists.
2. **Quality control**
   - `fastp` trimming and QC on Illumina reads.
   - `NanoPlot` QC and `Filtlong` filtering on long reads.
3. **Long-read assembly**
   - `Flye` assembles each Nanopore or PacBio sample; the assembly is then treated like any other assembly.
4. **Variant calling and consensus generation**
   - `snippy` maps reads (or assemblies) to the reference and calls variants.
   - `samtools consensus` makes per-sample consensus FASTA sequences.
5. **Cohort alignment creation**
   - samples with an empty or partial consensus are left out, then the consensus FASTA sequences are concatenated into one multi-sample alignment.
6. **Alignment cleaning**
   - filter sequences with high missingness using `seq_cleaner.py`.
7. **Optional clustering**
   - with `skip_fastbaps = false`, `FastBAPS` splits the cleaned alignment into clusters.
8. **Recombination masking**
   - `gubbins` identifies recombinant regions, on the whole alignment or per cluster.
   - mask recombinant positions before tree inference.
9. **Variable-site extraction**
   - `varcodons.py` converts the masked alignment into a variable-site codon-aware alignment.
10. **Phylogeny inference**
    - `iqtree` builds the final tree from the masked alignment.
11. **Assembly, typing and AMR** (alongside steps 4–10)
    - `SPAdes` assembles Illumina reads; `mlst` and `ABRicate` screen every assembly.
12. **Reporting**
    - `MultiQC` summarizes QC and workflow information.

## Workflow components

### Input and staging

Samples come from a sample sheet, from folders (`reads_dir`, `ont_reads_dir`, `pacbio_hifi_reads_dir`, `pacbio_clr_reads_dir`, `contigs_dir`), or from SRA/ENA accession lists (`sra_list`, `ont_sra_list`, `pacbio_sra_list`, or an `sra_id` sample sheet column). Each sample is routed by type:

- Illumina reads (paired-end or single-end)
- long reads (Nanopore, PacBio HiFi or PacBio CLR)
- contigs/assemblies, optionally gzipped (decompressed before use)

Assembly input is accepted as FASTA and bypasses read trimming and de novo assembly.

### Read QC

`fastp` handles Illumina read trimming, adapter clipping, and quality filtering. QC summaries are collected from `fastp` and `FastQC` for MultiQC.

### Long-read QC and assembly

`NanoPlot` reports read-length and quality statistics, `Filtlong` removes short and low-quality reads (optionally capping coverage with `long_read_target_bases`), and `Flye` assembles each sample. Flye's mode depends on the data: `--nano-raw` for Nanopore, `--pacbio-hifi` for PacBio HiFi and `--pacbio-raw` for PacBio CLR. The chemistry is not auto-detected; it comes from the folder option or the sample sheet's `platform` value. A sample whose assembly fails is skipped with a `NOTE`, and the run continues.

### Reference-guided variant calling

`snippy` is the core mapping and variant calling tool. It uses a GenBank reference given with `--ref_genbank`, which is required (the `test` profile sets it). `resources/reference/GCF_003063785.full.gbk` is included and recommended. Assemblies, including Flye assemblies, are aligned with snippy's contig mode.

### Consensus and alignment

The pipeline converts each sample BAM to a consensus FASTA with `samtools consensus`, then concatenates those FASTA sequences into a cohort alignment.
The reference has one record per chromosome, and each sample's records are joined into one sequence. Before joining, samples with no consensus, or covering only part of the reference (for example no reads on one chromosome), are left out with a warning, so that every sequence has the reference's full length.
This forms the basis for the downstream core-genome tree.

### Cleaning and filtering

`seq_cleaner.py` removes sequences with excessive missing data according to `--max_missing_percentage`.
This step ensures only sufficiently complete sequences go into recombination masking and tree inference.

### Optional FastBAPS clustering

With `skip_fastbaps = false`, `FastBAPS` partitions the cleaned alignment into clusters, and Gubbins runs on each cluster separately. Clusters with fewer samples than `min_partition_size` (default 4) skip Gubbins, because RAxML cannot build a tree from them, and their samples are not in the final tree.

### Recombination masking

`gubbins` detects recombinant regions in the cleaned alignment (or in each cluster). Those regions are masked before the tree is built, reducing the impact of horizontal gene transfer on the phylogeny.
Gubbins runs single-threaded on purpose: with several threads its recombination output (GFF) can be corrupted. Before masking, each GFF record is also checked, and any malformed record is repaired or dropped with a warning.

### Codon-aware variable-site conversion

`varcodons.py` uses the reference annotation to extract coding-variable sites from the masked alignment.
The resulting alignment is intended for phylogenetic analysis while preserving codon structure.

### Tree inference

`iqtree` is the final phylogeny engine. The tree is inferred from a recombination-masked, reference-guided alignment derived from consensus sequences. On large datasets it can take a day or more; it is allowed up to 72 h.

### Assembly, typing and AMR

`SPAdes` assembles Illumina reads. `mlst` assigns sequence types and `ABRicate` screens for AMR, virulence and plasmid genes, on the SPAdes assemblies, the Flye assemblies and any supplied assemblies. These results do not feed into the tree.

## Optional global alignment mode

CholeraSeq can merge new data into an existing global core alignment using:

- `global_core_alignment`
- `cohort_core_alignment`

When enabled, the pipeline concatenates the provided alignments and then proceeds through clustering and tree inference.

## Notes for users

- `skip_clustering` will skip the clustering/tree workflow entirely.
- `skip_fastbaps` (default `true`) skips FastBAPS, so Gubbins runs on the whole alignment. With FastBAPS on, Gubbins runs per cluster, and samples in clusters smaller than `min_partition_size` are not in the final tree.
- On Nextflow 26, set booleans to `false` and numbers in a params file, not on the command line (see [usage.md](usage.md)).
- The workflow focuses on phylogeny and QC, with typing and AMR screening alongside; it does not cover serotyping or downstream epidemiological annotation.

## Outputs and results

For result details, see [output.md](output.md).

## Related docs

- [Usage](usage.md) for running the pipeline
- [Parameters](parameters.md) for configuration options
- [Output](output.md) for result file descriptions
