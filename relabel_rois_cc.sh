#!/bin/bash

wd=$1
rois_file=$2


mkdir -p "$wd"/relabeled_cc_masks

while read -r line
do
	l="$line"
	IFS=$'\t'
	tmp=($l)
	roi_value="${tmp[0]}"
	new_value="${tmp[1]}"

	div=$(bc -l <<< 'scale=1; 1/10')
	roi="$wd"/roi"$roi_value"_cc.nii.gz
	thr=$(bc -l <<< "scale=1; $new_value+$div")
	
	fslmaths "$roi" -mul $div "$wd"/relabeled_cc_masks/roi"$roi_value"_cc_relabel.nii.gz
	fslmaths "$wd"/relabeled_cc_masks/roi"$roi_value"_cc_relabel.nii.gz -add $new_value "$wd"/relabeled_cc_masks/roi"$roi_value"_cc_relabel.nii.gz
	
	min_v=$(fslstats "$wd"/relabeled_cc_masks/roi"$roi_value"_cc_relabel.nii.gz -R | awk '{print $1}')
	
	if (( $(echo "$min_v > $new_value" | bc -l) )); then
		thr=$(bc -l <<< "scale=1; $new_value+$div")
	else
		thr=$(bc -l <<< "scale=1; $min_v+$div")
	fi
		
	echo $new_value $thr
	
	fslmaths "$wd"/relabeled_cc_masks/roi"$roi_value"_cc_relabel.nii.gz -thr $thr "$wd"/relabeled_cc_masks/roi"$roi_value"_cc_relabel.nii.gz

done < "$rois_file"

