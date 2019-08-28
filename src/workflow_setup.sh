#!/bin/bash
## 
## Set up script for Dino annotation pipeline.
## 
## This script will set up the directory scructure and any queue submission scripts 
## required by this annotation file. Requires that the env.sh file be in the directory
## where this script is executed (e.g. env.sh in the place where you wish to start the 
## annotation pipeline). 
## 
## NOTE: The only part of this script you will need to change is the 'PBS_header' function
##       as this will chnage depending on the PBS system you are using.

# Exit pipeline if error found
set -o errexit

# Get absolute location this script - follows symlinks
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SRC="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Directory from where the script is called.
thisdir=`readlink -f $PWD`


# Script usage
cmd=$1
if [ $# -ne 1 ] || [ $1 == '-h' ] || [ $1 == '--help' ]; then
        echo; echo "Usage: $(basename $0) <command>"
        echo "command: command to be run. Options: all, trinitygg, 
		trinitydn, seqclean, pasa, blast2db, 
		repeats, hhblits, transposonpsi, 
		cdhits, goldengenes, genemark, 
		snap, augustus, maker_protein, 
		evidencemodeler"
        exit
fi


# Check if env.sh is present in curent directory
if [ -e env.sh ]; then
	source env.sh
else
	echo; echo "env.sh not found! Please move to a directory with this file or copy a new one from $SRC/env.sh"
	echo
	exit
fi




#############################################
## Set up TrinityGG
#############################################
if [ $cmd == "trinitygg" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up Trinity GG"
	
	mkdir TRINITY_GG
	cd TRINITY_GG/
	
	# Link data
	ln -s ../${GENOME_NAME}
	
	# Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/TrinityGG.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_TrinityGG/" \
		-e "s/__NCPUS__/24/" \
		-e "s/__MEM__/240GB/" \
		-e "s/__VMEM__/240GB/" \
		-e "s/__WALLTIME__/120:00:00/" \
		-e "s/__TRINITY_MEM__/240G/" > run_TrinityGG.sh
	
	cat $SRC/PBS_header.sh ${SRC}/Examine_Strand_Specificity.sh | sed \
                -e "s/__JOB_NAME__/${PREFIX}_TrinityGG_Examine_Strand_Specificity/" \
                -e "s/__NCPUS__/24/" \
                -e "s/__MEM__/60GB/" \
                -e "s/__VMEM__/60GB/" \
                -e "s/__WALLTIME__/120:00:00/" \
                -e "s/__TRINITY_ASSEMBLY__/Trinity-GG.fasta/" > run_Examine_Strand_Specificity.sh
	
	cd ../
	echo "... done!"
fi



#############################################
## Set up TrinityDN
#############################################
if [ $cmd == "trinitydn" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up Trinity DN"
	
	mkdir TRINITY_DN
	cd TRINITY_DN/
	
	# Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/TrinityDN.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_TrinityDN/" \
                -e "s/__NCPUS__/24/" \
                -e "s/__MEM__/60GB/" \
                -e "s/__VMEM__/60GB/" \
                -e "s/__WALLTIME__/120:00:00/" \
		-e "s/__TRINITY_MEM__/240G/" > run_TrinityDN.sh
	
	cat $SRC/PBS_header.sh ${SRC}/Examine_Strand_Specificity.sh | sed \
                -e "s/__JOB_NAME__/${PREFIX}_TrinityDN_Examine_Strand_Specificity/" \
                -e "s/__NCPUS__/24/" \
                -e "s/__MEM__/240GB/" \
                -e "s/__VMEM__/240GB/" \
                -e "s/__WALLTIME__/120:00:00/" \
                -e "s/__TRINITY_ASSEMBLY__/Trinity-DN.fasta/" > run_Examine_Strand_Specificity.sh
	
	cd ../
	echo "... done!"
fi



#############################################
## Set up SeqClean
#############################################
if [ $cmd == "seqclean" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up SeqClean"

	mkdir SEQCLEAN
        cd SEQCLEAN/

        # Link data
        ln -s ../TRINITY_DN/Trinity-DN.fasta .
	ln -s ../TRINITY_GG/Trinity-GG.fasta .

        # Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/SeqClean.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_SeqClean/" \
                -e "s/__NCPUS__/4/" \
                -e "s/__MEM__/24GB/" \
                -e "s/__VMEM__/24GB/" \
                -e "s/__WALLTIME__/4:00:00/" > run_SeqClean.sh
	
        cd ../
	echo "... done!"
fi



#############################################
## Set up PASA
#############################################
if [ $cmd == "pasa" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up PASA"

        mkdir PASA
        cd PASA/

        # Link data
	ln -s ../${GENOME_NAME}
        ln -s ../SEQCLEAN/transcripts.fasta .
        ln -s ../SEQCLEAN/transcripts.fasta.cidx .
	ln -s ../SEQCLEAN/transcripts.fasta.clean .
	ln -s ../SEQCLEAN/transcripts.fasta.cln .

        # Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/PASA.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_PASA/" \
                -e "s/__NCPUS__/8/" \
                -e "s/__MEM__/48GB/" \
                -e "s/__VMEM__/48GB/" \
                -e "s/__WALLTIME__/72:00:00/" > run_PASA.sh
	
	cat $SRC/PASA_alignAssembly.config > alignAssembly.config
	chmod +x alignAssembly.config
	
        cd ../
	echo "... done!"
fi



#############################################
## Set up BLAST2DB
#############################################
if [ $cmd == "blast2db" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up BLAST2DB"

        mkdir BLAST2DB
        cd BLAST2DB/

        # Link data
	ln -s ../PASA/${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep .
	
        # Construct submission script
	cat $SRC/PBS_array_header.sh ${SRC}/BLAST_Batch.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_BLAST/" \
                -e "s/__NCPUS__/8/" \
                -e "s/__MEM__/24GB/" \
                -e "s/__VMEM__/24GB/" \
                -e "s/__WALLTIME__/168:00:00/" \
		-e 's/__ARRAYSIZE__/50/' > run_BLAST.sh
	
        cd ../
	echo "... done!"
fi



#############################################
## Set up Repeat Analysis
#############################################
if [ $cmd == "repeats" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up Repeat Masker/Modeler"

        mkdir REPEAT_ANALYSIS
        cd REPEAT_ANALYSIS/

        # Link data
	ln -s ../${GENOME_NAME}
	
        # Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/RepeatAnalysis.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_RepeatAnalysis/" \
                -e "s/__NCPUS__/24/" \
                -e "s/__MEM__/80GB/" \
                -e "s/__VMEM__/80GB/" \
                -e "s/__WALLTIME__/168:00:00/" > run_RepeatAnalysis.sh
	
        cd ../
	echo "... done!"
fi



#############################################
## Set up HHBLITS
#############################################
if [ $cmd == "hhblits" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up HHBLITS"

	mkdir HHBLITS
	cd HHBLITS/
	
	# Link data
	ln -s ../BLAST2DB/${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep.complete_only.filtered.top_coverage.faa .
	
	# Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/HHBLITS.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_HHBLITS/" \
                -e "s/__NCPUS__/24/" \
                -e "s/__MEM__/24GB/" \
                -e "s/__VMEM__/24GB/" \
                -e "s/__WALLTIME__/48:00:00/" > run_HHBLITS.sh
	
	cd ../
	echo "... done!"
fi



#############################################
## Set up TransposonPSI
#############################################
if [ $cmd == "transposonpsi" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up TransposonPSI"

        mkdir TRANSPOSON_PSI
        cd TRANSPOSON_PSI/

        # Link data
	ln -s ../BLAST2DB/${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep.complete_only.filtered.top_coverage.faa .
	
        # Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/TransposonPSI.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_TransposonPSI/" \
                -e "s/__NCPUS__/1/" \
                -e "s/__MEM__/24GB/" \
                -e "s/__VMEM__/24GB/" \
                -e "s/__WALLTIME__/48:00:00/" > run_TransposonPSI.sh
	
        cd ../
fi



#############################################
## Set up CD-Hits
#############################################
if [ $cmd == "cdhits" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up CD-Hits"

        mkdir CDHITS
        cd CDHITS/

        # Link data
	ln -s ../BLAST2DB/${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep.complete_only.filtered.top_coverage.faa .

        # Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/CD_HIT.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_CD_HIT/" \
                -e "s/__NCPUS__/1/" \
                -e "s/__MEM__/8GB/" \
                -e "s/__VMEM__/8GB/" \
                -e "s/__WALLTIME__/1:00:00/" \
		-e "s/@CDHITS_MEM@/8000/" > run_CD_HIT.sh
	
        cd ../
	echo "... done!"
fi



#############################################
## Set up GoldenGenes
#############################################
if [ $cmd == "goldengenes" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up GoldenGenes"

        mkdir GOLDEN_GENES
        cd GOLDEN_GENES/

        # Link data
        ln -s ../REPEAT_ANALYSIS/${GENOME_NAME}.masked .
	ln -s ../REPEAT_ANALYSIS/${GENOME_NAME}.softmasked .
	ln -s ../CDHITS/${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep.complete_only.filtered.top_coverage.final.faa.cdhit75.ids CD-HIT.ids.txt

        # Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/GoldenGenes.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_GoldenGenes/" \
                -e "s/__NCPUS__/24/" \
                -e "s/__MEM__/60GB/" \
                -e "s/__VMEM__/60GB/" \
                -e "s/__WALLTIME__/48:00:00/" > run_GoldenGenes.sh
	
        cd ../
	echo "... done!"
fi



#############################################
## Set up GeneMark-ES
#############################################
if [ $cmd == "genemark" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up GeneMark-ES"
	
        mkdir GENEMARK-ES
        cd GENEMARK-ES/
	
        # Link data
        ln -s ../REPEAT_ANALYSIS/${GENOME_NAME}.masked .
	
        # Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/Genemark-ES.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_Genemark-ES/" \
                -e "s/__NCPUS__/24/" \
                -e "s/__MEM__/24GB/" \
                -e "s/__VMEM__/24GB/" \
                -e "s/__WALLTIME__/48:00:00/" > run_Genemark-ES.sh
	
        cd ../
	
	# Check if gm_key is present in users home directory
	if [ -e ~/.gm_key ]; then
		echo ".gm_key found in your home directory"
	else
		echo ".gm_key not found in your home directory. Adding it now!"
		cp $SRC/gm_key ~/.gm_key
	fi 
	echo "... done!"
fi


#############################################
## Set up SNAP
#############################################
if [ $cmd == "snap" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up SNAP"

        mkdir SNAP
        cd SNAP/

        # Link data
        ln -s ../REPEAT_ANALYSIS/${GENOME_NAME}.softmasked .
	ln -s ../GOLDEN_GENES/final_golden_genes.gff3.nr.golden.zff .
	
        # Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/SNAP.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_SNAP/" \
                -e "s/__NCPUS__/24/" \
                -e "s/__MEM__/24GB/" \
                -e "s/__VMEM__/24GB/" \
                -e "s/__WALLTIME__/48:00:00/" > run_SNAP.sh
	
        cd ../
	echo "... done!"
fi



#############################################
## Set up AUGUSTUS
#############################################
if [ $cmd == "augustus" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up AUGUSTUS"
	
        mkdir AUGUSTUS
        cd AUGUSTUS/
	
        # Link data
        ln -s ../GOLDEN_GENES/final_golden_genes.gff3.nr.golden.optimization.good.gb .
	ln -s ../GOLDEN_GENES/final_golden_genes.gff3.nr.golden.train.good.gb .
	
        # Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/Augustus_Training.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_Augustus_Training/" \
                -e "s/__NCPUS__/8/" \
                -e "s/__MEM__/24GB/" \
                -e "s/__VMEM__/24GB/" \
                -e "s/__WALLTIME__/48:00:00/" > run_Augustus_Training.sh
	
	# 
	mkdir PREDICTION
        cd PREDICTION/
	
	# Construct submission script
        ln -s ../../REPEAT_ANALYSIS/${GENOME_NAME}.softmasked .
	cat $SRC/PBS_array_header.sh ${SRC}/Augustus_Prediction.sh | sed \
                -e "s/__JOB_NAME__/${PREFIX}_Augustus_Prediction/" \
                -e "s/__NCPUS__/1/" \
                -e "s/__MEM__/24GB/" \
                -e "s/__VMEM__/24GB/" \
                -e "s/__WALLTIME__/72:00:00/" \
                -e 's/__ARRAYSIZE__/100/' > run_Augustus_Prediction.sh
	
	cd ../../
	echo "... done!"
fi



#############################################
## Set up MAKER_PROTEIN
#############################################
if [ $cmd == "maker_protein" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up MAKER_PROTEIN"

        mkdir MAKER_PROTEIN
        cd MAKER_PROTEIN/

        # Link data
        ln -s ../${GENOME_NAME} .
	cp ${SRC}/MAKER_PROTEIN_maker_bopts.ctl .
	cp ${SRC}/MAKER_PROTEIN_maker_exe.ctl .
	cp ${SRC}/MAKER_PROTEIN_maker_opts.ctl .
	cp ${SRC}/MAKER_PROTEIN_setup_maker_Batch.sh . 

        # Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/MAKER_PROTEIN_run_MAKER.sh | sed \
		-e "s/__JOB_NAME__/__NAME__/" \
                -e "s/__NCPUS__/__NCPUS__/" \
                -e "s/__MEM__/4GB/" \
                -e "s/__VMEM__/4GB/" \
                -e "s/__WALLTIME__/24:00:00/" > MAKER_PROTEIN_run_MAKER.sh
	chmod +x MAKER_PROTEIN_run_MAKER.sh
	
        cd ../
	echo "... done!"
fi



#############################################
## Set up EvidenceModeler
#############################################
if [ $cmd == "evidencemodeler" ] || [ $cmd == "all" ]; then
	echo; echo "Setting up EvidenceModeler"

        mkdir EVIDENCE_MODELER
        cd EVIDENCE_MODELER/

        # Link data
        ln -s ../${GENOME_NAME} .
	ln -s ../GENEMARK-ES/genemark.gff3 .
	ln -s ../SNAP/PREDICT/snap.gff3 .
	ln -s ../AUGUSTUS/PREDICTION/augustus.gff3 .
	ln -s ../MAKER_PROTEIN/genome.all.maker.gff .
	ln -s ../PASA/${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.genome.gff3 .
	ln -s ../REPEAT_ANALYSIS/${GENOME_NAME}.out.gff .
	cp ${SRC}/evm_weights.txt .
	
        # Construct submission script
	cat $SRC/PBS_header.sh ${SRC}/EVidenceModeler.sh | sed \
		-e "s/__JOB_NAME__/${PREFIX}_EVidenceModeler/" \
                -e "s/__NCPUS__/24/" \
                -e "s/__MEM__/48GB/" \
                -e "s/__VMEM__/48GB/" \
                -e "s/__WALLTIME__/48:00:00/" > run_EVidenceModeler.sh
	
        cd ../
	echo "... done!"
fi



#############################################
## Set up EvidenceModeler
#############################################
if [ $cmd == "evidencemodeler" ] || [ $cmd == "all" ]; then
	echo; echo "Checking executables"
	#echo -e "Samtools:\t" `command -v samtool || echo "Not found"`
fi







