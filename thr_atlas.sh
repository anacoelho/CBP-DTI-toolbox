#! /bin/bash

code_dir=$1
wd=$2
size_thr=$3
atlas_file=$4
orig_atlas_file=$5
out_filename=$6
metric=$7

export COMMAND_MATLAB=$(command -v matlab)

${COMMAND_MATLAB} -nodisplay -nosplash -r "addpath('${code_dir}');thr_atlas('${wd}','${size_thr}','${atlas_file}','${orig_atlas_file}','${out_filename}','${metric}');exit"

