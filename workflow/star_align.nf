include {STARALIGN as _STARALIGN} from '../modules/star_align.nf'
include {STARALIGN_2PASS as _STARALIGN_2PASS} from '../modules/star_align.nf'
include {INDEX as BAMINDEX} from '../modules/bam_ops.nf'
include {SORT as BAMSORT} from '../modules/bam_ops.nf'

workflow STARALIGN{
    take:
        ch_data
        genomeDir
        stage
        star_params
    main:
        ch_star = _STARALIGN(ch_data, genomeDir, stage, star_params)
        ch_sort = BAMSORT(ch_star.bam, stage)
        ch_index = BAMINDEX(ch_sort.bam, stage)
    emit:
        bam = ch_star.bam 
        index = ch_index.index
        stats = ch_star.stats
        junctions = ch_star.junctions
}

workflow STARALIGN_2PASS{
    take:
        ch_data
        genomeDir
        sjFiles
        stage
        star_params
    main:
        ch_star = _STARALIGN_2PASS(ch_data, genomeDir, sjFiles, stage, star_params)
        ch_sort = BAMSORT(ch_star.bam, stage)
        ch_index = BAMINDEX(ch_sort.bam, stage)
    emit:
        bam = ch_star.bam 
        index = ch_index.index
        stats = ch_star.stats
        junctions = ch_star.junctions
}

