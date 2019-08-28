#! /opt/pkg/latest/bin/perl
use strict;
use warnings;
use List::MoreUtils qw (uniq);

########################################################
## USAGE
##
my $USAGE =<<USAGE;

	Usage: EditAlignFile4RepeatedGenes.pl geneRepeatFamilies.ids Repeats.align > newRepeats.align
             
		geneRepeatFamilies.ids:	list of family IDs of multiple-copy genes
		Repeats.align:		file with repeat alignments
		newRepeats.align: 	output with reformated repeats
USAGE
#
######################################################

if ($#ARGV != 1 ) {
	print "$USAGE\n";
	exit;
}

# Store all repeat families that are actually repeated genes

my $repGenes = $ARGV[0]; 
open (RGEN, "$repGenes") or die "Couldn't open $repGenes\n";

my @repIDs;

while (my $l = <RGEN>){
	chomp $l;
	push @repIDs, $l;
}
close RGEN;

@repIDs = uniq(@repIDs);

# Replace the "Unknown" tag of families of repeated genes with "Gene"

my $align = $ARGV[1]; # *.align file
open(ALN, $align) or die "Couldn't open $align\n";

while(my $l = <ALN>){
	chomp $l;
	if ($l =~ m/.+\s(.+)\#Unknown/){
		if (grep /^$1$/, @repIDs){
			my $nl = $l =~ s/Unknown/Gene/r;
			print "$nl\n";
		}else{
			print "$l\n";
		}
	}else{
		print "$l\n";
	}
}
close ALN;
