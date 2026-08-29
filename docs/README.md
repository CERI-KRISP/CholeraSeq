# CholeraSeq documentation

This repository contains documentation for the `CERI-KRISP/CholeraSeq` Nextflow pipeline.

CholeraSeq is a phylogenetics-focused workflow for *Vibrio cholerae* outbreak analysis. It takes sequencing reads or assemblies, performs QC and reference-based variant calling, masks recombination, and infers a maximum likelihood tree.

## Documentation pages

- [Usage](usage.md)
  - How to run the pipeline, prepare inputs, and use common parameters.
- [Parameters](parameters.md)
  - Reference for the main pipeline parameters and default values.
- [Output](output.md)
  - Description of result files and where to find key tree and QC outputs.
- [Workflow](workflow.md)
  - Detailed description of what the pipeline does and how the stages are connected.

## Getting started

The recommended entry point is [usage.md](usage.md), which includes sample commands and input requirements.

If you are new to the pipeline, read the workflow overview first to understand the data flow, then use the parameters document for configuration details, and finally use the output page to find the generated reports and files.
