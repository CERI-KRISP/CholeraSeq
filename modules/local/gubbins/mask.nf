process MASK_GUBBINS {
    label 'process_medium'

    conda "bioconda::gubbins=3.3.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gubbins:3.3.0--py310pl5321h8472f5a_0' :
        'biocontainers/gubbins:3.3.0--py310pl5321h8472f5a_0' }"


    input:
    tuple path(alignment), path(input_gff)

    output:
    path "*.fasta"                          , emit: fasta
    path "*.gff"                            , emit: gff
    path "*.vcf"                            , emit: vcf
    path "*.csv"                            , emit: stats
    path "*.phylip"                         , emit: phylip
    path "*.recombination_predictions.embl" , emit: embl_predicted
    path "*.branch_base_reconstruction.embl", emit: embl_branch
    path "*.final_tree.tre"                 , emit: tree
    path "*.node_labelled.final_tree.tre"   , emit: tree_labelled
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    //FIXME this is a custom script and isn't delivered with gubbins package

    """
    mask_gubbins_aln.py \\
      --aln ${alignment} \\
      --gff ${input_gff} \\
      --out ${alignment.simpleName}.gub.masked.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gubbins: \$(mask_gubbins_aln.py --version 2>&1)
    END_VERSIONS
    """
}
