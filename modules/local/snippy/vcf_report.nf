process SNIPPY_VCF_REPORT {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::snippy=4.6.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/snippy:4.6.0--hdfd78af_2' :
        'biocontainers/snippy:4.6.0--hdfd78af_2' }"

    input:
    tuple val(meta), path(sample_ref_fasta), path(sample_ref_bam), path(sample_ref_vcf)

    output:
    tuple val(meta), path("${prefix}.vcf_report.txt")              , emit: report
    path "versions.yml"                                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    snippy-vcf_report \\
            $args \\
            --cpus $task.cpus \\
            --ref $sample_ref_fasta \\
            --vcf $sample_ref_vcf \\
            --bam $sample_ref_bam \\
    > ${prefix}.vcf_report.txt



    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        snippy: \$(echo \$(snippy --version 2>&1) | sed 's/snippy //')
    END_VERSIONS
    """
}

