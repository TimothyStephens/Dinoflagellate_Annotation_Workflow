#!/usr/bin/env perl

use strict;
use FindBin;
use lib ("$FindBin::Bin/PerlLib");
use Fasta_reader;
use File::Basename;
use Cwd;



my $usage = "\n\nusage: $0 fastaFile prot|nuc\n\n";

my $scriptDir = "$FindBin::Bin/scripts";

my $dbDir = "$FindBin::Bin/transposon_PSI_LIB";
unless (-d $dbDir) {
    die "Error, cannot find $dbDir";
}


my $max_Evalue = "1e-5";

my $REMOVE_OUTPUTS = 1;

     
my $fastaFile = $ARGV[0] or die $usage;
my $dbType = $ARGV[1] or die $usage;
unless ($dbType eq "prot" || $dbType eq "nuc") {
    die $usage;
}

my $hostname = `hostname`;
$hostname =~ s/\s//g;

my $tempDir = "transposonPSI.$$.$hostname.tmp";
mkdir ($tempDir) or die "Error, cannot mkdir $tempDir";

my $fastaFile_basename = basename($fastaFile);

 main: {     
     my $runDir = cwd();
     
	 my $topHits_file = "$fastaFile_basename.TPSI.topHits";
	 my $allHits_file = "$fastaFile_basename.TPSI.allHits";
	 
	 open (TOPHIT, ">$topHits_file") or die $!;
     open (ALLHITS, ">$allHits_file") or die $!;
     
     my $fasta_reader = new Fasta_reader($fastaFile);
     
     while (my $seqObj = $fasta_reader->next()) {
         my $accession = $seqObj->get_accession();
         my $fasta_seq = $seqObj->get_FASTA_format();
         
         print STDERR "processing $accession.\n";
         
         &run_transposonPSI($accession, $fasta_seq, $dbType);
         
     }
     
     close TOPHIT;
     close ALLHITS;
     

	 if ($REMOVE_OUTPUTS) {
		 `rm -rf $tempDir`;
	 }
	 if ($dbType eq 'nuc') {
		 unlink ($topHits_file);  # not so helpful here.
		 
		 ## chain the hits into elements.
		 my $cmd = "$FindBin::Bin/scripts/TBLASTN_hit_chainer.pl $allHits_file btab > $allHits_file.chains";
		 &process_cmd($cmd);

		 ## convert chains to gff3
		 $cmd = "$FindBin::Bin/scripts/TPSI_btab_to_gff3.pl $allHits_file.chains > $allHits_file.chains.gff3";
		 &process_cmd($cmd);

		 ## use a DP scan to pull out the best scoring chains.
		 $cmd = "$FindBin::Bin/scripts/TBLASTN_hit_chainer_nonoverlapping_genome_DP_extraction.pl $allHits_file.chains > $allHits_file.chains.bestPerLocus";
		 &process_cmd($cmd);
		 
		 ## make gff3 file for the best chains.
		 $cmd = "$FindBin::Bin/scripts/TPSI_chains_to_gff3.pl $allHits_file.chains.bestPerLocus > $allHits_file.chains.bestPerLocus.gff3";
		 &process_cmd($cmd);
	 }

	 
	 
     exit(0);
     
 }

####
sub run_transposonPSI {
    my ($accession, $fasta_seq, $dbType) = @_;
    
    
    my $seqDir = $accession;
    $seqDir =~ s/\W/_/g;
    my $clean_acc = $seqDir;
    
    $seqDir = "$tempDir/$clean_acc";
    mkdir $seqDir or die "Error, cannot mkdir $seqDir\n";
    
    my $seqFilename = "$seqDir/$clean_acc.seq";
    open (SEQFILE, ">$seqFilename") or die $!;
    print SEQFILE $fasta_seq;
    close SEQFILE;
    
#    my $isProt = ($dbType eq "nuc") ? "F" : "T";
    my $cmd = "makeblastdb -in $seqFilename -dbtype $dbType";
    system $cmd;
    die "Error, $cmd (ret $?)" if $?;
    
    
    
    my @hit_summary;
    
    foreach my $refseq (<$dbDir/*.refSeq>) {
        
        print STDERR "\tblast against $refseq\n";
        
        my $chkpFile = $refseq;
        $chkpFile =~ s/\.refSeq/\.chk/;
        my $coreFilename = basename($refseq);
        
        my $outputFile = "$seqDir/$clean_acc.$coreFilename.psitblastn";
        
        my $cmd;
        if ($dbType eq "nuc") {
            # do psitblastn w/ blastall
            #$cmd = "tpsiblastn -query $refseq -db $seqFilename -out_pssm $chkpFile -dust no -matrix BLOSUM62 -t -1 -e $max_Evalue -v 10000 -b 10000 > $outputFile";
            next;
        } else {
            # do psiblast w/ blastpgp
            $cmd = "psiblast -query $refseq -db $seqFilename -out_pssm $chkpFile -num_iterations 1 -evalue $max_Evalue -out $outputFile";
        }
        
        print "CMD: $cmd\n";
        system $cmd;
        die "Error $cmd $?" if $?;
        
        ## covert to btab output
        my $cmd = "$scriptDir/BPbtab < $outputFile > $outputFile.btab";
        system $cmd;
        die "Error $cmd $?" if $?;
        
        open (BTAB, "$outputFile.btab") or die $!;
        while (<BTAB>) {
            unless (/\w/) { next;}
            unless (/error/i) {
                chomp;
                my @x = split (/\t/);
                push (@hit_summary, [@x]);
            }
        }
        close BTAB;
        
    }
    
    my $summary_file = "$seqFilename.btab";
    @hit_summary = reverse sort {$a->[12]<=>$b->[12]} @hit_summary;
    
    my $top_hit;
    open (SUMMARY, ">$summary_file") or die $!;
    foreach my $hit (@hit_summary) {
        my $btab_entry = join ("\t", @$hit);
        print ALLHITS "$btab_entry\n" if $btab_entry;
        
        unless ($top_hit) {
            $top_hit = $btab_entry;
        }
        print SUMMARY "$btab_entry\n";
    }
    close SUMMARY;
    
    if ($top_hit) {
        print TOPHIT $top_hit . "\n";
    } else {
        print TOPHIT "// $accession lacks T-PSI match.\n";
    } 
    
    ## remove the output files (addon)
    if ($REMOVE_OUTPUTS) {
        system ("rm -rf $seqDir");
    }

}



####
sub process_cmd {
	my ($cmd) = @_;

	print "CMD: $cmd\n";

	my $ret = system($cmd);

	if ($ret) {
		die "Error, cmd: $cmd died with ret $ret";
	}

	return;
}



