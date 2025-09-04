include {
    starAlign as starAlign_P ;
    starAlign2Pass as starAlign2Pass_P
} from '../modules/star.nf'
include { UMI_DEDUP } from './umi_dedup.nf'
include {
    fastq as fastqMapped ;
    fastq as fastqUnmapped ;
    fastq as fastqMultimapped
} from '../modules/samtools.nf'
include {
    SOURMASH as SOURMASH_MAPPED ;
    SOURMASH as SOURMASH_UNMAPPED ;
    SOURMASH as SOURMASH_MULTIMAPPED
} from './sourmash.nf'

workflow STARALIGN {
    take:
    ch_data
    genomeDir
    star_params
    dedup
    dedup_params
    sketch_params
    abund
    compare_K

    main:
    ch_star = starAlign_P(ch_data, genomeDir, star_params, "align")
    if (dedup) {
        ch_dedup = UMI_DEDUP(ch_star.bam, dedup_params, "dedup")
        ch_bam = ch_dedup.bam
        ch_align = ch_star.bam
    }
    else {
        ch_bam = ch_star.bam
        ch_align = []
    }
    // to fastq and sourmash
    ch_fq_mapped = fastqMapped(ch_bam, "mapped")
    ch_sm_mapped = SOURMASH_MAPPED(ch_fq_mapped.fastq, sketch_params, abund, compare_K, "mapped")
    ch_fq_unmapped = fastqUnmapped(ch_star.bam, "unmapped")
    ch_sm_unmapped = SOURMASH_UNMAPPED(ch_fq_unmapped.fastq, sketch_params, abund, compare_K, "unmapped")
    ch_fq_multimapped = fastqMultimapped(ch_star.bam, "multimapped")
    ch_sm_multimapped = SOURMASH_MULTIMAPPED(ch_fq_multimapped.fastq, sketch_params, abund, compare_K, "multimapped")
    // sourmash data
    // ch_signatures = ch_sm_mapped.signatures.merge(ch_sm_unmapped.signatures, ch_sm_multimapped.signatures)
    // ch_comparison = ch_sm_mapped.comparison.merge(ch_sm_unmapped.comparison, ch_sm_multimapped.comparison)
    // ch_plot = ch_sm_mapped.plot.merge(ch_sm_unmapped.plot, ch_sm_multimapped.plot)

    emit:
    bam = ch_bam
    align = ch_align
    stats = ch_star.stats
    junctions = ch_star.junctions
    mapped = ch_fq_mapped.fastq
    unmapped = ch_fq_unmapped.fastq
    multimapped = ch_fq_multimapped.fastq
    // sourmash
    sourmash = ch_sm_mapped.signatures|merge(ch_sm_unmapped.signatures)|merge(ch_sm_multimapped.signatures)|
                    merge(ch_sm_mapped.comparison)|merge(ch_sm_unmapped.comparison)|merge(ch_sm_multimapped.comparison)|
                    merge(ch_sm_mapped.plot)|merge(ch_sm_unmapped.plot)|merge(ch_sm_multimapped.plot)
}

workflow STARALIGN_2PASS {
    take:
    ch_data
    genomeDir
    star_params
    dedup
    dedup_params
    sketch_params
    abund
    compare_K

    main:
    ch_fp = starAlign_P(ch_data, genomeDir, star_params, "firstPass")
    ch_sp = starAlign2Pass_P(ch_data, genomeDir, star_params, ch_fp.junctions.collect(), "secondPass")
    if (dedup) {
        ch_dedup = UMI_DEDUP(ch_sp.bam, dedup_params, "dedup")
        ch_bam = ch_dedup.bam
        ch_align = ch_sp.bam|concat(ch_fp.bam)
    }
    else {
        ch_bam = ch_sp.bam
        ch_align = ch_fp.bam
    }
    // to fastq and sourmash
    ch_fq_mapped = fastqMapped(ch_bam, "mapped")
    ch_sm_mapped = SOURMASH_MAPPED(ch_fq_mapped.fastq, sketch_params, abund, compare_K, "mapped")
    ch_fq_unmapped = fastqUnmapped(ch_sp.bam, "unmapped")
    ch_sm_unmapped = SOURMASH_UNMAPPED(ch_fq_unmapped.fastq, sketch_params, abund, compare_K, "unmapped")
    ch_fq_multimapped = fastqMultimapped(ch_sp.bam, "multimapped")
    ch_sm_multimapped = SOURMASH_MULTIMAPPED(ch_fq_multimapped.fastq, sketch_params, abund, compare_K, "multimapped")
    // sourmash data
    // ch_signatures = ch_sm_mapped.signatures.merge(ch_sm_unmapped.signatures, ch_sm_multimapped.signatures)
    // ch_comparison = ch_sm_mapped.comparison.merge(ch_sm_unmapped.comparison, ch_sm_multimapped.comparison)
    // ch_plot = ch_sm_mapped.plot.merge(ch_sm_unmapped.plot, ch_sm_multimapped.plot)

    emit:
    bam = ch_bam
    align = ch_align
    stats = ch_fp.stats.merge(ch_sp.stats)
    junctions = ch_fp.junctions.merge(ch_sp.junctions)
    mapped = ch_fq_mapped.fastq
    unmapped = ch_fq_unmapped.fastq
    multimapped = ch_fq_multimapped.fastq
    // signatures = ch_signatures
    // comparison = ch_comparison
    // plot = ch_plot
    // sourmash
    // sourmash
    sourmash = ch_sm_mapped.signatures|merge(ch_sm_unmapped.signatures)|merge(ch_sm_multimapped.signatures)|
                    merge(ch_sm_mapped.comparison)|merge(ch_sm_unmapped.comparison)|merge(ch_sm_multimapped.comparison)|
                    merge(ch_sm_mapped.plot)|merge(ch_sm_unmapped.plot)|merge(ch_sm_multimapped.plot)
}
