include { SNIPPY_RUN   } from '../../modules/nf-core/snippy/run/main.nf'


workflow VARIANT_CALLING_WF {

    take:
        reads_ch

    main:

        SNIPPY_RUN(reads_ch, [], false, false)

    emit:
        versions = SNIPPY_RUN.out.versions
}
