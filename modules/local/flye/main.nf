// Local module - based on nf-core/modules FLYE (master), adapted to
// CholeraSeq's classic versions.yml convention. `mode` is a broadcast value
// (not per-sample) - e.g. '--nano-raw', '--pacbio-hifi' - so ONT and PacBio
// batches must be run as separate FLYE calls, not mixed into one.
process FLYE {
    tag "$meta.id"
    label 'process_high'

    container "community.wave.seqera.io/library/flye:2.9.5--d577924c8416ccd8"

    input:
    tuple val(meta), path(reads)
    val mode

    output:
    tuple val(meta), path("*.assembly.fasta.gz"), emit: fasta
    tuple val(meta), path("*.assembly_info.txt"), emit: info
    path 'versions.yml'                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def valid_mode = ["--pacbio-raw", "--pacbio-corr", "--pacbio-hifi", "--nano-raw", "--nano-corr", "--nano-hq"]
    if (!valid_mode.contains(mode)) { error "Unrecognised mode to run Flye. Options: ${valid_mode.join(', ')}" }
    """
    flye \\
        $mode \\
        $reads \\
        --out-dir . \\
        --threads $task.cpus \\
        $args

    gzip -c assembly.fasta > ${prefix}.assembly.fasta.gz
    mv assembly_info.txt ${prefix}.assembly_info.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: \$(flye --version)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo stub | gzip -c > ${prefix}.assembly.fasta.gz
    echo contig_1 > ${prefix}.assembly_info.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: 2.9.5
    END_VERSIONS
    """
}
