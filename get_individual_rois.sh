#!/bin/bash

dir=$1
roi_file=$2
subj_file=$3
metric=$4

while read -r line
do
	sub="$line"

	while read -r rline
	do
		l="$rline"
		IFS=$'\t'
		tmp=($l)
		roi_id="${tmp[0]}"

		if [ "$metric" == "silhouette" ]; then
			k="${tmp[1]}"
		elif [ "$metric" == "db" ]; then
			k="${tmp[2]}"
		elif [ "$metric" == "ch" ]; then
			k="${tmp[3]}"
		fi

		min_cl="${roi_id}1"
		max_cl="$roi_id$k"

		fslmaths "$dir"/"$sub"/"$metric"/mni2009c_asym/"$sub"_parc_filt_relabeled.nii.gz -thr $min_cl -uthr $max_cl "$dir"/"$sub"/"$metric"/k"$k"_roi"$roi_id"_MNI2009_filt.nii.gz
	
	done < "$roi_file"

done < "$subj_file"

