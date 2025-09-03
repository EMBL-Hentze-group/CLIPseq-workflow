include {
    bedGraph ;
    bigWig
} from '../modules/tracks.nf'

workflow TRACKS {
    take:
    sites
    genome
    bed_params

    main:
    bedgraph = bedGraph(sites, genome, bed_params)
    ch_bigWig = bigWig(bedgraph.bg, genome)

    emit:
    bw = ch_bigWig.bw
}
