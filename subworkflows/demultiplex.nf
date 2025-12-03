include {fastqc_demux} from '../modules/fastqc.nf'
include {multiqc} from '../modules/multiqc.nf'
include {demultiplex} from '../modules/flexbar.nf'
include {fix_header} from '../modules/helpers.nf'

/*
This workflow performs demultiplexing of iCLIP data using UMI-tools and Flexbar.
*/

workflow DEMULTIPLEX{
    take:
    ch_init
    prefix
    min_read_length
    flexbar_params

    main:
    ch_demux = demultiplex(ch_init, prefix, min_read_length, flexbar_params)
    ch_fastqc = fastqc_demux(ch_init)
    ch_multiqc = multiqc(ch_fastqc.zip.collect(), "before_demultiplex")
    ch_fastq = fix_header(ch_demux.flatten())
    
    emit:
    fastq = ch_fastq.map{file -> 
                def sample = file.getBaseName(file.name.endsWith('.gz') ? 2 : 1).replaceFirst(/^.*\_barcode\_/,'')
                // ^.*barcode_ is hardcoded in flexbar output naming convention
                return [sample, false, [file]]
    }
    qc = ch_fastqc.zip.collect().merge(ch_fastqc.html.collect(),ch_multiqc.multiqc)
}