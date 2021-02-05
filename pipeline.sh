#! /bin/bash

# Connectivity Based Parcellation toolbox
# pipeline file
# Ana Coelho 01/2021

code_dir=$1
shift
in_dir=$1
shift 
wd=$1
shift
data_dir=$1
shift
subj_list=$1
shift
atlas=$1
shift
nrois=$1
shift
min_k=$1
shift
max_k=$1
shift 
transform=$1
shift
thr=$1
shift
nsim=$1
shift
size_thr=$1
shift
SWITCH=("$@")

# fetch the variables
set -o allexport

SWITCH=(${SWITCH[@]/#/_}) #add a _ before step
SWITCH=(${SWITCH[@]/%/_}) #add a _ after step


# 1) transform ROI connectivity matrix to use in python
if [[ ${SWITCH[@]/_1_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 1: get ROI sparse connectivity matrix start! ------------" 
T="$(date +%s)"

bash get_sparse_mat.sh ${code_dir} ${in_dir} ${wd} ${subj_list} ${nrois}

T="$(($(date +%s)-T))"
echo "------------ Step 1: get ROI sparse connectivity matrix done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))"
fi

# 2) preprocess connectivity matrix, apply SOM + K-Means clustering and calculate clustering validity metrics (silhouette, db, ch)
if [[ ${SWITCH[@]/_2_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 2: SOM + K-Means Analysis start! ------------" 
T="$(date +%s)"	

for ((i=1; i<="$nrois"; i++))
do
	python ${PIPELINE}/som_kmeans_analysis.py ${wd} ${subj_list} ${i} ${wd} ${transform} ${thr} ${nsim} ${min_k} ${max_k}
done

T="$(($(date +%s)-T))"
echo "------------ Step 2: SOM + K-Means Analysis done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 3) get optimal K for each clustering validity metric
if [[ ${SWITCH[@]/_3_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 3: get optimal K start! ------------"
T="$(date +%s)"	

python get_optimal_k.py ${wd} ${subj_list} ${nrois}

T="$(($(date +%s)-T))"
echo "------------ Step 3: get optimal K done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 4) get cluster image for the optimal K for each clustering validity metric
if [[ ${SWITCH[@]/_4_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 4: get cluster image start! ------------"
T="$(date +%s)"	

for ((i=1; i<="$nrois"; i++))
do
	python get_cluster_img.py ${wd} ${data_dir} ${subj_list} ${i} "silhouette"
	python get_cluster_img.py ${wd} ${data_dir} ${subj_list} ${i} "db"
	python get_cluster_img.py ${wd} ${data_dir} ${subj_list} ${i} "ch"
done

T="$(($(date +%s)-T))"
echo "------------ Step 4: get cluster image done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 5) relabel cluster images (multiply roi ID by 10) to merge all clusters in an image
if [[ ${SWITCH[@]/_5_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 5: relabel clusters start! ------------"
T="$(date +%s)"	

bash relabel_clusters.sh ${wd} ${subj_list} "silhouette" ${nrois}
bash relabel_clusters.sh ${wd} ${subj_list} "db" ${nrois}
bash relabel_clusters.sh ${wd} ${subj_list} "ch" ${nrois}

T="$(($(date +%s)-T))"
echo "------------ Step 5: relabel clusters done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 6) create individual clustered parcellation for each subjecy
if [[ ${SWITCH[@]/_6_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 6: create individual parcellation start! ------------"
T="$(date +%s)"	

bash create_ind_parcellation.sh ${wd} ${subj_list} "silhouette"
bash create_ind_parcellation.sh ${wd} ${subj_list} "db"
bash create_ind_parcellation.sh ${wd} ${subj_list} "ch"

T="$(($(date +%s)-T))"
echo "------------ Step 6: create individual parcellation done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 7) register individual clustered parcellation to standard space (MNI 2009)
if [[ ${SWITCH[@]/_7_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 7: register individual parcellation to MNI start! ------------"
T="$(date +%s)"	

bash run_antsRegistration.sh ${data_dir} ${wd} ${subj_list} "silhouette"
bash run_antsRegistration.sh ${data_dir} ${wd} ${subj_list} "db"
bash run_antsRegistration.sh ${data_dir} ${wd} ${subj_list} "ch"

T="$(($(date +%s)-T))"
echo "------------ Step 7: register individual parcellation to MNI done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 8) remove voxels from individual clustering that don't overlap with original atlas
if [[ ${SWITCH[@]/_8_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 8: remove voxels outside original atlas start! ------------"
T="$(date +%s)"	

bash filter_outside_voxels.sh ${wd} ${subj_list} ${wd}/${atlas}.nii.gz "silhouette"
bash filter_outside_voxels.sh ${wd} ${subj_list} ${wd}/${atlas}.nii.gz "db"
bash filter_outside_voxels.sh ${wd} ${subj_list} ${wd}/${atlas}.nii.gz "ch"

T="$(($(date +%s)-T))"
echo "------------ Step 8: remove voxels outside original atlas done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 9) relabel voxels from individual clustering that overlap with different regions of the original atlas
if [[ ${SWITCH[@]/_9_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 9: relabel voxels with different overlap with original atlas start! ------------"
T="$(date +%s)"	

bash relabel_voxels_ind_parcellation.sh ${code_dir} ${wd} ${subj_list} ${wd}/${atlas}.nii.gz ${wd} "silhouette"
bash relabel_voxels_ind_parcellation.sh ${code_dir} ${wd} ${subj_list} ${wd}/${atlas}.nii.gz ${wd} "db"
bash relabel_voxels_ind_parcellation.sh ${code_dir} ${wd} ${subj_list} ${wd}/${atlas}.nii.gz ${wd} "ch"

T="$(($(date +%s)-T))"
echo "------------ Step 9: relabel voxels with different overlap with original atlas done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 10) get individual ROIs of the relabeled individual parcellation
if [[ ${SWITCH[@]/_10_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 10: get individual ROIs start! ------------"
T="$(date +%s)"	

bash get_individual_rois.sh ${wd} ${wd}/optimal_k.txt ${subj_list} "silhouette"
bash get_individual_rois.sh ${wd} ${wd}/optimal_k.txt ${subj_list} "db"
bash get_individual_rois.sh ${wd} ${wd}/optimal_k.txt ${subj_list} "ch"

T="$(($(date +%s)-T))"
echo "------------ Step 10: get individual ROIs done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 11) get individual ROIs of the original atlas
if [[ ${SWITCH[@]/_11_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 11: get atlas ROIs start! ------------"
T="$(date +%s)"	

bash get_atlas_masks.sh ${wd} ${atlas} {nrois} 

T="$(($(date +%s)-T))"
echo "------------ Step 11: get atlas ROIs done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 12) apply consensus clustering to each ROI of the individual parcellations to create group parcellation
if [[ ${SWITCH[@]/_12_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 12: consensus clustering start! ------------"
T="$(date +%s)"	

while read -r line
do
		l="$line"
		IFS=$'\t'
		tmp=($l)
		roi_id="${tmp[0]}"
		k_s="${tmp[1]}"
		k_db="${tmp[2]}"
		k_ch="${tmp[3]}"

		python consensus_clustering.py ${wd} ${subj_list} "silhouette" ${roi_id} ${k_s} ${atlas}
		python consensus_clustering.py ${wd} ${subj_list} "db" ${roi_id} ${k_db} ${atlas}
		python consensus_clustering.py ${wd} ${subj_list} "ch" ${roi_id} ${k_ch} ${atlas}

done < ${wd}/optimal_k.txt

T="$(($(date +%s)-T))"
echo "------------ Step 12: consensus clustering ROIs done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 13) remove isolated voxels from consensus clusters
if [[ ${SWITCH[@]/_13_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 13: postprocessing consensus clusters start! ------------"
T="$(date +%s)"	

while read -r line
do
		l="$line"
		IFS=$'\t'
		tmp=($l)
		roi_id="${tmp[0]}"
		k_s="${tmp[1]}"
		k_db="${tmp[2]}"
		k_ch="${tmp[3]}"

		bash postprocess_cluster.sh ${code_dir} ${wd} "silhouette" ${roi_id} ${k_s}
		bash postprocess_cluster.sh ${code_dir} ${wd} "db" ${roi_id} ${k_db}
		bash postprocess_cluster.sh ${code_dir} ${wd} "ch" ${roi_id} ${k_ch}

done < ${wd}/optimal_k.txt

T="$(($(date +%s)-T))"
echo "------------ Step 13: postprocessing consensus clusters done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 14) relabel consensus clusters to merge all clusters for the group parcellation
if [[ ${SWITCH[@]/_14_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 14: relabel consensus clusters start! ------------"
T="$(date +%s)"	

bash relabel_rois.sh ${wd} ${atlas} {nrois} "silhouette"
bash relabel_rois.sh ${wd} ${atlas} {nrois} "db"
bash relabel_rois.sh ${wd} ${atlas} {nrois} "ch"

T="$(($(date +%s)-T))"
echo "------------ Step 14: relabel consensus clusters done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 15) create the group parcellation 
if [[ ${SWITCH[@]/_15_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 15: create group parcellation start! ------------"
T="$(date +%s)"	

bash create_atlas.sh ${wd}/consensus_rois/silhouette/ _sm18_relabel atlas
bash create_atlas.sh ${wd}/consensus_rois/db/ _sm18_relabel atlas
bash create_atlas.sh ${wd}/consensus_rois/ch/ _sm18_relabel atlas

T="$(($(date +%s)-T))"
echo "------------ Step 15: create group parcellation done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 16) get group parcellation values and individual ROIs
if [[ ${SWITCH[@]/_16_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 16: get group parcellation values and ROIs start! ------------"
T="$(date +%s)"	

mkdir -p ${wd}/consensus_rois/silhouette/atlas_masks
mkdir -p ${wd}/consensus_rois/db/atlas_masks
mkdir -p ${wd}/consensus_rois/ch/atlas_masks

bash get_atlas_values_rois.sh ${code_dir} ${wd}/consensus_rois/silhouette/atlas.nii.gz ${wd}/consensus_rois/silhouette/atlas_masks/
bash get_atlas_values_rois.sh ${code_dir} ${wd}/consensus_rois/db/atlas.nii.gz ${wd}/consensus_rois/db/atlas_masks/
bash get_atlas_values_rois.sh ${code_dir} ${wd}/consensus_rois/ch/atlas.nii.gz ${wd}/consensus_rois/ch/atlas_masks/

T="$(($(date +%s)-T))"
echo "------------ Step 16: get group parcellation values and ROIs done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 17) get connected components of each ROI
if [[ ${SWITCH[@]/_17_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 17: get connected components start! ------------"
T="$(date +%s)"	

while read -r line 
do 
	value="$line"
	python3 get_cc.py ${wd}/consensus_rois/silhouette/atlas_masks/ $value

done < ${wd}/consensus_rois/silhouette/atlas_masks/atlas_values.txt 

while read -r line 
do 
	value="$line"
	python3 get_cc.py ${wd}/consensus_rois/db/atlas_masks/ $value

done < ${wd}/consensus_rois/db/atlas_masks/atlas_values.txt 

while read -r line 
do 
	value="$line"
	python3 get_cc.py ${wd}/consensus_rois/ch/atlas_masks/ $value

done < ${wd}/consensus_rois/ch/atlas_masks/atlas_values.txt 

T="$(($(date +%s)-T))"
echo "------------ Step 17: get connected components done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 18) remove components with size bellow threshold
if [[ ${SWITCH[@]/_18_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 18: remove connected components with size bellow threshold start! ------------"
T="$(date +%s)"	

bash remove_isolated_components.sh ${code_dir} ${wd}/consensus_rois/silhouette/atlas_masks/ ${wd}/consensus_rois/silhouette/atlas_masks/atlas_values.txt ${wd}/consensus_rois/silhouette/atlas.nii.gz ${wd}/${atlas}.nii.gz ${size_thr}
bash remove_isolated_components.sh ${code_dir} ${wd}/consensus_rois/db/atlas_masks/ ${wd}/consensus_rois/db/atlas_masks/atlas_values.txt ${wd}/consensus_rois/db/atlas.nii.gz ${wd}/${atlas}.nii.gz ${size_thr}
bash remove_isolated_components.sh ${code_dir} ${wd}/consensus_rois/ch/atlas_masks/ ${wd}/consensus_rois/ch/atlas_masks/atlas_values.txt ${wd}/consensus_rois/ch/atlas.nii.gz ${wd}/${atlas}.nii.gz ${size_thr}

T="$(($(date +%s)-T))"
echo "------------ Step 18: remove connected components with size bellow threshold done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 19) get group parcellation filtered values and individual ROIs
if [[ ${SWITCH[@]/_19_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 19: get group parcellation filtered values and ROIs start! ------------"
T="$(date +%s)"	

mkdir -p ${wd}/consensus_rois/silhouette/atlas_masks/rois_filt_thr${size_thr}
mkdir -p ${wd}/consensus_rois/db/atlas_masks/rois_filt_thr${size_thr}
mkdir -p ${wd}/consensus_rois/ch/atlas_masks/rois_filt_thr${size_thr}

bash get_atlas_values_rois.sh ${code_dir} ${wd}/consensus_rois/silhouette/atlas_masks/atlas_filt_thr${size_thr}.nii.gz ${wd}/consensus_rois/silhouette/atlas_masks/rois_filt_thr${size_thr}
bash get_atlas_values_rois.sh ${code_dir} ${wd}/consensus_rois/db/atlas_masks/atlas_filt_thr${size_thr}.nii.gz ${wd}/consensus_rois/db/atlas_masks/rois_filt_thr${size_thr}
bash get_atlas_values_rois.sh ${code_dir} ${wd}/consensus_rois/ch/atlas_masks/atlas_filt_thr${size_thr}.nii.gz ${wd}/consensus_rois/ch/atlas_masks/rois_filt_thr${size_thr}
T="$(($(date +%s)-T))"
echo "------------ Step 19: get group parcellation filtered values and ROIs done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 20) get connected components of each filtered ROI
if [[ ${SWITCH[@]/_20_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 20: get connected components of filtered ROIs start! ------------"
T="$(date +%s)"	

while read -r line 
do 
	value="$line"
	python3 get_cc.py ${wd}/consensus_rois/silhouette/atlas_masks/rois_filt_thr${size_thr}/ $value

done < ${wd}/consensus_rois/silhouette/atlas_masks/rois_filt_thr${size_thr}/atlas_values.txt 

while read -r line 
do 
	value="$line"
	python3 get_cc.py ${wd}/consensus_rois/db/atlas_masks/rois_filt_thr${size_thr}/ $value

done < ${wd}/consensus_rois/db/atlas_masks/rois_filt_thr${size_thr}/atlas_values.txt 

while read -r line 
do 
	value="$line"
	python3 get_cc.py ${wd}/consensus_rois/ch/atlas_masks/rois_filt_thr${size_thr}/ $value

done < ${wd}/consensus_rois/ch/atlas_masks/rois_filt_thr${size_thr}/atlas_values.txt 

T="$(($(date +%s)-T))"
echo "------------ Step 20: get connected components of filtered ROIs done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 21) relabel ROIs (new label for connected components)
if [[ ${SWITCH[@]/_21_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 21: relabel filtered ROIs (new labels for connected components) start! ------------"
T="$(date +%s)"	

bash relabel_rois_cc.sh ${wd}/consensus_rois/silhouette/atlas_masks/rois_filt_thr${size_thr}/ ${wd}/consensus_rois/silhouette/atlas_masks/rois_filt_thr${size_thr}/atlas_new_labels.txt # ---> need to create this file (automatic or manual)???
bash relabel_rois_cc.sh ${wd}/consensus_rois/db/atlas_masks/rois_filt_thr${size_thr}/ ${wd}/consensus_rois/db/atlas_masks/rois_filt_thr${size_thr}/atlas_new_labels.txt
bash relabel_rois_cc.sh ${wd}/consensus_rois/ch/atlas_masks/rois_filt_thr${size_thr}/ ${wd}/consensus_rois/ch/atlas_masks/rois_filt_thr${size_thr}/atlas_new_labels.txt

T="$(($(date +%s)-T))"
echo "------------ Step 21: relabel filtered ROIs (new labels for connected components) done! ------------" 
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 22) create group parcellation with new labels for connected components
if [[ ${SWITCH[@]/_22_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 22: create group filtered parcellation start! ------------"
T="$(date +%s)"

bash create_atlas.sh ${wd}/consensus_rois/silhouette/atlas_masks/rois_filt_thr${size_thr}/relabeled_cc_masks/ _cc_relabel atlas_filt_cc
bash create_atlas.sh ${wd}/consensus_rois/db/atlas_masks/rois_filt_thr${size_thr}/relabeled_cc_masks/ _cc_relabel atlas_filt_cc
bash create_atlas.sh ${wd}/consensus_rois/ch/atlas_masks/rois_filt_thr${size_thr}/relabeled_cc_masks/ _cc_relabel atlas_filt_cc

T="$(($(date +%s)-T))"
echo "------------ Step 22: create group filtered parcellation done! ------------"
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

# 23) apply size threshold to group parcellation
if [[ ${SWITCH[@]/_23_/} != ${SWITCH[@]} ]]; then
echo "------------ Step 23: apply size threshold to group filtered parcellation start! ------------"
T="$(date +%s)"

bash thr_atlas.sh ${wd} ${size_thr} atlas_filt_cc.nii.gz atlas_filt_cc_thr.nii.gz silhouette
bash thr_atlas.sh ${wd} ${size_thr} atlas_filt_cc.nii.gz atlas_filt_cc_thr.nii.gz db
bash thr_atlas.sh ${wd} ${size_thr} atlas_filt_cc.nii.gz atlas_filt_cc_thr.nii.gz ch

T="$(($(date +%s)-T))"
echo "------------ Step 23: apply size threshold to group filtered parcellation done! ------------"
printf "Time elapsed: %02d:%02d:%02d:%02d\n\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" 
fi

echo "----------------All Done!!----------------"
