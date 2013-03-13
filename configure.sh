#! /bin/sh
#
# Create the login scripts (captain.profile and captain.cshrc).  This
# rewrites input templates with installation specific values.
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

###########################################################
# Set the location of this install.
CAPT_ROOT=$(dirname ${PWD})

# Set default for the CAPTAIN http pages.  This will be used with
# punctuation between the variable and the pages.
CAPT_HTTP='http://nngroup.physics.sunysb.edu/~captain'

# Set the default for the CAPTAIN git server.  This will be used as
# "${CAPT_GIT}repository_name".  Notice that there is no punctuation
# between the variable and the repository.
CAPT_GIT=`git config remote.origin.url | sed s/CAPTAIN//`

# Make sure that this is being run from the top CAPTAIN directory.  Exit if we
# are not.
if [ x.git != x$(git rev-parse --git-dir) ]; then
    usage   
    echo ERROR: Must be run from a top level CAPTAIN directory.
    exit 1; 
fi

# Handle the input parameters.  This is mostly copied from the getopt
# documentation.  It relies on gnu getopt.

TEMP=$(getopt -o hu:g: \
    --long help,url-root:,git-root: \
    -- "$@")

if [ $? != 0 ]; then
    echo
    echo "Try '$0 --help'"
    exit 1;
fi

eval set -- "${TEMP}"

while true; do
    case "$1" in
	-h|--help) usage; shift; exit 0;;
	-u|--url-root) CAPT_HTTP=$2; shift 2;;
	-g|--git-root) CAPT_GIT=$2; shift 2;;
	--) break;;
	*) break;;
    esac
done
shift

#####################################################################
# Find the base directory and other "setables" for this installation,
# and set it in the login scripts.  The login scripts have this
# parameterized as "@@CAPTAINROOT@@", &c.

for input in inputs/*.in; do
    output=`basename ${input} .in`
    echo "Write $output from $input"
    cat $input | \
	sed "s-@@CAPTAINHTTP@@-${CAPT_HTTP}-" | \
	sed "s-@@CAPTAINGIT@@-${CAPT_GIT}-" | \
	sed "s:@@CAPTAINROOT@@:${CAPT_ROOT}:g" \
	> $output
done

cat <<EOF

Setup files named 

   ${CAPT_ROOT}/CAPTAIN/captain.profile
   ${CAPT_ROOT}/CAPTAIN/captain.cshrc

have been created.  You can source these files directly, or add the
following aliases to the login scripts to simplify CAPTAIN setup.

sh:  alias capt-setup=". ${CAPT_ROOT}/CAPTAIN/captain.profile"
csh: alias capt-setup "source ${CAPT_ROOT}/CAPTAIN/captain.cshrc"

The environment will then be setup by running "capt-setup" If this
command is run from inside of a CAPTAIN package or project, the local
CMT setup script (cmt/setup.sh or cmt/setup.csh) will be run.

EOF

