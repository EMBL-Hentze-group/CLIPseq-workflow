process SKETCH {
    label "process_low"
    tag "$sample $stage"

    container params.singularity.sourmash

    input:
        tuple val(sample), val(paired), path(fastqs)
        val stage
        val sketch_params
        val abund

    output:
        path("${sample}_${stage}.sig.zip"), emit: sig

    script:
    def out = "${sample}_${stage}.sig.zip"
    sketch_params = abund ? sketch_params + ",abund" : sketch_params
    """
    sourmash sketch dna -f -p ${sketch_params} --name ${sample} -o ${out} ${fastqs}
    """
}