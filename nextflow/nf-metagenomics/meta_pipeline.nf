#! /usr/bin/env nextflow

workflow{
	ch_input = Channel.fromFilePairs(params.input_read_pairs, checkIfExists: true )	

	// quality control
	FASTQC ( ch_input )

	//merging pairs
	FLASH2( ch_input )	
	
	//bowtie
        BOWTIE2 (Channel.fromPath(params.bowtie2_db, checkIfExists: true ).toList(), FLASH2.out.merged_reads)
	
	//kraken
	KRAKEN(Channel.fromPath(params.kraken2_db, checkIfExists: true ).toList(), ch_input )

	// assembling reports
	MULTIQC ( FASTQC.out.qc_zip.collect())
}


// Publish directories are numbered to help understand processing order
// all variables named params.name are listed in params.yml

// fast quality control of fastq files
process FASTQC {

	input:
	tuple val(id), path(reads)


	// directives
	container 'https://depot.galaxyproject.org/singularity/fastqc:0.11.9--hdfd78af_1' 
	publishDir "$params.outdir/01_fastqc" 

	script: 
	"""

	fastqc \\
	    --noextract \\
	    $reads

	"""

	output:
	path "${id}*fastqc.html", 	emit: qc_html
	path "${id}*fastqc.zip", 	emit: qc_zip

}


process MULTIQC {

	input: 
	path(fastqc_zips) 

	// directives
	container 'https://depot.galaxyproject.org/singularity/multiqc:1.9--pyh9f0ad1d_0'
	publishDir "$params.outdir/08_multiqc"

	script: 
	"""
	multiqc \\
    	    --force \\
    	    --title "metagenomics" \\
		.
	"""

	output: 
	path "*"
}

process FLASH2 {
    input:
   tuple val(id), path(reads)
    
	// directives
	container 'https://depot.galaxyproject.org/singularity/flash2:2.2.00--hed695b0_2'
	publishDir "$params.outdir/02_flash"

    script:
    """
    flash2 \\
	$reads \\
	--output-prefix="${id}.flash2" \\
	| tee -a ${id}_flash2.log 
    """

    output:
	tuple val(id), path ("${id}.flash2.extendedFrags.fastq"), emit: merged_reads
	path "${id}_flash2.log", emit: log

}

process BOWTIE2 {

	input: 
	path(bowtie2_db)
	tuple val(id), path(merged_reads)

	// directives:
	container 'https://depot.galaxyproject.org/singularity/mulled-v2-ac74a7f02cebcfcc07d8e8d1d750af9c83b4d45a:f70b31a2db15c023d641c32f433fb02cd04df5a6-0'
	publishDir "$params.outdir/03_bowtie2"

	script:
	db_name = bowtie2_db.find{it.name.endsWith(".rev.1.bt2")}.name.minus(".rev.1.bt2")
	"""

	bowtie2 \\
	    -x $db_name \\
	    -U $merged_reads \\
	    -S ${id}_bowtie2_merged_${db_name}.sam \\
	    --no-unal \\
	    |& tee -a ${id}_bowtie2_merged_${db_name}.log

	"""

	output:
	path "${id}_bowtie2_merged_${db_name}.log", emit: logs
	path "${id}_bowtie2_merged_${db_name}.sam", emit: aligned_reads 
	
}

process KRAKEN {                                                                          input:
	path(kraken2_db)
	tuple val(id), path(reads)
	// directives                                                                
        container 'https://depot.galaxyproject.org/singularity/mulled-v2-8706a1dd73c6cc426e12dd4dd33a5e917b3989ae:c8cbdc8ff4101e6745f8ede6eb5261ef98bdaff4-0'
	publishDir "$params.outdir/04_kraken"

    script:
"""
    kraken2 \\
        --db $kraken2_db \\
	--output "${id}.kraken2" \\
	--paired \\
	--report "${id}.kraken2.report" \\
	$reads
        
"""

output:
	path "${id}.kraken2", emit: kraken_out
        path "${id}.kraken2.report", emit: kraken_report
}
