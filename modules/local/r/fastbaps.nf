process R_FASTBAPS {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::r-fastbaps=1.0.8"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        //'https://depot.galaxyproject.org/singularity/snippy:4.6.0--hdfd78af_2' :
        //'biocontainers/snippy:4.6.0--hdfd78af_2' }"

    input:
    tuple val(meta), path(reads)
    path reference

    output:
    tuple val(meta), path("${prefix}/${prefix}.tab")              , emit: tab
    path "versions.yml"                                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def fastq_inputs = (meta.single_end && !meta.is_contig) ? "--se ${reads[0]}" : "--R1 ${reads[0]} --R2 ${reads[1]}"
    def final_inputs = meta.is_contig ? "--ctgs ${reads[0]}" : fastq_inputs

//NOTE: https://github.com/gtonkinhill/fastbaps#command-line-script

    """
    snippy \\
        $args \\
        --cpus $task.cpus \\
        --outdir $prefix \\
        --reference $reference \\
        --prefix $prefix \\
        $final_inputs

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R_FASTBAPS: FIXME
    END_VERSIONS
    """
}
