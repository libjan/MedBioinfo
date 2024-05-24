#!/bin/bash
date
echo "script start: download and initial sequencing read quality control"


#my singularity environment image is in my user folder, hence it was easier to run most of the following commands from the directory below
cd /proj/applied_bioinformatics/users/x_libja

#downloading
# test run
# singularity exec meta.sif fastq-dump --accession "ERR6913168" -X 10 --split-3 --gzip --readids --disable-multithreading --outdir "MedBioinfo/data/sra_fastq"

#downloading all 10 samples using xargs
cat MedBioinfo/analyses/x_libja_run_accessions.txt | srun --cpus-per-task=1 --time=00:30:00 singularity exec meta.sif xargs -I {} fastq-dump --accession {}  --split-3 --gzip --readids --disable-multithreading --outdir "MedBioinfo/data/sra_fastq"

#counting the number of  reads
for file in MedBioinfo/data/sra_fastq/*.fastq.gz; do echo "$file: $(( $(zcat "$file" | wc -l) / 4 ))"; done

#to estimate type of quality score, looking at the output files - these encode ASCII values that match with the phred+33 format
#zcat "MedBioinfo/data/sra_fastq/ERR6913168_1.fastq.gz" | head -n 50
#but there are also tools to determine this more precisely, will also be confirmed by FastQC

#counting number of reads using seqkit
find -name "*.fastq.gz" | srun --cpus-per-task=1 --time=00:05:00 singularity exec meta.sif xargs -I {} seqkit --threads 1 stats {}

#check files for dupication removal - checking one test one
srun --cpus-per-task=1 --time=00:10:00 singularity exec meta.sif seqkit rmdup -s -i ./MedBioinfo/data/sra_fastq/ERR6913171_2.fastq.gz -D duplicated.test.txt 
#looking at the file, there are plenty of duplicate sequences - duplicates have not been removed
#may not be desirable for metagenomics to remove those

#tryin whether adaptors have been trimmed                                                            
zcat ./MedBioinfo/data/sra_fastq/ERR6913171_1.fastq.gz | srun --cpus-per-task=1 --time=00:10:00 singularity exec meta.sif seqkit amplicon -F "AGATCGGAAGAGCACACGTCTGAACTCCAGTCA" -R "AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT" --bed > primertrim.txt
# empty output
#including -u flagg to write unmatched and verify that the command is working
 zcat ./MedBioinfo/data/sra_fastq/ERR6913171_1.fastq.gz | srun --cpus-per-task=1 --time=00:10:00 singularity exec meta.sif seqkit amplicon -F "AGATCGGAAGAGCACACGTCTGAACTCCAGTCA" -R "AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT" --bed -u > primertrim.txt
#command is working

#trying with shortened adaptors - still no matched output
 zcat ./MedBioinfo/data/sra_fastq/ERR6913171_1.fastq.gz | srun --cpus-per-task=1 --time=00:10:00 singularity exec meta.sif seqkit amplicon -F "AGCACACGTCTGAACTCCAGTCA" -R "AGATCGGAAGAGCGTCGTGTAGG" --bed > primertrim.txt

echo "Sequences are already trimmed."

#fastqc
#test on two files
srun --cpus-per-task=2 --time=00:10:00 singularity exec meta.sif fastqc  --threads 2 --noextract -o ./MedBioinfo/analyses/fastqc ./MedBioinfo/data/sra_fastq/ERR6913171_1.fastq.gz ./MedBioinfo/data/sra_fastq/ERR6913171_2.fastq.gz

#expand to more files
cat MedBioinfo/analyses/x_libja_run_accessions.txt | srun --cpus-per-task=2 --time=00:30:00 singularity exec meta.sif xargs -I {} fastqc  --threads 2 --noextract -o ./MedBioinfo/analyses/fastqc ./MedBioinfo/data/sra_fastq/{}_1.fastq.gz ./MedBioinfo/data/sra_fastq/{}_2.fastq.gz

echo "FastQC ran. Based on the reports, low quality bases were excluded and adapters were trimmed."

#merging reads
#test run
srun --cpus-per-task=2 singularity exec meta.sif flash --threads=2 --output-prefix=ERR6913171.flash --output-directory=./MedBioinfo/data/merged_pairs --compress MedBioinfo/data/sra_fastq/ERR6913171_1.fastq.gz MedBioinfo/data/sra_fastq/ERR6913171_2.fastq.gz 2>&1 | tee -a MedBioinfo/analyses/x_libja_flash2.log
echo "Merging of test file suggests that the max-overlap parameter could be increased as there are high levels that overlap more. Over 90% of pairs were combined."

#checking length with seqkit
srun --cpus-per-task=1 singularity exec meta.sif seqkit stats MedBioinfo/data/merged_pairs/ERR6913171.flash.extendedFrags.fastq.gz

echo "Histogram suggests that the average read length may be below 150 bp."

#merging for all files
srun --cpus-per-task=2 singularity exec meta.sif xargs -a MedBioinfo/analyses/x_libja_run_accessions.txt -I {} -n 1 flash --threads=2 --output-prefix={}.flash --output-directory=./MedBioinfo/data/merged_pairs --compress MedBioinfo/data/sra_fastq/{}_1.fastq.gz MedBioinfo/data/sra_fastq/{}_2.fastq.gz 2>&1 | tee -a MedBioinfo/analyses/x_libja_flash2.log

#checking total base numbers per sample in all fastq files
find -name "*.fastq.gz" | srun --cpus-per-task=1 --time=00:05:00 singularity exec meta.sif xargs -I {} seqkit --threads 1 stats {}
echo "Less base pairs per sample than before merging due to elimination of some redundancies."

#PhiX contamination
singularity exec meta.sif efetch -db nuccore -id NC_001422 -format fasta > MedBioinfo/data/reference_seqs/PhiX_NC_001422.fna

# head MedBioinfo/data/reference_seqs/PhiX_NC_001422.fna 
mkdir MedBioinfo/data/bowtie2_DBs
srun singularity exec meta.sif bowtie2-build -f MedBioinfo/data/reference_seqs/PhiX_NC_001422.fna MedBioinfo/data/bowtie2_DBs/PhiX_bowtie2_DB

#allignment
srun --cpus-per-task=8 singularity exec meta.sif bowtie2 -x MedBioinfo/data/bowtie2_DBs/PhiX_bowtie2_DB -U MedBioinfo/data/merged_pairs/ERR*.extendedFrags.fastq.gz -S MedBioinfo/analyses/bowtie/x_libja_merged2PhiX.sam --threads 8 --no-unal 2>&1 | tee MedBioinfo/analyses/bowtie/x_libja_bowtie_merged2PhiX.log
# reported no alignments

echo "N aligned sequences to PhiX"

#SARS-CoV-2
singularity exec meta.sif efetch -db nuccore -id NC_045512 -format fasta > MedBioinfo/data/reference_seqs/SARS-CoV-2_NC_045512.fna

srun singularity exec meta.sif bowtie2-build -f MedBioinfo/data/reference_seqs/SARS-CoV-2_NC_045512.fna MedBioinfo/data/bowtie2_DBs/SARS-CoV-2_bowtie2_DB

srun --cpus-per-task=8 singularity exec meta.sif bowtie2 -x MedBioinfo/data/bowtie2_DBs/SARS-CoV-2_bowtie2_DB -U MedBioinfo/data/merged_pairs/ERR*.extendedFrags.fastq.gz -S MedBioinfo/analyses/bowtie/x_libja_merged2SARS-CoV-2.sam --threads 8 --no-unal 2>&1 | tee MedBioinfo/analyses/bowtie/x_libja_bowtie_merged2SARS-CoV-2.log

echo "4 reads aligned.ls"

#multiqc
srun singularity exec meta.sif multiqc --force --title "x_libja sample sub-set" MedBioinfo/data/merged_pairs/ MedBioinfo/analyses/fastqc/ MedBioinfo/analyses/x_libja_flash2.log MedBioinfo/analyses/bowtie/


date
echo "script end."

