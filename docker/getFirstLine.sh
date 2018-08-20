#!/bin/bash
#
#  An example bash function to get the first line from a file, remove
#  the line from the file, and print the line to stdout.  This is
#  used as follows (assuming the file to be read is
#  "file-to-read.txt").

# while true; do
#     LINE=$(getFirstLine file-to-read.txt)
#     if [ ${#LINE} -lt 1 ]; then
#         echo NO INPUT
#         exit 0;
#     fi
#     echo ${LINE}
# done

function getFirstLine () {
    INPUT=${1}
    if [ ${#INPUT} -lt 1 ]; then
	return
    fi
    (flock 9
     head -n 1 ${INPUT}
     sed -i.bak 1d ${INPUT}
	) 9> ${INPUT}-lock
}

