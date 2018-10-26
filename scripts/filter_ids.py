"""
	
	Filter a set of ids from a text file.

	Can filter using a list of ids to remove and a list of ifs to keep. 
	
	
	
"""
import argparse

# Parse args
def main():
	parser = argparse.ArgumentParser(description='Filter a set of ids')
	parser.add_argument('-i', '--in_file', metavar='IDs_to_filter.txt', type=str, required=True, help='IDs to filter')
	parser.add_argument('-o', '--out_file', metavar='filtered_IDs.txt', type=str, required=True, help='Output file for IDs that pass filtereing')
	parser.add_argument('-k', '--keep', metavar='IDs_to_keep_1.txt,IDs_to_keep_2.txt', type=str, required=False, help='File/Files containing IDs to keep if found, comma sep')
	parser.add_argument('-r', '--remove', metavar='IDs_to_remove.txt', type=str, required=False, help='File/Files containing IDs to remove if found, comma sep')
	args = parser.parse_args()

	print args 

	# Read in_file
	IDS = load_IDs_from_files(args.in_file)
	print IDS

	# Filter for IDs to keep
        if args.keep is not None:
                print args.keep
                to_keep = load_IDs_from_files(args.keep)
		print to_keep
		IDS = keep_IDs(IDS, to_keep)
		print IDS


	# Filter for IDs to remove
	if args.remove is not None:
		print args.remove
		to_remove = load_IDs_from_files(args.remove)
		print to_remove
		IDS = remove_IDs(IDS, to_remove)
		print IDS


	# Write out_file
	fh = open(args.out_file, 'w')
	for i in IDS:
		fh.write(i + "\n")
	fh.close()


# Keep IDs in given set.
def keep_IDs(ids_to_filter, ids_to_keep):
	filtered = []
	for i in ids_to_filter:
		if i in ids_to_keep:
			filtered.append(i)
	return set(filtered)


# Remove IDs in given set. 
def remove_IDs(ids_to_filter, ids_to_remove):
	filtered = []
	for i in ids_to_filter:
		if i not in ids_to_remove:
			filtered.append(i)
	return set(filtered)


# Load IDs from file/files and return a set (non-redundant).
# File names comma sep
def load_IDs_from_files(file_names):
	files = file_names.split(',')
	ids = []
	for f in files:
		fh = open(f, 'r')
		ids.extend(fh.read().split('\n'))
		fh.close()
	ids = filter(None, ids) # Clean blank entries
	ids = set(ids)
	return ids


if __name__ == '__main__':
	main()
