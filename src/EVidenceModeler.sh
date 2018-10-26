source ../env.sh

mkdir PARTITIONS_EVM
cd PARTITIONS_EVM/
ln -s ../abinitio_gene_predictions.gff3 .
ln -s ../repeats.gff3 .
ln -s ../evm_weights.txt .
ln -s ../${GENOME_NAME} .

run_cmd "${EVIDENCEMODELER}/EvmUtils/partition_EVM_inputs.pl --genome ${GENOME_NAME} --gene_predictions abinitio_gene_predictions.gff3 --repeats repeats.gff3 --segmentSize 50000000 --overlapSize 10000 --partition_listing partitions_list.out"

run_cmd "${EVIDENCEMODELER}/EvmUtils/write_EVM_commands.pl --genome ${GENOME_NAME} --gene_predictions abinitio_gene_predictions.gff3 --repeats repeats.gff3 --weights `pwd`/evm_weights.txt --output_file_name evm.out  --partitions partitions_list.out >  commands.list"

run_cmd "/home/timothy.stephens/PROGRAMS/trinityrnaseq-2.1.1/trinity-plugins/parafly-code/bin/ParaFly -v -CPU ${NCPUS} -c commands.list -failed_cmds commands.list.failed"

run_cmd "${EVIDENCEMODELER}/EvmUtils/recombine_EVM_partial_outputs.pl --partitions partitions_list.out --output_file_name evm.out"

run_cmd "${EVIDENCEMODELER}/EvmUtils/convert_EVM_outputs_to_GFF3.pl  --partitions partitions_list.out --output evm.out --genome ${GENOME_NAME}"
cd ../
find PARTITIONS_EVM/ -name evm.out.gff3 -exec cat '{}' \; >> ${GENOME_NAME}.evm.gff3


## Get CDS and Proteins. 
# 
# sed 's@EVM.evm.TU@EVM.evm.TU@' will remove ^\ (file seperator) character from EVM^\evm.TU to EVM.evm.TU
# 
run_cmd "${EVIDENCEMODELER}/EvmUtils/gff3_file_to_proteins.pl ${GENOME_NAME}.evm.gff3 ${GENOME_NAME} CDS | sed 's@EVM.evm.TU@EVM.evm.TU@' > ${GENOME_NAME}.evm.cds.fna"
run_cmd "${EVIDENCEMODELER}/EvmUtils/gff3_file_to_proteins.pl ${GENOME_NAME}.evm.gff3 ${GENOME_NAME} prot | sed 's@EVM.evm.TU@EVM.evm.TU@' > ${GENOME_NAME}.evm.protein.faa"

