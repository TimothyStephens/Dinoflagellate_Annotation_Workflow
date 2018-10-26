source ../env.sh

# Clean up.
# rm -r *.masked_dir *.softmasked_dir *.softmasked.* GoldenGenes.* *.fasta.transdecoder.cds.gmap *.fasta.transdecoder.cds_vs_genome.* *.fasta.transdecoder.genome.gff3.nr.log *.assemblies.fasta.transdecoder.gff3.* *.assemblies.fasta.transdecoder.genome.gff3.nr final_golden_genes.gff3.* run_exonerate_commands.cmd*
# 
# rm -r ${GENOME_NAME}.masked_dir/ ${GENOME_NAME}.softmasked_dir/ ${GENOME_NAME}.softmasked.gmap/ PASA.assemblies.fasta.transdecoder.cds.gmap/ PASA.assemblies.fasta.transdecoder.gff3.contigs_queries/

export PATH=${CDBFASTA}:$PATH
export PATH=${BLAST}:$PATH
export PATH=${JAMG_PATH}/3rd_party/exonerate-2.2.0-x86_64/bin:$PATH
export PATH=${AUGUSTUS}/bin:$PATH
export PATH=${AUGUSTUS}/scripts:$PATH
export PATH=${SNAP}:$PATH
export PATH=${TRINITY}/trinity-plugins/BIN:$PATH
export PATH=${EMBOSS}:$PATH
export PATH=${GMAP}:$PATH

export PERL5LIB=${PREPARE_GOLDEN}/PerlLib/
export PATH=${PREPARE_GOLDEN}:$PATH

${PREPARE_GOLDEN}/prepare_golden_genes_for_predictors_GA_DonorSite.pl \
        -genome ${GENOME_NAME}.masked \
        -softmasked ${GENOME_NAME}.softmasked \
        -no_gmap -same_species -intron $MAX_INTRON_LENGTH -cpu $NCPUS -norefine -complete -no_single -verbose \
        -pasa_gff *.assemblies.fasta.transdecoder.gff3 \
        -pasa_peptides *.assemblies.fasta.transdecoder.pep \
        -pasa_cds *.assemblies.fasta.transdecoder.cds \
        -pasa_genome *.assemblies.fasta.transdecoder.genome.gff3 \
        -pasa_assembly *.assemblies.fasta

