#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Tue Jan 22 14:34:41 2019

@author: anacoelho
"""

import numpy as np
import nibabel as nib
import sys
import os
from nipype.interfaces import fsl

def create_cluster_img(cluster_file, ref_filepath, out_file):
    
    # load b0 image
    ref_img=nib.load(ref_filepath)
    # use b0 matrix shape to create new cluster image
    ref_data=ref_img.get_data()
    new_cluster=np.zeros(ref_data.shape)
    
    # set cluster id for each coordinate
    clusters=np.loadtxt(cluster_file)
    
    for i in range(len(clusters)):
        x=int(clusters[i][0])
        y=int(clusters[i][1])
        z=int(clusters[i][2])
        value=clusters[i][3]
        new_cluster[x,y,z]=value
    
    # save in new image
    cluster_img = nib.Nifti1Image(new_cluster, ref_img.affine, ref_img.header)
    nib.save(cluster_img, out_file)

    
#check if we have all arguments
if len(sys.argv) < 6:
    print ('usage: get_cluster_img <working_dir> <data_dir> <subjects_file> <id_roi> <metric>')
else:
    # process inputs
    working_dir = str(sys.argv[1]) # working directory
    data_dir = str(sys.argv[2]) # data directory
    subjects_filepath = str(sys.argv[3]) # file with subjects ID
    id_roi = int(sys.argv[4])
    metric = str(sys.argv[5])
    
    with open(subjects_filepath, 'r') as subjects:
        mylist = subjects.read().splitlines()
        for line in mylist:
            # get subject name from file
            subject = line
            print (subject)
            
            # get filepaths for inputs and outputs
            ref_img_file=os.path.join(data_dir,subject,subject+'_diff_b0_bet.nii.gz') # b0 bet subject image
            
            # file with cluster ids and coords
            cl_filepath=os.path.join(working_dir,subject,metric,'roi'+str(id_roi)+'_clusters.txt')
      
            # output file for cluster image
            out_file=os.path.join(working_dir,subject,metric,'roi'+str(id_roi)+'_cluster_mask.nii.gz')
  
            # create cluster image
            create_cluster_img(cl_filepath,ref_img_file,out_file)



