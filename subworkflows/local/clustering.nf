include { R_FASTBAPS                  } from '../../modules/local/r/fastbaps.nf'
include { PYTHON_SEQ_CLEANER          } from '../../modules/local/python/seq_cleaner.nf'
include { SEQKIT_GREP                 } from '../../modules/nf-core/seqkit/grep/main'
include { GUBBINS as RUN_GUBBINS      } from '../../modules/nf-core/gubbins/main.nf'
include { MASK_GUBBINS                } from '../../modules/local/gubbins/mask.nf'
include { CLJ_SPLIT_CLUSTERS          } from '../../modules/local/clojure/split_clusters.nf'
include { IQTREE                      } from '../../modules/nf-core/iqtree/main'

workflow CLUSTERING_WF {

    take:
        clean_full_aln_fasta

    main:
        if(params.enable_fastbaps || !params.skip_fastbaps) {

            R_FASTBAPS( clean_full_aln_fasta )

            CLJ_SPLIT_CLUSTERS( R_FASTBAPS.out.classification )

            SEQKIT_GREP( CLJ_SPLIT_CLUSTERS.out.clusters.flatten().map{ it -> [["id": it.baseName], it]},
                         clean_full_aln_fasta.map { m,f -> f}.collect())

            in_run_gubbins_ch = SEQKIT_GREP.out.fasta

        } else {

            in_run_gubbins_ch = clean_full_aln_fasta

        }

         RUN_GUBBINS( in_run_gubbins_ch )

         MASK_GUBBINS( RUN_GUBBINS.out.fasta_gff )


         //VARIANT_CODON_ALIGNMENT using varcodons and GBK reference
         //MASK_GUBBINS.out.masked_fasta. Also use the -r to generate and output
        //a report for users for information (-a)

        SAMTOOLS_CONSENSUS( )

        //TODO: MASK_GUBBINS output should be concatenated

         PYTHON_SEQ_CLEANER ( MASK_GUBBINS.out.masked_fasta )

        //TODO: Check the overall functionality
         in_iqtree = PYTHON_SEQ_CLEANER.out.cleaned_fasta.map {m -> [m[0], m[1], []]}

         IQTREE(in_iqtree, [], [], [], [], [], [], [], [], [], [], [], [] )

    emit:
        versions = RUN_GUBBINS.out.versions //TODO:
}
