include {samplesheetToList} from 'plugin/nf-schema'
include {CREATE_SLIDING_WINDOWS} from './subworkflows/shoji_createSlidingWindows.nf'
include {COUNT} from './subworkflows/shoji_count.nf'
include { createMatrix } from './modules/shoji.nf'
// Tracks
include {TRACKS} from './subworkflows/tracks.nf'



nextflow.enable.dsl=2
nextflow.preview.output= true

def flatten_fqs = { sample, paired, fqs ->
    if (paired) {
        return fqs.flatten()
    } else {
        return fqs
    }
}

def get_alignment =  {
    sample, paired, bam, index ->
        return [bam, index]
}

workflow {
    main:
        ch_bam = Channel
            .fromList(samplesheetToList(params.input, "./assets/schema_bam.json"))
            .map {
                sample, paired, bam, index ->
                    // sample, paired, [fastq paths]
                    return [ sample, paired, bam, index ]
                    // if (!fastq_2) {
                    //     return [ sample, false, [fastq_1]]
                    // } else {
                    //     return [ sample, true, [fastq_1, fastq_2]]
                    // }
            }
        // Shoji process alignments
        ch_sw = CREATE_SLIDING_WINDOWS(params.shoji.gff3, params.shoji.split_intron, 
                    params.shoji.annotation_params, params.shoji.window, params.shoji.step)
        // Count reads in sliding windows
        ch_counts = COUNT(ch_bam, params.shoji.ignore_pcr_duplicates,
                        params.shoji.primary, params.shoji.mate, params.shoji.site,
                        params.shoji.offset, params.shoji.extract_params, ch_sw.sliding_windows)
        ch_matrix = createMatrix(ch_counts.counts.collect(), params.shoji.baseName, params.shoji.suffix)
        // Tracks
        ch_tracks = TRACKS(ch_counts.sites, params.tracks.genome, params.tracks.params)
        publish:
        // Shoji
        annotation = ch_sw.annotation|concat(ch_sw.sliding_windows)
        sites = ch_counts.sites
        counts = ch_counts.counts
        matrices = ch_matrix.annotation|concat(ch_matrix.countsMat)|concat(ch_matrix.maxCountsMat)
        // Tracks
        bigwigs = ch_tracks.bw
}

output{
    // Shoji
    annotation {
        path params.out.Shoji.annotation
    }
    sites {
        path params.out.Shoji.sites
    }
    counts {
        path params.out.Shoji.counts
    }
    matrices {
        path params.out.Shoji.matrices
    }
    // Tracks
    bigwigs {
        path params.out.Shoji.tracks
    }
}