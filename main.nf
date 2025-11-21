include {samplesheetToList} from 'plugin/nf-schema'
// demultiplex (only for iCLIP now)
include {demultiplex} from './modules/flexbar.nf'
// Raw QC and Sourmash and stats
include {QC_WRAPPER as QC} from './subworkflows/qc.nf'
include {SOURMASH_WRAPPER as SOURMASH} from './subworkflows/sourmash.nf'
// read stats
include {
    stats as stats_raw
    } from './modules/seqkit.nf'
// Trim 
include {FASTP} from './subworkflows/fastp.nf'
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
// kraken2
include {KRAKEN2} from './subworkflows/kraken2.nf'
// combine stats
include {sample_stats; compile_stats} from './modules/stats.nf'



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
    _sample, _paired, bam, index ->
        return [bam, index]
}

workflow {
    main:
        if(params.demultiplex){
            // @TODO: make demultiplex a default param in the schema
            ch_init = Channel
                .fromList(samplesheetToList(params.input, "./assets/schema_iclip.json"))
            ch_pre = demultiplex(ch_init, "iCLIP", params.min_read_length, " --umi-tags ")
            ch_data = ch_pre.flatten().map{ file -> 
                def sample = file.getBaseName(file.name.endsWith('.gz') ? 2 : 1).replaceFirst(/^.*\_barcode\_/,'')
                return [sample, params.is_paired, [file]]
            }
        }else{
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
        }
        // Raw data QC
        ch_raw_qc = QC(ch_data, "raw") // raw QC
        ch_raw_sourmash = SOURMASH(ch_data, params.sourmash.sketch, params.sourmash.abund, 
                            params.sourmash.comparison_K, "raw") // raw sourmash
        // seqkit stats
        raw_reads_stats = stats_raw(ch_data, "raw")
        // adapter trimming
        if (params.two_step_trim) { // two step trim
            ch_trim = FASTP_2STEP(ch_data, params.fastp.trim1, params.fastp.trim2, params.sourmash.sketch, 
                        params.sourmash.abund, params.sourmash.comparison_K) // two step trim with fastp
            ch_trimmed_fqs = ch_trim.trimmed|concat(ch_trim.first)
            ch_trimmed_report = ch_trim.report|merge(ch_trim.first_report)
        }else{ // one step trim
            ch_trim = FASTP(ch_data, params.fastp.trim, params.sourmash.sketch, params.sourmash.abund, 
                        params.sourmash.comparison_K,"trim") // single step trim with fastp
            ch_trimmed_fqs = ch_trim.trimmed
            ch_trimmed_report = ch_trim.report
        }
        if(params.rRNA_trim){
            // trim rRNA
            ch_bbduk = BBDUK(ch_trim.trimmed, params.bbduk.ref, params.bbduk.params, 
                        params.sourmash.sketch, params.sourmash.abund, params.sourmash.comparison_K) // bbduk to remove rRNA
            ch_trimmed_reads = ch_bbduk.free
            // concatenate read stats until this point
            ch_read_stats = raw_reads_stats.stats.concat(ch_trim.read_stats, ch_bbduk.read_stats)
        }
        else{
            ch_trimmed_reads = ch_trim.trimmed
            // concatenate read stats until this point
            ch_read_stats = raw_reads_stats.stats.concat(ch_trim.read_stats)
            /*
            @TODO: find a more elegant way to handle this
            */
            ch_bbduk = [:]
            ch_bbduk.qc = Channel.empty()
            ch_bbduk.sourmash = Channel.empty()
            ch_bbduk.free = Channel.empty()
            ch_bbduk.match = Channel.empty()
            ch_bbduk.stats = Channel.empty()
        }
        // Align
        if(params.twopass_mapping) { // two pass mapping
            ch_star = STARALIGN_2PASS(ch_trimmed_reads, params.STAR.genomeDir, params.STAR.align_params, 
                        params.dedup, params.umi_tools.dedup_params, params.sourmash.sketch, 
                        params.sourmash.abund, params.sourmash.comparison_K) // star align
        } else {
            ch_star = STARALIGN(ch_trimmed_reads, params.STAR.genomeDir, params.STAR.align_params, params.dedup, 
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
        // concatenate alignment and optionally dedup stats to read stats
        ch_all_stats = ch_read_stats.concat(ch_star.read_stats).map{
            sample, stage, fname ->
                return [sample, [stage, fname]]
        }.groupTuple().map {
            sample, stage_file_list ->
                def stage_map = stage_file_list.collectEntries { stage, fname -> [(stage): fname] }
                def files = stage_map.values() as List
                return [sample, stage_map, files]
                /*
                ** Warning **
                This is a hack to make sure that all input files are staged, 
                otherwise process `sample_stats` will fail when run in a container
                */
        }
        // combine stats per sample
        ch_sample_stats = sample_stats(ch_all_stats)
        // compile all stats for all samples
        all_stats = compile_stats(ch_sample_stats.collect())
 
        // Shoji process alignments
        ch_sw = CREATE_SLIDING_WINDOWS(params.shoji.gff3, params.shoji.split_intron, 
                    params.shoji.annotation_params, params.shoji.window, params.shoji.step)
        // Count reads in sliding windows
        ch_counts = COUNT(ch_star.bam, params.shoji.ignore_pcr_duplicates,
                        params.shoji.primary, params.shoji.mate, params.shoji.site,
                        params.shoji.offset, params.shoji.extract_params, ch_sw.sliding_windows)
        ch_matrix = createMatrix(ch_counts.counts.collect(), params.shoji.baseName, params.shoji.suffix)
        // Tracks
        ch_tracks = TRACKS(ch_counts.sites, params.tracks.genome, params.tracks.params)
        // Check contamination for unmapped reads with kraken2
        ch_kraken2 = KRAKEN2(ch_star.unmapped, params.kraken2.db, params.kraken2.kraken2_params, 
                        params.kraken2.mpa_params, params.sourmash.sketch, params.sourmash.abund, 
                        params.sourmash.comparison_K, "unmapped")
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
        // kraken2
        kraken2_fqs = ch_kraken2.classified|concat(ch_kraken2.unclassified)
        kraken2_report = ch_kraken2.report
        kraken2_sourmash = ch_kraken2.sourmash
        kraken2_qc = ch_kraken2.qc
        // all per sample and combined stats
        combined_stats = all_stats.concat(ch_sample_stats)
}

output{
    // QC
    raw_qc { 
        path params.out.QC.raw
    }
    trim_qc {
        path params.out.QC.trim
    }
    rRNA_qc { 
        path params.out.QC.rRNA
    }
    kraken2_qc {
        path params.out.QC.kraken2
    }
    // SOURMASH
    raw_sourmash {
        path params.out.Sourmash.raw
    }
    
    trim_sourmash {
        path params.out.Sourmash.trim
    }
    rRNA_sourmash {
        path params.out.Sourmash.rRNA
    }
    align_sourmash {
        path params.out.Sourmash.align
    }
    kraken2_sourmash {
        path params.out.Sourmash.kraken2
    }
    // reads and stats
    trim_fq {
        path params.out.Fastq.trim
    }
    trim_report {
        path params.out.Fastq.trim
    }
    rRNA_fq {
        path params.out.Fastq.rRNA
    }
    rRNA_report {
        path params.out.Fastq.rRNA
    }
    // alignments
    align_bam {
        path params.out.Align.main
    }
    align_stats {
        path params.out.Align.main
    }
    align_mapped {
        path params.out.Fastq.mapped
    }
    align_unmapped {
        path params.out.Fastq.unmapped
    }
    align_multimapped {
        path params.out.Fastq.multimapped
    }
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
    // Contamination check with kraken2
    kraken2_fqs {
        path params.out.Kraken2.main
    }
    kraken2_report {
        path params.out.Kraken2.main
    }
    // stats
    combined_stats {
        path params.out.Stats.main 
    }
}