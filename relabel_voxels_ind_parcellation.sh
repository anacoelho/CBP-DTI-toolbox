#! /bin/bash

code_dir=$1
in_dir=$2
subj_file=$3
atlas_file=$4
out_dir=$5
metric=$6

export COMMAND_MATLAB=$(command -v matlab)

${COMMAND_MATLAB} -nodisplay -nosplash -r "addpath('${code_dir}');relabel_voxels_ind_parcellation('${in_dir}','${subj_file}','${atlas_file}','${out_dir},'${metric}');exit"