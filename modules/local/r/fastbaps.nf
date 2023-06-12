process R_FASTBAPS {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::r-fastbaps=1.0.8 bioconda::bioconductor-biostrings=2.66.0"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        //'https://depot.galaxyproject.org/singularity/snippy:4.6.0--hdfd78af_2' :
        //'biocontainers/snippy:4.6.0--hdfd78af_2' }"

    input:
    tuple val(meta), path(cleaned_fa)

    output:
    path "versions.yml"                                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: "-p optimise.symmetric -l 1 -t ${task.cpus} "
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    run_fastbaps \\
        $args \\
        -i ${cleaned_fa}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R_FASTBAPS: 1.0.8
    END_VERSIONS
    """
}
