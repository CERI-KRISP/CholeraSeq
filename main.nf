#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CERI-KRISP/CholeraSeq
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/CERI-KRISP/CholeraSeq----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOW FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CHOLERASEQ } from './workflows/choleraseq'

//
// WORKFLOW: Run main CERI-KRISP/CholeraSeq analysis pipeline
//
workflow CERI_KRISP {
    CHOLERASEQ ()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN ALL WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
// See: https://github.com/nf-core/rnaseq/issues/619
//
workflow {
    // VALIDATE & PRINT PARAMETER SUMMARY
    // NOTE: moved here from top-level script scope - bare statements outside
    // a process/workflow/function are not allowed under Nextflow's strict
    // script syntax (default since Nextflow 26.04).
    WorkflowMain.initialise(workflow, params, log)

    CERI_KRISP ()

    // COMPLETION EMAIL AND SUMMARY
    // NOTE: this must live at this exact nesting level (main.nf's entry workflow),
    // not inside CHOLERASEQ - registering workflow.onComplete deeper than this
    // throws a NullPointerException at runtime because `params` doesn't reliably
    // resolve inside a closure invoked later (at session shutdown) from that far
    // down the workflow-call chain. summary_params is recomputed here rather than
    // forwarded from CHOLERASEQ, since it only depends on workflow/params, both of
    // which are already known-good at this level.
    //
    // multiqc_report is built as a direct file path rather than forwarded through
    // CHOLERASEQ/CERI_KRISP's `emit:` - attempting that hits an unresolved Nextflow
    // bug ("Missing workflow output parameter") when a workflow output is nested
    // two `emit:` hops deep (see nextflow-io/nextflow#6204 for the same failure
    // mode). Since this value is only used to attach the report to a completion
    // email (a path only reached if params.email/email_on_fail is set), and
    // MULTIQC's publishDir is deterministic, constructing the path directly avoids
    // the bug entirely with no loss of functionality.
    //
    // `wf`/`prms`/`lg`/`pd` capture the corresponding implicit bindings BEFORE
    // entering the closure below. Referencing bare implicit identifiers (workflow,
    // params, log, projectDir) *inside* `workflow.onComplete {}` is ambiguous -
    // Groovy sets the closure's delegate to the workflow object itself, so those
    // names can resolve against that delegate instead of the outer script binding,
    // silently returning null. This affects every implicit binding used inside the
    // closure, not just `workflow` (confirmed: first hit workflow.revision, then
    // hit params.containsKey() the same way after aliasing only `workflow`) -
    // aliasing all four up front avoids fixing this one variable at a time.
    def wf   = workflow
    def prms = params
    def lg   = log
    def pd   = projectDir
    workflow.onComplete {
        def summary_params  = NfcoreSchema.paramsSummaryMap(wf, prms)
        def multiqc_report  = ["${prms.outdir}/multiqc/multiqc_report.html"]
        if (prms.email || prms.email_on_fail) {
            NfcoreTemplate.email(wf, prms, summary_params, pd, lg, multiqc_report)
        }
        NfcoreTemplate.summary(wf, prms, lg)
        if (prms.hook_url) {
            NfcoreTemplate.IM_notification(wf, prms, summary_params, pd, lg)
        }
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
