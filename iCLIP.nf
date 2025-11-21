include {samplesheetToList} from 'plugin/nf-schema'
include {demultiplex} from './modules/flexbar.nf'

nextflow.enable.dsl=2
nextflow.preview.output= true

workflow{
    main:
        if (params.demultiplex){
            
            ch_init = Channel
                .fromList(samplesheetToList(params.input, "./assets/schema_iclip.json"))
            ch_init.view()
            ch_pre = demultiplex(ch_init, "iCLIP_RAF", params.min_read_length, " --umi-tags ")
            ch_data = ch_pre.flatten().map{ file -> 
                def sample = file.getBaseName(file.name.endsWith('.gz') ? 2 : 1).replaceFirst(/^.*\_barcode\_/,'')
                return [sample, params.is_paired, [file]]
            }
            ch_data.view()
            // ch_data = fastq_to_sample(ch_pre, "iCLIP_RAF_barcode_", ".fastq.gz", false)
            // ch_data.view()
        }
}