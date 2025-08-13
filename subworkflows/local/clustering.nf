include { R_FASTBAPS                  } from '../../modules/local/r/fastbaps.nf'
include { PYTHON_SEQ_CLEANER          } from '../../modules/local/python/seq_cleaner.nf'
include { SEQKIT_GREP                 } from '../../modules/nf-core/seqkit/grep/main'
include { GUBBINS as RUN_GUBBINS      } from '../../modules/nf-core/gubbins/main.nf'
include { MASK_GUBBINS                } from '../../modules/local/gubbins/mask.nf'
include { PYTHON_SPLIT_CLUSTERS       } from '../../modules/local/clojure/split_clusters.nf'
include { IQTREE                      } from '../../modules/nf-core/iqtree/main'
include { CAT_CAT                     } from '../../modules/nf-core/cat/cat/main.nf'
include { UTILS_VARCODONS                     } from '../../modules/local/utils/varcodons/main.nf'

workflow CLUSTERING_WF {

    take:
        clean_full_aln_fasta

    main:


        PYTHON_SEQ_CLEANER ( clean_full_aln_fasta )

        if(params.enable_fastbaps || !params.skip_fastbaps) {

            R_FASTBAPS( PYTHON_SEQ_CLEANER.out.cleaned_fasta )

            PYTHON_SPLIT_CLUSTERS( R_FASTBAPS.out.classification )

            SEQKIT_GREP( PYTHON_SPLIT_CLUSTERS.out.clusters.flatten().map{ it -> [["id": it.baseName], it]},
                         clean_full_aln_fasta.map { m,f -> f}.collect())

            in_run_gubbins_ch = SEQKIT_GREP.out.fasta

        } else {

            in_run_gubbins_ch = clean_full_aln_fasta

        }

         RUN_GUBBINS( PYTHON_SEQ_CLEANER.out.cleaned_fasta )

         MASK_GUBBINS( RUN_GUBBINS.out.fasta_gff )


         //MASK_GUBBINS.out.masked_fasta. Also use the -r to generate and output
        //a report for users for information (-a)

        ch_all_masked_fastas = MASK_GUBBINS.out.masked_fasta
                            .map{m, f -> f}
                            .collect().map{v -> [[id: 'concatenated_masked_fastas'], v]}

        CAT_CAT(ch_all_masked_fastas)

        UTILS_VARCODONS( CAT_CAT.out.file_out, params.ref_genbank )


        //VARCODONS__Optional( SAMTOOLS_CONSENSUS.out.FIXME )

        //TODO: Check the overall functionality
         in_iqtree = PYTHON_SEQ_CLEANER.out.cleaned_fasta.map {m -> [m[0], m[1], []]}

         IQTREE(in_iqtree, [], [], [], [], [], [], [], [], [], [], [], [] )

    emit:
        versions = RUN_GUBBINS.out.versions //TODO:
}
