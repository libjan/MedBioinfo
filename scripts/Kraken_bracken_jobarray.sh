#!/bin/bash
#
#SBATCH --ntasks=1                   # nb of *tasks* to be run in // (usually 1), this task can be multithreaded (see cpus-per-task)
#SBATCH --nodes=1                   # nb of nodes to reserve for each task (usually 1)
#SBATCH --cpus-per-task=1            # nb of cpu (in fact cores) to reserve for each task /!\ job killed if commands below use more cores
#SBATCH --mem=90GB                  # amount of RAM to reserve for the tasks /!\ job killed if commands below use more RAM
#SBATCH --time=01:00:00               # maximal wall clock duration (D-HH:MM) /!\ job killed if commands below take more time than reservation
#SBATCH -o slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e slurm.%A.%a.err   # standard error  (STDERR) redirected to these files (with Job ID and array ID in file names)
# /!\ Note that the ./outputs/ dir above needs to exist in the dir where script is submitted **prior** to submitting this script
#SBATCH --array=1-10                # 1-N: clone this script in an array of N tasks: $SLURM_ARRAY_TASK_ID will take the value of 1,2,...,N


#################################################################
# Preparing work (cd to working dir, get hold of input data, convert/un-compress input data when needed etc.)
workdir="/proj/applied_bioinformatics/users/x_libja"
datadir="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/data/sra_fastq"
accnum_file="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/x_libja_run_accessions.txt"
outdir="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses"

echo START: `date`

#module load seqkit blast #as required

mkdir -p ${workdir}      # -p because it creates all required dir levels **and** doesn't throw an error if the dir exists :)
cd ${workdir}

# this extracts the item number $SLURM_ARRAY_TASK_ID from the file of accnums
accnum=$(sed -n "$SLURM_ARRAY_TASK_ID"p ${accnum_file})
echo $accnum
input_file="${datadir}/${accnum}"
echo $input_file

#names for all outputs
report_k_file="${outdir}/kraken/${accnum}_kraken2_report.txt"
output_k_file="${outdir}/kraken/${accnum}_kraken2.txt"

output_b_file="${outdir}/bracken/${accnum}_bracken.txt"
report_b_file="${outdir}/bracken/${accnum}_bracken_report.txt"


#################################################################
# Start work
#module load seqkit blast #as required #done using singularity
dbfile="/proj/applied_bioinformatics/common_data/kraken_database/"          sing_image="/proj/applied_bioinformatics/common_data/kraken2.sif"

echo "starting kraken on " $input_file"_1.fastq.gz" " and " $input_file"_2.fastq.gz"
#first run kracken
srun --job-name="kraken2_$accnum" singularity exec -B /proj:/proj $sing_image kraken2 --db $dbfile --threads 1 --paired --output $output_k_file --report $report_k_file $input_file"_1.fastq.gz"  $input_file"_2.fastq.gz"
echo "creating k output "  $output_k_file " and " $report_k_file

echo "starting bracken on " $report_k_file
#now bracken
srun --job-name="bracken_$accnum" singularity exec -B /proj:/proj $sing_image bracken -d $dbfile -i $report_k_file -o $output_b_file -w $report_b_file


#################################################################
# Clean up (eg delete temp files, compress output, recompress input etc)
#srun gzip ${input_file}
#srun gzip ${output_file}
echo END: `date`
