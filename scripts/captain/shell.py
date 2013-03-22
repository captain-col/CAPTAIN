#####################################################################
# This package is automatically available to python scripts in the
# CAPTAIN/scripts directory.
#
# Provide a compatible interface to shell commands.  This works around
# all the crazy deprecation going on in python.  This needs to support
# SL5 which only includes 2.4, and most of the 2.4 process handling is
# deprecated in 2.7 (which is standard on lots of systems).  This is
# suppose to survive the transition to python 3.0

import subprocess

def CaptureShell(command,quiet=True):
    """ Return a tuple with the first element being the stdout, 
    the second being stderr, and the third being the status"""
    if not quiet: print "$", command
    result = subprocess.Popen(command,
                              shell=True,
                              universal_newlines=True,
                              stdout=subprocess.PIPE, 
                              stderr=subprocess.PIPE)
    return (result.stdout.read(), result.stderr.read(), result.returncode)

def Shell(command,quiet=True):
    """ Run a command in a shell.  This has no return value, but will
    raise a subprocess.CallProcessError if the shell return code is
    not zero."""
    if not quiet: print "$", command
    result = subprocess.Popen(command,
                              shell=True,
                              universal_newlines=True)
    retcode = result.wait();
    if retcode != 0:
        raise subprocess.CalledProcessError(retcode,command)
