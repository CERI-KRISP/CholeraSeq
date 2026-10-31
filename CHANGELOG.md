# CERI-KRISP/CholeraSeq: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Entries for 1.2.0 and earlier were reconstructed from the git tags and history; the
2.0.0 section follows pull requests [#24](https://github.com/CERI-KRISP/CholeraSeq/pull/24),
[#30](https://github.com/CERI-KRISP/CholeraSeq/pull/30) and
[#31](https://github.com/CERI-KRISP/CholeraSeq/pull/31).

## 2.0.0 - 2026-10-31

A major release: the pipeline now needs **Nextflow 25.04.8 or newer** (it was 24.04.2), and adds assembly/typing/AMR, long-read and accession inputs.

### Breaking changes

- **Minimum Nextflow is now 25.04.8** (`manifest.nextflowVersion`, the README badge and the CI matrix). The Nextflow 26 strict-syntax changes do not compile on older releases: 24.04.2 and 24.10.9 stop with `Variable 'workflow' already defined in the process scope` in `main.nf`. 25.04.8, 25.10.4 and 26.04.3 load the pipeline and build the full workflow graph (`-preview`).
- Real runs were only validated on Nextflow 26.04.x (26.04.3 on a Nomad cluster, 26.04.6 for the targeted tests); on 25.04.8 and 25.10.4 only the load-and-preview check above has been done.
- On Nextflow 26, a boolean or number given on the command line arrives as a string, so `--skip_x false` does not turn a step back on. Use a params file for booleans and numbers.

### `Added`

- **Assembly, typing and AMR** (from [Cholera_genomics](https://github.com/ottovon-dakurah/Cholera_genomics)): SPAdes de novo assembly, MLST typing and ABRicate screening, run alongside the existing variant-calling path and not feeding into the tree.
  - ABRicate screens `ncbi`, `resfinder` (AMR), `vfdb` (virulence) and `plasmidfinder` (plasmids); set with `abricate_dbs`.
  - Run-wide tables: one MLST summary, and per ABRicate database a gene-by-sample table and an all-hits table.
  - Skip with `skip_assembly`, `skip_mlst` or `skip_amr`.
- **New input options** besides a samplesheet of FASTQ files and assemblies:
  - a samplesheet `sra_id` column (download from SRA/ENA with `sra-tools`);
  - folder discovery: `reads_dir`, `contigs_dir` (including gzipped and arbitrarily named assemblies), `ont_reads_dir`, `pacbio_hifi_reads_dir`, `pacbio_clr_reads_dir`;
  - accession lists: `sra_list`, `ont_sra_list`, `pacbio_sra_list`.
- **Oxford Nanopore and PacBio long reads**: NanoPlot QC, Filtlong filtering and Flye assembly. Each assembly then follows the same path as any other assembly, so variant calling, typing and clustering needed no changes.
  - PacBio chemistry is set per sample (`pacbio_hifi` or `pacbio_clr`).
  - `long_read_min_length`, `long_read_keep_percent` and `long_read_target_bases` control filtering and coverage.
  - A sample whose assembly fails is skipped with a `NOTE` instead of stopping the run.
- `bin/fix_gubbins_gff.py`: checks every record of the Gubbins recombination GFF before masking, repairs or drops any bad record and logs a warning.
- `min_partition_size` (default 4): FastBAPS clusters with fewer sequences are skipped with a warning.
- `trace_timestamp` is now an explicit parameter, used in the `pipeline_info/` report file names.
- `.gitignore` entries for test data, outputs and local artifacts.

### `Changed`

- **Nextflow 26.04 compatibility** (strict config and script syntax): `check_max()` replaced by native `resourceLimits`; the `try/catch` around `includeConfig` replaced by a conditional include; top-level statements, `for` loops and `exit 1, 'msg'` rewritten for the strict parser; `workflow.onComplete` moved to the entry workflow.
- Gubbins now runs single-threaded (`cpus = 1` in `conf/modules.config`), see *Fixed*.
- IQ-TREE is allowed up to 72 h (was the `process_medium` limit of 8 h); still capped by `max_time`.
- The `test` profile samplesheet uses `https://` URLs instead of `ftp://` or local-only paths, which stage more reliably.
- Documentation rewritten and reorganised (#24): `README.md`, `docs/usage.md`, `docs/parameters.md`, `docs/output.md`, `docs/workflow.md`, plus a global core alignment page. The `min_trim_length` default is documented as 35 (not 50) and `ref_genbank` as required (no default).
- `docs/output.md` now matches what a run actually writes: Gubbins results are under `run/` (not `mask/`), per-sample consensus FASTAs are under `samtools/`, report files in `pipeline_info/` carry a timestamp, and the `varcodons.py` outputs under `utils/` are listed.
- `nextflow_schema.json` documents all the new parameters.

### `Fixed`

- **Gubbins output could be corrupted when run multi-threaded.** Gubbins 3.4.1 (unchanged in 3.4.3) hands one recombination GFF file handle to every worker thread and writes each record with several unlocked `fprintf` calls, so with more than one thread records from different branches are spliced together. This crashed `mask_gubbins_aln.py` (`AttributeError: 'NoneType' object has no attribute 'group'`) and could silently mis-mask lines that still parsed. Fixed by running Gubbins single-threaded, with `fix_gubbins_gff.py` as a safety net. This is an upstream Gubbins problem and also affects `master`.
- **FastBAPS clustering had no effect on Gubbins**: `RUN_GUBBINS` always received the whole alignment and ignored the per-cluster channel. It now runs per cluster; clusters below `min_partition_size` are skipped because RAxML fails on them (`TOO FEW SPECIES`).
- **The global and cohort alignment merge** referenced `global_core_alignment` and `cohort_core_alignment` without `params.`, so that branch failed whenever both were supplied.
- **IQ-TREE was killed after 8 hours** on large datasets without being retried.
- **One sample without a usable consensus aborted the whole alignment.** `grep -v '^>'` exited 1 on an empty consensus under `bash -e` with no error message, and a consensus covering only one chromosome produced unequal-length sequences that Gubbins rejects. Samples with an empty or partial consensus are now excluded before the gather step, each named in a warning; the run stops with a clear message only if none remain.
- **Command-line values are strings on Nextflow 26**: `100 - params.max_missing_percentage` threw an error, and `n >= params.min_partition_size` silently evaluated to false and skipped every cluster. Both now convert the value to a number first.
- **`UTILS_VARCODONS` used the head node's path to the reference** (`params.ref_genbank`) instead of the staged input, so it failed with `FileNotFoundError` on any executor without a shared filesystem, such as Nomad (#31). It now uses the staged `ref_genbank` file.
- `bin/check_samplesheet.py` executable bit restored, and the samplesheet check is less strict about when it stops the run.
- Snippy: the Java performance-data file is disabled so concurrent `snpEff` runs under Singularity/Apptainer no longer collide on `/tmp`.
- Skip the local file-existence check for remote sample URLs.

### `Dependencies`

- Nextflow 25.04.8 or newer is required; full runs have only been validated on 26.04.x (see *Breaking changes*).
- New tools: SPAdes, MLST, ABRicate, NanoPlot, Filtlong, Flye, `sra-tools`.

### `Deprecated`

- `--download_method ftp` and `aspera` are not implemented and stop with a clear message; only `sratools` works.

### Known limitations

- `nf-core pipelines lint` cannot run: nf-core/tools 4.x needs the newer `nf-schema` plugin, while this pipeline still uses `NfcoreSchema.groovy`.
- PacBio chemistry is not auto-detected.
- With FastBAPS on, samples in clusters below `min_partition_size` are not in the final tree.
- Filtlong's filtered reads are published to `outdir/filtlong/` and can be large.
- How `UTILS_VARCODONS` maps positions on the second chromosome of the two-record reference has not been reviewed; it is unchanged from 1.2.0.
- Validated on the `test` profile on a Nomad cluster only with `CUSTOM_DUMPSOFTWAREVERSIONS` disabled; that step fails there for a reason outside this pipeline (a bootstrap script problem in the Nomad S5cmd executor plugin).

## 1.2.0 - 2025-11-10

### `Added`

- Reviewer-feedback release (#20). Regenerated the parameter schema (`nextflow_schema.json`, #21), then reverted to the older nf-core JSON schema format and listed the pipeline-specific parameters in `schema_ignore_params` to silence validation warnings.

### `Changed`

- `fastp` module updated to the current nf-core version, with clearer names for output files (#18).
- Gubbins and the Python and `varcodons` environment dependencies updated.
- `min_trim_length` default lowered from 50 to 35.

## 1.1.1 - 2025-09-15

### `Added`

- A global core alignment of 100 genomes (`cholera_global_n100_2025.09.01.fasta`, Zenodo record 16909942) as the `global_core_alignment` default for the `test` profile.
- `docs/installation.md`; expanded `docs/usage.md`, `docs/parameters.md` and `docs/output.md`; a new MultiQC example image.

### `Changed`

- `samtools consensus` is run with `-a` (output all positions, including those with no coverage).

### `Removed`

- The `ref_fasta` parameter, and the bundled reference FASTA and `NZ_CP028827.1.gbk`. The reference is now given only as a GenBank file with `ref_genbank`.

## 1.1.0 - 2025-08-22

First tagged release of CERI-KRISP/CholeraSeq, created with the [nf-core](https://nf-co.re/) template: reference-guided variant calling with Snippy, consensus sequences with `samtools`, recombination detection with Gubbins, and maximum-likelihood phylogeny with IQ-TREE, using the published global cohort alignment ([Zenodo 10984554](https://doi.org/10.5281/zenodo.10984554)).
