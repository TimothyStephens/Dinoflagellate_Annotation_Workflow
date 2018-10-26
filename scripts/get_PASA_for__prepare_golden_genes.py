"""
	
	Filters PASA/transdecoder output files using ids passed in a seperate file. 

	Used to get a subset of PASA genes which have gone through transposon removal and clustering.
	
	
	May be a problem if PASA gff have gene features with multiple mRNA. As this script 
	relies on mRNA to have "same" name as gene features. If mRNA names different from genes 
	there will be gene < mRNA.
	
	
	
	
	
"""
import argparse
from itertools import *
import urllib
import sqlite3

# Parse args
def main():
	parser = argparse.ArgumentParser(description="Filters PASA output files for 'prepare_golden_genes_for_predictors_GA_DonorSite.pl'")
	parser.add_argument('-i', '--ids', metavar='CD-HIT.ids.txt', type=str, required=True, help='List of PASA ids to keep')
	parser.add_argument('-a', '--pasa_assembly', metavar='db.assemblies.fasta', type=str, required=True, help='PASA output file')
	parser.add_argument('-c', '--pasa_cds', metavar='db.assemblies.fasta.transdecoder.cds', type=str, required=True, help='PASA output file')
	parser.add_argument('-p', '--pasa_peptides', metavar='db.assemblies.fasta.transdecoder.pep', type=str, required=True, help='PASA output file')
	parser.add_argument('-f', '--pasa_gff', metavar='db.assemblies.fasta.transdecoder.gff3', type=str, required=True, help='PASA output file')
	parser.add_argument('-g', '--pasa_genome', metavar='db.assemblies.fasta.transdecoder.genome.gff3', type=str, required=True, help='PASA output file')
	args = parser.parse_args()

	run_filter_process(args.ids, args.pasa_assembly, args.pasa_cds, args.pasa_peptides, args.pasa_gff, args.pasa_genome)


# Filter the PASA output files. 
def run_filter_process(id_file, pasa_assembly_file, pasa_cds_file, pasa_peptides_file, pasa_gff_file, pasa_genome_file):
	#print id_file, pasa_assembly_file, pasa_cds_file, pasa_peptides_file, pasa_gff_file, pasa_genome_file
	gff_list, seq_list, ass_list = load_IDS_to_list(id_file)
	#print gff_list, seq_list, ass_list

	print "PASA assemblies"
	filter_pasa_seq_file(ass_list, pasa_assembly_file, "PASA.assemblies.fasta") # PASA assemblies
	print "PASA cds"
	filter_pasa_seq_file(seq_list, pasa_cds_file, "PASA.assemblies.fasta.transdecoder.cds") # PASA cds
	print "PASA pep"
	filter_pasa_seq_file(seq_list, pasa_peptides_file, "PASA.assemblies.fasta.transdecoder.pep") # PASA pep
	print "PASA gff"
	filter_pasa_gff_file(gff_list, pasa_gff_file, "PASA.assemblies.fasta.transdecoder.gff3") # PASA gff
	print "PASA genome.gff"
	filter_pasa_gff_file(gff_list, pasa_genome_file, "PASA.assemblies.fasta.transdecoder.genome.gff3") # PASA genome.gff



# Get only seqs which match an ID in the given list.
def filter_pasa_seq_file(id_list, pasa_seq_file, out_file_name):
	out = open(out_file_name, 'w')
	faiter = fasta_iter(pasa_seq_file)
	for header, seq in faiter:
		seq_name = header.split(" ")[0]
		if seq_name in id_list:
			out.write(header+'\n')
			out.write('\n'.join(seq)+'\n')
	out.close()



# Get only GFF features which match the mRNA seq names. sub |m. for |g. to get 'gene' feature. 
# This may couse problems if mRNA names are not the "same" as gene names. Then count genes < mRNA. 
def filter_pasa_gff_file(id_list, pasa_gff_file, out_file_name):
	db = sqlite3.connect(':memory:') # Load gff file into SQLite3 database in memory. Avoids problem with lustra systems. 
	load_GFF_to_SQL(pasa_gff_file, db)
	
	c = db.cursor()
	out = open(out_file_name, 'w')
	for IDs in id_list:
		gene_ID = IDs
		mRNA_ID = IDs
		#print gene_ID, mRNA_ID
		
		# Get raw_line for 'gene' feature; USE: id=gene_ID
                sql_list = c.execute('SELECT raw_line FROM gff WHERE id=?', ('GENE.'+gene_ID.split('.')[0]+'~~'+gene_ID, )).fetchall()
                if len(sql_list) != 1:
			print "ERROR: Feature count != 1 for Gene_ID: " + gene_ID
			print sql_list
		out.write('\n'.join([x[0] for x in sql_list])+'\n')

                # Get raw_line for 'mRNA' feature; USE: id=mRNA_ID 
                sql_list = c.execute('SELECT raw_line FROM gff WHERE id=?', (mRNA_ID, )).fetchall()
                if len(sql_list) != 1:
                        print "ERROR: Feature count != 1 for mRNA_ID: " + mRNA_ID
                        print sql_list
		out.write('\n'.join([x[0] for x in sql_list])+'\n')

                # Get raw_line for 'exon/CDS/etc.' features; USE: parent=mRNA_ID
                sql_list = c.execute('SELECT raw_line FROM gff WHERE parent=?', (mRNA_ID, )).fetchall()
                if len(sql_list) == 0:
                        print "ERROR: No features found for mRNA_ID: " + mRNA_ID
                        print sql_list
		out.write('\n'.join([x[0] for x in sql_list])+'\n')
		
		out.write('\n')

	db.commit()
	out.close()
	db.close()


# Pass gff atributes into dict. 
def parseGFFAttributes(attributeString):
	if attributeString == ".":
		return {}
	ret = {}
	for attribute in attributeString.split(";"):
		key, value = attribute.split("=")
		ret[urllib.unquote(key)] = urllib.unquote(value)
	return ret


# Load GFF file into SQLite3 database. 
def load_GFF_to_SQL(gff_file, db):
        createTable_GFF(db)

        c = db.cursor()
        fh = open(gff_file, 'r')
        for line in fh.read().split('\n'):
                if len(line.strip()) == 0 or line.startswith('#'):
                        continue
                split_GFF = split_GFF_line(line)
                c.execute('INSERT INTO gff (seqid, source, type, start, end, score, strand, phase, attributes, id, parent, raw_line) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                                (split_GFF[0], split_GFF[1], split_GFF[2], split_GFF[3], split_GFF[4], split_GFF[5], split_GFF[6], split_GFF[7], split_GFF[8], split_GFF[9], split_GFF[10], line))
        db.commit()


# Return list with 9 columns from GFF feature PLUS ID and Parent attribute, where applicable. 
# [seqid, source, type, start, end, score, strand, phase, attributes, ID, Parent]
def split_GFF_line(line_2_split):
        line_split = line_2_split.split('\t')
        attributes = parseGFFAttributes(line_split[8])
        line_split.append(attributes['ID'])
        if 'Parent' in attributes.keys():
                line_split.append(attributes['Parent'])
        else:
                line_split.append(None)
        #print line_split
        return line_split


## Create BLAST table. Deleate if already exists. 
def createTable_GFF(db):
        c = db.cursor()
        c.execute('CREATE TABLE gff (seqid, source, type, start, end, score, strand, phase, attributes, id, parent, raw_line)')
        c.execute('CREATE INDEX entry_index ON gff (seqid, start, end)')
        c.execute('CREATE INDEX ID_index ON gff (id)')
        c.execute('CREATE INDEX Parent_index ON gff (parent)')
        db.commit()



# Loads PASA ids and returns list of ids which can be used in filtering. 
# Creates:
# 	gff_list => list of ids for filtering gff features (i.e. [asmbl_1000|g.758, asmbl_1000|m.758], [..., ...], .....)
# 	seq_list => list of ids for filtering cds/pep seqs (i.e. asmbl_1000|m.758, ......)
# 	ass_list => list of ids for filtering assemblies seqs (i.e. asmbl_1000, .....)
# NOTE: Will cause problems if same seq has 2 proteins present (should not happen as only longest ORF was chosen).
def load_IDS_to_list(id_file):
	IDS = []
	fh = open(id_file, 'r')
	for line in fh.read().split('\n'):
		# Ignore line if blank.
		if len(line.strip()) == 0:
			continue

		IDS_split = line.lstrip('>')
		#print IDS_split
		IDS.append(IDS_split)

	# Construct tuple regex objects.
	gff_list = [x for x in IDS]
	seq_list = [">"+x for x in IDS]
	ass_list = [">"+x.split('.')[0] for x in IDS]
	
	return gff_list, seq_list, ass_list



# Iterator for traversing the sequence file. 
# Yields tuples of (seq_name, sequence)
def fasta_iter(fasta_file):
        fh = open(fasta_file, 'r')
        # Drop boolean (x[0]) and just take the group information. 
        faiter = (x[1] for x in groupby(fh, lambda line: line[0] == ">"))
        for header in faiter:
                header = header.next().rstrip('\n')
                seq = [s.strip() for s in faiter.next()] 
                yield header, seq




if __name__ == "__main__":
	main()
