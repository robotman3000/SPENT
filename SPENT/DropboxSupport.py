"""
Backs up and restores a settings file to Dropbox.
This is an example app for API v2.
"""
from __future__ import print_function

from SPENT import LOGGER as log
import argparse
import contextlib
import datetime
import os
import six
import time
import unicodedata
import sys
import dropbox
from dropbox.files import WriteMode
from dropbox.exceptions import ApiError, AuthError

if sys.version.startswith('2'):
    input = raw_input  # noqa: E501,F821; pylint: disable=redefined-builtin,undefined-variable,useless-suppression

dplog = log.getLogger("dropbox")
log.getLogger("urllib3.connectionpool") # This line removes duplicated entries from this name

# Add OAuth2 access token here.
# You can generate one for yourself in the App Console.
# See <https://blogs.dropbox.com/developers/2014/05/generate-an-access-token-for-your-own-account/>
TOKEN = 'sl.AsY2edZMvY-YMT-kRZq9v6cLNsOvYPGJLrjm9pffWR7uvtxIBRhnJHngwSgtGJhfG_zMAJ8wflkhygCeiVc3utv5RpC0VZhEhsRTfocKNn7hQIbZ7iFFNAqWaJr8Gk6EKLDcnlM'

class DropboxHelper:
    def __init__(self, filepath):
        self.localfile = filepath
        self.backuppath = '/' + filepath
        
        # Check for an access token
        if (len(TOKEN) == 0):
            sys.exit("ERROR: Looks like you didn't add your access token. "
                     "Open up backup-and-restore-example.py in a text editor and "
                     "paste in your token in line 14.")

        # Create an instance of a Dropbox class, which can make requests to the API.
        dplog.debug("Creating a Dropbox object...")
        self.dbx = dropbox.Dropbox(TOKEN)

        # Check that the access token is valid
        try:
            self.dbx.users_get_current_account()
        except AuthError:
            sys.exit("ERROR: Invalid access token; try re-generating an "
                     "access token from the app console on the web.")


    # Uploads contents of self.localfile to Dropbox
    def backup(self):
        with open(self.localfile, 'rb') as f:
            # We use WriteMode=overwrite to make sure that the settings in the file
            # are changed on upload
            dplog.info("Uploading " + self.localfile + " to Dropbox as " + self.backuppath + "...")
            try:
                self.dbx.files_upload(f.read(), self.backuppath, mode=WriteMode('overwrite'))
            except ApiError as err:
                # This checks for the specific error where a user doesn't have
                # enough Dropbox space quota to upload this file
                if (err.error.is_path() and
                        err.error.get_path().reason.is_insufficient_space()):
                    sys.exit("ERROR: Cannot back up; insufficient space.")
                elif err.user_message_text:
                    dplog.error(err.user_message_text)
                    sys.exit()
                else:
                    dplog.error(err)
                    sys.exit()
    
    # Change the text string in self.localfile to be new_content
    # @param new_content is a string
    def change_local_file(self, new_content):
        dplog.info("Changing contents of " + self.localfile + " on local machine...")
        with open(self.localfile, 'wb') as f:
            f.write(new_content)
    
    # Restore the local and Dropbox files to a certain revision
    def restore(self, rev=None):
        # Restore the file on Dropbox to a certain revision
        dplog.info("Restoring " + self.backuppath + " to revision " + rev + " on Dropbox...")
        self.dbx.files_restore(self.backuppath, rev)
    
        # Download the specific revision of the file at self.backuppath to self.localfile
        dplog.info("Downloading current " + self.backuppath + " from Dropbox, overwriting " + self.localfile + "...")
        self.dbx.files_download_to_file(self.localfile, self.backuppath, rev)
    
    # Look at all of the available revisions on Dropbox, and return the oldest one
    def select_revision(self):
        # Get the revisions for a file (and sort by the datetime object, "server_modified")
        dplog.debug("Finding available revisions on Dropbox...")
        entries = self.dbx.files_list_revisions(self.backuppath, limit=30).entries
        revisions = sorted(entries, key=lambda entry: entry.server_modified)
    
        for revision in revisions:
            print(revision.rev, revision.server_modified)
    
        # Return the oldest revision (first entry, because revisions was sorted oldest:newest)
        return revisions[0].rev

    def sync_file(self, localfileName, forceUpload = False, forceDownload = False):
        # If this fails then we assume the file doesn't exist and we upload our version if any exists

        fileName = "/" + localfileName
        dplog.debug("Using remote file \'%s\'" % fileName)
        md = None
        try:
            md = self.dbx.files_get_metadata(fileName)
        except dropbox.exceptions.ApiError as err:
            dplog.exception(err)

        if md is None and os.path.exists(localfileName) and os.path.isfile(localfileName):
            dplog.info(localfileName + ' exists on local but not remote, uploading')
            self.upload(self.dbx, localfileName, fileName)
        elif md is not None:
            if not os.path.exists(localfileName) or not os.path.isfile(localfileName):
                dplog.info(localfileName + ' exists on remote but not local, downloading')
                res = self.download(self.dbx, fileName)
                with open(localfileName, 'wb') as f:
                    f.write(res)

            if forceUpload:
                dplog.info(localfileName + ' force upload')
                self.upload(self.dbx, localfileName, fileName, overwrite=True)

            if forceDownload:
                dplog.info(localfileName + ' force download')
                res = self.download(self.dbx, fileName)
                with open(localfileName, 'wb') as f:
                    f.write(res)

        else:
            dplog.error("Failed to sync DB")

    def sync_file_smart(self, localfileName):
        # If this fails then we assume the file doesn't exist and we upload our version if any exists

        fileName = "/" + localfileName
        dplog.debug("Using remote file \'%s\'" % fileName)
        md = None
        try:
            md = self.dbx.files_get_metadata(fileName)
        except dropbox.exceptions.ApiError as err:
            dplog.exception(err)

        if md is None and os.path.exists(localfileName) and os.path.isfile(localfileName):
            dplog.info(localfileName + ' exists on local but not remote, uploading')
            self.upload(self.dbx, localfileName, fileName)
        elif md is not None:
            if not os.path.exists(localfileName) or not os.path.isfile(localfileName):
                dplog.info(localfileName + ' exists on remote but not local, downloading')
                res = self.download(self.dbx, fileName)
                with open(localfileName, 'wb') as f:
                    f.write(res)

            mtime = os.path.getmtime(localfileName)
            mtime_dt = datetime.datetime(*time.gmtime(mtime)[:6])
            size = os.path.getsize(localfileName)

            if (isinstance(md, dropbox.files.FileMetadata) and
                    mtime_dt == md.client_modified and size == md.size):
                dplog.info(localfileName + ' is already synced [stats match]')
            else:
                dplog.info(localfileName + ' exists with different stats, downloading')
                res = self.download(self.dbx, fileName)
                with open(localfileName, 'rb') as f:
                    data = f.read()
                if res == data:
                    dplog.info(localfileName + ' is already synced [content match]')
                else:
                    dplog.info(localfileName + ' has changed since last sync')
                    self.upload(self.dbx, localfileName, fileName, overwrite=True)
        else:
            dplog.error("Failed to sync DB")

    def close(self):
        self.dbx.close()

    def list_folder(vdbx, folder, subfolder):
        """List a folder.

        Return a dict mapping unicode filenames to
        FileMetadata|FolderMetadata entries.
        """
        path = '/%s/%s' % (folder, subfolder.replace(os.path.sep, '/'))
        while '//' in path:
            path = path.replace('//', '/')
        path = path.rstrip('/')
        try:
            with stopwatch('list_folder'):
                res = dbx.files_list_folder(path)
        except dropbox.exceptions.ApiError as err:
            dplog.error('Folder listing failed for', path, '-- assumed empty:', err)
            return {}
        else:
            rv = {}
            for entry in res.entries:
                rv[entry.name] = entry
            return rv

    def download(self, dbx, remotePath):
        """Download a file.

        Return the bytes of the file, or None if it doesn't exist.
        """
        #path = '/%s/%s/%s' % (folder, subfolder.replace(os.path.sep, '/'), name)
        #while '//' in path:
        #    path = path.replace('//', '/')
        with self.stopwatch('download'):
            try:
                md, res = dbx.files_download(remotePath)
            except dropbox.exceptions.HttpError as err:
                dplog.exception(err)
                return None
        data = res.content
        #dplog.debug(len(data) + ' bytes; md:', md)
        return data

    def upload(self, dbx, fullname, remotePath, overwrite=False):
        """Upload a file.

        Return the request response, or None in case of error.
        """
        #path = '/%s/%s/%s' % (folder, subfolder.replace(os.path.sep, '/'), name)
        #while '//' in path:
        #    path = path.replace('//', '/')
        mode = (dropbox.files.WriteMode.overwrite
                if overwrite
                else dropbox.files.WriteMode.add)
        mtime = os.path.getmtime(fullname)
        with open(fullname, 'rb') as f:
            data = f.read()
        with self.stopwatch('upload %d bytes' % len(data)):
            try:
                res = dbx.files_upload(
                    data, remotePath, mode,
                    client_modified=datetime.datetime(*time.gmtime(mtime)[:6]),
                    mute=True)
            except dropbox.exceptions.ApiError as err:
                dplog.exception(err)
                return None
        dplog.debug('uploaded as %s' % res.name.encode('utf8'))
        return res

    def yesno(self, message, default, args):
        """Handy helper function to ask a yes/no question.

        Command line arguments --yes or --no force the answer;
        --default to force the default answer.

        Otherwise a blank line returns the default, and answering
        y/yes or n/no returns True or False.

        Retry on unrecognized answer.

        Special answers:
        - q or quit exits the program
        - p or pdb invokes the debugger
        """
        if args.default:
            print(message + '? [auto]', 'Y' if default else 'N')
            return default
        if args.yes:
            print(message + '? [auto] YES')
            return True
        if args.no:
            print(message + '? [auto] NO')
            return False
        if default:
            message += '? [Y/n] '
        else:
            message += '? [N/y] '
        while True:
            answer = input(message).strip().lower()
            if not answer:
                return default
            if answer in ('y', 'yes'):
                return True
            if answer in ('n', 'no'):
                return False
            if answer in ('q', 'quit'):
                print('Exit')
                raise SystemExit(0)
            if answer in ('p', 'pdb'):
                import pdb
                pdb.set_trace()
            print('Please answer YES or NO.')

    @contextlib.contextmanager
    def stopwatch(self, message):
        """Context manager to print how long a block of code took."""
        t0 = time.time()
        try:
            yield
        finally:
            t1 = time.time()
            dplog.debug('Total elapsed time for %s: %.3f' % (message, t1 - t0))


if __name__ == '__main__':
        # Create a backup of the current settings file
        backup()

        # Change the user's file, create another backup
        change_local_file(b"updated")
        backup()

        # Restore the local and Dropbox files to a certain revision
        to_rev = select_revision()
        restore(to_rev)

        print("Done!")