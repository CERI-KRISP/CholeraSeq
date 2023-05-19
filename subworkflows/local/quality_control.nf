include { FASTP   } from '../../modules/nf-core/fastp/main'
include { FASTQC  } from '../../modules/nf-core/fastqc/main'


workflow QUALITY_CONTROL_WF {

    take:
        reads_ch

    main:

        FASTQC(reads_ch)

        FASTP(reads_ch, [], false, false)

    emit:
        versions = FASTQC.out.versions.first()
}
