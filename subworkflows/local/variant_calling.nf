include { SNIPPY_CORE         } from '../../modules/nf-core/snippy/core/main.nf'
include { SNIPPY_RUN          } from '../../modules/nf-core/snippy/run/main.nf'
include { SNIPPY_CLEAN        } from '../../modules/local/snippy/snippy_clean.nf'
include { SAMTOOLS_CONSENSUS  } from '../../modules/nf-core/samtools/consensus/main.nf'


workflow VARIANT_CALLING_WF {

    take:
        reads_ch

    main:

        SNIPPY_RUN(reads_ch, params.fasta) //NOTE: Either fasta or gbk

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

        SNIPPY_CORE( ch_snippy_core, params.fasta )


        //SAMTOOLS_CONSENSUS(SNIPPY_CORE.out.bam )

        //TODO: Concatenate the aligned fasta files
        //UTILS_CAT_CONSENSUS ( SAMTOOLS_CONSENSUS.out.consensus_fasta.collect{ m, f -> [m, f] })

        //VARCODONS__Optional( SAMTOOLS_CONSENSUS.out.FIXME )

        //VARCODONS( SAMTOOLS_CONSENSUS.out.fasta )

    emit:
        cleaned_full_aln = SNIPPY_CLEAN.out.cleaned_full_aln
        snippy_varcall_txt = SNIPPY_RUN.out.txt
        versions = SNIPPY_RUN.out.versions
}
