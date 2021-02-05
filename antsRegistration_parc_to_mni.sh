#!/bin/bash

dim=3 # image dimensionality
#AP="/home/neuroimaging/Documents/antsbin/bin/" # path to ANTs binaries
ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4  # controls multi-threading
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS
diff=$1 ; str=$2 ; str_mask=$3; template=$4; template_mask=$5; out=$6; parcellation=$7   # diffusion image, T1 image, T1 mask image, template image, template mask image, output directory, parcellation to register from diffusion to MNI

if [[ ${#diff} -eq 0 ]] ; then #CLI feedback when parameters are not given correctly to the script 
	echo usage is 
	echo $0 diff.nii.gz str.nii.gz str_brain_mask.nii.gz template.nii.gz template_brain_mask.nii.gz naming_prefix parcellation.nii.gz
	exit
fi

if [[ ! -s $diff ]] ; then echo no diffusion $f ; exit; fi
if [[ ! -s $str ]] ; then echo no structural $str ; exit; fi
if [[ ! -s $str_mask ]] ; then echo no structural brain mask $str_mask ;exit; fi
if [[ ! -s $template ]] ; then echo no template $template ; exit; fi
if [[ ! -s $template_mask ]] ; then echo no template brain mask $template_mask ;exit; fi
if [[ ! -s $parcellation ]] ; then echo no parcellation $parcellation ;exit; fi

reg=antsRegistration # path to antsRegistration
its=10000x1111x5 #iterations per scale for affine step
percentage=0.25 #percentage of voxels sampled for evaluating the metric
syn="20x20x0,0,5" #iterations per scale and stopping criterion


#------------------------------------------------ T1 to MNI registration -------------------------------------------------
imgs=" $template, $str " #variable specifying the fixed and moving images
nm1=$out/T1_to_MNI #naming prefix

$reg -d $dim -r [ $imgs ,1] -m mattes[  $imgs, 1 , 32, regular, 0.05 ] -t translation[ 0.1 ] -c [1000,1.e-8,20] -s 4vox -f 6 -l 1 -m mattes[  $imgs, 1 , 32, regular, 0.1 ] -t rigid[ 0.1 ] -c [1000x1000,1.e-8,20] -s 4x2vox -f 4x2 -l 1 -m mattes[  $imgs, 1 , 32, regular, 0.1 ] -t affine[ 0.1 ] -c [$its,1.e-8,20] -s 4x2x1vox -f 3x2x1 -l 1 -m mattes[  $imgs, 1 , 32 ] -t SyN[ .20, 3, 0 ] -c [ $syn] -s 1x0.5x0vox -f 4x2x1 -l 1 -u 1 -z 1 -x $template_mask --float 1 -o [${nm1},${nm1}_diff.nii.gz,${nm1}_inv.nii.gz] -v 1

antsApplyTransforms -d $dim -i $str -r $template -n linear -t ${nm1}1Warp.nii.gz -t ${nm1}0GenericAffine.mat -o ${nm1}_warped.nii.gz --float 1 -v 1


#------------------------------------------------ Diff to T1 registration ------------------------------------------------
imgs=" $str, $diff " #variable specifying the fixed and moving images
nm2=$out/diff_to_T1 #naming prefix

$reg -d $dim -r [ $imgs ,1] -m mattes[  $imgs, 1 , 32, regular, 0.05 ] -t translation[ 0.1 ] -c [1000,1.e-8,20] -s 4vox -f 6 -l 1 -m mattes[  $imgs, 1 , 32, regular, 0.1 ] -t rigid[ 0.1 ] -c [1000x1000,1.e-8,20] -s 4x2vox -f 4x2 -l 1 -m mattes[  $imgs, 1 , 32, regular, 0.1 ] -t affine[ 0.1 ] -c [$its,1.e-8,20] -s 4x2x1vox -f 3x2x1 -l 1 -m mattes[  $imgs, 1 , 32 ] -t SyN[ .20, 3, 0 ] -c [ $syn] -s 1x0.5x0vox -f 4x2x1 -l 1 -u 1 -z 1 -x $str_mask --float 1 -o [${nm2},${nm2}_diff.nii.gz,${nm2}_inv.nii.gz] -v 1

antsApplyTransforms -d $dim -i $diff -r $str -n linear -t ${nm2}1Warp.nii.gz -t ${nm2}0GenericAffine.mat -o ${nm2}_warped.nii.gz --float 1 -v 1


#------------------------------------------------ Diff to MNI registration -----------------------------------------------
nm3=$out/diff_to_MNI
antsApplyTransforms -d $dim -i $parcellation  -r $template -n nearestneighbor -t ${nm1}1Warp.nii.gz -t ${nm1}0GenericAffine.mat -t ${nm2}1Warp.nii.gz -t ${nm2}0GenericAffine.mat -o ${nm3}_warped.nii.gz --float 1 -v 1
