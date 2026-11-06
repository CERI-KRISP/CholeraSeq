// Downloads reads for a single SRA/ENA accession (SRR/ERR/DRR). Method is
// selected via params.download_method:
//   'sratools' (default, and the ONLY currently implemented method) - prefetch
//                            + fasterq-dump against NCBI's SRA infrastructure.
//                            Independent of EBI - this is what got test data
//                            downloading again during an EBI outage encountered
//                            while integrating this pipeline. Proven working
//                            against real accessions.
//   'ftp'                  - NOT YET IMPLEMENTED. An earlier attempt queried
//                            ENA's filereport API and parsed the TSV response
//                            in-container, but repeatedly failed in ways that
//                            pointed to GNU-vs-BusyBox shell utility differences
//                            (curlimages/curl is Alpine-based) rather than
//                            anything wrong with the underlying approach - and
//                            critically, this was never something Cholera_genomics
//                            itself did, so there was no working reference to
//                            debug against. Fails fast with a clear message
//                            rather than shipping something unreliable. The
//                            more robust path, if revisited: compute the fastq
//                            URL(s) deterministically in Groovy (ENA's
//                            documented vol1/fastq/<prefix>/<subdir>/<acc> path
//                            convention, based on accession length) rather than
//                            querying an API and parsing its response inside
//                            the container shell.
//   'aspera'                - NOT YET IMPLEMENTED. Fails fast with a clear error
//                            rather than silently falling back to another
//                            method. Scaffolded as a future optimization -
//                            nf-core/fetchngs reports ~50% faster transfers than
//                            FTP for large-scale downloads, at the cost of extra
//                            setup (licensed Aspera CLI + key file bundled into
//                            the container) and, per user reports, more
//                            transient transfer errors requiring -resume retries.
process SRA_DOWNLOAD {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/sra-tools:3.0.9--h9f5acd7_0"

    input:
    val meta   // [ id: <sample name>, sra_id: <SRR/ERR/DRR accession> ]

    output:
    tuple val(meta), path("*.fastq.gz"), emit: reads
    path 'versions.yml'                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    if (params.download_method == 'aspera') {
        """
        echo "ERROR: --download_method aspera is not yet implemented in this pipeline." >&2
        echo "Use 'sratools' (default) instead." >&2
        exit 1
        """
    } else if (params.download_method == 'ftp') {
        """
        echo "ERROR: --download_method ftp is not yet implemented in this pipeline." >&2
        echo "Use 'sratools' (default) instead." >&2
        exit 1
        """
    } else {
        """
        prefetch ${meta.sra_id} --max-size u

        fasterq-dump \\
            --split-3 \\
            --threads $task.cpus \\
            ${meta.sra_id}

        # --split-3 produces either:
        #   <acc>_1.fastq + <acc>_2.fastq  (paired-end; a leftover <acc>.fastq of
        #                                    unpaired reads may also appear - dropped)
        #   <acc>.fastq                     (single-end)
        if [ -f ${meta.sra_id}_1.fastq ] && [ -f ${meta.sra_id}_2.fastq ]; then
            mv ${meta.sra_id}_1.fastq ${meta.id}_1.fastq
            mv ${meta.sra_id}_2.fastq ${meta.id}_2.fastq
            rm -f ${meta.sra_id}.fastq
        else
            mv ${meta.sra_id}.fastq ${meta.id}.fastq
        fi

        gzip -n ${meta.id}*.fastq

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            sratools: \$(prefetch --version 2>&1 | sed -n 's/.* \\([0-9.]*\\)\$/\\1/p')
        END_VERSIONS
        """
    }

    stub:
    """
    echo "" | gzip > ${meta.id}_1.fastq.gz
    echo "" | gzip > ${meta.id}_2.fastq.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sratools: 3.0.9
    END_VERSIONS
    """
}
