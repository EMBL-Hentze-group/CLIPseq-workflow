include {STARALIGN as STARALIGN_P} from '../modules/star.nf'
include {STARALIGN_2PASS as STARALIGN_2PASS_P} from '../modules/star.nf'

workflow STARALIGN{
    take:
        ch_data
        genomeDir
        star_params
        stage
    main:
        ch_star = STARALIGN_P(ch_data, genomeDir, star_params, stage)
    emit:
        bam = ch_star.bam 
        stats = ch_star.stats
        junctions = ch_star.junctions
}

workflow STARALIGN2{
    take:
        ch_data
        genomeDir
        star_params
        stage
    main:
        ch_star = STARALIGN_P(ch_data, genomeDir, star_params, stage)
    emit:
        bam = ch_star.bam 
        stats = ch_star.stats
        junctions = ch_star.junctions
}

workflow STARALIGN_2PASS{
    take:
        ch_data
        genomeDir
        star_params
        sjFiles
        stage
        
    main:
        ch_star = STARALIGN_2PASS_P(ch_data, genomeDir, star_params, sjFiles, stage)
    emit:
        bam = ch_star.bam
        stats = ch_star.stats
        junctions = ch_star.junctions
}

