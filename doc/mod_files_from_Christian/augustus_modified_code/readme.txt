5 scripts need to be changed to support GA-AG splice site.

1. introntrain.cc - line 269:

void IntronModel::processDSS( const char* dna, int pos){
    if (hasSpliceSites || pos < Constant::dss_start + 1){
        return;
    }

    static char *dstr = new char[Constant::dss_size()+1]; // forget the delete
    Seq2Int s2i(Constant::dss_size());
    if (!onGenDSS(dna+pos+1))				############### function onGenDSS
        throw IntronModelError("DSS error! Expected 'gt'" +
                               string(Constant::dss_gc_allowed ?  " or 'gc'" : "") +
							   string(Constant::dss_ga_allowed ?  " or 'ga'" : "") +	// added for GA-AG splice site - YONG LI
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



2. augustus/include/geneticcode.hh - line 51:

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

// 'ga'		// added for GA-AG splice site - YONG LI
#define GA_DSS_SEQUENCE "ga"	// added for GA-AG splice site - YONG LI
#define GA_RDSS_SEQUENCE "tc"	// added for GA-AG splice site - YONG LI
DECLARE_ON(onGaDSS,  GA_DSS_SEQUENCE, 2)	// added for GA-AG splice site - YONG LI
DECLARE_ON(onGaRDSS, GA_RDSS_SEQUENCE, 2)	// added for GA-AG splice site - YONG LI

// 'gt' or 'gc'
// or 'ga'	// added for GA-AG splice site - YONG LI
inline bool onGenDSS(const char* dna) {
    return
        onDSS(dna) || (Constant::dss_gc_allowed && onAltDSS(dna)) || (Constant::dss_ga_allowed && onGaDSS(dna));	// changed for GA-AG splice site - YONG LI
}
inline bool onGenRDSS(const char* dna) {
    return
        onRDSS(dna) || (Constant::dss_gc_allowed && onAltRDSS(dna)) || (Constant::dss_ga_allowed && onGaRDSS(dna));	// changed for GA-AG splice site - YONG LI
}



3. etraining.cc - line 77:
Constant::dss_gc_allowed = true; // default value for training!
Constant::dss_ga_allowed = true;	// added for GA-AG splice site - YONG LI

4. types.cc - line 77/325:
bool Constant::dss_gc_allowed = false;
bool Constant::dss_ga_allowed = false;	// added for GA-AG splice site - YONG LI

Properties::assignProperty("/IntronModel/allow_dss_consensus_gc", dss_gc_allowed);
Properties::assignProperty("/IntronModel/allow_dss_consensus_ga", dss_ga_allowed);	// added for GA-AG splice site - YONG LI


5. include/types.hh:
static bool dss_gc_allowed;
static bool dss_ga_allowed;	// added for GA-AG splice site - YONG LI


6. properties.cc - line 147
"/IntronModel/allow_dss_consensus_gc",
"/IntronModel/allow_dss_consensus_ga",	// added for GA-AG splice site - YONG LI

7. include/properties.hh - line 33
#define NUMPARNAMES 227	// changed for GA-AG splice site (226->227) - YONG LI





Usage:

augustus --/IntronModel/allow_dss_consensus_gc=true --/IntronModel/allow_dss_consensus_ga=true --/IntronModel/non_gt_dss_prob=1 --gff3=true








