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

   -h : Print this documentation.

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
CAPT_GIT=`git config remote.origin.url | sed s/CAPTAIN.git// | sed s/CAPTAIN//`

# Make sure that this is being run from the top CAPTAIN directory.  Exit if we
# are not.
if [ x.git != x$(git rev-parse --git-dir) ]; then
    usage   
    echo ERROR: Must be run from a top level CAPTAIN directory.
    exit 1; 
fi

while getopts "hu:g:" option; do
    case $option in
	h) usage; exit 0;;
	u) CAPT_HTTP=$OPTARG;;
	g) CAPT_GIT=$OPTARG;;
	*) usage; exit 1;;
    esac
done
shift $((OPTIND-1))

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

if [ "x${CAPTAIN_CPP_COMPILER}" != "x" ]; then
    echo User selected C++ compiler: $(which ${CAPTAIN_CPP_COMPILER})
    ln -sf $(which $CAPTAIN_CPP_COMPILER) ${CAPT_ROOT}/CAPTAIN/scripts/g++
else
    # Set the default c++ compiler for this installation.  This should be
    # changed to reflect the preferred compilers.
    for vers in g++-4.9 g++-4.8 g++-5 g++-4.7 g++; do
	if which $vers; then
	    echo Choosing default C++ compiler: $(which $vers)
	    ln -sf $(which $vers) ${CAPT_ROOT}/CAPTAIN/scripts/g++
	    break;
	fi
    done
fi

if [ "x${CAPTAIN_CC_COMPILER}" != "x" ]; then
    echo User selected C++ compiler: $(which ${CAPTAIN_CC_COMPILER})
    ln -sf $(which $CAPTAIN_CC_COMPILER) ${CAPT_ROOT}/CAPTAIN/scripts/g++
else
    # Set the default c++ compiler for this installation.  This should be
    # changed to reflect the preferred compilers.
    for vers in gcc-4.9 gcc-4.8 gcc-5 gcc-4.7 gcc; do
	if which $vers; then
	    echo Choosing default C++ compiler: $(which $vers)
	    ln -sf $(which $vers) ${CAPT_ROOT}/CAPTAIN/scripts/g++
	    break;
	fi
    done
fi

cat <<EOF

Setup files named 

   ${CAPT_ROOT}/CAPTAIN/captain.profile
   ${CAPT_ROOT}/CAPTAIN/captain.cshrc

have been created.  You can source these files directly, or add the
following aliases to the login scripts to simplify CAPTAIN setup.

sh:  alias capt-setup=". ${CAPT_ROOT}/CAPTAIN/captain.profile"
csh: alias capt-setup "source ${CAPT_ROOT}/CAPTAIN/captain.cshrc"

These scripts make sure the capt-setup command is defined, and the
environment will then be setup by running "capt-setup".  If this
command is run from inside of a CAPTAIN package or project, the local
CMT setup script (cmt/setup.sh or cmt/setup.csh) will be run.

EOF

