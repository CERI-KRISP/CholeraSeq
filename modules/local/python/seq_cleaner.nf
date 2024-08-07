process PYTHON_SEQ_CLEANER {
    tag "seq_cleaner $prefix"
    label 'process_low'

    conda "conda-forge::python=3.10.13"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://quay.io/biocontainers/biopython:1.81':
        'quay.io/biocontainers/biopython:1.81' }"


    input:
    tuple val(meta), path(input_fasta)

    output:
    tuple val(meta), path("${prefix}.fasta")             , emit: cleaned_fasta
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    seq_cleaner.py -f ${params.fasta_threshold} $input_fasta ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: 3.10.13
    END_VERSIONS
    """
}
