#!/bin/bash
# The resulting captain/LCGCMT sets up a image that can be used to
# build a CAPTAIN user image.  It defines three mount points that can
# be set using udocker.  The script should be executed as root or with sudo
#
#  sudo ./docker-LCGCMT.sh
#
# See the docker-CAPTAIN.sh script to see how this is used.  The
# CAPTAIN software is installed in /home/captain.
#
# The user environment should be setup using
#
# source /home/captain/CAPTAIN/captain.profile
#
# The created mount points are as follows:
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
# /home/user -- This provides a mount point for where you can attach
# your home directory for debugging.  It should usually be left unattached.
#
# If you are using udocker, you can attached directories to the mount
# points as follows.
#
#   udocker run -v ${HOME}:/home/user captain/lcgcmt
#
docker image build -t captain/lcgcmt - <<EOF
######################################################################
# Build a CAPTAIN LCGCMT working environment to run batch jobs.
#

FROM debian:stable-slim
MAINTAINER "clark.mcgrew@stonybrook.edu"

# Install the absolute must have core
RUN apt-get update && apt-get install -y \
   bash \
   binutils \
   curl \
   emacs-nox \
   gcc \
   g++ \
   gfortran \
   git \
   lsb-release \
   make \
   nano

# Install the needed development libraries.
RUN apt-get update && apt-get install -y \
    graphviz-dev \
    libavahi-compat-libdnssd-dev \
    libbz2-dev \
    libcfitsio-dev \
    libftgl-dev \
    libglew1.5-dev \
    libgmp-dev \
    libgsl0-dev \
    libkrb5-dev \
    libldap2-dev \
    libmpfr-dev \
    libpcre3-dev \
    libqt4-dev \
    libssl-dev \
    libx11-dev \
    libxext-dev \
    libxft-dev \
    libxml2-dev \
    libxpm-dev \
    python-dev \
    xlibmesa-glu-dev

# Create the captain user
RUN adduser --disabled-password --gecos ""  captain 

# Create a directory that can be attached to the users work directory.
#  This is expected to be the directory in which the job is going to run.
RUN mkdir /home/work; chown captain:captain /home/work

# Create a directory to be attached to the location of the input data.
RUN mkdir /home/data; chown captain:captain /home/data

# Create a directory to be attached to where the output data should be written.
RUN mkdir /home/output; chown captain:captain /home/output

# Create a directory that can be attached to the users home directory.
#  This should probably not be attached in most circumstances.
RUN mkdir /home/user; chown captain:captain /home/user

# Change the working user to captain, and set the main image directory.
USER captain
WORKDIR /home/captain

# Build the CAPTAIN environment.
RUN git clone https://github.com/captain-col/CAPTAIN.git

RUN cd /home/captain/CAPTAIN && \
    ./configure.sh && \
     bash -c "source /home/captain/CAPTAIN/captain.profile; capt-install-cmt"

RUN cd /home/captain && bash -c "source /home/captain/CAPTAIN/captain.profile; capt-install-project -c LCGCMT master" && \
    cd /home/captain/LCGCMT/master/DOWNLOADS && (rm *.* || true) && \
    cd /home/captain/LCGCMT/master/EXTERNALS && (rm *.tar.gz || true) && \
    cd /home/captain/LCGCMT/master/EXTERNALS/ROOT/6.10.02 && \
       (rm -rf root-6.10.02 || true) && \
    cd /home/captain/LCGCMT/master/EXTERNALS && \
       ( (find . -name "*-build" -type d | xargs rm -rf) || true ) && \
    cd /home/captain/LCGCMT/master/EXTERNALS/Boost/1.53.0 && \
       (rm -rf boost_1_53_0 || true)

CMD ["bash"]

EOF

######################################################################

