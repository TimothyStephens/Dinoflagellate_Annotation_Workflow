#!/bin/bash
## 
## Program, database and data/variables used during the Dino annotation pipeline.
## 
## 
## 
## 




###############
## Variables ##
###############

export GENOME_NAME=scaffolds_minlen1kbp.fa # Name of genome file.
export PREFIX=Test_Run #Prefix to use for job names

export SPECIES=$PREFIX # Species for Augustus

## Transcript data
# Comma seperate multiple read file (fill path). Multiple fwd/rev datasets must corrospond in comma seperated list.
# Fwd/Rev & single reads.
export TRANSCRIPTOME_READS_1=/path/to/reads/Paired_R1.fastq.gz
export TRANSCRIPTOME_READS_2=/path/to/reads/Paired_R2.fastq.gz
#export TRANSCRIPTOME_SINGLE_READS=

# Assembled transcripts (in fasta format) i.e. IsoSeq polished transcripts or 454 isotigs. Comma seperate multiple file.
export TRANSCRIPTS=

export MAX_INTRON_LENGTH=70000 # maximum size of intron.

# Used for Repeat landscape construction (use contig size not scaffold size)
export GENOME_SIZE=



###############
## Databases ##
###############
export DATABASES=/shares/common/groups/Group-Ragan/Dinoflagellate_Annotation_Workflow/databases
export UNIVEC=${DATABASES}/UNIVEC/BUILD_10.0/UniVec_Core
export BLASTX_PROTEIN_DB=${DATABASES}/REFSEQ_88_COMPLETE_SYM_PEP/RefSeq_complete_88.faa
export PROTEINS_4_PREDICTION=${DATABASES}/SwissProt27062018_SymPep/SwissProt_SymPep.fasta
export TRANSPOSON_DB_HHBLITS=${DATABASES}/transposon_db_hhblits/transposons



##############
## Programs ##
##############
export PROGRAMS=/shares/common/groups/Group-Ragan/Dinoflagellate_Annotation_Workflow/programs
export SCRIPTS=/shares/common/groups/Group-Ragan/Dinoflagellate_Annotation_Workflow/scripts

#export AUGUSTUS=${PROGRAMS}/augustus-3.1-modified
export BBMAP=${PROGRAMS}/bbmap
export BEDTOOLS=/opt/Modules/bedtools2/2.24.0 # Avalible on most systems
export BLAST=/opt/Modules/blast+/2.4.0/bin # Avalible on most systems
export BLAT=${PROGRAMS}/blat_v36x2
export BLASTALL=${PROGRAMS}/blast-2.2.26/bin
export BOWTIE2=${PROGRAMS}/bowtie2-2.3.4.1-linux-x86_64
export CDBFASTA=${PROGRAMS}/cdbfasta_v1
export CDHIT=${PROGRAMS}/cd-hit-v4.6.8-2017-1208
export EMBOSS=${PROGRAMS}/EMBOSS-6.6.0/bin
export EVIDENCEMODELER=${PROGRAMS}/EVidenceModeler-1.1.1-modified
export GENEMARK=${PROGRAMS}/gm_et_linux_64/gmes_petap
export GMAP=${PROGRAMS}/gmap-2018-07-04/bin
export PREPARE_GOLDEN=${PROGRAMS}/Prepare_Golden_Genes
export JAMG_PATH=${PROGRAMS}/JAMg
export HHSUITE=${PROGRAMS}/hhsuite-2.0.16-linux-x86_64/bin
export JELLYFISH=${PROGRAMS}/Jellyfish-2.2.10/bin
#export MAKER=${PROGRAMS}/maker/bin
export PASA=${PROGRAMS}/PASApipeline-v2.3.3-modified
export REPEATMODELER=${PROGRAMS}/RepeatModeler-open-1.0.11
export REPEATMASKER=${PROGRAMS}/RepeatMasker-open-4-0-7
export SALMON=${PROGRAMS}/Salmon-0.9.1/bin
export SAMTOOLS=/opt/Modules/samtools/1.3/bin # Avalible on most systems
export SNAP=${PROGRAMS}/SNAP_ret20Jul2018
export TRANSPOSON_PSI=${PROGRAMS}/TransposonPSI_modified
export TRINITY=${PROGRAMS}/Trinity-v2.6.6



export AUGUSTUS=~/PROGRAMS/augustus-3.1-modified
export MAKER=~/PROGRAMS/maker-modified/bin



## Function to help keep track of progress. 
function run_cmd(){
	echo
	echo "`date`      CMD: $@"
	eval "$@"
}


