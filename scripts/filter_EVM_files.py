"""
	
	Searches in the given EVM output directory for all subdirectories which contain 'evm.out' file that are not empty.
	Imports the prediction evidence information for each group and prints the [scaffold, star, end] info if it passes the filter conditions.

	FILTER CONDITIONS:
		IF 'transdecoder' IN types OR len(types) >= 2:
			RETURN scaffold, strat, end
	
"""
import argparse
from itertools import *
import urllib
import os

# Parse args
def main():
	parser = argparse.ArgumentParser(description='Filter EVM genes')
	parser.add_argument('--evm_dir', metavar='PARTITIONS_EVM/', type=str, required=True, help='EVM output directory')
	parser.add_argument('--out', metavar='filtered_EVM_predictions.txt', type=str, required=False, default='filtered_EVM_predictions.txt', help='File to write EVM predictions thich passed filtering')
	args = parser.parse_args()

	# Get valid evm.out files. 
	sub_dirs_evm = get_EVM_out_files(args.evm_dir)

	# Write scaffold + coords to file if they meet conditions. 
	preds_count_total = 0
	preds_count_passed = 0
	out_handle = open(args.out, 'w')
	for d in sub_dirs_evm:
		a ,b = evm_out_iterator(d, out_handle)
		preds_count_total += a
		preds_count_passed += b

	out_handle.close()
	print '## Number of EVM predictions - Total: ' + str(preds_count_total)
	print '## Number of EVM predictions - Passed: ' + str(preds_count_passed)




# evm.out iterator.
def evm_out_iterator(evm_out_file, out_handle):
	scaffold = evm_out_file.split('/')[-2] # Get scaffold from file name. Only way I know to get it.
	
	preds_total = 0
	preds_passed = 0
	fh = open(evm_out_file, 'r')
	info_iter = groupby(fh, key=lambda x: x.lstrip().startswith("# EVM prediction:"))
	for k, v in info_iter:
		# Split file by '# EVM prediction:'
		# Take True segments as header and following False segment as information.  
		if k:
			# Take segment as header of features.
			header_line = list(v)[0].rstrip('\n') # '''# EVM prediction: Mode:STANDARD S-ratio: 2.42 214125-214727 orient(+) .........'''
			header_split = header_line.split(" ")
			start, end = header_split[6].split('-') # Take 6th column i.e. 214125-214727
			
			# Get info lines cleaned of \n and blank list elements removed. 
			lines = filter(None, [x.rstrip() for x in list(next(info_iter)[1])])
			# Remove !! lines from info.
			lines = filter(lambda k: '!!' not in k, lines)
			
			# Take only evidence sources from lines i.e. Last Column
			lines_clean = [x.split('\t')[-1] for x in lines]

			# Split evidence types i.e. 
			# {Augustus.g17206.t1;Augustus},{Augustus.g17206.t2;Augustus}, {transdecoder_35|m.26;transdecoder} -> ['Augustus', 'transdecoder'] 
			info = [x for y in lines_clean for x in y.lstrip('{').rstrip('}').split('},{')] # Remove brackets {}
			types = set(x.split(';')[1] for x in info)
			#print scaffold, start, end, types

			
			## FILTER CONDITIONS:
			## 
			## 	IF 'transdecoder' IN types OR len(types) >= 2:
			## 		RETURN scaffold, strat, end
			##	
			if 'transdecoder' in types or len(types) >= 2:
				out_handle.write(scaffold + '\t' + start + '\t' + end + '\n')
				preds_passed += 1
			preds_total += 1
	return preds_total, preds_passed


# Get evm.out files in EVM directory. 
def get_EVM_out_files(evm_out_dir):
	sub_dirs = [name for name in os.listdir(evm_out_dir) if os.path.isdir(os.path.join(evm_out_dir, name))]
	print '## Number of subdirectories found: ' + str(len(sub_dirs))

	sub_dirs_evm = []
	empty_files_found = 0
	for d in sub_dirs:
		evm_out_file = evm_out_dir + '/' + d + '/evm.out'
		if os.path.isfile(evm_out_file):
			if os.stat(evm_out_file).st_size > 0:
				sub_dirs_evm.append(evm_out_file)
			else:
				empty_files_found += 1
				#print 'NOTE: File is empty: ' + evm_out_file
		else:
			print 'WARNING: File does not exist: ' + evm_out_file

	print '## Number of empty evm.out files found: ' + str(empty_files_found)
	print '## Number of valid evm.out files found: ' + str(len(sub_dirs_evm))
	return sub_dirs_evm






if __name__ == '__main__':
	main()
