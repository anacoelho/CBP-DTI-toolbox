#! /bin/bash

wd=$1
atlas=$2
nrois=$3


mkdir -p "$wd"/"$atlas"_masks

for ((i=1; i<="$nrois"; i++))
do
	fslmaths "$wd"/"$atlas".nii.gz -thr $i -uthr $i -bin "$wd"/"$atlas"_masks/"$atlas"_"$i".nii.gz
done