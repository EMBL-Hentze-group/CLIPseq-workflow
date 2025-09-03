include {
    extract ;
    count as count_P
} from '../modules/shoji.nf'

workflow COUNT {
    take:
    bam
    tabix
    ignore_pcr_duplicates
    primary
    mate
    site
    offset
    extract_params
    sliding_windows

    main:
    ch_bed = extract(bam, tabix, ignore_pcr_duplicates, primary, mate, site, offset, extract_params)
    ch_count = count_P(ch_bed.bed, sliding_windows)

    emit:
    sites = ch_bed.sites
    counts = ch_count.counts
}
