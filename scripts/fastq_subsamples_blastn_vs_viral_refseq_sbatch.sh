#!/bin/bash

#SBATCH --ntasks=1                   # nb of *tasks* to be run in // (usually 1), this task can be multithreaded (see cpus-per-task)
#SBATCH --nodes=1                    # nb of nodes to reserve for each task (usually 1)
#SBATCH --cpus-per-task=4            # nb of cpu (in fact cores) to reserve for each task /!\ job killed if commands below use more cores
#SBATCH --job-name=MedBioinfo        # name of the task as displayed in squeue & sacc, also encouraged as srun optional parameter

#################################################################
# Preparing work (cd to working dir, get hold of input data, convert/un-compress input data when needed etc.)
workdir="/proj/applied_bioinformatics/users/x_libja"
datadir="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/data/merged_pairs"
dbdir="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/data/blast_db"
outdir="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/blastn_sample"
#accnum_file="/proj/applied_bioinformatics/users/x_libja/MedBioinfo/analyses/file_of_acc_nums.txt"

echo START: `date`

#module load seqkit blast #as required #done using singularity
PATH=$PATH:/proj/applied_bioinformatics/tools/ncbi-blast-2.15.0+-src

#ls $datadir/S*.fasta.gz | zcat | srun blastn -db MedBioinfo/data/blast_db/refseq_viral_genomic -evalue 10 -perc_identity 80 -o 

zcat $datadir/Sample100.fasta.gz | srun blastn -db MedBioinfo/data/blast_db/refseq_viral_genomic -evalue 10 -perc_identity 80 -out $outdir/Sample100.out -outfmt 6

zcat $datadir/Sample1000.fasta.gz | srun blastn -db MedBioinfo/data/blast_db/refseq_viral_genomic -evalue 10 -perc_identity 80 -out $outdir/Sample1000.out -outfmt 6

zcat $datadir/Sample10000.fasta.gz | srun blastn -db MedBioinfo/data/blast_db/refseq_viral_genomic -evalue 10 -perc_identity 80 -out $outdir/Sample10000.out -outfmt 6

echo END: `date`
