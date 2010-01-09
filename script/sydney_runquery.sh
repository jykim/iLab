#!/bin/bash
source /home/jykim/.bash_profile
#$ -S /bin/sh -o cluster_out.log -e cluster_err.log -cwd
$1/bin/runquery $4 $2 > $3
