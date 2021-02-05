#! /bin/bash

code_dir=$1
wd=$1
roi_file=$2
atlas_file=$3
orig_atlas_file=$4
size_thr=$5

export COMMAND_MATLAB=$(command -v matlab)

${COMMAND_MATLAB} -nodisplay -nosplash -r "addpath('${code_dir}');remove_isolated_components('${wd}','${roi_file}','${atlas_file}','${orig_atlas_file}','${size_thr}');exit"

