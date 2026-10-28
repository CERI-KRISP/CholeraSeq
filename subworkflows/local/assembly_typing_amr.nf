include { SPADES       } from '../../modules/local/spades/main.nf'
include { MLST         } from '../../modules/local/mlst/main.nf'
include { ABRICATE_RUN } from '../../modules/local/abricate/main.nf'
include { ABRICATE_SUMMARY } from '../../modules/local/abricate/summary.nf'
include { MLST_SUMMARY     } from '../../modules/local/mlst/summary.nf'

// De novo assembly, MLST typing, and AMR/virulence screening. Branches off the
// same input channel shape VARIANT_CALLING_WF takes (mixed fastq + pre-assembled
// contig samples, distinguished via meta.is_contig - set in input_check.nf).
// Samples that are already contigs skip SPAdes entirely and go straight to
// MLST/ABRicate; fastq samples are assembled with SPAdes first.
//
// NOTE: MLST/ABRICATE_RUN are always invoked, even when --skip_mlst/--skip_amr
// is set - they're just fed Channel.empty() in that case, so zero tasks run.
// This is deliberate: conditionally calling a process inside an `if` block
// (skipping the call entirely) leaves ProcessName.out undefined for that run,
// which breaks any downstream/emit reference to it - the same class of bug
// that took a long time to track down for workflow.onComplete earlier in this
// migration. Always-invoke-with-empty-input avoids that failure mode entirely.
//
// NOTE: mlst and abricate both accept gzipped fasta input natively, so
// SPADES' gzipped scaffolds output is used as-is here without an extra
// gunzip step - verify this holds for the exact tool versions pinned in
// modules/local/{mlst,abricate}/main.nf if either process behaves
// unexpectedly on real data.
workflow ASSEMBLY_TYPING_AMR_WF {

    take:
        reads_ch   // channel: [ val(meta), [ reads ] ]  (meta.is_contig: true|false)

    main:
        ch_versions = Channel.empty()

        reads_ch
            .branch {
                contigs: it[0].is_contig == true
                fastqs:  it[0].is_contig == false
            }
            .set { branched_ch }

        //
        // Assemble fastq samples; pre-assembled contig samples pass through untouched
        //
        SPADES ( branched_ch.fastqs )
        ch_versions = ch_versions.mix(SPADES.out.versions)

        assembly_ch = SPADES.out.scaffolds.mix(branched_ch.contigs)

        //
        // MLST typing
        //
        mlst_input_ch = params.skip_mlst ? Channel.empty() : assembly_ch
        MLST ( mlst_input_ch )
        ch_versions = ch_versions.mix(MLST.out.versions)

        // One table for all samples (runs only if MLST produced anything)
        MLST_SUMMARY ( MLST.out.tsv.map { _meta, tsv -> tsv }.collect() )
        ch_versions = ch_versions.mix(MLST_SUMMARY.out.versions)

        //
        // AMR / virulence / plasmid screening
        //
        abricate_input_ch = params.skip_amr ? Channel.empty() : assembly_ch
        ABRICATE_RUN ( abricate_input_ch, [] )
        ch_versions = ch_versions.mix(ABRICATE_RUN.out.versions)

        // Gene-by-sample and all-hits tables, one pair per database
        ABRICATE_SUMMARY ( ABRICATE_RUN.out.report.map { _meta, reports -> reports }.flatten().collect() )
        ch_versions = ch_versions.mix(ABRICATE_SUMMARY.out.versions)

    emit:
        assembly_ch
        mlst_tsv         = MLST.out.tsv
        abricate_report  = ABRICATE_RUN.out.report
        mlst_summary     = MLST_SUMMARY.out.summary
        abricate_summary = ABRICATE_SUMMARY.out.summary
        versions         = ch_versions
}
