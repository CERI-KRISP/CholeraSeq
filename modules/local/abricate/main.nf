// Local module - based on nf-core/modules ABRICATE_RUN (master branch),
// adapted to CholeraSeq's classic versions.yml convention. databasedir is
// optional - pass [] to use ABRicate's bundled default databases.
process ABRICATE_RUN {
    tag "$meta.id"
    label 'process_medium'

    container "quay.io/biocontainers/abricate:1.0.1--ha8f3691_1"

    input:
    tuple val(meta), path(assembly)
    path databasedir

    output:
    tuple val(meta), path("*.txt"), emit: report
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args   ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def datadir = databasedir ? "--datadir ${databasedir}" : ''
    // One report per database: by default AMR (ncbi), virulence (vfdb) and plasmid
    // replicons (plasmidfinder) - set with --abricate_dbs. Without --db, abricate
    // searches only its default 'ncbi' AMR database.
    def dbs     = (task.ext.dbs ?: 'ncbi').tokenize(',')*.trim().findAll { db -> db }
    """
    if [[ "${assembly}" != "${prefix}.fasta" ]]; then
        ln -s ${assembly} ${prefix}.fasta
    fi

    for db in ${dbs.join(' ')}; do
        abricate \\
            ${prefix}.fasta \\
            --db \$db \\
            ${args} \\
            ${datadir} \\
            --threads ${task.cpus} \\
            > ${prefix}.\${db}.txt
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \$(abricate --version | sed 's/^.* //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def dbs    = (task.ext.dbs ?: 'ncbi').tokenize(',')*.trim().findAll { db -> db }
    """
    for db in ${dbs.join(' ')}; do touch ${prefix}.\${db}.txt; done
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: 1.0.1
    END_VERSIONS
    """
}
