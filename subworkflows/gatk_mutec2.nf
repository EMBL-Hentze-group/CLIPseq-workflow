include { GATK_RG_SPLIT } from './gatk_rg_split.nf'
include { mutect2 ; learnReadOrientation ; filterMutect } from '../modules/gatk_vc.nf'
include { getVcfs } from '../modules/utilities.nf'

workflow Mutect2Variants {
    take:
    ch_bam // tuple: [sample, bam]
    ch_reference // tuple: [genome, genome_dict]
    rg_params
    split_params
    mutect2_params
    learnReadOrientation_params
    filterMutect_params

    main:
    GATK_RG_SPLIT(ch_bam, ch_reference, rg_params, split_params)
    mutect2(GATK_RG_SPLIT.out.bam, ch_reference, mutect2_params)
    learnReadOrientation(mutect2.out.f1r2, learnReadOrientation_params)
    filterMutect(
        mutect2.out.vcf,
        ch_reference,
        learnReadOrientation.out.orientation,
        filterMutect_params,
    )
    ch_vcf = filterMutect.out.vcf.concat(mutect2.out.vcf.map { vcf -> getVcfs(vcf) })
    ch_bam = GATK_RG_SPLIT.out.bam

    emit:
    bam = ch_bam
    vcf = ch_vcf
}
