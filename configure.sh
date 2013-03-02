#!/bin/dash
#
#

usage () {
    cat <<EOF

Setup the CAPTAIN software.  This creates the files that can be
sourced by users to access the software.  Mostly they just define
paths.  This script must be executed from the main CAPTAIN directory.
After it has been run, the captain.profile and captain.cshrc files
will exist.  They can be directly sourced by the user, or an alias can
be added to the profile or cshrc.

Usage:
  ./configure.sh

Options:

   -h, --help : Print this documentation.

EOF
}

# Make sure that this is being run from the top CAPTAIN directory.  Exit if we
# are not.
if [ x.git != x$(git rev-parse --git-dir) ]; then
    usage   
    echo ERROR: Must be run from a top level CAPTAIN directory.
    exit 1; 
fi

CAPTAINROOT=$(dirname ${PWD})

cat inputs/captain.profile.in | \
    sed "s:@@CAPTAINROOT@@:${CAPTAINROOT}:g" \
    > captain.profile

cat inputs/captain.cshrc.in | \
    sed "s:@@CAPTAINROOT@@:${CAPTAINROOT}:g" \
    > captain.cshrc

cat <<EOF
Setup files named 

   ${CAPTAINROOT}/CAPTAIN/captain.profile
   ${CAPTAINROOT}/CAPTAIN/captain.cshrc

have been created.  Users can source these files directly, or add the
following aliases to their login scripts to simplify CAPTAIN setup.

sh:  alias capt-setup=". ${CAPTAINROOT}/CAPTAIN/captain.profile"
csh: alias capt-setup "source ${CAPTAINROOT}/CAPTAIN/captain.cshrc"

The environment will then be setup by running "capt-setup" If this
command is run from inside of a CAPTAIN package or project, the local
CMT setup script (cmt/setup.sh or cmt/setup.csh) will be run.

EOF

