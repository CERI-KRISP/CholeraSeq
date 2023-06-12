include { SNIPPY_CORE         } from '../../modules/nf-core/snippy/core/main.nf'
include { SNIPPY_RUN          } from '../../modules/nf-core/snippy/run/main.nf'
include { SNIPPY_AND_SNPSITES } from '../../modules/local/mulled/snippy_and_snpsites.nf'


workflow VARIANT_CALLING_WF {

    take:
        reads_ch

    main:

        SNIPPY_RUN(reads_ch, params.fasta)

        //NOTE: Drop the samples from further analysis if the effective size of vcf_report is 0
        //to addresses the negative control
        ch_passed_samples = SNIPPY_RUN.out.vcf
                                .join(SNIPPY_RUN.out.aligned_fa)
                                .filter { m, v, f  -> (v.countLines() > 27) }

        ch_merge_vcf = ch_passed_samples
                            .collect{ meta, vcf, aligned_fa -> vcf }
                            .map{ vcf -> [[id:'snippy-core'], vcf]}

        ch_merge_aligned_fa = ch_passed_samples
                                .collect{meta, vcf, aligned_fa -> aligned_fa}
                                .map{ aligned_fa -> [[id:'snippy-core'], aligned_fa]}

        ch_snippy_core = ch_merge_vcf.join( ch_merge_aligned_fa )

        ch_snippy_core.dump(tag: "ch_snippy_core")

        SNIPPY_CORE( ch_snippy_core, params.fasta )

        SNIPPY_AND_SNPSITES( SNIPPY_CORE.out.full_aln )

    emit:
        versions = SNIPPY_RUN.out.versions
}
