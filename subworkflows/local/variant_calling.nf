include { SNIPPY_CORE                         } from '../../modules/nf-core/snippy/core/main.nf'
include { SNIPPY_RUN                          } from '../../modules/nf-core/snippy/run/main.nf'
include { SNIPPY_CLEAN                        } from '../../modules/local/snippy/snippy_clean.nf'
include { UTILS_CAT_SAMTOOLS_CONSENSUS        } from '../../modules/local/utils/catsamtoolsconsensus/main.nf'
include { SAMTOOLS_CONSENSUS                  } from '../../modules/nf-core/samtools/consensus/main.nf'


workflow VARIANT_CALLING_WF {

    take:
        reads_ch

    main:

        //NOTE: Must be a gbk
        SNIPPY_RUN(reads_ch, params.ref_genbank)


        SAMTOOLS_CONSENSUS(SNIPPY_RUN.out.bam )


        ch_cat_cat_in = SAMTOOLS_CONSENSUS.out.fasta.collect{ m, f -> f }.map { f -> [[id: 'cat_consensus'], f] }

        UTILS_CAT_SAMTOOLS_CONSENSUS ( ch_cat_cat_in )


    emit:
        concatenated_aln = UTILS_CAT_SAMTOOLS_CONSENSUS.out.fasta
        snippy_varcall_txt = SNIPPY_RUN.out.txt
        versions = SNIPPY_RUN.out.versions
}
