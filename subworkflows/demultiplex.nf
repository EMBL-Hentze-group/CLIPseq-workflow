include {trim_demultiplex} from '../modules/fastp.nf'
include {multiqc} from '../modules/multiqc.nf'
include {extract} from '../modules/umi_tools.nf'
include {demultiplex} from '../modules/flexbar.nf'

/*
This workflow performs demultiplexing of iCLIP data using UMI-tools and Flexbar.
*/

workflow DEMULTIPLEX{
    take:
    ch_init
    bc_pattern
    min_read_length

    main:
    ch_trim = trim_demultiplex(ch_init, min_read_length)
    ch_multiqc = multiqc(ch_trim.report.collect(), "demultiplex")
    ch_pre = extract(ch_trim.fastq, bc_pattern)
    ch_demux = demultiplex(ch_pre.fastq, "iCLIP", min_read_length, "")

    emit:
    fastq = ch_demux.flatten().map{file -> 
                def sample = file.getBaseName(file.name.endsWith('.gz') ? 2 : 1).replaceFirst(/^.*\_barcode\_/,'')
                return [sample, false, [file]]
    }
    report = ch_trim.report|merge(ch_multiqc.multiqc)
    umi_log = ch_pre.log
}