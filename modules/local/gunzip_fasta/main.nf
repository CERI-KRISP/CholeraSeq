// Decompresses a gzipped assembly fasta (e.g. NCBI's <acc>_genomic.fna.gz) so
// every is_contig:true sample reaches Snippy's contig-alignment mode as plain
// fasta, regardless of how it was supplied. Uses docker.io/ubuntu:22.04 (the
// explicit docker.io/ prefix is required - this pipeline's
// docker.registry = 'quay.io' setting would otherwise prepend quay.io/, where
// ubuntu doesn't exist) since all this needs is zcat.
process GUNZIP_FASTA {
    tag "$meta.id"
    label 'process_single'

    container "docker.io/ubuntu:22.04"

    input:
    tuple val(meta), path(gz_fasta)

    output:
    tuple val(meta), path("${gz_fasta.baseName}"), emit: fasta

    script:
    """
    zcat ${gz_fasta} > ${gz_fasta.baseName}
    """

    stub:
    """
    touch ${gz_fasta.baseName}
    """
}
