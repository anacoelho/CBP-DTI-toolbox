#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Tue Nov 13 12:14:38 2018

@author: anacoelho
"""

import numpy as np
import Cluster_Ensembles as CE
import os
from nipype.interfaces.fsl import ImageStats
import nibabel as nib
import sys

def get_labels(image_path, mask_path):
   
	# get indices of non zero elements in ROI mask
	roi_mask = nib.load(mask_path)
	mask_data=roi_mask.get_data()
	
	roi_ids = np.transpose(np.nonzero(mask_data))
				
	# load subject image
	sub_img = nib.load(image_path)
	sub_data = sub_img.get_data()

	# get subject labels for ROI ids
	labels = np.zeros((len(roi_ids),1))
	for i in xrange(len(roi_ids)):
		x = roi_ids[i][0]
		y = roi_ids[i][1]
		z = roi_ids[i][2]
		
		labels[i][0] = sub_data[x][y][z] 
	
	labels = np.transpose(labels)
	return labels

def change_labels(image_path, new_labels, output_path):
	
	# load ROI image
	roi_img = nib.load(image_path)
	roi_data = roi_img.get_data()
	roi_ids = np.transpose(np.nonzero(roi_data))
	
	# change labels
	for i in xrange(len(roi_ids)):
		x = roi_ids[i][0]
		y = roi_ids[i][1]
		z = roi_ids[i][2]
		
		roi_data[x][y][z] = new_labels[i]
		
	# create new ROI image
	consensus_img = nib.Nifti1Image(roi_data, roi_img.affine, roi_img.header)
	nib.save(consensus_img, output_path)

		
def ensemble_clustering(working_dir,subjects_filepath,roi_name,id_roi, nr_cl,atlas_name):

	# load ROI mask and get size
	roi_path=os.path.join(working_dir,str(atlas_name)+'_masks',str(atlas_name)+'_'+str(id_roi)+'.nii.gz')
	stats = ImageStats(in_file=roi_path, op_string='-V',terminal_output='stream')
	output_stat=stats.run()
	roi_size=int(output_stat.outputs.out_stat[0])
	
	# get labels for each subject
	with open(subjects_filepath, 'r') as subjects:
		mylist = subjects.read().splitlines()
		cluster_mat = np.zeros((len(mylist),roi_size))
		
		for i in xrange(len(mylist)):
			# get subject name from file
			subject = mylist[i]
			print (subject)
				
			sub_path = os.path.join(working_dir, subject,metric,'k'+str(nr_cl)+'_roi'+str(id_roi)+'_MNI2009_filt.nii.gz')
			
			# apply ROI mask and get vector with voxel labels
			sub_labels = get_labels(sub_path,roi_path)
			#print(np.unique(sub_labels))
			# add subject vector to matrix
			cluster_mat[i][:] = sub_labels
			
		cluster_mat[cluster_mat==0] = np.nan
		#np.savetxt(os.path.join(working_dir,'roi'+str(id_roi)+'_clustering_mat.txt'),cluster_mat)
		ensemble_labels = CE.cluster_ensembles(cluster_mat,verbose=True,N_clusters_max=nr_cl)
		ensemble_labels = ensemble_labels + 1
	return ensemble_labels

#check if we have all arguments
if len(sys.argv) < 7:
	print ('usage: consensus_clustering <working_dir> <subjects_file> <metric> <id_roi> <k> <atlas>')
else:
	# process inputs
	working_dir = str(sys.argv[1]) # working directory
	subjects_filepath = str(sys.argv[2]) # file with subjects ID
	metric = str(sys.argv[3]) # metric
	id_roi = int(sys.argv[4]) # ID ROI 
	k = int(sys.argv[5]) # number of clusters 
	atlas_name = str(sys.argv[6]) # name of the atlas used

	# get new labels with consensus clustering
	roi_labels=ensemble_clustering(working_dir,subjects_filepath,metric,id_roi,k,atlas_name)
	
	# change labels of ROI
	# create directory if it doesn't exist
	output_path=os.path.join(working_dir,'consensus_rois',metric)
	if not os.path.exists(output_path):
		os.makedirs(output_path)

	change_labels(os.path.join(working_dir,str(atlas_name)+'_masks',str(atlas_name)+'_'+str(id_roi)+'.nii.gz'),roi_labels,os.path.join(output_path,'roi'+str(id_roi)+'_consensus.nii.gz'))
