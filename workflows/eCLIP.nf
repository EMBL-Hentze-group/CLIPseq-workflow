include {samplesheetToList} from 'plugin/nf-schema'
// Raw QC and Sourmash
include {QC_WRAPPER as QC} from './subworkflows/qc.nf'
include {SOURMASH_WRAPPER as SOURMASH} from './subworkflows/sourmash.nf'
// Trim 
include {FASTP as FASTP_2STEP} from './subworkflows/fastp_two_step.nf'
// BBDUK
include {BBDUK} from './subworkflows/bbduk.nf'
// STAR align
include {
    STARALIGN
    STARALIGN_2PASS
    } from './subworkflows/star_align.nf'
// Shoji
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
        ch_data = Channel
            .fromList(samplesheetToList(params.input, "./assets/schema_input.json"))
            .map {
                sample, fastq_1, fastq_2 ->
                    // sample, paired, [fastq paths]
                    if (!fastq_2) {
                        return [ sample, false, [fastq_1]]
                    } else {
                        return [ sample, true, [fastq_1, fastq_2]]
                    }
            }
        // Raw data QC
        ch_raw_qc = QC(ch_data, "raw") // raw QC
        ch_raw_sourmash = SOURMASH(ch_data, params.sourmash.sketch, params.sourmash.abund, 
                            params.sourmash.comparison_K, "raw") // raw sourmash
        // adapter trimming
        if (params.two_step_trim) { // two step trim
            ch_trim = FASTP_2STEP(ch_data, params.fastp.trim1, params.fastp.trim2, params.sourmash.sketch, 
                        params.sourmash.abund, params.sourmash.comparison_K) // two step trim with fastp
            ch_trimmed_fqs = ch_trim.trimmed|concat(ch_trim.first)
            ch_trimmed_report = ch_trim.report|merge(ch_trim.first_report)
        }else{ // one step trim
            ch_trim = FASTP(ch_data, params.fastp.trim, params.sourmash.sketch, params.sourmash.abund, 
                        params.sourmash.comparison_K) // single step trim with fastp
            ch_trimmed_fqs = ch_trim.trimmed
            ch_trimmed_report = ch_trim.report
        }
        // trim rRNA
        ch_bbduk = BBDUK(ch_trim.trimmed, params.bbduk.ref, params.bbduk.params, 
                    params.sourmash.sketch, params.sourmash.abund, params.sourmash.comparison_K) // bbduk to remove rRNA
        // Align
        if(params.twopass_mapping) { // two pass mapping
            ch_star = STARALIGN_2PASS(ch_bbduk.free, params.STAR.genomeDir, params.STAR.align_params, 
                        params.dedup, params.umi_tools.dedup_params, params.sourmash.sketch, 
                        params.sourmash.abund, params.sourmash.comparison_K) // star align
        } else {
            ch_star = STARALIGN(ch_bbduk.free, params.STAR.genomeDir, params.STAR.align_params, params.dedup, 
                        params.umi_tools.dedup_params, params.sourmash.sketch, params.sourmash.abund, 
                        params.sourmash.comparison_K) // star align
        }
        if(params.twopass_mapping || params.dedup) { 
            /*
            if two pass mapping or dedup, merge  bam channels
            ++++ NOTE ++++
            This channel is used only to output bam files, 
            NOT used in downstream analysis
            */
            ch_bam = ch_star.bam|concat(ch_star.align)
        } else {
            ch_bam = ch_star.bam
        }
        // Shoji process alignments
        ch_sw = CREATE_SLIDING_WINDOWS(params.shoji.gff3, params.shoji.tabix, params.shoji.split_intron, 
                    params.shoji.annotation_params, params.shoji.window, params.shoji.step)
        ch_sw.annotation.view()
        ch_sw.sliding_windows.view()
        ch_counts = COUNT(ch_star.bam, params.shoji.tabix, params.shoji.ignore_pcr_duplicates,
                        params.shoji.primary, params.shoji.mate, params.shoji.site,
                        params.shoji.offset, params.shoji.extract_params, ch_sw.sliding_windows)
        ch_matrix = createMatrix(ch_counts.counts.collect(), params.shoji.baseName, params.shoji.suffix)
        // Tracks
        ch_tracks = TRACKS(ch_counts.sites, params.tracks.genome, params.tracks.params)

        publish:
        // Raw
        raw_qc = ch_raw_qc.qc
        raw_sourmash = ch_raw_sourmash.sourmash
        // Trim
        trim_qc = ch_trim.qc
        trim_sourmash = ch_trim.sourmash
        trim_fq = ch_trimmed_fqs|map(flatten_fqs)
        trim_report = ch_trimmed_report
        // rRNA trim
        rRNA_qc = ch_bbduk.qc
        rRNA_sourmash = ch_bbduk.sourmash
        rRNA_fq = ch_bbduk.free|concat(ch_bbduk.match)|map(flatten_fqs)
        rRNA_report = ch_bbduk.stats
        // Genome alignment
        align_sourmash = ch_star.sourmash
        align_bam = ch_bam|map(get_alignment)
        align_stats = ch_star.stats|concat(ch_star.junctions)
        // reads after alignment
        align_mapped = ch_star.mapped|map(flatten_fqs)
        align_unmapped = ch_star.unmapped|map(flatten_fqs)
        align_multimapped = ch_star.multimapped|map(flatten_fqs)
        // Shoji
        annotation = ch_sw.annotation|concat(ch_sw.sliding_windows)
        sites = ch_counts.sites
        counts = ch_counts.counts
        matrices = ch_matrix.annotation|concat(ch_matrix.countsMat)|concat(ch_matrix.maxCountsMat)
        // Tracks
        bigwigs = ch_tracks.bw
}

output{
    // QC
    raw_qc { 
        path "QC/raw"
    }
    trim_qc {
        path "QC/trim"
    }
    rRNA_qc { 
        path "QC/rRNA_trim"
    }
    raw_sourmash {
        path "Sourmash/raw"
    }
    // SOURMASH
    trim_sourmash {
        path "Sourmash/trim"
    }
    rRNA_sourmash {
        path "Sourmash/rRNA_trim"
    }
    align_sourmash {
        path "Sourmash/Genome_align"
    }
    // reads and stats
    trim_fq {
        path "Fastq/trim"
    }
    trim_report {
        path "Fastq/trim"
    }
    rRNA_fq {
        path "Fastq/rRNA_trim"
    }
    rRNA_report {
        path "Fastq/rRNA_trim"
    }
    // alignments
    align_bam {
        path "Genome_align"
    }
    align_stats {
        path "Genome_align"
    }
    align_mapped {
        path "Fastq/Genome_align/mapped"
    }
    align_unmapped {
        path "Fastq/Genome_align/unmapped"
    }
    align_multimapped {
        path "Fastq/Genome_align/multimapped"
    }
    // Shoji
    annotation {
        path "Shoji/annotation"
    }
    sites {
        path "Shoji/sites"
    }
    counts {
        path "Shoji/counts"
    }
    matrices {
        path "Shoji/analysis_files"
    }
    // Tracks
    bigwigs {
        path "Tracks"
    }
}