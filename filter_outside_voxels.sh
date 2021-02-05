#!/bin/bash

# script to remove voxels from individual clusterings that don't overlap with original atlas

dir=$1 # directory where individual clusterings are stored
filename=$2 # file with subject IDs
atlas_mask=$3 # original atlas mask
metric=$4

while read -r line
do
	sub="$line"
	echo "$sub"

	fslmaths "$dir"/"$sub"/"$metric"/mni2009c_asym/diff_to_MNI_warped.nii.gz -mas $atlas_mask "$dir"/"$sub"/"$metric"/mni2009c_asym/"$sub"_dkt40_parcellation_filtered


done < "$filename"
	
