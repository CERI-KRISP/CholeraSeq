// Local module - based on nf-core/modules MLST (master branch), adapted to
// CholeraSeq's classic versions.yml convention.
process MLST {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/mlst:2.25.0--hdfd78af_0"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mlst \\
        $args \\
        --threads $task.cpus \\
        $fasta \\
        > ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mlst: \$(mlst --version 2>&1 | sed 's/mlst //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mlst: 2.25.0
    END_VERSIONS
    """
}
