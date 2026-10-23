/*
* Utility functions for the workflow
*/

/*
 * workflow info
 */
def info() {
    log.info(
        """
        ==================================================
        ${workflow.manifest.name} v${workflow.manifest.version}
        ==================================================
        Description   : ${workflow.manifest.description}
        Author        : ${workflow.manifest.author}
        Nextflow      : ${workflow.nextflow.version}
        Run arguments : ${workflow.commandLine}
        ==================================================
        """
    )
}


/*
 * Enable preview output for older Nextflow versions.
 * This is kept for compatibility with versions before 25.10.0.
 * The feature was later promoted out of preview.
 */
def enablePreview() {
    if (nextflow.version < ' 25.10.0') {
        nextflow.preview.output = true
    }
}

/*
 * Get Sourmash configuration from the provided parameters as a map
 */
def getSourmashCfg(sourmashParams) {
    return [
        sketch: sourmashParams.sketch,
        abund: sourmashParams.abund,
        comparison_K: sourmashParams.comparison_K,
    ]
}

/*
 * Recursively flatten nested lists or tuples into a single list.
 * mostly for paired-end data
 */
def flattenFiles(values) {
    def out = []
    values.each { v ->
        if (v instanceof List || v instanceof Tuple) {
            out.addAll(flattenFiles(v))
        }
        else {
            out.add(v)
        }
    }
    return out
}

/*
 * Return files/strings that match the provided pattern
*/
def getFilesByPattern(values, patterns) {
    def regexes = patterns.collect { p ->
        p instanceof java.util.regex.Pattern
            ? p
            : java.util.regex.Pattern.compile(p.toString())
    }

    return values.findAll { v ->
        def s = v != null ? v.toString() : null
        (s != null) && regexes.any { r -> r.matcher(s).find() }
    }
}

// fastq files
def getFqs(values) {
    return getFilesByPattern(flattenFiles(values), [/\.f(ast)?q.*$/])
}
// bam files
def getBams(values) {
    return getFilesByPattern(values, [/\.bam.*$/])
}
// vcf files
def getVcfs(values) {
    return getFilesByPattern(values, [/\.vcf.*$/])
}
