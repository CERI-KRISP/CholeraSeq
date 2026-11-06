// One MLST table for the whole run: sample, scheme, sequence type (ST) and the
// allele calls. mlst writes one line per sample (FILE, SCHEME, ST, then one column
// per locus); the allele calls are joined into one column so every row has the
// same number of columns whatever the scheme.
process MLST_SUMMARY {
    label 'process_single'

    container "quay.io/biocontainers/mlst:2.25.0--hdfd78af_0"

    input:
    path tsvs, stageAs: 'mlst/*'

    output:
    path "mlst_summary.tsv", emit: summary
    path 'versions.yml'    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    printf "sample\\tscheme\\tST\\talleles\\n" > mlst_summary.tsv
    for f in \$(ls mlst/*.tsv | sort); do
        s=\$(basename "\$f" .tsv)
        awk -F'\\t' -v OFS='\\t' -v s="\$s" 'NF >= 3 { a = \$4; for (i = 5; i <= NF; i++) a = a " " \$i; print s, \$2, \$3, a }' "\$f" >> mlst_summary.tsv
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mlst: \$(mlst --version 2>&1 | sed 's/mlst //')
    END_VERSIONS
    """

    stub:
    """
    printf "sample\\tscheme\\tST\\talleles\\n" > mlst_summary.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mlst: 2.25.0
    END_VERSIONS
    """
}
