include {
    starAlign as starAlign_P ;
    starAlign2Pass as starAlign2Pass_P
} from '../modules/star.nf'
include { UMI_DEDUP } from './umi_dedup.nf'
include {
    fastq as fastqMapped ;
    fastq as fastqUnmapped ;
    fastq as fastqMultimapped ;
    fastq as fastqDedup
} from '../modules/samtools.nf'
include {
    SOURMASH as SOURMASH_MAPPED ;
    SOURMASH as SOURMASH_UNMAPPED ;
    SOURMASH as SOURMASH_MULTIMAPPED ;
    SOURMASH as SOURMASH_DEDUP
} from './sourmash.nf'

include {
    align_stats_STAR as stats_aln;
    align_stats_STAR as stats_sp_aln;
    align_stats_STAR as stats_dedup;
    align_stats_STAR as stats_sp_dedup
} from '../modules/stats.nf'


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
    // alignment stats for aligned reads
    ch_read_aln_stats = stats_aln(ch_star.bam, "align")
    if (dedup) {
        ch_dedup = UMI_DEDUP(ch_star.bam, dedup_params, "dedup")
        ch_bam = ch_dedup.bam
        ch_align = ch_star.bam
        // alignment stats for deduplicated reads
        ch_read_aln_stats = ch_read_aln_stats.concat(stats_dedup(ch_dedup.bam, "dedup"))
        // mapped reads
        ch_fq_map = fastqMapped(ch_star.bam, "mapped")
        ch_sm_map = SOURMASH_MAPPED(ch_fq_map.fastq, sketch_params, abund, compare_K, "mapped")
        // dedup reads
        ch_fq_dedup = fastqDedup(ch_dedup.bam, "dedup")
        ch_sm_dedup = SOURMASH_DEDUP(ch_fq_dedup.fastq, sketch_params, abund, compare_K, "dedup")
        // merge mapped and dedup
        // @TODO: find an elegant solution
        ch_fq_mapped = ch_fq_map.fastq|concat(ch_fq_dedup.fastq)|multiMap{fq -> fastq:fq}
        ch_sm_sigs = ch_sm_map.signatures|concat(ch_sm_dedup.signatures)
        ch_sm_comp = ch_sm_map.comparison|concat(ch_sm_dedup.comparison)
        ch_sm_plot = ch_sm_map.plot|concat(ch_sm_dedup.plot)
    }
    else {
        ch_bam = ch_star.bam
        ch_align = [] // @TODO: find an elegant solution
        // to fastq and sourmash for mapped
        ch_fq_mapped = fastqMapped(ch_star.bam, "mapped")
        ch_sm_mapped = SOURMASH_MAPPED(ch_fq_mapped.fastq, sketch_params, abund, compare_K, "mapped")
        ch_sm_sigs = ch_sm_mapped.signatures
        ch_sm_comp = ch_sm_mapped.comparison
        ch_sm_plot = ch_sm_mapped.plot
    }
    // to fastq and sourmash for unmapped and multimapped
    ch_fq_unmapped = fastqUnmapped(ch_star.bam, "unmapped")
    ch_sm_unmapped = SOURMASH_UNMAPPED(ch_fq_unmapped.fastq, sketch_params, abund, compare_K, "unmapped")
    ch_fq_multimapped = fastqMultimapped(ch_star.bam, "multimapped")
    ch_sm_multimapped = SOURMASH_MULTIMAPPED(ch_fq_multimapped.fastq, sketch_params, abund, compare_K, "multimapped")

    emit:
    bam = ch_bam
    align = ch_align
    stats = ch_star.stats
    read_stats = ch_read_aln_stats
    junctions = ch_star.junctions
    mapped = ch_fq_mapped.fastq
    unmapped = ch_fq_unmapped.fastq
    multimapped = ch_fq_multimapped.fastq
    // sourmash
    sourmash = ch_sm_sigs|concat(ch_sm_unmapped.signatures)|concat(ch_sm_multimapped.signatures)|
                    concat(ch_sm_comp)|concat(ch_sm_unmapped.comparison)|concat(ch_sm_multimapped.comparison)|
                    concat(ch_sm_plot)|concat(ch_sm_unmapped.plot)|concat(ch_sm_multimapped.plot)
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
    // alignment stats for aligned reads after second pass
    ch_read_aln_stats = stats_sp_aln(ch_sp.bam, "align")
    if (dedup) {
        ch_dedup = UMI_DEDUP(ch_sp.bam, dedup_params, "dedup")
        ch_bam = ch_dedup.bam
        ch_align = ch_sp.bam|concat(ch_fp.bam)
        // alignment stats for deduplicated reads after second pass
        ch_read_aln_stats = ch_read_aln_stats.concat(stats_sp_dedup(ch_dedup.bam, "dedup"))
        // mapped reads
        ch_fq_map = fastqMapped(ch_sp.bam, "mapped")
        ch_sm_map = SOURMASH_MAPPED(ch_fq_map.fastq, sketch_params, abund, compare_K, "mapped")
        // dedup reads
        ch_fq_dedup = fastqDedup(ch_dedup.bam, "dedup")
        ch_sm_dedup = SOURMASH_DEDUP(ch_fq_dedup.fastq, sketch_params, abund, compare_K, "dedup")
        // merge mapped and dedup fastqs
        ch_fq_mapped = ch_fq_map.fastq|concat(ch_fq_dedup.fastq)|multiMap{fq -> fastq:fq}
        // merge mapped and dedup sourmash
        ch_sm_sigs = ch_sm_map.signatures|concat(ch_sm_dedup.signatures)
        ch_sm_comp = ch_sm_map.comparison|concat(ch_sm_dedup.comparison)
        ch_sm_plot = ch_sm_map.plot|concat(ch_sm_dedup.plot)
        
    }
    else {
        ch_bam = ch_sp.bam
        ch_align = ch_fp.bam
        // to fastq and sourmash for mapped
        ch_fq_mapped = fastqMapped(ch_sp.bam, "mapped")
        ch_sm_mapped = SOURMASH_MAPPED(ch_fq_mapped.fastq, sketch_params, abund, compare_K, "mapped")
        ch_sm_sigs = ch_sm_mapped.signatures
        ch_sm_comp = ch_sm_mapped.comparison
        ch_sm_plot = ch_sm_mapped.plot
    }
    // to fastq and sourmash
    ch_fq_unmapped = fastqUnmapped(ch_sp.bam, "unmapped")
    ch_sm_unmapped = SOURMASH_UNMAPPED(ch_fq_unmapped.fastq, sketch_params, abund, compare_K, "unmapped")
    ch_fq_multimapped = fastqMultimapped(ch_sp.bam, "multimapped")
    ch_sm_multimapped = SOURMASH_MULTIMAPPED(ch_fq_multimapped.fastq, sketch_params, abund, compare_K, "multimapped")

    emit:
    bam = ch_bam
    align = ch_align
    stats = ch_fp.stats.merge(ch_sp.stats)
    read_stats = ch_read_aln_stats
    junctions = ch_fp.junctions.merge(ch_sp.junctions)
    mapped = ch_fq_mapped.fastq
    unmapped = ch_fq_unmapped.fastq
    multimapped = ch_fq_multimapped.fastq
    sourmash = ch_sm_sigs|concat(ch_sm_unmapped.signatures)|concat(ch_sm_multimapped.signatures)|
                    concat(ch_sm_comp)|concat(ch_sm_unmapped.comparison)|concat(ch_sm_multimapped.comparison)|
                    concat(ch_sm_plot)|concat(ch_sm_unmapped.plot)|concat(ch_sm_multimapped.plot)
}
