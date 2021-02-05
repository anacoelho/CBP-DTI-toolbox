#!/bin/bash

template="$FSLDIR"/standard/mni_icbm152_t1_tal_nlin_asym_09c_brain.nii.gz 
template_mask="$FSLDIR"/standard/mni_icbm152_t1_tal_nlin_asym_09c_mask.nii

data_dir=$1
wd_dir=$2
filename=$3
metric=$4

while read -r line
do
	sub="$line"
	mkdir -p "$wd_dir"/"$sub"/"$metric"/mni2009c_asym/

	diff="$data_dir"/"$sub"/"$sub"_diff_b0_bet.nii.gz
	str="$data_dir"/"$sub"/"$sub"_STR_bet.nii.gz 
	str_mask="$data_dir"/"$sub"/"$sub"_STR_bet_mask.nii.gz
	out="$wd_dir"/"$sub"/"$metric"/mni2009c_asym/
	parcellation="$wd_dir"/"$sub"/"$metric"/"$sub"_parcellation.nii.gz

	bash antsRegistration_parc_to_mni.sh $diff $str $str_mask $template $template_mask $out $parcellation

done < "$filename"
