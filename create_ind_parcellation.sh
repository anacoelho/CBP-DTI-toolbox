#!/bin/bash

WD=$1
filename=$2
metric=$3


while read -r line 
do
	sub="$line"
	string_add=''
	n=0	
	
	files=$(find "$WD"/"$sub"/"$metric"/ -name 'roi*_cluster_relabel.nii.gz' -type f)

	for file in $files
	do
		
		#echo $file
		if (( $(echo "$n" == "0"| bc -l) )); then
			string_add="$string_add "$file""
		else
			string_add="$string_add -add "$file""

		fi
		n=$((n+1))

	done
	fslmaths $string_add "$WD"/"$sub"/"$metric"/"$sub"_parcellation.nii.gz
	
done < "$filename"

