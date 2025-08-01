process PYTHON_SPLIT_CLUSTERS {
    tag "split_clusters"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://community.wave.seqera.io/library/biopython:1.70--9ffc9e654351f59a':
        'community.wave.seqera.io/library/biopython:1.70--9ffc9e654351f59a' }"

    input:
    tuple val(meta), path(fastbaps_clusters)

    output:
    path("cluster.*.csv")             , emit: clusters
    path "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    //prefix = task.ext.prefix ?: "${meta.id}"

    """
    split_clusters.py csv --cluster-file $fastbaps_clusters

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        babashka: \$(echo \$(bb --version 2>&1) | sed 's/babashka //')
    END_VERSIONS
    """
}
