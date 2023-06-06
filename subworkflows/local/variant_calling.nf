include { SNIPPY_CORE    } from '../../modules/nf-core/snippy/core/main.nf'
include { SNIPPY_RUN     } from '../../modules/nf-core/snippy/run/main.nf'


workflow VARIANT_CALLING_WF {

    take:
        reads_ch

    main:


        //NOTE: Later, we could implement the snippy-vcf_report
        //enhancement as per the combined shell script
        SNIPPY_RUN(reads_ch, params.fasta)

        ch_merge_vcf = SNIPPY_RUN.out.vcf.collect{ meta, vcf -> vcf }
                            .map{ vcf -> [[id:'snippy-core'], vcf]}


        ch_merge_aligned_fa = SNIPPY_RUN.out.aligned_fa.collect{meta, aligned_fa -> aligned_fa}
                            .map{ aligned_fa -> [[id:'snippy-core'], aligned_fa]}

        ch_snippy_core = ch_merge_vcf.join( ch_merge_aligned_fa )

        SNIPPY_CORE( ch_snippy_core, params.fasta )

    emit:
        versions = SNIPPY_RUN.out.versions
}
