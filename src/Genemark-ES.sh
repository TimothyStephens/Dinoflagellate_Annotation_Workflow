source ../env.sh

export PERL5LIB=~/perl5/lib/perl5

run_cmd "perl ${GENEMARK}/gmes_petap.pl --ES --cores $NCPUS --v --sequence ${GENOME_NAME}.masked 1>&2> genemark.log"

# Convert the GeneMark-ES genemark.gtf file into genemark.gff3 for use in EvidenceModler. 
run_cmd "${MAKER}/genemark_gtf2gff3 genemark.gtf > genemark.gff3"

