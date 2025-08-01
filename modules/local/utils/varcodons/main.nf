process UTILS_VARCODONS {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://community.wave.seqera.io/library/biopython:1.70--9ffc9e654351f59a':
        'community.wave.seqera.io/library/biopython:1.70--9ffc9e654351f59a' }"

    input:
    tuple val(meta), path(cat_consensus_fasta)
    path(ref_genbank)

    output:
    tuple val(meta), path("*.varcodons.fasta"), emit: fasta
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    varcodons.py \\
        -f ${cat_consensus_fasta} \\
        -g ${ref_genbank} \\
        -o ${prefix}.varcodons.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.varcodons.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version)
    END_VERSIONS
    """
}
