include { R_FASTBAPS                  } from '../../modules/local/r/fastbaps.nf'
include { PYTHON_SEQ_CLEANER          } from '../../modules/local/python/seq_cleaner.nf'
include { CAT_CAT                     } from '../../modules/nf-core/cat/cat/main.nf'
include { SEQKIT_GREP                 } from '../../modules/nf-core/seqkit/grep/main'
include { GUBBINS as RUN_GUBBINS      } from '../../modules/nf-core/gubbins/main.nf'
include { MASK_GUBBINS                } from '../../modules/local/gubbins/mask.nf'
include { CLJ_SPLIT_CLUSTERS          } from '../../modules/local/clojure/split_clusters.nf'
include { IQTREE } from '../modules/nf-core/iqtree/main'


workflow PATCH_CORE_ALIGNMENT_WF {

    take:
        global_core_alignment
        cohort_core_alignment

    main:

        in_cat_cat = Channel.of([[id: 'patch_core_aln'], [global_core_alignment, cohort_core_alignment]])

        CAT_CAT(in_cat_cat)

        PYTHON_SEQ_CLEANER ( CAT_CAT.out.file_out )

        ch_cat_core_alignment = PYTHON_SEQ_CLEANER.out.cleaned_fasta

        if(params.enable_fastbaps) {

            R_FASTBAPS( ch_cat_core_alignment )

            CLJ_SPLIT_CLUSTERS( R_FASTBAPS.out.classification )

            SEQKIT_GREP( CLJ_SPLIT_CLUSTERS.out.clusters.flatten().map{ it -> [["id": it.baseName], it]},
                         ch_cat_core_alignment.map { m,f -> f}.collect())

            in_run_gubbins_ch = SEQKIT_GREP.out.fasta

        } else {

            in_run_gubbins_ch = ch_cat_core_alignment

        }

         RUN_GUBBINS( in_run_gubbins_ch )
         MASK_GUBBINS( RUN_GUBBINS.out.fasta_gff )

    emit:
        versions = RUN_GUBBINS.out.versions
}
