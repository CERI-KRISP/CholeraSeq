process CLJ_SPLIT_CLUSTERS {
    tag "$meta.id"
    label 'process_low'

    //FIXME Publish babashka binary in a conda channel
    //conda "bioconda::snippy=4.6.0 bioconda::snp-sites=2.5.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://babashka/babashka:1.3.181':
        'docker.io/babashka/babashka:1.3.181' }"

    input:
    tuple val(meta), path(fastbaps_clusters)

    output:
    path("cluster.*.csv")                              , emit: clusters
    path "versions.yml"                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    split_clusters.bb.clj $fastbaps_clusters

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        babashka: \$(echo \$(bb --version 2>&1) | sed 's/babashka //')
    END_VERSIONS
    """
}
