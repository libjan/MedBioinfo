#!/bin/bash
#
#SBATCH --mem=90GB
#SBATCH --time=01:00:00
#SBATCH --nodes=1


file="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/data/sra_fastq/ERR6913172"
dbfile="/proj/applied_bioinformatics/common_data/kraken_database/"
sing_image="/proj/applied_bioinformatics/common_data/kraken2.sif"

report_k_file="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/kraken/Onesample_kraken2_report.txt"
output_k_file="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/kraken/Onesample_kraken2.txt"

output_b_file="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/bracken/Onesample_bracken.txt"
report_b_file="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/bracken/Onesample_bracken_report.txt"

#first run kracken
srun --job-name "kraken" singularity exec -B /proj:/proj $sing_image kraken2 --db $dbfile --threads 1 --paired --output $output_k_file --report $report_k_file $file"_1.fastq.gz"  $file"_2.fastq.gz"

#now bracken
srun --job-name "bracken" singularity exec -B /proj:/proj $sing_image bracken -d $dbfile -i $report_k_file -o $output_b_file -w $report_b_file
