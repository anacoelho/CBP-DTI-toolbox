#! /bin/bash

code_dir=$1
atlas_file=$2
out_dir=$3

out_file="$out_dir"/atlas_values.txt

export COMMAND_MATLAB=$(command -v matlab)

${COMMAND_MATLAB} -nodisplay -nosplash -r "addpath('${code_dir}');get_atlas_values('${atlas_file}','${out_file}');exit"

while read -r line
do 
	value="$line"
	fslmaths "$atlas_file" -thr $value -uthr $value "$out_dir"/roi"$value".nii.gz

done < "$out_file"