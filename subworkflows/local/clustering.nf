include { R_FASTBAPS                  } from '../../modules/local/r/fastbaps.nf'
include { GUBBINS as RUN_GUBBINS      } from '../../modules/nf-core/gubbins/main.nf'
include { MASK_GUBBINS                } from '../../modules/nf-core/gubbins/main.nf'


workflow CLUSTERING_WF {

    take:
        reads_ch

    main:

        if(enable_fastbaps) {
            //R_FASTBAPS
            //in_run_gubbins_ch =
        } else {
            //in_run_gubbins_ch =
        }

         //RUN_GUBBINS
         //MASK_GUBBINS

//    emit:
//        versions = RUN_GUBBINS.out.versions
}
