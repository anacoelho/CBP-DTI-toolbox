#!/bin/bash

WD=$1
infile_basename=$2
outfile_basename=$3

string_add=''
n=0

for file in "$WD"/*"$infile_basename".nii.gz
do
	#echo $file
	if (( $(echo "$n" == "0"| bc -l) )); then
		string_add="$string_add "$file""
	else
		string_add="$string_add -add "$file""

	fi
	n=$((n+1))

done

#echo $string_add

fslmaths $string_add "$WD"/"$outfile_basename".nii.gz
