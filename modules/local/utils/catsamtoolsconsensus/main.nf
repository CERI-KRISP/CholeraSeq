process UTILS_CAT_SAMTOOLS_CONSENSUS {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    input:
    tuple val(meta), path("consensus_seqs/*")

    output:
    tuple val(meta), path("*.fasta"), emit: fasta
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"


    // ls consensus_seqs/* > consensus_seqs/inputFile.list

    // myFiles=($(<../inputFiles.list))

    // for i in \${myFiles[@]};
    // do
    //     echo -e ">\${i}" >> alignment.fasta
    //     grep -v '>' ../consensus_seqs/\${i}.consensus.fasta >> alignment.fasta
    //     sed -i "s/\*/-/g" alignment.fasta
    // done



    """
    ls consensus_seqs/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -n1 | cut -d' ' -f4)
        grep: \$(grep --version | head -n1 | cut -d' ' -f4)
        sed: \$(sed --version | head -n1 | cut -d' ' -f4)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -n1 | cut -d' ' -f4)
        grep: \$(grep --version | head -n1 | cut -d' ' -f4)
        sed: \$(sed --version | head -n1 | cut -d' ' -f4)
    END_VERSIONS
    """
}
