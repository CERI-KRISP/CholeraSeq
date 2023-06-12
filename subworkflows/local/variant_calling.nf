include { SNIPPY_CORE    } from '../../modules/nf-core/snippy/core/main.nf'
include { SNIPPY_RUN     } from '../../modules/nf-core/snippy/run/main.nf'


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
                                .map {
                                    m,v,f -> [[id: "snippy-core"], v, f ]
                                }
                                .collect()
                                .view()

        //SNIPPY_CORE( ch_snippy_core, params.fasta )


    emit:
        versions = SNIPPY_RUN.out.versions
}
