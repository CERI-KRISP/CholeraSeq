include { R_FASTBAPS                  } from '../../modules/local/r/fastbaps.nf'
include { GUBBINS as RUN_GUBBINS      } from '../../modules/nf-core/gubbins/main.nf'
include { MASK_GUBBINS                } from '../../modules/nf-core/gubbins/main.nf'


workflow CLUSTERING_WF {

    take:
        reads_ch

    main:

        SNIPPY_RUN( reads_ch, params.fasta )

        R_FASTBAPS

         RUN_GUBBINS
         MASK_GUBBINS

    emit:
        versions = SNIPPY_RUN.out.versions
}
