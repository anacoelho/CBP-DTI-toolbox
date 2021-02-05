#! /bin/bash

code_dir=$1
wd=$2
metric=$3
roi_id=$4
k=$5


export COMMAND_MATLAB=$(command -v matlab)

${COMMAND_MATLAB} -nodisplay -nosplash -r "addpath('${code_dir}');postprocess_cluster('${wd}','${metric}','${roi_id}','${k}');exit" &