process MULTIQC {
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::multiqc=1.13a" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.13a--pyhdfd78af_1':
        'quay.io/biocontainers/multiqc:1.13a--pyhdfd78af_1' }"

    input:
    path multiqc_config
    path mqc_custom_config
    path software_versions
    path workflow_summary
    path methods_description
    path logo

    path ('fastqc/*')
    path ('trimgalore/fastqc/*')
    path ('trimgalore/*')

    path ('alignment/library/*')
    path ('alignment/library/*')
    path ('alignment/library/*')

    path ('alignment/mergedLibrary/unfiltered/*')
    path ('alignment/mergedLibrary/unfiltered/*')
    path ('alignment/mergedLibrary/unfiltered/*')
    path ('alignment/mergedLibrary/unfiltered/picard_metrics/*')

    path ('alignment/mergedLibrary/filtered/*')
    path ('alignment/mergedLibrary/filtered/*')
    path ('alignment/mergedLibrary/filtered/*')
    path ('alignment/mergedLibrary/filtered/picard_metrics/*')

    path ('preseq/*')

    path ('deeptools/*')
    path ('deeptools/*')
    // path ('phantompeakqualtools/*')
    // path ('phantompeakqualtools/*')
    // path ('phantompeakqualtools/*')
    // path ('phantompeakqualtools/*')

    path ('macs2/mergedLibrary/peaks/*')
    path ('macs2/mergedLibrary/peaks/*')
    path ('macs2/mergedLibrary/annotation/*')
    path ('macs2/mergedLibrary/featurecounts/*')

    path ('alignment/mergedReplicate/*')
    path ('alignment/mergedReplicate/*')
    path ('alignment/mergedReplicate/*')
    path ('alignment/mergedReplicate/picard_metrics/*')

    path ('macs2/mergedReplicate/peaks/*')
    path ('macs2/mergedReplicate/peaks/*')
    path ('macs2/mergedReplicate/annotation/*')
    path ('macs2/mergedReplicate/featurecounts/*')

    path ('deseq2_lib/*')
    path ('deseq2_lib/*')
    path ('deseq2_rep/*')
    path ('deseq2_rep/*')

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "*_plots"             , optional:true, emit: plots
    path "versions.yml"        , emit: versions

    script:
    def args          = task.ext.args ?: ''
    def custom_config = params.multiqc_config ? "--config $mqc_custom_config" : ''
    """
    multiqc \\
        -f \\
        $args \\
        $custom_config \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed -e "s/multiqc, version //g" )
    END_VERSIONS
    """
}
