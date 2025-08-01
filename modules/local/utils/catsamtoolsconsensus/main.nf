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


    """
    ls consensus_seqs/*fasta > inputFiles.txt

    input_files_list=inputFiles.txt

    # Read file names from the input list and process each consensus file
    while IFS= read -r filename; do
    if [[ -n "\$filename" ]]; then
        echo ">\${filename}" >> ${meta.id}.fasta
        grep -v '^>' \${filename} >> ${meta.id}.fasta
    fi
    done < \${input_files_list}

    # Replace asterisks with dashes
    sed -i 's/\\*/\\-/g' ${meta.id}.fasta


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -n1 | cut -d' ' -f4)
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
