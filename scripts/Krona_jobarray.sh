#!/bin/bash
#
#SBATCH --ntasks=1                   # nb of *tasks* to be run in // (usually 1), this task can be multithreaded (see cpus-per-task)
#SBATCH --nodes=1                   # nb of nodes to reserve for each task (usually 1)
#SBATCH --cpus-per-task=1            # nb of cpu (in fact cores) to reserve for each task /!\ job killed if commands below use more cores
#SBATCH --time=01:00:00               # maximal wall clock duration (D-HH:MM) /!\ job killed if commands below take more time than reservation
#SBATCH -o slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e slurm.%A.%a.err   # standard error  (STDERR) redirected to these files (with Job ID and array ID in file names)
# /!\ Note that the ./outputs/ dir above needs to exist in the dir where script is submitted **prior** to submitting this script
#SBATCH --array=1-10                # 1-N: clone this script in an array of N tasks: $SLURM_ARRAY_TASK_ID will take the value of 1,2,...,N


#################################################################
# Preparing work (cd to working dir, get hold of input data, convert/un-compress input data when needed etc.)
workdir="/proj/applied_bioinformatics/users/x_libja"
datadir="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/bracken"
accnum_file="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/x_libja_run_accessions.txt"
outdir="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/krona"

echo START: `date`

#module load seqkit blast #as required

mkdir -p ${workdir}      # -p because it creates all required dir levels **and** doesn't throw an error if the dir exists :)
cd ${workdir}

# this extracts the item number $SLURM_ARRAY_TASK_ID from the file of accnums
accnum=$(sed -n "$SLURM_ARRAY_TASK_ID"p ${accnum_file})
echo $accnum
input_file="${datadir}/${accnum}_bracken_report.txt"
echo $input_file

#names for all outputs
output_txt_file="${outdir}/${accnum}_krona.txt"
output_txt_noprefix_file="${outdir}/${accnum}_krona_noprefix.txt"
output_html_file="${outdir}/${accnum}_krona.html"


###############################################################
# Start work
#module load seqkit blast #as required #done using singularity
sing_image="/proj/applied_bioinformatics/common_data/kraken2.sif"
PATH=$PATH:/proj/applied_bioinformatics/tools/KrakenTools

#first run report to krona conversion
srun python /proj/applied_bioinformatics/tools/KrakenTools/kreport2krona.py -r $input_file -o $output_txt_file

#now eliminating prefix
sed -E 's/\b(k__|p__|c__|o__|f__|g__|s__)//g' $output_txt_file > $output_txt_noprefix_file

srun singularity exec -B /proj:/proj $sing_image ktImportText $output_txt_noprefix_file -o $output_html_file

#################################################################
# Clean up (eg delete temp files, compress output, recompress input etc)
#srun gzip ${input_file}
#srun gzip ${output_file}
echo END: `date`
