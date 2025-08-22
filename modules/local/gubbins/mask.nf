process MASK_GUBBINS {
    label 'process_medium'
    tag "${meta.id}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gubbins:3.3.5--py39pl5321he4a0461_0' :
        'biocontainers/gubbins:3.3.5--py39pl5321he4a0461_0' }"


    input:
    tuple val(meta), path(alignment), path(input_gff)

    output:
    tuple val(meta), path("*masked.fasta")  , emit: masked_fasta
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    mask_gubbins_aln.py \\
      --aln ${alignment} \\
      --gff ${input_gff} \\
      --out ${alignment.baseName}.gub.masked.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gubbins: \$(mask_gubbins_aln.py --version 2>&1)
    END_VERSIONS
    """
}
