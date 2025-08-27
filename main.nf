include {samplesheetToList} from 'plugin/nf-schema'
// QCs
include {QC as QC_RAW} from './workflow/qc.nf'
include {QC as QC_CA_TRIM1} from './workflow/qc.nf'
include {QC as QC_CA_TRIM2} from './workflow/qc.nf'
include {QC as QC_FP_TRIM1} from './workflow/qc.nf'
include {QC as QC_FP_TRIM2} from './workflow/qc.nf'
// Trims
// // cutadapt
include {CUTADAPT as CUTADAPT_TRIM1} from './workflow/cutadapt.nf'
include {CUTADAPT as CUTADAPT_TRIM2} from './workflow/cutadapt.nf'
// // fastp
include {FASTP as FASTP_TRIM1} from './workflow/fastp.nf'
include {FASTP as FASTP_TRIM2} from './workflow/fastp.nf'
// Sourmash
include {SOURMASH as SOURMASH_RAW} from './workflow/sourmash.nf'
include {SOURMASH as SOURMASH_TRIM1_CA} from './workflow/sourmash.nf'
include {SOURMASH as SOURMASH_TRIM2_CA} from './workflow/sourmash.nf'
include {SOURMASH as SOURMASH_TRIM1_FP} from './workflow/sourmash.nf'
include {SOURMASH as SOURMASH_TRIM2_FP} from './workflow/sourmash.nf'    

// for output
nextflow.preview.output = true
  
// collect qc outputs
def collect_qc_outputs = { qc_channel ->
    qc_channel.zip.concat( qc_channel.html, qc_channel.multiqc)
    .collect()
    .flatten()
}
// collect trim outputs
def collect_trim_outputs = { trim_channel ->
    trim_channel.trimmed.map{it[2]}
    .concat(trim_channel.report.map{it[2]})
    .collect()
}
// collect sourmash outputs
def collect_sourmash_outputs = { sourmash_channel ->
    sourmash_channel.plot
    .concat(sourmash_channel.signatures, sourmash_channel.comparison.flatten())
    .collect()
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
        // QC Raw
        ch_raw_qc = QC_RAW(ch_data, "raw") // raw
        // trim using cutadapt and QC
        ch_ca_trim1 = CUTADAPT_TRIM1(ch_data,"trim1", params.cutadapt.trim1) // first trim
        ch_ca_trim2 = CUTADAPT_TRIM2(ch_ca_trim1.trimmed,"trim2", params.cutadapt.trim2) // second trim
        // trim using cutadapt and QC
        ch_fp_trim1 = FASTP_TRIM1(ch_data,"trim1", params.fastp.trim1)
        ch_fp_trim2 = FASTP_TRIM2(ch_fp_trim1.trimmed,"trim2", params.fastp.trim2)
        
        //SOURMASH
        ch_raw_sourmash = SOURMASH_RAW(ch_data, "raw", params.sourmash.sketch, params.sourmash.abund, params.sourmash.comparison_K) // sourmash on raw
        ch_trim1_ca_sourmash = SOURMASH_TRIM1_CA(ch_ca_trim1.trimmed, "trim1", params.sourmash.sketch, params.sourmash.abund, params.sourmash.comparison_K) // sourmash on trim1
        ch_trim2_ca_sourmash = SOURMASH_TRIM2_CA(ch_ca_trim2.trimmed, "trim2", params.sourmash.sketch, params.sourmash.abund, params.sourmash.comparison_K) // sourmash on trim2
        ch_trim1_fp_sourmash = SOURMASH_TRIM1_FP(ch_fp_trim1.trimmed, "trim1", params.sourmash.sketch, params.sourmash.abund, params.sourmash.comparison_K) // sourmash on trim1
        ch_trim2_fp_sourmash = SOURMASH_TRIM2_FP(ch_fp_trim2.trimmed, "trim2", params.sourmash.sketch, params.sourmash.abund, params.sourmash.comparison_K) // sourmash on trim2

    publish:
        //QC outputs
        raw_qc = collect_qc_outputs(ch_raw_qc)
        trim1_ca_qc = collect_qc_outputs(ch_ca_trim1)
        trim2_ca_qc = collect_qc_outputs(ch_ca_trim2)
        trim1_fp_qc = collect_qc_outputs(ch_fp_trim1)
        trim2_fp_qc = collect_qc_outputs(ch_fp_trim2)
        // trim outputs
        trim1_ca = collect_trim_outputs(ch_ca_trim1)
        trim2_ca = collect_trim_outputs(ch_ca_trim2)
        trim1_fp = collect_trim_outputs(ch_fp_trim1)
        trim2_fp = collect_trim_outputs(ch_fp_trim2)
        //SOURMASH outputs
        sourmash_raw = collect_sourmash_outputs(ch_raw_sourmash)
        sourmash_trim1_ca = collect_sourmash_outputs(ch_trim1_ca_sourmash)
        sourmash_trim2_ca = collect_sourmash_outputs(ch_trim2_ca_sourmash)
        sourmash_trim1_fp = collect_sourmash_outputs(ch_trim1_fp_sourmash)
        sourmash_trim2_fp = collect_sourmash_outputs(ch_trim2_fp_sourmash)  
}

output{
    raw_qc {
        path "QC"
        mode params.mode
    }
    trim1_ca_qc {
        path "QC/cutadapt"
        mode params.mode
    }
    trim2_ca_qc {
        path "QC/cutadapt"
        mode params.mode
    }
    trim1_ca {
        path "trim/cutadapt"
        mode params.mode
    }
    trim2_ca {
        path "trim/cutadapt"
        mode params.mode
    }
    trim1_fp_qc {
        path "QC/fastp"
        mode params.mode
    }
    trim2_fp_qc {
        path "QC/fastp"
        mode params.mode
    }
    trim1_fp {
        path "trim/fastp"
        mode params.mode
    }
    trim2_fp {
        path "trim/fastp"
        mode params.mode
    }
    sourmash_raw {
        path "sourmash"
        mode params.mode
    }
    sourmash_trim1_ca {
        path "sourmash/cutadapt"
        mode params.mode
    }
    sourmash_trim2_ca {
        path "sourmash/cutadapt"
        mode params.mode
    }
    sourmash_trim1_fp {
        path "sourmash/fastp"
        mode params.mode
    }
    sourmash_trim2_fp {
        path "sourmash/fastp"
        mode params.mode
    }
}
