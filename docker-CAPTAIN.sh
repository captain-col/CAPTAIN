#!/bin/bash
#
# This builds a docker container (using save) that can be imported
# into udocker using "udocker load -i captainRelease.tar".  The
# resulting container defines three mount points that can be set using
# udocker
#
# /home/work -- This is suppose to be pointed at whereever you have
# the script you want to run.  My intention is that you will create a
# cmt project inside /home/work:
#
#   cd /home/work
#   cmt create_project <my-job-name> -use=captain-release:master
#   cd /home/work/<my-job-name>
#   cmt create <work-area> v0
#      -- Then setup the local work area
#
# /home/data -- This is where I intend to have the input data
# "mounted".  It should be attached to a directory containing the
# input data file.
#
# /home/output -- This is where I intend to have the output directory
# "mounted".  It should be attached to a directory where the output
# will go.
#
# Using udocker, and assuming a script that will create the project
# area in /home/work, the running will be:
#
# udocker load -i captainRelease.tar
# udocker --volume=${HOME}:/home/work \
#      --volume=<data-dir>:/home/data \
#      --volume=<output-dir>:/home/output \
#      shell_script.sh
#
# More explicitly.  Assuming that the data is in the directory
# /project/CAPTAIN/2017/tpc/, that the output files should be
# placed in the directory /project/CAPTAIN/tpc/output/, and you want
# to run a shell scripted named "shell_script.sh", then the command is
#
# udocker --volume=${HOME}:/home/work \
#      --volume=/project/CAPTAIN/2017/tpc:/home/data \
#      --volume=/project/CAPTAIN/tpc/output:/home/output \
#      run captain/release shell_script.sh
#
# The shell commands can also be embedded
#
# udocker --volume=${HOME}:/home/work \
#      --volume=/project/CAPTAIN/2017/tpc:/home/data \
#      --volume=/project/CAPTAIN/tpc/output:/home/output \
#      run captain/release /bin/bash <<EOF
# echo "hello world"
# cd /home/work
# pwd
# ls -l
# EOF

docker image build -t captain/release - <<EOF
######################################################################
# Build a CAPTAIN working environment to run batch jobs.
#

FROM captain/lcgcmt:latest
MAINTAINER "clark.mcgrew@stonybrook.edu"

RUN cd /home/captain && \
     bash -c "source /home/captain/CAPTAIN/captain.profile; capt-install-project captain-release master"

RUN cd /home/captain/captain-release/master/captainRelease/cmt  && \
     bash -c "source /home/captain/CAPTAIN/captain.profile; cmt config"

RUN cd /home/captain/captain-release/master/captainRelease/cmt  && \
     bash -c "source /home/captain/CAPTAIN/captain.profile; cmt broadcast cmt config"

RUN cd /home/captain/captain-release/master/captainRelease/cmt  && \
     bash -c "source /home/captain/CAPTAIN/captain.profile; cmt broadcast make"

CMD ["bash"]

EOF

docker save captain/release:latest -o captainRelease.tar


echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo YOU MUST CHANGE THE OWNERSHIP OF THE CONTAINER TAR FILE
echo e.g. sudo chown mcgrew captainRelease.tar
echo OBVIOUSLY... USE YOUR OWN USER NAME
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Add the container to udocker using "udocker load -i captainRelease.tar"

