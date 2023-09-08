process SNIPPY_CLEAN {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::snippy=4.6.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/snippy:4.6.0--hdfd78af_2':
        'biocontainers/snippy:4.6.0--hdfd78af_1' }"

    input:
    tuple val(meta), path(snippy_aligned_fasta)

    output:
    tuple val(meta), path("${prefix}.cleaned_full.aln"), emit: cleaned_full_aln
    tuple val(meta), path("${prefix}_cls.full.aln")    , emit: cls_full_aln
    tuple val(meta), path("${prefix}_iq_cls.full.aln") , emit: iq_cls_full_aln
    tuple val(meta), path("${prefix}_mm_cls.full.aln") , emit: mm_cls_full_aln
    path "versions.yml"                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    # removing ambiguous iupac codes and replacing them with Ns
    snippy-clean_full_aln ${snippy_aligned_fasta} >  ${prefix}.cleaned_full.aln

    # finding snp sites from multi FASTA alignment file
    snp-sites -c  -o ${prefix}.snpsites.aln ${prefix}.cleaned_full.aln
    snp-sites -C  -o ${prefix}.snpsites.iq.aln    ${prefix}.cleaned_full.aln
    snp-sites -cb -o ${prefix}.snpsites.mm.aln    ${prefix}.cleaned_full.aln

    # removing iupac codes and repalcing them with Ns
    snippy-clean_full_aln ${prefix}.snpsites.aln    >> ${prefix}_cls.full.aln
    snippy-clean_full_aln ${prefix}.snpsites.iq.full.aln >> ${prefix}_iq_cls.full.aln
    snippy-clean_full_aln ${prefix}.snpsites.mm.full.aln >> ${prefix}_mm_cls.full.aln

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        snippy: \$(echo \$(snippy-core --version 2>&1) | sed 's/snippy-core //')
        snpsites: \$(snp-sites -V 2>&1 | sed 's/snp-sites //')
    END_VERSIONS
    """
}
