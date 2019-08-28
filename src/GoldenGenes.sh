source ../env.sh

export PATH=${CDBFASTA}:$PATH
export PATH=${BLAST}:$PATH
export PATH=${JAMG_PATH}/3rd_party/exonerate-2.2.0-x86_64/bin:$PATH
export PATH=${AUGUSTUS}/bin:$PATH
export PATH=${AUGUSTUS}/scripts:$PATH
export PATH=${SNAP}:$PATH
export PATH=${TRINITY}/trinity-plugins/BIN:$PATH
export PATH=${EMBOSS}:$PATH
export PATH=${GMAP}:$PATH

export PERL5LIB=${PREPARE_GOLDEN}/PerlLib/:$PERL5LIB
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

