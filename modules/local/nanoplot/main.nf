// Local module - based on nf-core/modules NANOPLOT (master), adapted to
// CholeraSeq's classic versions.yml convention.
process NANOPLOT {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/nanoplot:1.47.0--pyhdfd78af_0"

    input:
    tuple val(meta), path(ontfile)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.png"), optional: true, emit: png
    tuple val(meta), path("*.txt"), emit: txt
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // -p: NanoPlot otherwise names every sample's files identically (NanoPlot-report.html,
    // NanoStats.txt, ...), so all samples publishing into one nanoplot/ folder overwrite
    // each other and only the last sample's QC survives.
    """
    NanoPlot \\
        $args \\
        -t $task.cpus \\
        -p ${prefix}_ \\
        --fastq ${ontfile}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoplot: \$(NanoPlot --version | sed 's/^.*NanoPlot //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_NanoPlot-report.html
    touch ${prefix}_NanoStats.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoplot: 1.47.0
    END_VERSIONS
    """
}
