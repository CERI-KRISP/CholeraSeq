# CholeraSeq workflow

This document explains how the CholeraSeq pipeline works, the methods it uses, and the key decisions baked into the workflow.

## What CholeraSeq does

CholeraSeq is a phylogenomics pipeline for *Vibrio cholerae* that:

- accepts raw Illumina reads or FASTA assemblies
- performs QC and trimming on reads
- maps data to a reference genome using `snippy`
- generates consensus sequences and a cohort alignment
- masks recombination using `gubbins`
- extracts codon-aware variable sites with `varcodons.py`
- infers an ML tree with `iqtree`
- aggregates QC and workflow metadata in `MultiQC`

It is not a general genome characterization pipeline. It does not include AMR profiling, MLST typing, or serotype prediction.

## High-level workflow

1. **Input validation**
   - sample sheet parsing and input file checking.
2. **Quality control**
   - `fastp` trimming and QC on raw reads.
3. **Variant calling and consensus generation**
   - `snippy` maps reads to the reference and calls variants.
   - `samtools consensus` makes per-sample consensus FASTA sequences.
4. **Cohort alignment creation**
   - concatenate consensus FASTA sequences into one multi-sample alignment.
5. **Alignment cleaning**
   - filter sequences with high missingness using `seq_cleaner.py`.
6. **Recombination masking**
   - `gubbins` identifies recombinant regions.
   - mask recombinant positions before tree inference.
7. **Variable-site extraction**
   - `varcodons.py` converts the masked alignment into a variable-site codon-aware alignment.
8. **Phylogeny inference**
   - `iqtree` builds the final tree from the masked alignment.
9. **Reporting**
   - `MultiQC` summarizes QC and workflow information.

## Workflow components

### Input and staging

The pipeline reads the sample sheet and splits samples into:

- raw reads (paired-end or single-end)
- contigs/assemblies

Assembly input is accepted as FASTA and bypasses read trimming.

### Read QC

`fastp` handles read trimming, adapter clipping, and quality filtering. QC summaries are collected from `fastp` and `FastQC` for MultiQC.

### Reference-guided variant calling

`snippy` is the core mapping and variant calling tool. It uses a GenBank reference defined by `--ref_genbank`.
The default reference is `GCF_003063785.full.gbk`.

### Consensus and alignment

The pipeline converts each sample BAM to a consensus FASTA with `samtools consensus`, then concatenates those FASTA sequences into a cohort alignment.
This forms the basis for the downstream core-genome tree.

### Cleaning and filtering

`seq_cleaner.py` removes sequences with excessive missing data according to `--max_missing_percentage`.
This step ensures only sufficiently complete sequences go into recombination masking and tree inference.

### Recombination masking

`gubbins` detects recombinant regions in the cleaned alignment. Those regions are masked before the tree is built, reducing the impact of horizontal gene transfer on the phylogeny.

### Codon-aware variable-site conversion

`varcodons.py` uses the reference annotation to extract coding-variable sites from the masked alignment.
The resulting alignment is intended for phylogenetic analysis while preserving codon structure.

### Tree inference

`iqtree` is the final phylogeny engine. The tree is inferred from a recombination-masked, reference-guided alignment derived from consensus sequences.

## Optional global alignment mode

CholeraSeq can merge new data into an existing global core alignment using:

- `global_core_alignment`
- `cohort_core_alignment`

When enabled, the pipeline concatenates the provided alignments and then proceeds through clustering and tree inference.

## Notes for users

- `skip_clustering` will skip the clustering/tree workflow entirely.
- `skip_fastbaps` disables optional FastBAPS clustering but does not affect the main tree path.
- The workflow focuses on phylogeny and QC, not on genome-wide characterization or downstream epidemiological annotation.

## Outputs and results

For result details, see [output.md](output.md).

## Related docs

- [Usage](usage.md) for running the pipeline
- [Parameters](parameters.md) for configuration options
- [Output](output.md) for result file descriptions
