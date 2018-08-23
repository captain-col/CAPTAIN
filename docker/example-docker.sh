#!/bin/bash
#
# This is an example script that might be submitted to a batch queue.
# This assumes that the udocker code is installed at the location of
# UDOCKER_DIR.  It can be installed by doing
#
# cd /my/installation/area
# tar xvzf udocker-1.1.1.tar.gz
# export UDOCKER_DIR=/my/installation/area/udocker-1.1.1
#
# Where you (obviously) need to change "/my/installation/area" to be
# where you unpack the udocker tar file.
#
# The captain container can be built with some scripts found in the
# CAPTAIN repository.  It has probably been built already.  You need
# to install it using
#
# udocker load -i captainRelease.tar
# udocker run --name="captain_180802" captain/release:latest
#
# You can choose any container name you want.  I suggest that you
# check the udocker documentation for more information.

######################
# This particular script is submitted with a single command line
# argument for the number of events to generate.
#
# Example (for slurm):  sbatch --array=0-10 example-docker.sh 10
#
######################

# The run number for this job.  For example, this might be 90 (to indicate MC)
# plus the 6 digit date (YYMMDD) for the date of the software version.
RUN_NUMBER=90180727

# The number of events to generate
EVENT_COUNT=$1
shift

###########################################################################
# This should be set to something that is going to be useful.  The
# actual structure of this will depend on the queue system, but it is
# a good idea to include the job number in the name.
# Examples: 
#   JOB_NAME=lansceProton_${SLURM_JOB_ID}        # For slurm
  JOB_NAME=lansceProton_${SLURM_ARRAY_JOB_ID}  # For slurm with a job array
#   JOB_NAME=lansceProton_${PBS_JOBID}           # For PBS
#   JOB_NAME=lansceProton                        # For testing
###########################################################################

###########################################################################
# The next four exports need to be edited to reflect your
# installation.  At the time this comment was written, the values
# reflected running a job in my area on seawulf.physics.sunysb.edu.
###########################################################################

###########################################################################
# This needs to be adjusted to point to the location where udocker is
# installed.
export UDOCKER_DIR=/home/mcgrew/work/captain/software/udocker-1.1.1
###########################################################################

###########################################################################
# The standard captain/release image defines some working directories
# that can be used to export results from the job.  This directories
# must exist, if they aren't provided the image may be modified and
# bad things (unspecified!) can happen.
###########################################################################

###########################################################################
# The location where the job should be run.  This directory needs to
# be created before the job is run.  It will be mapped to "/home/work"
# inside the udocker job.
export WORK_DIR=/home/mcgrew/tmp/work
###########################################################################

# The location where the input data should be read from (not used for
# most MC jobs).  This will be mapped to "/home/data" inside the
# udocker job.  If absolutely nothing is read, or written to
# /home/data, the it doesn't need to be attached
export DATA_DIR=/home/mcgrew/tmp/data
###########################################################################

###########################################################################
# The location where the output data should be written.  It will be
# mapped to "/home/output" inside of the udocker jobs.
export OUTPUT_DIR=/home/mcgrew/tmp/output
###########################################################################

# Create a new working directory under neet ${WORK_DIR}.  Notice that
# this is happening outside of udocker!  This should only be used in
# the calculation of JOB_PACKAGE.
JOB_DIR=${WORK_DIR}/${JOB_NAME}
if [ ! -f ${JOB_DIR} ] ; then
    mkdir -p ${JOB_DIR}
fi

# Define some variables that will be substituted into the
# "here-document".  The JOB_PACKAGE will be a subdirectory of
# /home/work/${JOB_NAME}, and is used to create a cmt package to run
# the MC from.
JOB_PACKAGE=$(mktemp -d -p ${JOB_DIR} ${JOB_NAME}.XXXXXXXX)
JOB_PACKAGE=$(basename ${JOB_PACKAGE})

# Run udocker with a script that is provided as a "here-document".
# Notice that inside the here-document script all directories are
# refering to the udocker file system, and the native file system is
# not directly available.
${UDOCKER_DIR}/udocker run -v ${WORK_DIR}:/home/work \
    -v ${DATA_DIR}:/home/data \
    -v ${OUTPUT_DIR}:/home/output \
    captainRelease_180802 <<EOF
source /home/captain/CAPTAIN/captain.profile
cd /home/work

while [ ! -f /home/work/${JOB_NAME}/cmt/project.cmt ]; do
    echo MISSING /home/work/${JOB_NAME}/cmt/project.cmt
    echo CREATE ${JOB_NAME} in ${PWD}
    cmt create_project ${JOB_NAME} -use=captain-release:master
    sleep 2
done
sleep 2

cd /home/work/${JOB_NAME}
source /home/captain/CAPTAIN/captain.profile
cmt create ${JOB_PACKAGE} v0
chmod g+rw ${JOB_PACKAGE}

cd /home/work/${JOB_NAME}/${JOB_PACKAGE}/cmt
echo use captainRelease >> requirements
cmt config
source /home/captain/CAPTAIN/captain.profile

########################################################
# EVERYTHING ABOVE THIS IS FAIRLY GENERIC (change JOB_NAME and MOUNTED
# DIRECTORIES to modify the behavior).  FROM HERE ON IS THE ACTUAL JOB
# CODE.  It can be changed to run different programs and scripts.

# Create an output directory in /home/output based on the job name and
# package.  This then changes to that directory.
cd /home/output
mkdir -p ${JOB_NAME}/${JOB_PACKAGE}
cd /home/output/${JOB_NAME}/${JOB_PACKAGE}

# Run the script.  This should use the full path of the script in the 
# udocker container.
/home/captain/captain-release/master/detSim/scripts/detsim-lansce-proton ${RUN_NUMBER} ${EVENT_COUNT}

# Put the various types of output files into their own special locations.
if [ ! -f /home/output/${JOB_NAME}/reco ]; then
    mkdir -p /home/output/${JOB_NAME}/reco || true
fi
mv *_reco_*.root /home/output/${JOB_NAME}/reco || true

if [ ! -f /home/output/${JOB_NAME}/g4mc ]; then
    mkdir /home/output/${JOB_NAME}/g4mc || true
fi
mv *_g4mc_*.root /home/output/${JOB_NAME}/g4mc || true

if [ ! -f /home/output/${JOB_NAME}/log ]; then
    mkdir /home/output/${JOB_NAME}/log || true
fi
mv captControl*.log /home/output/${JOB_NAME}/log || true

# Clean up the temporary files that were created as the job ran.
cd /home/output
ls /home/output/${JOB_NAME}/${JOB_PACKAGE}
rm -rf /home/output/${JOB_NAME}/${JOB_PACKAGE} || true

EOF
