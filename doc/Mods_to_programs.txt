






#############################################
## AUGUSTUS
#############################################
## 
## 7 scripts need to be changed to support GA-AG splice site.
## 


## 1. src/introntrain.cc - line 269-298:

## FROM:
void IntronModel::processDSS( const char* dna, int pos){
    if (hasSpliceSites || pos < Constant::dss_start + 1){
        return;
    }

    static char *dstr = new char[Constant::dss_size()+1]; // forget the delete
    Seq2Int s2i(Constant::dss_size());
    if (!onGenDSS(dna+pos+1))
        throw IntronModelError("DSS error! Expected 'gt'" +
                               string(Constant::dss_gc_allowed ?  " or 'gc'" : "") +
                               ", but found '" + string(dna, pos+1, 2) + "' at position " +
                               itoa(pos+1) + ".");
    else {
        strncpy( dstr, dna + pos - Constant::dss_start + 1, Constant::dss_start );
        strncpy( dstr + Constant::dss_start, dna + pos + 3, Constant::dss_end );
        dstr[Constant::dss_size()] = '\0';
        try{
            dsscount[s2i(dstr)]++;
            c_dss += 1;
        } catch (InvalidNucleotideError e) {
            //cerr << "Donor splice site " << dstr << " contains an invalid character." << endl;
        }
        /*/output for seqlogo of ass 
        static char *dssfenster = new char[11];
        strncpy( dssfenster, dna + pos+1-4, 10);
        dssfenster[10]='\0';
        cout << "cds dss "  << dssfenster << endl;*/
    }
}

## TO:
void IntronModel::processDSS( const char* dna, int pos){
    if (hasSpliceSites || pos < Constant::dss_start + 1){
        return;
    }

    static char *dstr = new char[Constant::dss_size()+1]; // forget the delete
    Seq2Int s2i(Constant::dss_size());
    if (!onGenDSS(dna+pos+1))
        throw IntronModelError("DSS error! Expected 'gt'" +
                               string(Constant::dss_gc_allowed ?  " or 'gc'" : "") +
                               string(Constant::dss_ga_allowed ?  " or 'ga'" : "") +    // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI
                               ", but found '" + string(dna, pos+1, 2) + "' at position " +
                               itoa(pos+1) + ".");
    else {
        strncpy( dstr, dna + pos - Constant::dss_start + 1, Constant::dss_start );
        strncpy( dstr + Constant::dss_start, dna + pos + 3, Constant::dss_end );
        dstr[Constant::dss_size()] = '\0';
        try{
            dsscount[s2i(dstr)]++;
            c_dss += 1;
        } catch (InvalidNucleotideError e) {
            //cerr << "Donor splice site " << dstr << " contains an invalid character." << endl;
        }
        /*/output for seqlogo of ass 
        static char *dssfenster = new char[11];
        strncpy( dssfenster, dna + pos+1-4, 10);
        dssfenster[10]='\0';
        cout << "cds dss "  << dssfenster << endl;*/
    }
}







## 2. include/geneticcode.hh - line 35-66:

## FROM:
#define DECLARE_ON(NAME, PATTERN, COUNT)                \
    inline bool NAME(const char* dna) {                 \
        return strncmp(dna, PATTERN, COUNT) == 0;       \
    }
// 'gt'
#define DSS_SEQUENCE "gt"
#define RDSS_SEQUENCE "ac"
DECLARE_ON(onDSS,     DSS_SEQUENCE, 2)
DECLARE_ON(onRDSS,    RDSS_SEQUENCE, 2)

// 'gc'
#define ALT_DSS_SEQUENCE "gc"
#define ALT_RDSS_SEQUENCE "gc"
DECLARE_ON(onAltDSS,  ALT_DSS_SEQUENCE, 2)
DECLARE_ON(onAltRDSS, ALT_RDSS_SEQUENCE, 2)

// 'gt' or 'gc'
inline bool onGenDSS(const char* dna) {
    return
        onDSS(dna) || (Constant::dss_gc_allowed && onAltDSS(dna));
}
inline bool onGenRDSS(const char* dna) {
    return
        onRDSS(dna) || (Constant::dss_gc_allowed && onAltRDSS(dna));
}


## TO:
#define DECLARE_ON(NAME, PATTERN, COUNT)                \
    inline bool NAME(const char* dna) {                 \
        return strncmp(dna, PATTERN, COUNT) == 0;       \
    }
// 'gt'
#define DSS_SEQUENCE "gt"
#define RDSS_SEQUENCE "ac"
DECLARE_ON(onDSS,     DSS_SEQUENCE, 2)
DECLARE_ON(onRDSS,    RDSS_SEQUENCE, 2)

// 'gc'
#define ALT_DSS_SEQUENCE "gc"
#define ALT_RDSS_SEQUENCE "gc"
DECLARE_ON(onAltDSS,  ALT_DSS_SEQUENCE, 2)
DECLARE_ON(onAltRDSS, ALT_RDSS_SEQUENCE, 2)

// 'ga'         // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI
#define GA_DSS_SEQUENCE "ga"    // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI
#define GA_RDSS_SEQUENCE "tc"   // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI
DECLARE_ON(onGaDSS,  GA_DSS_SEQUENCE, 2)        // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI
DECLARE_ON(onGaRDSS, GA_RDSS_SEQUENCE, 2)       // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI

// 'gt' or 'gc'
// or 'ga'      // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI
inline bool onGenDSS(const char* dna) {
    return
        onDSS(dna) || (Constant::dss_gc_allowed && onAltDSS(dna)) || (Constant::dss_ga_allowed && onGaDSS(dna));        // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI
}
inline bool onGenRDSS(const char* dna) {
    return
        onRDSS(dna) || (Constant::dss_gc_allowed && onAltRDSS(dna)) || (Constant::dss_ga_allowed && onGaRDSS(dna));      // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI
}






## 3. src/etraining.cc - line 77:

FROM:
Constant::dss_gc_allowed = true; // default value for training!

TO:
Constant::dss_gc_allowed = true; // default value for training!
Constant::dss_ga_allowed = true; // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI








## 4. src/types.cc - line 78:

## FROM:
bool Constant::dss_gc_allowed = false;

## TO:
bool Constant::dss_gc_allowed = false;
bool Constant::dss_ga_allowed = false;  // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI



## 4. src/types.cc - line 426:

## FROM:
Properties::assignProperty("/IntronModel/allow_dss_consensus_gc", dss_gc_allowed);

## TO:
Properties::assignProperty("/IntronModel/allow_dss_consensus_gc", dss_gc_allowed);
Properties::assignProperty("/IntronModel/allow_dss_consensus_ga", dss_ga_allowed);   // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI





## 5. include/types.hh - line 308:

## FROM:
static bool dss_gc_allowed;

## TO:
static bool dss_gc_allowed;
static bool dss_ga_allowed;     // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI






## 6. src/properties.cc - line 174:

## FROM:
"/IntronModel/allow_dss_consensus_gc",

## TO:
"/IntronModel/allow_dss_consensus_gc",
"/IntronModel/allow_dss_consensus_ga",    // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI





## 7. include/properties.hh - line 32:

## FROM:
#define NUMPARNAMES 270

## TO (270->271):
#define NUMPARNAMES 271   // allows recognition of GA-AG sites in Dinoflagellates. TGS - credit YONG LI











#############################################
## EVidenceModeler
#############################################
## 
## 3 scripts need to be changed to support GA-AG splice site.
## 



# modified file:
evidence_modeler.pl 
# modified line:
698
## FROM:
print STDERR "\n-finding all potential splice sites, looking for GT/GC donors and AG acceptors.";
## TO:
print STDERR "\n-finding all potential splice sites, looking for GT/GC/GA donors and AG acceptors.";  # allows recognition of GA-AG sites in Dinoflagellates. TGS


# modified lines:
798-802
# FROM:
my @gt_positions = &find_all_positions('GT');
my @gc_positions = &find_all_positions('GC');
foreach my $pos (@gt_positions, @gc_positions) {
     $GENOME_FEATURES[$pos+1] = $DONOR;
}

# TO:
my @gt_positions = &find_all_positions('GT');
my @gc_positions = &find_all_positions('GC');
my @ga_positions = &find_all_positions('GA');  # allows recognition of GA-AG sites in Dinoflagellates. TGS
foreach my $pos (@gt_positions, @gc_positions, @ga_positions) {  # allows recognition of GA-AG sites in Dinoflagellates. TGS
   $GENOME_FEATURES[$pos+1] = $DONOR;
}




# modified file:
PerlLib/Gene_obj.pm 
# modified line:
1845
## FROM:
my $check_donor = ($donor =~ /gt|gc/i);
## TO:
my $check_donor = ($donor =~ /gt|gc|ga/i);  # allows recognition of GA-AG sites in Dinoflagellates. TGS




# modified file:
PerlLib/Gene_validator.pm
# modified line:
116
## FROM:
my $check_donor = ($donor =~ /gt|gc/i);
## TO:
my $check_donor = ($donor =~ /gt|gc|ga/i);  # allows recognition of GA-AG sites in Dinoflagellates. TGS










#############################################
## Genemark-ES
#############################################
## 
## Modify 1 script
## 

# modified file:
gmes_petap.pl 
# add after line:
83
## ADD:
# Workaround flock error with Lustre filesystems - Put the lock file on /tmp filesystem. ## TGS
$Logger::Simple::SEM = "/tmp/.LS.lock"; ## TGS

















#############################################
## Prepare_Golden_Genes (from JAMg)
#############################################
## 
## The scripts modified are distributed as part of the JAMg package.
## 

# modified file:
prepare_golden_genes_for_predictors_GA_DonorSite.pl
# modified line:
238
## FROM:
print "\nMethionine and * in protein sequence; Start codon and stop codon in genome; No overlapping genes; Splice sites (GT..AG or GC..AG)\n";
## TO:
print "\nMethionine and * in protein sequence; Start codon and stop codon in genome; No overlapping genes; Splice sites (GT..AG or GC..AG or GA..AG)\n";   # allows recognition of GA-AG sites in Dinoflagellates. TGS


# modified line:
376
## FROM:
print "Processing $exonerate_file using these cut-offs: identical:$identical_fraction_cutoff similar:$similar_fraction_cutoff;  No more than $mismatch_cutoff mismatches in total; Methionine and * in protein sequence; Start codon and st     op codon in genome; No overlapping genes; Splice sites (GT..AG or GC..AG)\n" unless $liberal_cutoffs;
## TO:
print "Processing $exonerate_file using these cut-offs: identical:$identical_fraction_cutoff similar:$similar_fraction_cutoff;  No more than $mismatch_cutoff mismatches in total; Methionine and * in protein sequence; Start codon and st     op codon in genome; No overlapping genes; Splice sites (GT..AG or GC..AG or GA..AG)\n" unless $liberal_cutoffs;   # allows recognition of GA-AG sites in Dinoflagellates. TGS


# modified line:
509
## FROM:
unless ( $site eq 'GT' || $site eq 'GC' ) {
## TO:
unless ( $site eq 'GT' || $site eq 'GC' || $site eq 'GA' ) {   # allows recognition of GA-AG sites in Dinoflagellates. TGS


# modified line:
2671
## FROM:
&process_cmd( 'run_exonerate.pl' . $exonerate_options );
## TO:
&process_cmd( 'run_exonerate_withPSSM.pl' . $exonerate_options );   # allows recognition of GA-AG sites in Dinoflagellates. TGS


# modified line:
2704
## FROM:
&process_cmd( 'run_exonerate.pl' . $exonerate_options );
## TO:
&process_cmd( 'run_exonerate_withPSSM.pl' . $exonerate_options );   # allows recognition of GA-AG sites in Dinoflagellates. TGS


# modified line:
3190
## FROM:
unless ( $site eq 'GC' || $site eq 'GT' ) {
## TO:
unless ( $site eq 'GC' || $site eq 'GT' || $site eq 'GA' ) {   # allows recognition of GA-AG sites in Dinoflagellates. TGS



# modified file:
run_exonerate_withPSSM.pl
# modified block:
633
## FROM:
. " --targettype dna -D 8192 -M 8192 --showquerygff y --showtargetgff y -n 1 -S n --maxintron $max_intron  ";
## TO:
. " --targettype dna -D 8192 -M 8192 --showquerygff y --showtargetgff y -n 1 -S n --maxintron $max_intron --splice5 ~/.exonerate_five_prime.pssm --splice3 ~/.exonerate_three_prime.pssm ";   # allows recognition of GA-AG sites in Dinoflagellates. TGS


# modified block:
749
## FROM:
. " --targettype dna -D 8192 -M 8192 --showtargetgff y -n 1 -S n --maxintron $max_intron  ";
## TO:
. " --targettype dna -D 8192 -M 8192 --showtargetgff y -n 1 -S n --maxintron $max_intron --splice5 ~/.exonerate_five_prime.pssm --splice3 ~/.exonerate_three_prime.pssm ";   # allows recognition of GA-AG sites in Dinoflagellates. TGS





# modified file:
PerlLib/CDNA/CDNA_alignment.pm
# modified block:
line 320 - 356

##
## FROM:
## 
sub get_consensus_splice_sites () {

    my $orientation = shift;

    my @pairs;

    if ($orientation eq '+') {

        ## Forward pairs
        # GT-AG
        # GC-AG
        # AT-AC

        push (@pairs, ['GT', 'AG'], ['GC', 'AG']);

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['AT', 'AC']);
        }

    }

    else {
        ## Rev Comp of above:
        # CT-AC
        # CT-GC
        # GT-AT

        push (@pairs, ['CT', 'AC'], ['CT', 'GC']);

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['GT', 'AT']);
        }
    }


    return (@pairs);
}


##
## TO:
##
sub get_consensus_splice_sites () {

    my $orientation = shift;

    my @pairs;

    if ($orientation eq '+') {

        ## Forward pairs
        # GT-AG
        # GC-AG
        # AT-AC

        push (@pairs, ['GT', 'AG'], ['GC', 'AG']);
        push (@pairs, ['GA' ,'AG']);    # add GA-AG for Dinoflagellates. TGS

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['AT', 'AC']);
        }

    }

    else {
        ## Rev Comp of above:
        # CT-AC
        # CT-GC
        # GT-AT

        push (@pairs, ['CT', 'AC'], ['CT', 'GC']);
        push (@pairs, ['CT', 'TC']);    # add GA-AG for Dinoflagellates. TGS

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['GT', 'AT']);
        }
    }


    return (@pairs);
}



# modified file:
PerlLib/Gene_validator.pm
# modified block:
line 139 - 175

##
## FROM:
## 
sub _get_consensus_splice_sites () {

    my $orientation = shift;

    my @pairs;

    if ($orientation eq '+') {

        ## Forward pairs
        # GT-AG
        # GC-AG
        # AT-AC

        push (@pairs, ['GT', 'AG'], ['GC', 'AG']);

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['AT', 'AC']);
        }

    }

    else {
        ## Rev Comp of above:
        # CT-AC
        # CT-GC
        # GT-AT

        push (@pairs, ['CT', 'AC'], ['CT', 'GC']);

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['GT', 'AT']);
        }
    }


    return (@pairs);
}


## 
## TO:
## 
sub _get_consensus_splice_sites () {

    my $orientation = shift;

    my @pairs;

    if ($orientation eq '+') {

        ## Forward pairs
        # GT-AG
        # GC-AG
        # AT-AC

        push (@pairs, ['GT', 'AG'], ['GC', 'AG']);
        push (@pairs, ['GA' ,'AG']);    # add GA-AG for Dinoflagellates. TGS

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['AT', 'AC']);
        }

    }

    else {
        ## Rev Comp of above:
        # CT-AC
        # CT-GC
        # GT-AT

        push (@pairs, ['CT', 'AC'], ['CT', 'GC']);
        push (@pairs, ['CT', 'TC']);    # add GA-AG for Dinoflagellates. TGS

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['GT', 'AT']);
        }
    }


    return (@pairs);
}




# modified file:
PerlLib/Gene_obj.pm
# modified block:
line 1822

##
## FROM:
## 
my $check_donor = ($donor =~ /gt|gc/i);


## 
## TO:
## 
my $check_donor = ($donor =~ /gt|gc|ga/i); # add GA-AG for Dinoflagellates. TGS



















#############################################
## PASA (SQLite compatable)
#############################################
## 
## https://github.com/PASApipeline/PASApipeline/wiki
## 

# to make PASA support non-canonical splice site.
# modified file:
${PASAHOME}/PerlLib/CDNA/CDNA_alignment.pm
# modified block:
line 334 - 360

##
## FROM:
## 
sub get_consensus_splice_sites () {

    my $orientation = shift;

    my @pairs;

    if ($orientation eq '+') {

        ## Forward pairs
        # GT-AG
        # GC-AG
        # AT-AC

        push (@pairs, ['GT', 'AG'], ['GC', 'AG']);

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['AT', 'AC']);
        }

    }

    else {
        ## Rev Comp of above:
        # CT-AC
        # CT-GC
        # GT-AT

        push (@pairs, ['CT', 'AC'], ['CT', 'GC']);

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['GT', 'AT']);
        }
    }


    return (@pairs);
}


##
## TO:
##
sub get_consensus_splice_sites () {

    my $orientation = shift;

    my @pairs;

    if ($orientation eq '+') {

        ## Forward pairs
        # GT-AG
        # GC-AG
        # AT-AC

        push (@pairs, ['GT', 'AG'], ['GC', 'AG']);
        push (@pairs, ['GA' ,'AG']);    # add GA-AG for Dinoflagellates. TGS

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['AT', 'AC']);
        }

    }

    else {
        ## Rev Comp of above:
        # CT-AC
        # CT-GC
        # GT-AT

        push (@pairs, ['CT', 'AC'], ['CT', 'GC']);
        push (@pairs, ['CT', 'TC']);    # add GA-AG for Dinoflagellates. TGS

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['GT', 'AT']);
        }
    }


    return (@pairs);
}





# modified file:
${PASAHOME}/PerlLib/Gene_validator.pm
# modified block:
line 154 - 190

##
## FROM:
## 
sub _get_consensus_splice_sites () {

    my $orientation = shift;

    my @pairs;

    if ($orientation eq '+') {

        ## Forward pairs
        # GT-AG
        # GC-AG
        # AT-AC

        push (@pairs, ['GT', 'AG'], ['GC', 'AG']);

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['AT', 'AC']);
        }

    }

    else {
        ## Rev Comp of above:
        # CT-AC
        # CT-GC
        # GT-AT

        push (@pairs, ['CT', 'AC'], ['CT', 'GC']);

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['GT', 'AT']);
        }
    }


    return (@pairs);
}




## 
## TO:
## 
sub _get_consensus_splice_sites () {

    my $orientation = shift;

    my @pairs;

    if ($orientation eq '+') {

        ## Forward pairs
        # GT-AG
        # GC-AG
        # AT-AC

        push (@pairs, ['GT', 'AG'], ['GC', 'AG']);
        push (@pairs, ['GA' ,'AG']);    # add GA-AG for Dinoflagellates. TGS

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['AT', 'AC']);
        }

    }

    else {
        ## Rev Comp of above:
        # CT-AC
        # CT-GC
        # GT-AT

        push (@pairs, ['CT', 'AC'], ['CT', 'GC']);
        push (@pairs, ['CT', 'TC']);    # add GA-AG for Dinoflagellates. TGS

        if ($ALLOW_ATAC_splice_pairs) {
            push (@pairs, ['GT', 'AT']);
        }
    }


    return (@pairs);
}




# modified file:
${PASAHOME}/PerlLib/Gene_obj.pm
# modified block:
line 1845

##
## FROM:
## 
my $check_donor = ($donor =~ /gt|gc/i);


## 
## TO:
## 
my $check_donor = ($donor =~ /gt|gc|ga/i); # add GA-AG for Dinoflagellates. TGS



# modified file:
${PASAHOME}/pasa-plugins/transdecoder/PerlLib/Gene_obj.pm
# modified block:
line 1845

##
## FROM:
## 
my $check_donor = ($donor =~ /gt|gc/i);


## 
## TO:
## 
my $check_donor = ($donor =~ /gt|gc|ga/i); # add GA-AG for Dinoflagellates. TGS







## Some perl module scripts have not been changes to recognize GA-AG sites.
## Likely not an issue as they will liekly not be used in the standard annotation procedure. 
./PerlLib/CIGAR.pm
./PerlLib/GTF.pm
./PasaWeb/*






#############################################
## maker
#############################################
## 
## 
## Two files will need to be modified and two files will need to be created.

# The two file need to be placed in your home directory. They are position specific score matrix files which allow exonerate to
# use alternative splice sites. The values in these files should really be generated using evidence based approaches (such as from PASA)
# however simply using them with place holder values will produce genes with more accurate intron/exon boundaries. 


$ cat ~/.exonerate_five_prime.pssm
# start of example 5' splice data
# A C G T
splice
 0  0 100   0
 33  33   0 34
# end of test 5' splice data


$ cat ~/.exonerate_three_prime.pssm
# start of example 3' splice data
# A C G T
100   0   0   0
  0   0 100   0
splice
 4  3  90  3
# end of example 3' splice data







# modified file:
${MAKER}/lib/polisher/exonerate/protein.pm 

# Add block below line 101
$command .= " --splice5 ~/.exonerate_five_prime.pssm --splice3 ~/.exonerate_three_prime.pssm ";




# modified file:
${MAKER}/lib/exonerate/splice_info.pm

# modified block:
line 23 - 46

## 
## FROM:
## 
sub splice_code {
        my $d = shift;
        my $a = shift;

        my $str = '';
        if    ($d =~ /^gt$/i && $a =~ /^ag$/i) {
                $str = '+';
        }
        elsif ($d =~ /^ct$/i && $a =~ /^ac$/i) {
                $str = '-';
        }
        elsif ($d =~ /^at$/i && $a =~ /^ac$/i){
               $str = '+';
        }
        elsif ($d =~ /^gt$/i && $a =~ /^at$/i){
               $str = '-';
        }

        else {
              $str = '0';
        }

        return $str;
}


## 
## TO:
## 
sub splice_code {
        my $d = shift;
        my $a = shift;

        my $str = '';
        if    ($d =~ /^gt$/i && $a =~ /^ag$/i) {
                $str = '+';
        }
        elsif ($d =~ /^ct$/i && $a =~ /^ac$/i) {
                $str = '-';
        }
        elsif ($d =~ /^gc$/i && $a =~ /^ag$/i) {
                $str = '+';
        }
        elsif ($d =~ /^ct$/i && $a =~ /^gc$/i) {
                $str = '-';
        }
        elsif ($d =~ /^ga$/i && $a =~ /^ag$/i) {
                $str = '+';
        }
        elsif ($d =~ /^ct$/i && $a =~ /^tc$/i) {
                $str = '-';
        }
        elsif ($d =~ /^at$/i && $a =~ /^ac$/i){
               $str = '+';
        }
        elsif ($d =~ /^gt$/i && $a =~ /^at$/i){
               $str = '-';
        }

        else {
              $str = '0';
        }

        return $str;
}





















