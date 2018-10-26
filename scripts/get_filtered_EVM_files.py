"""
	
	Takes the filter file (scaffold, start, end) and the EVM output SQLite3 database and returns 
	files containing just the predictions which passed the stringency test. 
	

	
"""
import argparse
import sqlite3

# Pass args.
def main():
	parser = argparse.ArgumentParser(description='Get the filtered EVM output files')
	parser.add_argument('--filter_file', metavar='filtered_EVM_predictions.txt', type=str, required=True, help='File from filter_EVM_files_v1.py')
	parser.add_argument('--sql_db', metavar='EVM.gff.sqlite3', type=str, required=True, help='SQLite3 gff DB file name')
	parser.add_argument('--gff_out', metavar='evm.filtered.gff', type=str, required=True, help='Out GFF file name')
	parser.add_argument('--protein_out', metavar='evm.filtered.protein.fasta', type=str, required=True, help='Out Protein file name')
	parser.add_argument('--mrna_out', metavar='evm.filtered.mRNA.fasta', type=str, required=True, help='Out mRNA file name')
	args = parser.parse_args()

	get_EVM_files(args.filter_file ,args.sql_db, args.gff_out, args.protein_out, args.mrna_out)



# Run processes to get filtered output files.
def get_EVM_files(filter_file, sql_db_file, gff_out_file, protein_out_file, mrna_out_file):
	db = sqlite3.connect(sql_db_file)
	mRNA_IDs = process_GFF_features(db, gff_out_file, filter_file)
	process_protein_seqs(db, protein_out_file, mRNA_IDs)
	process_mrna_seqs(db, mrna_out_file, mRNA_IDs)
	db.close()



# Process mRNA from database.
def process_mrna_seqs(db, out_file, mRNA_IDs):
	out = open(out_file, 'w')
	c = db.cursor()
	for ID in mRNA_IDs:
		c.execute('SELECT seq_name_raw FROM evm_mrna WHERE seq_name=?', (ID, ))
		out.write(c.fetchall()[0][0]+'\n')
		c.execute('SELECT seq_raw FROM evm_mrna WHERE seq_name=?', (ID, ))
		out.write('\n'.join([x[0] for x in c.fetchall()])+'\n')
	out.close()
	db.commit()
	out.close()


# Process proteins from database.
def process_protein_seqs(db, out_file, mRNA_IDs):
	out = open(out_file, 'w')
	c = db.cursor()
	for ID in mRNA_IDs:
		c.execute('SELECT seq_name_raw FROM evm_protein WHERE seq_name=?', (ID, ))
		out.write(c.fetchall()[0][0]+'\n')
		c.execute('SELECT seq_raw FROM evm_protein WHERE seq_name=?', (ID, ))
		out.write('\n'.join([x[0] for x in c.fetchall()])+'\n')
	out.close()
	db.commit()
	out.close()


# Process gff features from database.
def process_GFF_features(db, gff_out_file, filter_file):
	mRNA_IDs = []
	gff_out = open(gff_out_file, 'w')
	c = db.cursor()
	for line in open(filter_file, 'r').read().split('\n'):
		if len(line.strip()) == 0:
			continue # Ignore blank lines.

		scaffold, start, end = line.split('\t')
		
		# Get gene ID which matches [scaffold, start, end]
		gene_ID = c.execute('SELECT id FROM evm_gff WHERE type="gene" AND seqid=? AND start=? AND end=?', (scaffold, start, end)).fetchall()
		# Check if only one result returned. 
		if len(gene_ID) != 1:
			print 'Too many genes found for: ' + scaffold, start, end
			print gene_ID
			continue
		gene_ID = str(gene_ID[0][0]) # Get as str
		#print 'Gene ID: ' + gene_ID

		mRNA_ID = c.execute('SELECT id FROM evm_gff WHERE parent=?', (gene_ID, )).fetchall()
		# Check if only one result returned. 
		if len(mRNA_ID) != 1:
			print 'Too many mRNA found for: ' + gene_ID
			print gene_ID
			continue
		mRNA_ID = str(mRNA_ID[0][0])
		#print 'mRNA ID: ' + mRNA_ID
		mRNA_IDs.append(mRNA_ID)

		# Get raw_line for 'gene' feature; USE: id=gene_ID
		c.execute('SELECT raw_line FROM evm_gff WHERE id=?', (gene_ID, ))
		gff_out.write('\n'.join([x[0] for x in c.fetchall()])+'\n')

		# Get raw_line for 'mRNA' feature; USE: id=mRNA_ID 
		c.execute('SELECT raw_line FROM evm_gff WHERE id=?', (mRNA_ID, ))
		gff_out.write('\n'.join([x[0] for x in c.fetchall()])+'\n')

		# Get raw_line for 'exon/CDS/etc.' features; USE: parent=mRNA_ID
		c.execute('SELECT raw_line FROM evm_gff WHERE parent=?', (mRNA_ID, ))
		gff_out.write('\n'.join([x[0] for x in c.fetchall()])+'\n')

	gff_out.close()
	db.commit()

	return mRNA_IDs



if __name__ == '__main__':
	main()
