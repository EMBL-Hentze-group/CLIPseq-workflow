include { addRG ; splitNcigar } from '../modules/gatk_preprocess.nf'
workflow GATK_RG_SPLIT {
    take:
    ch_bam // tuple: [sample, bam]
    ch_reference // tuple: [genome, genome_dict]
    rg_params
    split_params

    main:
    addRG(
        ch_bam,
        rg_params,
    )

    splitNcigar(
        addRG.out.bam,
        ch_reference,
        split_params,
    )

    emit:
    bam = splitNcigar.out.bam
}
