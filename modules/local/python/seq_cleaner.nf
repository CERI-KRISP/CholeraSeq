process PYTHON_SEQ_CLEANER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://community.wave.seqera.io/library/biopython:1.70--9ffc9e654351f59a':
        'community.wave.seqera.io/library/biopython:1.70--9ffc9e654351f59a' }"


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
