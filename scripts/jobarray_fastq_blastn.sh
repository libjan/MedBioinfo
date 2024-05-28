#!/bin/bash
#
#SBATCH --ntasks=1                   # nb of *tasks* to be run in // (usually 1), this task can be multithreaded (see cpus-per-task)
#SBATCH --nodes=1                    # nb of nodes to reserve for each task (usually 1)
#SBATCH --cpus-per-task=4            # nb of cpu (in fact cores) to reserve for each task /!\ job killed if commands below use more cores
#SBATCH --mem=16GB                  # amount of RAM to reserve for the tasks /!\ job killed if commands below use more RAM
#SBATCH --time=00:30               # maximal wall clock duration (D-HH:MM) /!\ job killed if commands below take more time than reservation
#SBATCH -o slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e slurm.%A.%a.err   # standard error  (STDERR) redirected to these files (with Job ID and array ID in file names)
# /!\ Note that the ./outputs/ dir above needs to exist in the dir where script is submitted **prior** to submitting this script
#SBATCH --array=1-10                # 1-N: clone this script in an array of N tasks: $SLURM_ARRAY_TASK_ID will take the value of 1,2,...,N


#################################################################
# Preparing work (cd to working dir, get hold of input data, convert/un-compress input data when needed etc.)
workdir="/proj/applied_bioinformatics/users/x_libja"
datadir="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/data/merged_pairs"
accnum_file="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/x_libja_run_accessions.txt"
outdir="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/blastn"

echo START: `date`

#module load seqkit blast #as required

mkdir -p ${workdir}      # -p because it creates all required dir levels **and** doesn't throw an error if the dir exists :)
cd ${workdir}

# this extracts the item number $SLURM_ARRAY_TASK_ID from the file of accnums
accnum=$(sed -n "$SLURM_ARRAY_TASK_ID"p ${accnum_file})
echo $accnum
input_file="${datadir}/${accnum}.flash.extendedFrags.fastq.gz"
echo $input_file
fasta_file="${datadir}/${accnum}.fasta.gz"
output_file="${outdir}/${accnum}.out"
# alternatively, just extract the input file as the item number $SLURM_ARRAY_TASK_ID in the data dir listing
# this alternative is less handy since we don't get hold of the isolated "accnum", which is very handy to name the srun step below :)
#input_file=$(ls "${datadir}/*.fastq.gz" | sed -n ${SLURM_ARRAY_TASK_ID}p)

# if the command below can't cope with compressed input
#srun gunzip "${input_file}.gz"

# because there are mutliple jobs running in // each output file needs to be made unique by post-fixing with $SLURM_ARRAY_TASK_ID and/or $accnum
#output_file="${workdir}/ABCjob.${SLURM_ARRAY_TASK_ID}.${accnum}.out"

#################################################################
# Start work
#module load seqkit blast #as required #done using singularity
PATH=$PATH:/proj/applied_bioinformatics/tools/ncbi-blast-2.15.0+-src

#change fastq to fasta
srun --job-name $accnum singularity exec meta.sif seqkit fq2fa $input_file --compress-level 5 -o $fasta_file 

#run blastn
zcat $fasta_file | srun --job-name $accnum blastn -db MedBioinfo/data/blast_db/refseq_viral_genomic -evalue 10 -perc_identity 80 -out $output_file -outfmt 6

#################################################################
# Clean up (eg delete temp files, compress output, recompress input etc)
#srun gzip ${input_file}
#srun gzip ${output_file}
echo END: `date`
