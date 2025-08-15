process UTILS_VARCODONS {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://community.wave.seqera.io/library/biopython:1.70--9ffc9e654351f59a':
        'community.wave.seqera.io/library/biopython:1.70--9ffc9e654351f59a' }"

    input:
    tuple val(meta), path(cat_consensus_fasta)
    path(ref_fasta)
    path(ref_genbank)

    output:
    tuple val(meta), path("*.fasta")    , emit: fasta
    path("*snps.tsv")                   , emit: snp_report
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"



    //NOTE
    // -g ${ref_genbank} is used only when the reference is gbk format

    """
    varcodons.py \\
        ${task.ext.args} \\
        -f ${cat_consensus_fasta} \\
        -o ${prefix}.fasta \\
        -r ${prefix}.snps.tsv


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
