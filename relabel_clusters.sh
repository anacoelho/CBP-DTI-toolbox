#!/bin/bash

dir=$1
sub_file=$2
metric=$3
nrois=$4

while read -r line
do
	sub="$line"
	echo "$sub"

	for ((i=1; i<="$nrois"; i++))
	do

		roi_file="$dir"/"$sub"/"$metric"/roi"$i"_cluster_mask.nii.gz

		value=$((i*10))
		fslmaths $roi_file -add $value "$dir"/"$sub"/"$metric"/roi"$i"_cluster_relabel.nii.gz
		fslmaths "$dir"/"$sub"/"$metric"/roi"$i"_cluster_relabel.nii.gz -thr $((value+1)) "$dir"/"$sub"/"$metric"/roi"$i"_cluster_relabel.nii.gz
		
	done 
done < "$sub_file"
