include { R_FASTBAPS                  } from '../../modules/local/r/fastbaps.nf'
include { PYTHON_SEQ_CLEANER          } from '../../modules/local/python/seq_cleaner.nf'
include { SEQKIT_GREP                 } from '../../modules/nf-core/seqkit/grep/main'
include { GUBBINS as RUN_GUBBINS      } from '../../modules/nf-core/gubbins/main.nf'
include { MASK_GUBBINS                } from '../../modules/local/gubbins/mask.nf'
include { CLJ_SPLIT_CLUSTERS          } from '../../modules/local/clojure/split_clusters.nf'


workflow PATCH_CORE_ALIGNMENT_WF {

    take:
        existing_core_alignment

    main:

        if(params.enable_fastbaps) {

            R_FASTBAPS( existing_core_alignment )

            CLJ_SPLIT_CLUSTERS( R_FASTBAPS.out.classification )

            SEQKIT_GREP( CLJ_SPLIT_CLUSTERS.out.clusters.flatten().map{ it -> [["id": it.baseName], it]},
                         existing_core_alignment.map { m,f -> f}.collect())

            in_run_gubbins_ch = SEQKIT_GREP.out.fasta.map { m,f -> f}

        } else {

            in_run_gubbins_ch = existing_core_alignment.map { m,f -> f}

        }

         RUN_GUBBINS( in_run_gubbins_ch )
         MASK_GUBBINS( RUN_GUBBINS.out.fasta_gff )

    emit:
        versions = RUN_GUBBINS.out.versions
}
