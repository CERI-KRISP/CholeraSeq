// Run-wide ABRicate tables, one pair per database. The database names are read from
// the report file names (<sample>.<db>.txt, written by ABRICATE_RUN), so this step
// always matches whatever --abricate_dbs was used.
process ABRICATE_SUMMARY {
    label 'process_single'

    container "quay.io/biocontainers/abricate:1.0.1--ha8f3691_1"

    input:
    path reports, stageAs: 'reports/*'

    output:
    path "abricate_summary_*.tsv", emit: summary
    path "abricate_hits_*.tsv"   , emit: hits
    path 'versions.yml'          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    for db in \$(ls reports/*.txt | sed -E 's/.*\\.([^.]+)\\.txt\$/\\1/' | sort -u); do
        files=\$(ls reports/*.\${db}.txt | sort)
        # Gene-by-sample table: one row per sample, one column per gene; each cell is
        # the % coverage of that gene ('.' = not found). Sample names replace file paths.
        abricate --summary \$files \\
            | sed -E "1 s/^#FILE/sample/; 1! s#^reports/(.*)\\.\${db}\\.txt#\\1#" \\
            > abricate_summary_\${db}.tsv
        # Every hit from every sample in one table, with a single header line
        { head -n 1 \$(echo "\$files" | head -n 1); for f in \$files; do tail -n +2 "\$f"; done; } \\
            > abricate_hits_\${db}.tsv
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \$(abricate --version | sed 's/^.* //')
    END_VERSIONS
    """

    stub:
    """
    touch abricate_summary_ncbi.tsv abricate_hits_ncbi.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: 1.0.1
    END_VERSIONS
    """
}
