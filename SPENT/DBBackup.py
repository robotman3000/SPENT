#!/usr/bin/env python
# Credit to https://gist.github.com/JrMasterModelBuilder/4eff31252815669d90d1040be912a303 for this code
import os
import sys
import time
import datetime
import shutil

def timestamp():
	return datetime.datetime.utcnow().strftime('%Y-%m-%d_%H-%M-%S-%f')

def mkdirp(path):
	if not os.path.exists(path):
		os.makedirs(path)

def backupDB(argv):
	if len(argv) < 3:
		print('USAGE: %s save_file backup_dir' % (argv[0]))
		return 1

	save_file = argv[1]
	backup_dir = argv[2]

	save_file_basename = os.path.basename(save_file)

	mkdirp(backup_dir)

	last_modified = None

	modified = None
	try:
		modified = str(os.path.getmtime(save_file))
	except Exception as ex:
		print('Reading file modified failed: %s' % (str(ex)))

	if last_modified != modified:
		backup_file_name = '%s_%s' % (timestamp(), save_file_basename)
		backup_file_path = os.path.join(backup_dir, backup_file_name)

		try:
			shutil.copyfile(save_file, backup_file_path)
			last_modified = modified
			print('Backup created: %s' % (backup_file_name))
		except Exception as ex:
			print('Backup failed: %s' % (str(ex)))


#if __name__ == '__main__':
#	sys.exit(main(sys.argv))