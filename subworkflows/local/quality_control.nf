include { FASTP   } from '../../modules/nf-core/fastp/main'
include { FASTQC  } from '../../modules/nf-core/fastqc/main'


workflow QUALITY_CONTROL_WF {

    take:
        reads_ch

    main:

        FASTQC(reads_ch)

        ch_fastp_in = reads_ch.map { meta, files -> [meta, files, []] }

        FASTP(ch_fastp_in, [], false, false)

    emit:
        trimmed_reads = FASTP.out.reads
        fastp_json = FASTP.out.json
        fastqc_zip = FASTQC.out.zip
        //FIXME add the FASTP version as well
        versions = FASTQC.out.versions.first()
}
