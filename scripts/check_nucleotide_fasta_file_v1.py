#!/usr/bin/python
DESCRIPTION = '''
Checks nucleotide fasta file to ensure it will work with annotation files.

TODO: Add check for description. Some scripts dont like headers.

Tests for the below criteria:
	1. seq_length > min_length
	2. seq_characters in allowed_sequence_characters
	3. seq_characters are uppercase
	4. seq_header in allowed_header_characters
'''
import sys
import argparse
import logging
from itertools import groupby

## Pass arguments.
def main():
	# Pass command line arguments. 
	parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter, description=DESCRIPTION)
	parser.add_argument('-f', '--fasta', metavar='scaffolds.fasta', type=argparse.FileType('r'), required=True, help='Sequence file to check (default: %(default)s)')
	parser.add_argument('--allowed_sequence_characters', default='ATGCN', type=str, required=False, help='Allowed nucleotide characters (default: %(default)s)')
	parser.add_argument('--allowed_header_characters', default='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-', type=str, required=False, help='Allowed header characters (default: %(default)s)')
	parser.add_argument('--minlength', default=0, type=int, required=False, help='Minimum length of sequences expected (default: %(default)s)')
	parser.add_argument('--allow_lower', action='store_true', required=False, help='Dont warn about lowercase characters (default: %(default)s)')
	parser.add_argument('--debug', action='store_true', required=False, help='Print DEBUG info (default: %(default)s)')
	args = parser.parse_args()
	
	# Set up debugger
	if args.debug:
		logging.basicConfig(format='#DEBUG: %(message)s', stream=sys.stdout, level=logging.DEBUG)
	else:
		logging.basicConfig(format='#ERROR: %(message)s', stream=sys.stdout, level=logging.ERROR)
	
	logging.debug('%s', args) ## DEBUG
	
	# 
	count_bad_uppercase = 0
	count_bad_minlength = 0
	count_bad_sequences = 0
	count_bad_headers = 0
	for header, seq in fasta_iter(args.fasta):
		logging.debug('%s %s', header, seq) ## DEBUG
		
		if not args.allow_lower:
			count_bad_uppercase += check_sequence_uppercase(header, seq)
		count_bad_minlength += check_sequence_minlength(header, seq, args.minlength)
		count_bad_sequences += check_sequence_characters(header, seq, args.allowed_sequence_characters)
		count_bad_headers += check_header_characters(header, args.allowed_header_characters)
	
	# Print counts
	if not args.allow_lower:
		print "Number of sequecnes with lowercase characters: " + str(count_bad_uppercase)
	print "Number of sequecnes shorter then minlength: " + str(count_bad_minlength)
	print "Number of sequecnes with bad sequence characteris: " + str(count_bad_sequences)
	print "Number of sequecnes with bad header characteris: " + str(count_bad_headers)
	


def check_sequence_uppercase(header, seq):
	lowercase_letters = [c for c in set(seq) if c.islower()]
	if len(lowercase_letters) > 0:
		print header + "\tFound lowercase characters!"
		return 1
	else:
		return 0


def check_sequence_minlength(header, seq, minlength):
	if len(seq) < minlength:
		print header + "\tSequence less than minlength!"
		return 1
	else:
		return 0


def check_sequence_characters(header, seq, allowed_sequence_characters):
	bad_characters = [c for c in set(seq) if c not in allowed_sequence_characters]
	if len(bad_characters) > 0:
		print header + "\tSequence character found that is not in allowed_sequence_characters! They are " + ', '.join(bad_characters)
		return 1
	else:
		return 0



def check_header_characters(header, allowed_header_characters):
	bad_characters = [c for c in set(header) if c not in allowed_header_characters]
	if len(bad_characters) > 0:
		print header + "\tHeader character found that is not in allowed_header_characters! They are " + ', '.join(bad_characters)
		return 1
	else:
		return 0

	
	
def fasta_iter(fh):
    	"""
    	Given a fasta file. yield tuples of header, sequence
	
	From: https://www.biostars.org/p/710/
	Updated: 09/11/2017
	Version: 0.1
	"""
    	# ditch the boolean (x[0]) and just keep the header or sequence since
    	# we know they alternate.
    	faiter = (x[1] for x in groupby(fh, lambda line: line[0] == ">"))
    	for header in faiter:
        	# drop the ">"
        	header = header.next()[1:].strip()
        	# join all sequence lines to one.
        	seq = "".join(s.strip() for s in faiter.next())
        	yield header, seq



if __name__ == '__main__':
	main()
