include { SNIPPY_CORE    } from '../../modules/nf-core/snippy/core/main.nf'
include { SNIPPY_RUN     } from '../../modules/nf-core/snippy/run/main.nf'


workflow VARIANT_CALLING_WF {

    take:
        reads_ch

    main:


        SNIPPY_RUN(reads_ch, params.fasta)


        //TODO: Drop the samples from further analysis if the vcf_report is 0.
        //Addresses the negative control

/*
        list_failed_sample_ids =  SNIPPY_RUN.out.vcf
                                    .filter { m, f  -> f.countLines() <= 27 }
                                    .map { m, f -> m.id }
                                    .toList()
                                    .view()
*/

        SNIPPY_RUN.out.vcf
            .join(SNIPPY_RUN.out.aligned_fa)
            .filter { m, v, f  -> (v.countLines() > 27) }
            .filter { m, v, f  -> !(v.countLines() <= 27) }
            .branch {
                vcf: ( it.getExtension() == "vcf" )
                aligned_fa: ( it.getExtension() == "fa" )
            }
            .set { result }

         result.vcf.view()
         result.aligned_fa.view()

/*
        ch_merge_vcf = SNIPPY_RUN.out.vcf
                            .collect{ meta, vcf -> vcf }
                            .map{ vcf -> [[id:'snippy-core'], vcf]}

        ch_merge_aligned_fa = SNIPPY_RUN.out.aligned_fa
                                .collect{meta, aligned_fa -> aligned_fa}
                                .map{ aligned_fa -> [[id:'snippy-core'], aligned_fa]}

        ch_snippy_core = ch_merge_vcf.join( ch_merge_aligned_fa )

        //ch_snippy_core.view()

        //SNIPPY_CORE( ch_snippy_core, params.fasta )
*/
    emit:
        versions = SNIPPY_RUN.out.versions
}
