process SNIPPY_RUN {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::snippy=4.6.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/snippy:4.6.0--hdfd78af_3':
        'quay.io/biocontainers/snippy:4.6.0--hdfd78af_3' }"


    input:
    tuple val(meta), path(reads)
    path reference

    output:
    tuple val(meta), path("${prefix}/${prefix}.vcf_report.txt")   , emit: vcf_report
    tuple val(meta), path("${prefix}/${prefix}.tab")              , emit: tab
    tuple val(meta), path("${prefix}/${prefix}.csv")              , emit: csv
    tuple val(meta), path("${prefix}/${prefix}.html")             , emit: html
    tuple val(meta), path("${prefix}/${prefix}.vcf")              , emit: vcf
    tuple val(meta), path("${prefix}/${prefix}.bed")              , emit: bed
    tuple val(meta), path("${prefix}/${prefix}.gff")              , emit: gff
    tuple val(meta), path("${prefix}/${prefix}.bam")              , emit: bam
    tuple val(meta), path("${prefix}/${prefix}.bam.bai")          , emit: bai
    tuple val(meta), path("${prefix}/${prefix}.log")              , emit: log
    tuple val(meta), path("${prefix}/${prefix}.aligned.fa")       , emit: aligned_fa
    tuple val(meta), path("${prefix}/${prefix}.consensus.fa")     , emit: consensus_fa
    tuple val(meta), path("${prefix}/${prefix}.consensus.subs.fa"), emit: consensus_subs_fa
    tuple val(meta), path("${prefix}/${prefix}.raw.vcf")          , emit: raw_vcf
    tuple val(meta), path("${prefix}/${prefix}.filt.vcf")         , emit: filt_vcf
    tuple val(meta), path("${prefix}/${prefix}.vcf.gz")           , emit: vcf_gz
    tuple val(meta), path("${prefix}/${prefix}.vcf.gz.csi")       , emit: vcf_csi
    tuple val(meta), path("${prefix}/${prefix}.txt")              , emit: txt
    path "versions.yml"                                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def fastq_inputs = (meta.single_end && !meta.is_contig) ? "--se ${reads[0]}" : "--R1 ${reads[0]} --R2 ${reads[1]}"
    def final_inputs = meta.is_contig ? "--ctgs ${reads[0]}" : fastq_inputs

    """
    snippy \\
        $args \\
        --cpus $task.cpus \\
        --outdir $prefix \\
        --prefix $prefix \\
        --ref $reference \\
        $final_inputs


    snippy-vcf_report \\
            --cpus $task.cpus \\
            --ref $prefix/ref.fa \\
            --vcf $prefix/${prefix}.vcf \\
            --bam $prefix/${prefix}.bam \\
    > $prefix/${prefix}.vcf_report.txt


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        snippy: \$(echo \$(snippy --version 2>&1) | sed 's/snippy //')
    END_VERSIONS
    """
}
