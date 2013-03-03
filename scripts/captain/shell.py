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

def Shell(command):
    """ Return a tuple with the first element being the stdout, 
    the second being stderr, and the third being the status"""

    result = subprocess.Popen(command,
                              shell=True,
                              universal_newlines=True,
                              stdout=subprocess.PIPE, 
                              stderr=subprocess.PIPE)

    return (result.stdout.read(), result.stderr.read(), result.returncode)

