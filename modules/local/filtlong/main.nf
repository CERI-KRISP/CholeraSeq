// Local module - based on nf-core/modules FILTLONG (master), simplified to
// long-read-only input (no short-read hybrid filtering - not needed here),
// adapted to CholeraSeq's classic versions.yml convention.
process FILTLONG {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/filtlong:0.2.1--h9a82719_0"

    input:
    tuple val(meta), path(longreads)

    output:
    tuple val(meta), path("*.filt.fastq.gz"), emit: reads
    tuple val(meta), path("*.log")          , emit: log
    path 'versions.yml'                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    filtlong \\
        $args \\
        $longreads \\
        2>| >(tee ${prefix}.log >&2) \\
        | gzip -n > ${prefix}.filt.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        filtlong: \$(filtlong --version | sed -e "s/Filtlong v//g")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "" | gzip > ${prefix}.filt.fastq.gz
    touch ${prefix}.log
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        filtlong: 0.2.1
    END_VERSIONS
    """
}