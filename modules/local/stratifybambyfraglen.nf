

process STRATIFY_BAM_BY_FRAGLEN {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::bamtools=2.5.2 bioconda::samtools=1.15.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-0560a8046fc82aa4338588eca29ff18edab2c5aa:5687a7da26983502d0a8a9a6b05ed727c740ddc4-0' :
        'biocontainers/mulled-v2-0560a8046fc82aa4338588eca29ff18edab2c5aa:5687a7da26983502d0a8a9a6b05ed727c740ddc4-0' }"


    input:
    // COmment regarding original version which used "each" channel for ranges.
    // When script does not return either bam_ch or bai_ch (because no reads in range), the pipeline is hanging without finishing.
    // For now, I am changing script to always output file.  But I'd like to understand this problem.
    // UPDATE: Changing the output did not seem to fix it.  Only 20 of 21 range jobs are put on the queue.  Why would this be??  If the bai
    // was missing for one?
    // I've seen this again with a different dataset 95 out of 96 (and a different range 161-180).  Two runs back
    // to back, one gets 95 of 96, the other gets 96 of 96.  There is an error which seems to have to do
    // with Azure in the 95 of 96 one:
    // reactor.netty.ReactorNetty$InternalNettyException: java.lang.OutOfMemoryError: Java heap space
    // But I went back and I see this error in also one of the 21 of 21 runs.  So I'm not sure this is it.
    // I've spend many hours on this and it's very frustrating. It may be related to the note in the "each"
    // documentation which says it's unsupported for use with tuples.
    // BASED ON Chris Wright suggestion on https://github.com/nextflow-io/nextflow/discussions/3107
    // abandon use of each and instead cross it using channel operator (combine)
    tuple val(meta), path(bam), path(bai), val(range)

    output:
    tuple val(meta_new), path("*range*.bam"), emit: bam_ch, optional: true // Optional true in case we don't want to output a file if there are no reads
    tuple val(meta_new), path("*range*.bai"), emit: bai_ch, optional: true // Optional true in case we don't want to output a file if there are no reads
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // I used to have meta_new = meta.clone() here, but it would not work, said "No such variable: id" when I tried to set id
    def meta_keys = meta.keySet()
    meta_new = meta.subMap(meta_keys)
    meta_new.id = "${meta.id}.range${range}"
    meta_new.fraglen_range = "${range}"

    // If bam is "foo_1_aaa.bam.bai", then bam_new = "foo_1_aaa.range${range}.bam.bai"
    def bam_out = bam.toString().split('.bam')[0]
    bam_out = "${bam_out}.range${range}.bam"

    // I forget why I did this originally, but it was causing a problem to use the original
    def bam_new = "${meta.id}.bam"
    def ln_sec = (bam_new == bam) ? "" : "ln -s ${bam} ${bam_new} && ln -s ${bai} ${bam_new}.bai "

    // TODO have to handle the case where there are no reads in the range.
    // Currently , we will output an empty BAM. Currently this is working, because it has a valid header. But an empty
    // BAM file could crash downstream processes.

    """
    ${ln_sec}

    samtools view \\
        -h $bam_new \\
        -@ ${task.cpus-1} \\
        | awk -F'\\t' 'BEGIN {OFS="\\t"} /^@/ {print \$0} {tlen=\$9; if (tlen < 0) tlen *= -1; if (tlen >= ${range.split('-')[0]} && tlen <= ${range.split('-')[1]}) print \$0}' \\
        | samtools view \\
            -b \\
            -h \\
            -@ ${task.cpus-1} \\
            -o ${bam_out}

    samtools index \\
        -@ ${task.cpus-1} \\
        ${bam_out}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """


    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"


    def bam_out = bam.split('.bam')[0]
    bam_out = "${bam_out}.range${range}.bam"

    """
    touch ${bam_out}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(echo \$(python3 --version 2>&1) | sed 's/^.*Python //; s/ .*\$//')
    END_VERSIONS
    """


}
