process PYTHON_SEQ_CLEANER {
    tag "$meta.id"
    label 'process_low'

    conda "conda-forge::biopython=1.81"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://quay.io/biocontainers/biopython:1.81':
        'quay.io/biocontainers/biopython:1.81' }"

    input:
    tuple val(meta), path(input_fasta)

    output:
    tuple val(meta), path("*cleaned.fasta")             , emit: cleaned_fasta
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def local_min_valid_percentage = (100 - params.max_missing_percentage)

    """
    seq_cleaner.py -f ${local_min_valid_percentage} $input_fasta ${prefix}.cleaned.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: 3.10.13
    END_VERSIONS
    """
}
