#!/bin/bash

WD=$1
ATLAS=$2
NR_TOTAL_ROIS=$3
METRIC=$4

# path to ROI images
ROI_PATH="$WD"/consensus_rois/"$METRIC"

# multiply each cluster by 10
for (( i=1; i<=$NR_TOTAL_ROIS; i++))
do

	roi="$ROI_PATH"/roi"$i"_consensus_smoothed18.nii.gz
	echo $roi
	value=$((i*10))
	fslmaths "$roi" -add $value "$ROI_PATH"/roi"$i"_consensus_sm18_relabel.nii.gz
	fslmaths "$ROI_PATH"/roi"$i"_consensus_sm18_relabel.nii.gz -thr $((value+1)) "$ROI_PATH"/roi"$i"_consensus_sm18_relabel.nii.gz

done

