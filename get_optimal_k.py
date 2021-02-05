import os
import numpy as np
import pandas as pd
import pickle


def get_group_optimal_k(roi_results, sub_file):
    file = open(sub_file, 'r')
    subjects = file.readlines()

    k_subj_optimal = pd.DataFrame(columns=['k_s', 'k_db', 'k_ch'])

    for sub in subjects:
        sub = sub.strip()
        subj_roi_results = roi_results[roi_results['subject'] == sub]
        subj_optimal = pd.DataFrame(columns=['k_s', 'silhouette', 'k_db', 'db', 'k_ch', 'ch'])
        for i in range(0, 50, 5):
            sub_n = subj_roi_results[i:i + 5]
            sub_n = sub_n.reset_index(drop=True)
            subj_optimal = subj_optimal.append(
                {'k_s': sub_n.iloc[sub_n['silhouette'].idxmax(), 0], 'silhouette': sub_n['silhouette'].max(),
                 'k_db': sub_n.iloc[sub_n['db'].idxmin(), 0], 'db': sub_n['db'].min(),
                 'k_ch': sub_n.iloc[sub_n['ch'].idxmax(), 0], 'ch': sub_n['ch'].max()}, ignore_index=True)

        k_subj_optimal = k_subj_optimal.append(
            {'k_s': subj_optimal['k_s'].mode()[0], 'k_db': subj_optimal['k_db'].mode()[0],
             'k_ch': subj_optimal['k_ch'].mode()[0]}, ignore_index=True)

    k_s = k_subj_optimal['k_s'].mode()[0]
    k_db = k_subj_optimal['k_db'].mode()[0]
    k_ch = k_subj_optimal['k_ch'].mode()[0]

    return k_s, k_db, k_ch


def get_subj_labels(labels, k, roi_results, metric, sub_file, wd, roi_id):
    file = open(sub_file, 'r')
    subjects = file.readlines()

    for sub in subjects:
        sub = sub.strip()
        subj_roi_results = roi_results[roi_results['subject'] == sub]
        subj_roi_results = subj_roi_results.reset_index(drop=True)

        # get best result for the chosen k according to the specified metric
        subj_roi_results = subj_roi_results.loc[
            (subj_roi_results['k'] == k), [metric]]
        if metric == 'db':
            id_max = subj_roi_results[metric].idxmin()
        else:
            id_max = subj_roi_results[metric].idxmax()

        # need this because at first I used the 73 subjects
        subjects_orig = np.unique(roi_results['subject'])
        id_sub = np.where(subjects_orig == sub)[0][0]
        # get labels of subject
        sub_labels = labels[id_sub][id_max]

        # create file with coordinates and labels for region's voxels
        # load coordinates file
        coords = np.loadtxt(os.path.join(wd, sub, 'matrices', 'roi'+str(roi_id)+'_coords.txt'))
        coords_roi = np.zeros((len(sub_labels),4))
        coords_roi[:, 0] = coords[:, 0]
        coords_roi[:, 1] = coords[:, 1]
        coords_roi[:, 2] = coords[:, 2]
        coords_roi[:, 3] = sub_labels+1

        if not os.path.isdir(os.path.join(wd, sub, metric)):
            os.mkdir(os.path.join(wd, sub, metric))

        np.savetxt(os.path.join(wd, sub, metric,'roi'+str(roi_id)+'_clusters.txt'), coords_roi, fmt='%d')


# check if we have all arguments
if len(sys.argv) < 4:
    print(
        'usage: python get_optimal_k.py <working_dir> <subjects_file> <nrois>')
else:
    # get directories
    directory = str(sys.argv[1])
    subjects_file = str(sys.argv[2])
    nrois = int(sys.argv[3])

    # dataframe to save optimal k for all ROIs for each metric
    optimal_k = pd.DataFrame(columns=['roi_id', 'k_s', 'k_db', 'k_ch'])

    # get optimal k and cluster labels for all ROIS for each metric
    for roi in range(1,nrois+1):
        # load files
        filename = os.path.join(directory, 'roi' + str(roi) + '_results.csv')
        labels_file = os.path.join(directory, 'roi' + str(roi) + '_cluster_labels.pkl')
        results = pd.read_csv(os.path.join(directory, filename))
        # get optimal k for each metric
        k_s, k_db, k_ch = get_group_optimal_k(results, subjects_file)
        # save to dataframe
        optimal_k = optimal_k.append({'roi_id': roi, 'k_s': k_s, 'k_db': k_db,'k_ch': k_ch}, ignore_index=True)
        # get cluster labels for the optimal k for each metric
        cl_labels = pickle.load(open(os.path.join(directory, labels_file), "rb"))
        get_subj_labels(cl_labels, k_s, results, 'silhouette', subjects_file, directory, roi)
        get_subj_labels(cl_labels, k_db, results, 'db', subjects_file, directory, roi)
        get_subj_labels(cl_labels, k_ch, results, 'ch', subjects_file, directory, roi)

    # save dataframe to file
    np.savetxt(pjoin(directory, 'optimal_k.txt'),optimal_k.values, fmt='%d', delimiter='\t')
