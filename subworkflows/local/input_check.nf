//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'
include { SRA_DOWNLOAD      } from '../../modules/local/sra_download/main.nf'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    ch_versions = Channel.empty()

    parsed_rows_ch = SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .branch {
            // NOTE: sra_id rows can't go through create_fastq_channel - the fastq
            // files don't exist locally yet, they need an actual download process
            // first (SRA_DOWNLOAD below). check_samplesheet.py already enforces
            // that a row populates sra_id XOR fastq_1, so this split is unambiguous.
            sra:  it.sra_id?.trim()
            file: !it.sra_id?.trim()
        }

    //
    // Local-file rows: unchanged existing behaviour
    //
    file_reads_ch = parsed_rows_ch.file
        .map { create_fastq_channel(it) }

    //
    // sra_id rows: download first, then determine single/paired-end from what
    // was actually produced (unknown ahead of time, unlike local-file rows
    // where it's given explicitly in the samplesheet)
    //
    SRA_DOWNLOAD (
        parsed_rows_ch.sra.map { row -> [ id: row.sample, sra_id: row.sra_id.trim(), platform: row.platform ?: 'illumina' ] }
    )
    ch_versions = ch_versions.mix(SRA_DOWNLOAD.out.versions)

    sra_reads_ch = SRA_DOWNLOAD.out.reads
        .map { meta, reads ->
            def reads_list = reads instanceof List ? reads : [ reads ]
            def full_meta  = meta + [ single_end: reads_list.size() == 1, is_contig: false ]
            [ full_meta, reads_list ]
        }

    reads = file_reads_ch.mix(sra_reads_ch)

    emit:
    reads                                     // channel: [ val(meta), [ reads ] ]
    versions = SAMPLESHEET_CHECK.out.versions.mix(ch_versions) // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_fastq_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.sample
    meta.single_end = row.single_end.toBoolean()
    meta.is_contig  = check_is_contig(row.fastq_1)
    meta.platform   = row.platform ?: 'illumina'

    // add path(s) of the fastq file(s) to the meta map
    // NOTE: file(...).exists() is only checked for local paths. For remote URLs
    // (ftp/http/https/s3/etc), Nextflow's file() provider performs a real network
    // request under .exists() (a HEAD-style check) - this is unreliable for some
    // servers/protocols (observed: an https:// EBI URL took ~99s then falsely
    // reported as missing, despite being genuinely stageable). Remote paths are
    // still validated for real when Nextflow actually stages them, which is a
    // more reliable failure point anyway.
    def fastq_meta = []
    if (!is_remote_path(row.fastq_1) && !file(row.fastq_1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 file does not exist!\n${row.fastq_1}"
    }
    if (meta.single_end) {
        fastq_meta = [ meta, [ file(row.fastq_1) ] ]
    } else {
        if (!is_remote_path(row.fastq_2) && !file(row.fastq_2).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Read 2 file does not exist!\n${row.fastq_2}"
        }
        fastq_meta = [ meta, [ file(row.fastq_1), file(row.fastq_2) ] ]
    }
    return fastq_meta
}

// True for any path that looks like a remote URL (ftp://, http://, https://, s3://, etc.)
// rather than a local filesystem path.
def is_remote_path(path) {
    return path ==~ /^\w+:\/\/.*/
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def check_is_contig(fastq_1) {
    // Strip a trailing .gz first, so gzipped assemblies (e.g. NCBI's
    // <acc>_genomic.fna.gz) are recognised as assemblies rather than misread
    // as fastq. reads.fastq.gz still resolves to 'fastq' after the strip.
    def name = fastq_1.endsWith(".gz") ? fastq_1.substring(0, fastq_1.length() - 3) : fastq_1
    def lastExtension = name.split("\\.")[-1]
    def is_valid = (lastExtension == "fasta" || lastExtension == "fna" || lastExtension == "fa" )

    return is_valid
}
