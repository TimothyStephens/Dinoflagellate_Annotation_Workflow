#! /opt/pkg/latest/bin/perl
use strict;
use warnings;
use Bio::Seq;
use Bio::SeqIO;
use List::MoreUtils qw (uniq);

########################################################
## USAGE
##
my $USAGE =<<USAGE;

	Usage: GeneStats.pl CDS.fa EVM.gff3 Genome.fa
	
		CDS.fa:  CDS seq of genes
                Gene.gff3:  Gff of genes (EVM output)
                Genome.fa:  Genome seq
USAGE
#
######################################################

#print "@ARGV";
if ($#ARGV != 2 ) {
	print "$USAGE\n";
	exit;
}

my $genes = $ARGV[0]; # Genes fasta
my $gff = $ARGV[1]; # EVM GFF3 annotation
my $genome = $ARGV[2]; # Genome fasta

#Store all gene sequences in hash and get gene lengths and average
my $seqio_obj = Bio::SeqIO->new(-file => $genes, -format => "fasta" );

my @CDSlen;
my $totalCDSlen = 0;

while (my $seq_obj = $seqio_obj->next_seq){
	my $l = $seq_obj->length;
	$totalCDSlen = $totalCDSlen + $l;
	push @CDSlen, $l;
}

my $numCDS = scalar @CDSlen; 
my $avCDSlen = $totalCDSlen / $numCDS;

print "Number of CDS:\t$numCDS\n";
print "Average CDS length:\t$avCDSlen\n";

#Store all genome sequences in hash
my $genomeio_obj = Bio::SeqIO->new(-file => $genome, -format => "largefasta" );
my %GNM;
while ( my $genome_obj = $genomeio_obj->next_seq ){
	my $id = $genome_obj->display_id;
	my $seq = $genome_obj->seq;
	$GNM{$id} = $seq;
}

my $numSeq = keys %GNM;
print "Number of sequences in genome:\t$numSeq\n";

# Parse GFF to extract the relevant info:

my %GenLen; # Gene (CDS + introns) length
my %GenEx; # Exons per gene
my @ExLn; # Exons length
my $IntrGen = 0;# Genes with introns
my %IntrSt; # Intron start
my %IntrEnd; #Intron end
my @IntrDon; # Splice donors
my @IntrAcc; # Splice acceptors
my @InterGenLn; # Intergenic region length

open(GFF, $gff) or die "Couldn't open $gff\n";

my %GenOr;
my $scaff = '';
my %InterGenSt;
my %InterGenEnd;
my $TotInterGenLn = 0;
my $numInterGen = 0;
my $GenID = '';
my $IntrCount = 0;
my %ExScaff;
my %GenScaff;

while(my $l = <GFF>){
	chomp $l;
	my @items = split /\t/, $l;
	if (scalar @items == 9){
		if ($items[2] eq "gene"){
			if ($items[8] =~ m/ID\=(.+)\;Name\=/){
				$GenID = $1;
				$GenScaff{$GenID} = $items[0];
				$GenLen{$GenID} = $items[4] - $items[3] + 1; 
			}else{
				print "Not matched found for Gene ID\n";
			}
			$GenEx{$GenID} = 0;
			$IntrCount = 1;
			push @{ $InterGenSt{$items[0]} }, $items[4];
			push @{ $InterGenEnd{$items[0]} }, $items[3];
		}elsif($items[2] eq "exon"){
			my $exonID;
			if ($items[8] =~ m/ID\=(.+)\.exon.+/){
                                $exonID = $1;
                                $ExScaff{$exonID} = $items[0];
                        }else{
                                print "Not matched found for Gene ID\n";
                        }
			if($items[6] eq "+"){
				$GenOr{$exonID} = $items[6];
				my $prevIntr = $IntrCount - 1;
				$IntrEnd{"$exonID.$prevIntr"} = $items[3]; # This includes the 1st position of the next exon
				$IntrSt{"$exonID.$IntrCount"} = $items[4] + 1;
                        }else{
				$GenOr{$exonID} = $items[6];
                        	my $nextIntr = $IntrCount + 1; 
                                $IntrEnd{"$exonID.$nextIntr"} = $items[3] - 1;
                                $IntrSt{"$exonID.$IntrCount"} = $items[4];
			}
			$IntrCount++;
			$GenEx{$GenID}++;
			my $EL = $items[4] - $items[3] + 1;
			push @ExLn, $EL;
		}else{
			next;
		}
	}else{
		next;
	}
}
close(GFF);

# Get average gene length
my $totGenLen = 0;

foreach my $g (keys %GenLen){
	chomp $g;
	$totGenLen = $totGenLen + $GenLen{$g};
}

my $numGen = keys %GenLen;
my $avGenLen = $totGenLen / $numGen;

print "Total number of genes:\t$numGen\n";
print "Total gene length:\t$totGenLen\n";
print "Average gene length:\t$avGenLen\n";
 
# Intergenic regions calculations

my $outio_obj1 = Bio::SeqIO->new(-file => '>IntergenicRegions.fasta', -format => 'fasta');

foreach my $array (values %InterGenSt){
	@$array = sort { $a <=> $b } @$array;
}

foreach my $array (values %InterGenEnd){
	@$array = sort { $a <=> $b } @$array;
}

foreach my $s (keys %InterGenSt){
        chomp $s;
	my $as =  scalar @{$InterGenSt{$s}};
	if ($as > 1){
		my $last = $as - 2;
		foreach my $StIndex (0 .. $last){
			chomp $StIndex;
			$numInterGen++;
			my $EndIndex = $StIndex + 1;
			my $InterGenLn = $InterGenEnd{$s}[$EndIndex] - $InterGenSt{$s}[$StIndex] - 1;
			my $actualStart = $StIndex + 1; # The other start index is actually the last position of a gene
			my $fragment = substr $GNM{$s}, $actualStart, $InterGenLn;
			my $frag_obj = Bio::Seq->new(-seq => "$fragment", -display_id => "${s}_${numInterGen}", -alphabet => "dna");
			$outio_obj1->write_seq($frag_obj);
			$TotInterGenLn = $TotInterGenLn + $InterGenLn;
		}
	}else{
		next;
	}
}

# Get average number of exons per gene
my $totNumEx = 0;

foreach my $g (keys %GenEx){
	chomp $g;
	$totNumEx = $totNumEx + $GenEx{$g};
	$IntrGen++ if $GenEx{$g} > 1;
}

my $AvGenEx = $totNumEx / $numGen;

print "Total number of exons:\t$totNumEx\n";
print "Average number of exons per gene:\t$AvGenEx\n";

# Get average exon length
my $totExLn = 0;

foreach my $el (@ExLn){
	chomp $el;
	$totExLn = $totExLn + $el;
}

my $AvExLn = $totExLn / $totNumEx;

print "Average exon length:\t$AvExLn\n";
print "Total exon length:\t$totExLn\n";
print "Number of genes with introns:\t$IntrGen\n";

# Create a list with all uniq intron ids

my @intronIDs;

foreach my $id (keys %IntrSt){
	chomp $id;
	push @intronIDs, $id;
}

foreach my $id (keys %IntrEnd){
        chomp $id;
        push @intronIDs, $id;
}

@intronIDs = uniq(@intronIDs);

# Extract introns from genome sequences

my @introns;
my $outio_obj = Bio::SeqIO->new(-file => '>introns.fasta', -format => 'fasta');
my $IntrTotLn = 0;

foreach my $id (@intronIDs){
	chomp $id;
	my @items = split /\./, $id;
	pop @items;
	my $exonID = join '.', @items;
	if (!exists $ExScaff{$exonID}){
		print "No scaffold found for gene $exonID\n";
	}
	my $scaffID = $ExScaff{$exonID};
	if(exists $IntrSt{$id} && exists $IntrEnd{$id}){
		my $il = $IntrEnd{$id} - $IntrSt{$id}; #Intron end is including 1st base of next exon
		$IntrTotLn = $IntrTotLn + $il;
		my $offset = $il + 1; 
		my $StIndex = $IntrSt{$id} - 1;
		my $fragment = substr $GNM{$scaffID}, $StIndex, $offset;
		my $frag_obj = Bio::Seq->new(-seq => "$fragment", -display_id => "$id", -alphabet => "dna");
		my $intron;
		if($GenOr{$exonID} eq "+"){
			$intron = $frag_obj;
		}else{
			$intron = $frag_obj->revcom;
		}
		$outio_obj->write_seq($intron);
		my $seq = $intron->seq;
		push @introns, $seq;
	}
}

# Extract splice donors and acceptors from introns
my %don;
my %acc;

foreach my $i (@introns){
	chomp $i;
	my $donor = substr $i, 0, 2;
	$donor = uc $donor;
	if(exists $don{$donor}){
		$don{$donor}++;
	}else{
		$don{$donor} = 1;
	}
	my $acceptor = substr $i, -3;
	$acceptor = uc $acceptor;
	if(exists $acc{$acceptor}){
                $acc{$acceptor}++;
        }else{
                $acc{$acceptor} = 1;
        }
}

my $numIntr = scalar @introns;
my $AvIntrLn = $IntrTotLn / $numIntr;
my $AvGenIntr = $numIntr / $numGen;

print "Number of introns:\t$numIntr\n";
print "Total intron length:\t$IntrTotLn\n";
print "Average intron length:\t$AvIntrLn\n";
print "Average number of introns per gene:\t $AvGenIntr\n";
print "Splice donors (\%):\t/";

foreach my $d (keys %don){
	chomp $d;
	my $perc = ($don{$d} / $numIntr) * 100;
	printf "$d:%.2f\/", $perc;
}

print "\nSplice acceptors (%):\t/";

foreach my $a (keys %acc){
	chomp $a;
	my $perc = ($acc{$a} / $numIntr) * 100;
	substr($a,2,0) = '|';
        printf "$a:%.2f\/", $perc;
}

print "\n";

# Print intergenic region stats

my $AvInterGenLn = $TotInterGenLn / $numInterGen;

print "Number of intergenic regions:\t$numInterGen\n";
print "Total intergenic region length:\t$TotInterGenLn\n";
print "Average intergenic region length:\t$AvInterGenLn\n";

