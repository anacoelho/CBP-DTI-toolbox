#!/usr/bin/env python3

import cc3d
import numpy as np
import nibabel as nib
import os
import sys

def get_cc(image_path, roi_id):

	roi_img = nib.load(os.path.join(image_path,'roi'+str(roi_id)+'.nii.gz'))
	roi_data = roi_img.dataobj

	roi_data = np.array(roi_data)
	roi_data = roi_data.astype(int)
	labels_out = cc3d.connected_components(roi_data)
	roi_cc = nib.Nifti1Image(labels_out, roi_img.affine,roi_img.header)
	nib.save(roi_cc,os.path.join(image_path,'roi'+str(roi_id)+'_cc.nii.gz'))
	
	
#check if we have all arguments
if len(sys.argv) < 3:
	print ('usage: python get_cc.py <working_dir> <roi_id>')
else:
	# process inputs
	working_dir = str(sys.argv[1]) # working directory
	id_roi= int(sys.argv[2]) # ID ROI 
	
	get_cc(working_dir,id_roi)
	
	



