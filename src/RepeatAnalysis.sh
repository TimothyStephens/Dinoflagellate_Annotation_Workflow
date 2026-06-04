source ../env.sh

#### Run Repeat Modeler.
## 

# Move to scratch space. Repeat Modeler creates a lot of tmp files.
run_cmd "cp ${GENOME_NAME} ${TMPDIR}"
run_cmd "cd ${TMPDIR}"

# Run Modeler
run_cmd "perl ${REPEATMODELER}/BuildDatabase -name ${GENOME_NAME}_db -engine ncbi ${GENOME_NAME} > BuildDatabase.out"
run_cmd "perl ${REPEATMODELER}/RepeatModeler -engine ncbi -pa ${NCPUS} -database ${GENOME_NAME}_db 1> RepeatModeler.sdtout 2> RepeatModeler.stderr"

# Combine repeat modeler and repeat masker libraries.
run_cmd "perl ${REPEATMASKER}/util/buildRMLibFromEMBL.pl ${REPEATMASKER}/Libraries/RepeatMaskerLib.embl > RepeatMasker.lib"
run_cmd "cp RM_*/consensi.fa* ."
run_cmd "cat consensi.fa.classified RepeatMasker.lib > ${GENOME_NAME}_CombinedRepeatLib.lib"

# Move back to working directory.
run_cmd "cp -r * ${PBS_O_WORKDIR}"
run_cmd "cd ${PBS_O_WORKDIR}"


#### Run Repeat Masker
## 
## If you wish to run Repeat Masker without a custom repeat database comment out the above
## Repeat Modeler commands and remove the "-lib ${GENOME_NAME}_CombinedRepeatLib.lib" option 
## from the Repeat Masker command below. 
run_cmd "perl ${REPEATMASKER}/RepeatMasker -lib ${GENOME_NAME}_CombinedRepeatLib.lib -e ncbi -gff -x -no_is -a -pa ${NCPUS} ${GENOME_NAME} 1> RepeatMasker.sdtout 2> RepeatMasker.stderr"

# SoftMask Genome
run_cmd "${BEDTOOLS}/maskFastaFromBed -soft -fi ${GENOME_NAME} -fo ${GENOME_NAME}.softmasked -bed ${GENOME_NAME}.out.gff"

# Get repeat features in gff3 format (used for EVM later on)
run_cmd "perl ${REPEATMASKER}/util/rmOutToGFF3.pl ${GENOME_NAME}.out > ${GENOME_NAME}.out.gff3"

# Model repeat landscape (not needed for annotation)
run_cmd "perl ${REPEATMASKER}/util/calcDivergenceFromAlign.pl -s ${GENOME_NAME}.divsum ${GENOME_NAME}.align"
run_cmd "perl ${REPEATMASKER}/util/createRepeatLandscape.pl -div ${GENOME_NAME}.divsum -g ${GENOME_SIZE} > ${GENOME_NAME}.html"

