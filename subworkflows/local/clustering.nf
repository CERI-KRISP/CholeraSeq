include { R_FASTBAPS                  } from '../../modules/local/r/fastbaps.nf'
include { SEQKIT_GREP                 } from '../../modules/nf-core/seqkit/grep/main'
include { GUBBINS as RUN_GUBBINS      } from '../../modules/nf-core/gubbins/main.nf'
//include { MASK_GUBBINS                } from '../../modules/nf-core/gubbins/main.nf'


workflow CLUSTERING_WF {

    take:
        clean_full_aln_fasta

    main:

        if(params.enable_fastbaps) {
            R_FASTBAPS( clean_full_aln_fasta )
            //FIXME Implement SEQKIT_GREP
            //in_run_gubbins_ch =
        } else {
            in_run_gubbins_ch = clean_full_aln_fasta
        }

         in_run_gubbins_ch.map { m, f -> f }

         RUN_GUBBINS(in_run_gubbins_ch)
         //MASK_GUBBINS

    //emit:
        //versions = RUN_GUBBINS.out.versions
}
