include { SNIPPY_CORE                         } from '../../modules/nf-core/snippy/core/main.nf'
include { SNIPPY_RUN                          } from '../../modules/nf-core/snippy/run/main.nf'
include { SNIPPY_CLEAN                        } from '../../modules/local/snippy/snippy_clean.nf'
include { UTILS_VARCODONS                     } from '../../modules/local/utils/varcodons/main.nf'
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

        UTILS_VARCODONS( UTILS_CAT_SAMTOOLS_CONSENSUS.out.fasta, params.ref_genbank )

        //VARCODONS__Optional( SAMTOOLS_CONSENSUS.out.FIXME )



    /*
        //NOTE: Drop the samples from further analysis if the effective size of vcf_report is 0
        //to addresses the negative control

        ch_snipped_samples = SNIPPY_RUN.out.vcf.join(SNIPPY_RUN.out.aligned_fa)

        ch_failed_samples = ch_snipped_samples
                                .filter { m, v, f  -> (v.countLines() <= params.vcf_threshold) }
                                .collect { m,v,f -> [m.id] }
                                .flatten()
                                .collectFile(name: "${params.outdir}/failed_samples.txt", newLine: true)


        // 27 -> No SNP found
        ch_passed_samples = ch_snipped_samples
                                .filter { m, v, f  -> (v.countLines() > params.vcf_threshold) }

        ch_merge_vcf = ch_passed_samples
                            .collect{ meta, vcf, aligned_fa -> vcf }
                            .map{ vcf -> [[id:'cohort_aln'], vcf]}

        ch_merge_aligned_fa = ch_passed_samples
                                .collect{meta, vcf, aligned_fa -> aligned_fa}
                                .map{ aligned_fa -> [[id:'cohort_aln'], aligned_fa]}

        ch_snippy_core = ch_merge_vcf.join( ch_merge_aligned_fa )

        ch_snippy_core.dump(tag: "ch_snippy_core")
    */

        //SNIPPY_CORE( ch_snippy_core, params.fasta )



    emit:
        cleaned_full_aln = UTILS_VARCODONS.out.fasta
        snippy_varcall_txt = SNIPPY_RUN.out.txt
        versions = SNIPPY_RUN.out.versions
}
