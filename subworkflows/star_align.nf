include {
    STARALIGN as STARALIGN_P
    STARALIGN_2PASS as STARALIGN_2PASS_P
    } from '../modules/star.nf'
include {UMI_DEDUP} from './umi_dedup.nf'
include {
    FASTQ as FASTQ_MAPPED
    FASTQ as FASTQ_UNMAPPED
    FASTQ as FASTQ_MULTIMAPPED
    } from '../modules/samtools.nf'
include {
    SOURMASH as SOURMASH_MAPPED
    SOURMASH as SOURMASH_UNMAPPED
    SOURMASH as SOURMASH_MULTIMAPPED
    } from './sourmash.nf'

workflow STARALIGN{
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
        ch_star = STARALIGN_P(ch_data, genomeDir, star_params, "align")
        if (dedup){
            ch_dedup = UMI_DEDUP(ch_star.bam, dedup_params, "dedup")
            ch_bam = ch_dedup.bam
            ch_align = ch_star.bam
        }else{
            ch_bam = ch_star.bam
            ch_align = [] // @TODO: is there a better way to handle this?
        }
        // to fastq and sourmash
        ch_fq_mapped = FASTQ_MAPPED(ch_star.bam, "mapped")
        ch_sm_mapped = SOURMASH_MAPPED(ch_fq_mapped.fastq, sketch_params, abund, compare_K, "mapped")
        ch_fq_unmapped = FASTQ_UNMAPPED(ch_star.bam, "unmapped")
        ch_sm_unmapped = SOURMASH_UNMAPPED(ch_fq_unmapped.fastq, sketch_params, abund, compare_K, "unmapped")
        ch_fq_multimapped = FASTQ_MULTIMAPPED(ch_star.bam, "multimapped")
        ch_sm_multimapped = SOURMASH_MULTIMAPPED(ch_fq_multimapped.fastq, sketch_params, abund, compare_K, "multimapped")
        // sourmash data
        // ch_signatures = ch_sm_mapped.signatures
        ch_signatures = ch_sm_mapped.signatures.merge(ch_sm_unmapped.signatures,ch_sm_multimapped.signatures)
        // ch_comparison = ch_sm_mapped.comparison
        ch_comparison = ch_sm_mapped.comparison.merge(ch_sm_unmapped.comparison,ch_sm_multimapped.comparison)
        // ch_plot = ch_sm_mapped.plot
        ch_plot = ch_sm_mapped.plot.merge(ch_sm_unmapped.plot,ch_sm_multimapped.plot)
    emit:
        // align outputs
        bam = ch_bam
        align = ch_align
        stats = ch_star.stats
        junctions = ch_star.junctions
        // aligned reads as fastq
        mapped = ch_fq_mapped
        unmapped = ch_fq_unmapped
        multimapped = ch_fq_multimapped
        // sourmash 
        signatures = ch_signatures
        comparison = ch_comparison
        plot = ch_plot
}

workflow STARALIGN_2PASS{
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
        ch_fp = STARALIGN_P(ch_data, genomeDir, star_params, "firstPass")
        ch_sp = STARALIGN_2PASS_P(ch_data, genomeDir, star_params, ch_fp.junctions.collect(), "secondPass")
        if (dedup){
            ch_dedup = UMI_DEDUP(ch_sp.bam, dedup_params, "dedup")
            ch_bam = ch_dedup.bam
            ch_align = ch_sp.bam.merge(ch_fp.bam)
        }else{
            ch_bam = ch_sp.bam
            ch_align = ch_fp.bam
        }
        // to fastq and sourmash
        ch_fq_mapped = FASTQ_MAPPED(ch_bam, "mapped")
        ch_sm_mapped = SOURMASH_MAPPED(ch_fq_mapped.fastq, sketch_params, abund, compare_K, "mapped")
        ch_fq_unmapped = FASTQ_UNMAPPED(ch_sp.bam, "unmapped")
        ch_sm_unmapped = SOURMASH_UNMAPPED(ch_fq_unmapped.fastq, sketch_params, abund, compare_K, "unmapped")
        ch_fq_multimapped = FASTQ_MULTIMAPPED(ch_sp.bam, "multimapped")
        ch_sm_multimapped = SOURMASH_MULTIMAPPED(ch_fq_multimapped.fastq, sketch_params, abund, compare_K, "multimapped")
        // sourmash data
        ch_signatures = ch_sm_mapped.signatures.merge(ch_sm_unmapped.signatures,ch_sm_multimapped.signatures)
        ch_comparison = ch_sm_mapped.comparison.merge(ch_sm_unmapped.comparison,ch_sm_multimapped.comparison)
        ch_plot = ch_sm_mapped.plot.merge(ch_sm_unmapped.plot,ch_sm_multimapped.plot)
    emit:
        // align outputs
        bam = ch_bam
        align = ch_align
        stats = ch_fp.stats.merge(ch_sp.stats)
        junctions = ch_fp.junctions.merge(ch_sp.junctions)
        // aligned reads as fastq
        mapped = ch_fq_mapped
        unmapped = ch_fq_unmapped
        multimapped = ch_fq_multimapped
        // sourmash 
        signatures = ch_signatures
        comparison = ch_comparison
        plot = ch_plot
}

