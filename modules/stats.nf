
process align_stats_STAR {
    label "STATTER"
    label "process_single"
    tag "${sample} ${stage}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // container params.singularity.stats

    input:
    tuple val(sample), val(paired), path(bam), path(index)
    val stage
    
    output:
    tuple val(sample), val(stage), path("${sample}_${stage}_stats.json")
    
    script:
    """
    alignment_stats_STAR --bam ${bam} --out_json ${sample}_${stage}_stats.json
    """
}

process sample_stats {
    label "STATTER"
    label "process_single"
    tag "${sample}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // container params.singularity.stats

    input:
    tuple val(sample), val(stage_stat_map), path(files)
    /*
    ** Warning **
    This is a hack to make sure that all input files are staged, 
    otherwise process `sample_stats` will fail when run in a container
    */

    output:
    path("${sample}_all_stats.json")

    script:
    def args = ["-r", stage_stat_map["raw"]]
    if (stage_stat_map.containsKey("trim1")){
        // if there is trim1, then there must be trim2
        args.addAll(["-f", stage_stat_map["trim1"].name, "-s", stage_stat_map["trim2"].name])
    } else if (stage_stat_map.containsKey("trim")){
        args.addAll(["-f", stage_stat_map["trim"]])
    }
    if (stage_stat_map.containsKey("rRNA_match")){
        // if there is rRNA_match, then there must be rRNA_free
        args.addAll(["-m", stage_stat_map["rRNA_match"], "-u", stage_stat_map["rRNA_free"]])
    }
    args.addAll(["-a", stage_stat_map["align"]])
    if (stage_stat_map.containsKey("dedup")){
        args.addAll(["-d", stage_stat_map["dedup"]])
    }
    if (stage_stat_map.containsKey("kraken2")){
        args.addAll(["-k", stage_stat_map["kraken2"]])
    }
    def cmd_args = args.join(" ")
    """
    echo $cmd_args
    all_stats -n ${sample} -o ${sample}_all_stats.json ${cmd_args}
    """
}

process compile_stats {
    label "STATTER"
    label "process_single"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */

    input:
    path(stats)

    output:
    path("all_samples_combined_stats.csv")

    script:
    """
    compile_stats -o all_samples_combined_stats.csv ${stats.join(' ')}
    """
}