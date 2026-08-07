/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { GET_INPUT_WF                } from '../subworkflows/local/get_input'
include { QUALITY_CONTROL_WF         } from '../subworkflows/local/quality_control'
include { VARIANT_CALLING_WF         } from '../subworkflows/local/variant_calling'
include { CLUSTERING_WF              } from '../subworkflows/local/clustering'
include { ASSEMBLY_TYPING_AMR_WF     } from '../subworkflows/local/assembly_typing_amr'
include { CAT_CAT                    } from '../modules/nf-core/cat/cat/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CHOLERASEQ {

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // VALIDATE INPUTS
    // NOTE: everything below down to CONFIG FILES was originally bare top-level script
    // code (outside any process/workflow/function), which is no longer allowed under
    // Nextflow's strict script syntax (default since Nextflow 26.04). Moved inside the
    // workflow block, with the `for` loop rewritten as `.each {}` (for loops are no
    // longer supported at all) and `exit 1, 'msg'` rewritten as `error('msg')` (the
    // `exit`, code, message` command form is a removed DSL1-era construct).
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

    // Validate input parameters
    WorkflowCholera_analysis_nf.initialise(params, log)

    // TODO nf-core: Add all file path parameters for the pipeline to the list below
    // Check input path parameters to see if they exist
    def checkPathParamList = [ params.input, params.multiqc_config ]
    checkPathParamList.each { param -> if (param) { file(param, checkIfExists: true) } }

    // Check mandatory parameters - accept a samplesheet OR the directory/list
    // auto-discovery flags (from Cholera_genomics integration). GET_INPUT_WF
    // enforces the mutual-exclusivity/at-least-one-mode rules itself at runtime;
    // this is just an early, clear fail if literally nothing was given.
    if (!params.input && !params.reads_dir && !params.contigs_dir && !params.sra_list) {
        error('No input specified. Use --input <samplesheet.csv>, or one or more of --reads_dir/--contigs_dir/--sra_list.')
    }

    if (!(params.download_method in ['sratools', 'ftp', 'aspera'])) {
        error("--download_method must be one of: sratools, ftp, aspera (got '${params.download_method}')")
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // CONFIG FILES
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
    ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

    // NOTE: multiqc_report is declared once below, directly as the real channel
    // value from MULTIQC.out (not as a placeholder `[]` reassigned later) -
    // Nextflow's strict output resolution for workflow `emit:` blocks doesn't
    // reliably track a variable that starts as a plain value and is only later
    // reassigned to a channel (see nextflow-io/nextflow#6204).

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()


    if (params.global_core_alignment && params.cohort_core_alignment) {
        //=========================
        // PATCH GLOBAL GENOME ALIGNMENT
        //=========================

        in_cat_cat = Channel.of([[id: 'concatenate_alns'], [file(params.global_core_alignment), file(params.cohort_core_alignment)]])

        CAT_CAT(in_cat_cat)

        CLUSTERING_WF ( CAT_CAT.out.cat_fasta )

        ch_versions = ch_versions.mix(CLUSTERING_WF.out.versions)

    } else {

        //============================
        // CORE GENOME ALIGNMENT
        //============================

        //
        // SUBWORKFLOW: Get input reads/contigs - samplesheet, directory
        // auto-discovery, or SRA accession list (see get_input.nf)
        //
        GET_INPUT_WF ()
        ch_versions = ch_versions.mix(GET_INPUT_WF.out.versions)


        reads_ch = GET_INPUT_WF.out.reads
                    .branch {
                        contigs:  it[0].is_contig == true
                        fastqs:  it[0].is_contig == false
                    }


        QUALITY_CONTROL_WF (
            reads_ch.fastqs
        )
        ch_versions = ch_versions.mix(QUALITY_CONTROL_WF.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(QUALITY_CONTROL_WF.out.fastqc_zip.collect{it[1]}.ifEmpty([]))
        ch_multiqc_files = ch_multiqc_files.mix(QUALITY_CONTROL_WF.out.fastp_json.collect{it[1]}.ifEmpty([]))


        cleaned_reads_ch = QUALITY_CONTROL_WF.out.trimmed_reads
                            .mix(reads_ch.contigs)
                            //.view()
                            //.collect()
                            //.dump(tag: 'cleaned_reads_ch')

        VARIANT_CALLING_WF (
            cleaned_reads_ch
        )
        ch_versions = ch_versions.mix(VARIANT_CALLING_WF.out.versions)

        //
        // De novo assembly + MLST typing + AMR/virulence screening (from
        // Cholera_genomics integration). Runs on the same cleaned_reads_ch as
        // VARIANT_CALLING_WF above - entirely independent branch, doesn't touch
        // the existing Snippy/consensus/alignment logic. Gated by --skip_assembly
        // (whole subworkflow) and, inside it, --skip_mlst/--skip_amr (individual
        // steps). Always invoked with a (possibly empty) channel rather than
        // conditionally skipped, so ASSEMBLY_TYPING_AMR_WF.out is always defined -
        // see the note in assembly_typing_amr.nf for why that matters.
        //
        assembly_typing_input_ch = params.skip_assembly ? Channel.empty() : cleaned_reads_ch
        ASSEMBLY_TYPING_AMR_WF ( assembly_typing_input_ch )
        ch_versions = ch_versions.mix(ASSEMBLY_TYPING_AMR_WF.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(ASSEMBLY_TYPING_AMR_WF.out.mlst_tsv.collect{it[1]}.ifEmpty([]))
        ch_multiqc_files = ch_multiqc_files.mix(ASSEMBLY_TYPING_AMR_WF.out.abricate_report.collect{it[1]}.ifEmpty([]))


        if (!params.skip_clustering) {

            if(params.global_core_alignment ) {

                cohort_core_aln = VARIANT_CALLING_WF.out.concatenated_aln.map{it -> tuple([id:'patch_global_with_cohort_aln'], file(it[1]))}

                ch_global_aln = Channel.of([[id: 'patch_global_with_cohort_aln'], file(params.global_core_alignment)])

                ch_cat_alignments = ch_global_aln.join(cohort_core_aln).map { m, f1, f2 -> [m, [f1, f2]] }

                ch_cat_alignments.dump(tag: 'ch_cat_alignments', pretty: true)

                CAT_CAT(ch_cat_alignments)

                CLUSTERING_WF ( CAT_CAT.out.file_out )

            } else {

                CLUSTERING_WF ( VARIANT_CALLING_WF.out.concatenated_aln )
            }


            ch_versions = ch_versions.mix(CLUSTERING_WF.out.versions)
            ch_multiqc_files = ch_multiqc_files.mix(VARIANT_CALLING_WF.out.snippy_varcall_txt.collect{it[1]}.ifEmpty([]))

        }

    }


        //============================
        // CUSTOM STOP
        //============================

        CUSTOM_DUMPSOFTWAREVERSIONS (
            ch_versions.unique().collectFile(name: 'collated_versions.yml')
        )



        //
        // MODULE: MultiQC
        //
        workflow_summary    = WorkflowCholera_analysis_nf.paramsSummaryMultiqc(workflow, summary_params)
        ch_workflow_summary = Channel.value(workflow_summary)

        methods_description    = WorkflowCholera_analysis_nf.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
        ch_methods_description = Channel.value(methods_description)

        ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
        ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
        ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())

        MULTIQC (
            ch_multiqc_files.collect(),
            ch_multiqc_config.toList(),
            ch_multiqc_custom_config.toList(),
            ch_multiqc_logo.toList(),
            [],
            []
        )
        multiqc_report = MULTIQC.out.report.toList()

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // NOTE: workflow.onComplete { ... } used to live here, but that throws a
    // NullPointerException ("Cannot get property 'email' on null object") at runtime -
    // `params` does not reliably resolve inside a closure registered this many levels
    // deep (CHOLERASEQ -> CERI_KRISP -> main.nf's entry workflow). The completion hook
    // now lives in main.nf's outermost `workflow {}` block instead, and builds
    // multiqc_report as a direct file path rather than forwarding it from here -
    // routing it through this workflow's `emit:` hit a separate unresolved Nextflow
    // bug ("Missing workflow output parameter", nextflow-io/nextflow#6204). This
    // workflow is therefore back to a plain (unlabeled) body - no take:/main:/emit:
    // needed since nothing consumes CHOLERASEQ.out anymore.
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
