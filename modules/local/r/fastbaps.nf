process R_FASTBAPS {
    tag "r-fastbaps"
    label 'process_medium'

    conda "bioconda::r-fastbaps=1.0.8 bioconda::bioconductor-biostrings=2.66.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-fastbaps:1.0.8--r42h43eeafb_2' :
        'biocontainers/r-fastbaps:1.0.8--r42h43eeafb_2' }"

    input:
    tuple val(meta), path(cleaned_fa)

    output:
    tuple val(meta), path("fastbaps_clusters.csv")                , emit: classification
    path "versions.yml"                                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: "-p optimise.symmetric "
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    run_fastbaps \\
        $args \\
        -l 1 \\
        -i ${cleaned_fa} \\
        -t ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": R_FASTBAPS: 1.0.8
    END_VERSIONS
    """
}
