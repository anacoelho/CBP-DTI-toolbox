#! /bin/bash

code_dir=$1
in_dir=$2
out_dir=$3
subj_file=$4
nrois=$5

export COMMAND_MATLAB=$(command -v matlab)

${COMMAND_MATLAB} -nodisplay -nosplash -r "addpath('${code_dir}');get_sparse_mat('${in_dir}','${out_dir}','${subj_file}','${nrois}');exit"