[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.15167441-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.15167441)


[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/CERI-KRISP/CholeraSeq)

## Introduction


**CERI-KRISP/CholeraSeq** is a Nextflow pipeline for data genomic analysis of Cholera outbreaks.


## Reference sequence

We have created a multi-fasta reference with global cohort available on NCBI, available at the link below.

[![Zenodo Dataset](http://img.shields.io/badge/DOI-10.5281/zenodo.10984554-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.10984554)

## Documentation

The documentation for the pipeline is hosted at https://ceri-krisp.github.io/CholeraSeq/

## Testing

A built-in test profile are available in the choleraseq pipeline with different size of datasets. This profile can be used to run tests on the relevant infrastructure using the `test` profile, to help users identify and resolve any infrastructural issue before the analysis stage.

**NOTE**: The snippets below assumes you have `docker` on the sever/machine you wish to test the pipeline. For other institutional configs please refer [nf-core/configs](https://nf-co.re/docs/usage/configuration#max-resources) project, which are all applicable to this pipeline.

```bash

$ nextflow run CERI-KRISP/CholeraSeq \
  -profile test,docker --outdir test_output

```



## Credits

CERI-KRISP/CholeraSeq was originally written by the CholeraSeq publication authors.

<!-- FIXME add publication -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).
## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use  CERI-KRISP/CholeraSeq for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
