#
# Script to clean-up the MAKER temporary files created during the annotation process
#
# Will search for an clean up the theVoid.* & mpi_blastdb folders
# Run from top directory in which you wish to start cleaning from.
import os
import shutil
import time

mpi_blastdb = []
theVoid = []
#for root, dirs, files in os.walk("/short/d85/tgs564/MAKER/FAILED_RUN/00/001__scaffold3121_size84271.fasta"):
for root, dirs, files in os.walk(os.getcwd()):
	if "mpi_blastdb" in root and ".maker.output" in root:
		mpi_blastdb.append(root)
		dirs[:] = []
	elif "theVoid" in root and ".maker.output" in root and "_datastore" in root:
		theVoid.append(root)
		dirs[:] = []

for x in mpi_blastdb: print x
for x in theVoid: print x
total2clean = len(mpi_blastdb) + len(theVoid)
print "Total folders to clean: ", total2clean
print "Number mpi_blastdb:", len(mpi_blastdb)
print "Number theVoid:", len(theVoid)
print 

response = raw_input("(y/n) Do you wish to delete these files? ")
if response == 'y':
	response = raw_input("(y/n) Do you SURE!!? ")
	if response == 'y':
		print "OK"
		print 
		count = 1
		for x in mpi_blastdb: 
			print "Cleaning "+str(count)+"/"+str(total2clean)+": ", x
			tmp_dir_list = []
			master_prefix = x.rstrip("mpi_blastdb")
			for root, dirs, files in os.walk(x):
				prefix = root.replace(master_prefix, '')
				tmp_dir_list.append(prefix)
				for f in files:
					tmp_dir_list.append(prefix+'/'+f)
			count += 1
			
			for target in reversed(tmp_dir_list):
				if os.path.isfile(master_prefix+target) or os.path.islink(master_prefix+target):
					print "\tDeleteing: ", target
                                        #time.sleep(0.01)
                                        os.remove(master_prefix+target)
                                        #print "rm_file: ", master_prefix+target
				else:
					print "\tDeleteing: ", target
					#time.sleep(0.01)
					os.rmdir(master_prefix+target)
					#print "rm_dir: ", master_prefix+target
			#time.sleep(0.5)

		for x in theVoid: 
                        print "Cleaning "+str(count)+"/"+str(total2clean)+": ", x
                        tmp_dir_list = []
                        master_prefix = x.split("theVoid")[0]
                        for root, dirs, files in os.walk(x):
                                prefix = root.replace(master_prefix, '')
                                tmp_dir_list.append(prefix)
                                for f in files:
                                        tmp_dir_list.append(prefix+'/'+f)
                        count += 1

                        for target in reversed(tmp_dir_list): 
                                if os.path.isfile(master_prefix+target) or os.path.islink(master_prefix+target):
                                        print "\tDeleteing: ", target
                                        #time.sleep(0.01)
                                        os.remove(master_prefix+target)
                                        #print "rm_file: ", master_prefix+target
                                else:
                                        print "\tDeleteing: ", target
                                        #time.sleep(0.01)
                                        os.rmdir(master_prefix+target)
                                        #print "rm_dir: ", master_prefix+target
			#time.sleep(0.5)
		print
		print "DONE!"
		print 
	else:
		print "Canceled!"
else:
	print "Canceled!"


