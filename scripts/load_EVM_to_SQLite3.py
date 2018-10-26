"""
	
	Takes EVM gff/mRNA/protein files and loads them into a SQLite3 database. 
	
	
"""
import argparse
import sqlite3
from itertools import *
import urllib

# Parse args
def main():
	parser = argparse.ArgumentParser(description='Load EVM gff')
	parser.add_argument('--gff', metavar='evm.gff', type=str, required=True, help='EVM gff file to load')
	parser.add_argument('--protein', metavar='evm.protein.fasta', type=str, required=True, help='EVM protein sequence file to load')
	parser.add_argument('--mrna', metavar='evm.mRNA.fasta', type=str, required=True, help='EVM mRNA sequence file to load')
	parser.add_argument('--sql_db', metavar='EVM.gff.sqlite3', type=str, required=True, help='SQLite3 gff DB file name')

	args = parser.parse_args()
	
	db = sqlite3.connect(args.sql_db)
	load_GFF_to_SQL(args.gff, db)
	load_Protein_to_SQL(args.protein, db)
	load_mRNA_to_SQL(args.mrna, db)
	db.close()


# Load EVM protein file into the database.
def load_mRNA_to_SQL(mRNA_file, db):
	check_TABLE_exists(db, "evm_mrna")
	c = db.cursor()
	c.execute('CREATE TABLE evm_mrna (seq_name, seq_name_raw, seq_raw)')
	c.execute('CREATE INDEX mrna_index ON evm_mrna (seq_name)')
	db.commit()
	
	c = db.cursor()
	faiter = fasta_iter(mRNA_file)
	for header, seq in faiter:
		seq_name = header.split(" ")[0].lstrip('>')
		c.execute('INSERT INTO evm_mrna (seq_name, seq_name_raw, seq_raw) VALUES (?, ?, ?)', (seq_name, header, "\n".join(seq)))
	db.commit()     


# Load EVM protein file into the database.
def load_Protein_to_SQL(protein_file, db):
	check_TABLE_exists(db, "evm_protein")
	c = db.cursor()
	c.execute('CREATE TABLE evm_protein (seq_name, seq_name_raw, seq_raw)')
	c.execute('CREATE INDEX protein_index ON evm_protein (seq_name)')
	db.commit()

	c = db.cursor()
	faiter = fasta_iter(protein_file)
	for header, seq in faiter:
		seq_name = header.split(" ")[0].lstrip('>')
		c.execute('INSERT INTO evm_protein (seq_name, seq_name_raw, seq_raw) VALUES (?, ?, ?)', (seq_name, header, "\n".join(seq)))
	db.commit()	


# Load GFF file into SQLite3 database. 
def load_GFF_to_SQL(gff_file, db):
	createTable_GFF(db)
	
	c = db.cursor()
	fh = open(gff_file, 'r')
	for line in fh.read().split('\n'):
		if len(line.strip()) == 0:
			continue
		split_GFF = split_GFF_line(line)
		c.execute('INSERT INTO evm_gff (seqid, source, type, start, end, score, strand, phase, attributes, id, parent, raw_line) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', 
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
	

# Pass gff atributes into dict. 
def parseGFFAttributes(attributeString):
        if attributeString == ".":
                return {}
        ret = {}
        for attribute in attributeString.split(";"):
                key, value = attribute.split("=")
                ret[urllib.unquote(key)] = urllib.unquote(value)
        return ret


## Create BLAST table. Deleate if already exists. 
def createTable_GFF(db):
        check_TABLE_exists(db, "evm_gff")

        c = db.cursor()
        c.execute('CREATE TABLE evm_gff (seqid, source, type, start, end, score, strand, phase, attributes, id, parent, raw_line)')
        c.execute('CREATE INDEX entry_index ON evm_gff (seqid, start, end)')
	c.execute('CREATE INDEX ID_index ON evm_gff (id)')
	c.execute('CREATE INDEX Parent_index ON evm_gff (parent)')
        db.commit()


## Check if table_name exists in database.
def check_TABLE_exists(db, table_name):
        c = db.cursor()

        # Check if tabel exists. If yes, remove it.
        sql_out = c.execute('SELECT name FROM sqlite_master WHERE type="table" AND name=?', (table_name, )).fetchall()
        if 1 == len(sql_out):
                print table_name, "Exists! Overwriting!"
                c.execute('DROP TABLE {}'.format(table_name))
        db.commit()

# Iterator for traversing the sequence file. 
# Yields header and list of seq lines (preserves line structure).
def fasta_iter(fasta_file):
	fh = open(fasta_file, 'r')
	# Drop boolean (x[0]) and just take the group information. 
	faiter = (x[1] for x in groupby(fh, lambda line: line[0] == ">"))
	for header in faiter:
		header = header.next().rstrip('\n')
		seq = [x.strip() for x in faiter.next()] # Join sequence lines together. 
		yield header, seq


if __name__ == '__main__':
	main()
