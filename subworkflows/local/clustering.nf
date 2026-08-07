include { R_FASTBAPS                  } from '../../modules/local/r/fastbaps.nf'
include { PYTHON_SEQ_CLEANER          } from '../../modules/local/python/seq_cleaner.nf'
include { SEQKIT_GREP                 } from '../../modules/nf-core/seqkit/grep/main'
include { GUBBINS as RUN_GUBBINS      } from '../../modules/nf-core/gubbins/main.nf'
include { MASK_GUBBINS                } from '../../modules/local/gubbins/mask.nf'
include { PYTHON_SPLIT_CLUSTERS       } from '../../modules/local/clojure/split_clusters.nf'
include { IQTREE                      } from '../../modules/nf-core/iqtree/main'
include { CAT_CAT                     } from '../../modules/nf-core/cat/cat/main.nf'
include { UTILS_VARCODONS             } from '../../modules/local/utils/varcodons/main.nf'
include { UTILS_VARCODONS as UTILS_VARCODONS__REPORT             } from '../../modules/local/utils/varcodons/main.nf'

workflow CLUSTERING_WF {

    take:
        clean_full_aln_fasta

    main:


        PYTHON_SEQ_CLEANER ( clean_full_aln_fasta )

        if( !params.skip_fastbaps) {

            R_FASTBAPS( PYTHON_SEQ_CLEANER.out.cleaned_fasta )

            PYTHON_SPLIT_CLUSTERS( R_FASTBAPS.out.classification )

            SEQKIT_GREP( PYTHON_SPLIT_CLUSTERS.out.clusters.flatten().map{ it -> [["id": it.baseName], it]},
                         clean_full_aln_fasta.map { m,f -> f}.collect())

            in_run_gubbins_ch = SEQKIT_GREP.out.fasta

        } else {

            in_run_gubbins_ch = clean_full_aln_fasta

        }

        // NOTE: previously this called RUN_GUBBINS( PYTHON_SEQ_CLEANER.out.cleaned_fasta )
        // unconditionally, silently ignoring in_run_gubbins_ch computed above - meaning
        // Gubbins always ran on the whole alignment even when FastBAPS clustering was
        // enabled (--skip_fastbaps false). Fixed to actually consume in_run_gubbins_ch:
        // when FastBAPS splitting is on, that channel carries one [meta, fasta] tuple per
        // cluster, so GUBBINS (and MASK_GUBBINS right after it) now scatter automatically
        // and run once per cluster in parallel, instead of once on the full alignment.
        //
        // With scattering now actually happening, small FastBAPS clusters can contain too
        // few sequences for RAxML to build a tree from at all (Gubbins fails with
        // "TOO FEW SPECIES"). Filter those out before RUN_GUBBINS rather than let the
        // process crash - clusters below params.min_partition_size are skipped and logged,
        // not silently dropped.
        in_run_gubbins_ch
            .branch { meta, fasta ->
                def n_seqs = fasta.text.count('>')
                keep: n_seqs >= params.min_partition_size
                skip: true
            }
            .set { gubbins_input_ch }

        gubbins_input_ch.skip.subscribe { meta, fasta ->
            log.warn "Skipping Gubbins for '${meta.id}': fewer than params.min_partition_size (${params.min_partition_size}) sequences - too small for RAxML to build a tree."
        }

        RUN_GUBBINS( gubbins_input_ch.keep )

         MASK_GUBBINS( RUN_GUBBINS.out.fasta_gff )


         //MASK_GUBBINS.out.masked_fasta. Also use the -r to generate and output
        //a report for users for information (-a)

        ch_all_masked_fastas = MASK_GUBBINS.out.masked_fasta
                            .map{m, f -> f}
                            .collect().map{v -> [[id: 'concatenated_masked_fastas'], v]}

        CAT_CAT(ch_all_masked_fastas)

        UTILS_VARCODONS( CAT_CAT.out.file_out, params.ref_genbank )

        in_iqtree = UTILS_VARCODONS.out.fasta.map {m -> [m[0], m[1], []]}

        IQTREE(in_iqtree, [], [], [], [], [], [], [], [], [], [], [], [] )

        //Run only with gbk reference -- produces complimentary output for the user.
        UTILS_VARCODONS__REPORT( CAT_CAT.out.file_out, params.ref_genbank )


    emit:
        versions = RUN_GUBBINS.out.versions //TODO:
}
