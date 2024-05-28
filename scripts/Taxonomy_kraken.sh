#!/bin/bash
#
#SBATCH --mem=90GB
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --job-name=Kraken

file="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/data/sra_fastq/ERR6913172"
report_file="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/kraken/Onesample_kraken2_report.txt"
output_file="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/kraken/Onesample_kraken2.txt"
sing_image="/proj/applied_bioinformatics/common_data/kraken2.sif"

singularity exec -B /proj:/proj $sing_image kraken2 --db /proj/applied_bioinformatics/common_data/kraken_database/ --threads 1 --paired --output $output_file --report $report_file --use-mpa-style $file"_1.fastq.gz"  $file"_2.fastq.gz"
