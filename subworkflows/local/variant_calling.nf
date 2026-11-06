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


        //
        // Exclude samples with no consensus sequence before the gather step. A
        // sample that aligns to nothing - e.g. a genome of a different organism,
        // such as the influenza assemblies that surfaced this - yields an empty
        // consensus file. UTILS_CAT_SAMTOOLS_CONSENSUS runs `grep -v '^>'` under
        // `bash -e`, and grep exits 1 when it selects no lines, so ONE such
        // sample used to abort the concatenation (and with it the whole
        // alignment) for every other sample, with no error message. Here each
        // excluded sample is named in a warning, and the run only stops if NO
        // sample produced a sequence (nothing left to align).
        //
        // A consensus must also be the reference's FULL length. The reference has
        // one record per chromosome (two for V. cholerae) and `samtools consensus`
        // emits a record only for references that have aligned reads, so a sample
        // with reads on chromosome 1 but none on chromosome 2 gives a one-record
        // consensus that is a whole chromosome short (observed: 7 samples at
        // 2,975,504 bp among 172 at 4,047,835 bp, the gap being exactly the size of
        // chromosome 2). The gather step joins records into one sequence per sample,
        // so such a sample would put sequences of different lengths into the
        // alignment and Gubbins aborts: "Each sequence must be the same length".
        // Expected length = sum of the LOCUS lengths in the reference GenBank file.
        def ref_length = file(params.ref_genbank).readLines()
            .findResults { line ->
                def m = line =~ /^LOCUS\s+\S+\s+(\d+)\s+bp/
                m ? (m[0][1] as long) : null
            }
            .sum() ?: 0L

        if (ref_length == 0) {
            log.warn "Could not read the reference length from ${params.ref_genbank} (no 'LOCUS ... N bp' lines) - consensus sequences are only checked for being non-empty, not for full length"
        }

        SAMTOOLS_CONSENSUS.out.fasta
            .branch { _meta, fasta ->
                def seq_len = consensus_length(fasta)
                empty:         seq_len == 0
                with_sequence: ref_length == 0 || seq_len == ref_length
                partial:       true
            }
            .set { consensus_ch }

        consensus_ch.empty.subscribe { meta, _fasta ->
            log.warn "Sample '${meta.id}' produced no consensus sequence against the reference (is it a different organism?) - excluded from the core alignment"
        }

        consensus_ch.partial.subscribe { meta, fasta ->
            log.warn "Sample '${meta.id}' has a consensus of ${consensus_length(fasta)} bp but the reference is ${ref_length} bp - it did not align to the whole reference (e.g. no reads on one chromosome; possibly a different organism or very low coverage) - excluded from the core alignment so every sequence keeps the same length"
        }

        // Stop with a clear message only if consensus sequences WERE produced but none passed
        // the checks above. If nothing reached this step at all (an earlier step failed), stay
        // silent: that earlier error is the real one, and this message would only mislead.
        consensus_ch.with_sequence.count()
            .combine( SAMTOOLS_CONSENSUS.out.fasta.count() )
            .subscribe { n_kept, n_total ->
                if (n_total > 0 && n_kept == 0) {
                    error "No sample produced a full-length consensus sequence against the reference - nothing to align. Check that the samples match the reference genome (--ref_genbank)."
                }
            }

        ch_cat_cat_in = consensus_ch.with_sequence
            .collect{ _m, f -> f }
            .map { f -> [[id: 'cat_consensus'], f] }

        UTILS_CAT_SAMTOOLS_CONSENSUS ( ch_cat_cat_in )


    emit:
        concatenated_aln = UTILS_CAT_SAMTOOLS_CONSENSUS.out.fasta
        snippy_varcall_txt = SNIPPY_RUN.out.txt
        versions = SNIPPY_RUN.out.versions
}

// Number of sequence characters in a (possibly multi-record) fasta file, ignoring headers.
def consensus_length(fasta) {
    return fasta.readLines().inject(0L) { acc, line -> line.startsWith('>') ? acc : acc + line.trim().length() }
}
