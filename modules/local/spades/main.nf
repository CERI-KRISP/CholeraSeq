// Local module - based on nf-core/modules SPADES (master branch), adapted to
// CholeraSeq's classic versions.yml convention (ch_versions.mix(...)) instead
// of nf-core/modules' newer topic-based `topic: versions` emission, so it
// slots into the pipeline's existing version-collection pattern unchanged.
process SPADES {
    tag "$meta.id"
    label 'process_high'

    container "quay.io/biocontainers/spades:4.3.0--hde4eca7_0"

    input:
    tuple val(meta), path(illumina)

    output:
    tuple val(meta), path('*.scaffolds.fa.gz'), optional: true, emit: scaffolds
    tuple val(meta), path('*.contigs.fa.gz')  , optional: true, emit: contigs
    tuple val(meta), path('*.spades.log')     , emit: log
    path 'versions.yml'                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def maxmem = task.memory.toGiga()
    def illumina_reads = meta.single_end ? "-s ${illumina}" : "-1 ${illumina[0]} -2 ${illumina[1]}"
    """
    spades.py \\
        $args \\
        --threads $task.cpus \\
        --memory $maxmem \\
        $illumina_reads \\
        -o ./

    mv spades.log ${prefix}.spades.log

    if [ -f scaffolds.fasta ]; then
        mv scaffolds.fasta ${prefix}.scaffolds.fa
        gzip -n ${prefix}.scaffolds.fa
    fi
    if [ -f contigs.fasta ]; then
        mv contigs.fasta ${prefix}.contigs.fa
        gzip -n ${prefix}.contigs.fa
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spades: \$(spades.py --version 2>&1 | sed -n 's/^.*SPAdes genome assembler v//p')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "" | gzip > ${prefix}.scaffolds.fa.gz
    touch ${prefix}.spades.log
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spades: 4.1.0
    END_VERSIONS
    """
}
