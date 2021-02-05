import numpy as np
from os.path import dirname, join as pjoin
import scipy.io as sio
import scipy.sparse as scisparse
import matplotlib.pyplot as plt
import pandas as pd
import matplotlib.cm as cm
from sklearn import metrics
from sklearn.cluster import KMeans
from scipy import stats
from sklearn.decomposition import PCA
import SimpSOM as sps
import time
import datetime
from tqdm import tqdm
import contextlib
import sys
import multiprocessing
from joblib import Parallel, delayed
import pickle


class DummyFile(object):
    def write(self, x): pass


@contextlib.contextmanager
def nostdout():
    save_stdout = sys.stdout
    sys.stdout = DummyFile()
    yield
    sys.stdout = save_stdout


def loadMatrix(input_file):
    mat_contents = sio.loadmat(input_file)
    mat = mat_contents[list(mat_contents.keys())[3]]

    return mat


def preprocessMatrix(orig_mat, thr, transform):
    # convert from sparse to dense
    shape_mat = (max(orig_mat[:, 0]) + 1, max(orig_mat[:, 1]) + 1)
    dense_mat = scisparse.coo_matrix((orig_mat[:, 2], (orig_mat[:, 0], orig_mat[:, 1])), shape=shape_mat).toarray()

    # threshold
    dense_mat_thr = dense_mat
    dense_mat_thr[dense_mat_thr <= (thr * np.max(dense_mat_thr))] = 0

    # remove columns with only zeros
    dense_mat_flt = dense_mat_thr[:, ~np.all(dense_mat_thr == 0, axis=0)]

    # transform values to approximate to a normal distribution
    # get non-zero values
    connectivity_nz = dense_mat_flt[dense_mat_flt != 0]

    # apply corresponding transformation
    if transform == 'log':
        connectivity_transf = np.log(connectivity_nz)
    elif transform == 'cubic':
        connectivity_transf = np.cbrt(connectivity_nz)
    elif transform == 'boxcox':
        connectivity_transf, fitted_lambda = stats.boxcox(connectivity_nz)
    else:
        print('Transformation not valid!')

    # update transformed values in connectivity matrix
    # coordinates of non-zero values
    x_nz = np.where(dense_mat_flt != 0)[0]
    y_nz = np.where(dense_mat_flt != 0)[1]

    # matrix to save transformed values
    mat_transf = np.zeros(dense_mat_flt.shape)

    # update values
    for i in range(len(x_nz)):
        mat_transf[x_nz[i]][y_nz[i]] = connectivity_transf[i]

    return mat_transf


def som_kmeans_analysis(input_mat, n_iter, range_nclusters):
    df_results = pd.DataFrame(columns=['k', 'silhouette', 'db', 'ch'])
    cl_lab = []

    time_start = time.perf_counter()
    n = 0
    while n < n_iter:
        # SOM
        net = sps.somNet(10, 10, input_mat, PBC=True)
        net.train(0.01, 1000)

        prj = np.array(net.project(input_mat))

        # KMeans and compute validity metrics (silhouette and davies-bouldin)

        for i in range_nclusters:
            kmeans = KMeans(n_clusters=i, random_state=0)
            cluster_labels = kmeans.fit_predict(prj)
            mean_s = metrics.silhouette_score(prj, cluster_labels)
            mean_db = metrics.davies_bouldin_score(prj, cluster_labels)
            mean_ch = metrics.calinski_harabasz_score(prj, cluster_labels)
            df_results = df_results.append({'k': i, 'silhouette': mean_s, 'db': mean_db, 'ch': mean_ch}, ignore_index=True)
            cl_lab.append(cluster_labels)
        n = n + 1

    time_elapsed = (time.perf_counter() - time_start)
    print("Elapsed time: ", datetime.timedelta(seconds=time_elapsed))

    return df_results, cl_lab


def main(working_dir, subject, roi_id, transform, thr, n_sim, min_k, max_k):
    # load matrix
    mat_fname = pjoin(working_dir, subject, 'matrices', 'roi' + str(roi_id) + '_sparse_mat.mat')
    roi_mat = loadMatrix(mat_fname)

    # preprocess matrix
    roi_preprocessed = preprocessMatrix(roi_mat, thr, transform)

    # apply SOM for dimensionality reduction + KMeans for clustering and compute clustering indices
    with nostdout():
        roi_results, cl_labels = som_kmeans_analysis(roi_preprocessed, n_sim, range(min_k, max_k + 1))
        roi_results['subject'] = subject

    return [roi_results, cl_labels]


# check if we have all arguments
if len(sys.argv) < 10:
    print(
        'usage: python som_kmeans_analysis.py <working_dir> <subjects_file> <roi_id> <out_dir> <transform> <thr> <n_sim> <min_k> <max_k>')
else:
    # get directories
    working_dir = str(sys.argv[1])
    subjects_filepath = str(sys.argv[2])
    roi_id = int(sys.argv[3])
    out_dir = str(sys.argv[4])
    transform = str(sys.argv[5])
    thr = float(sys.argv[6])
    n_sim = int(sys.argv[7])
    min_k = int(sys.argv[8])
    max_k = int(sys.argv[9])

    print("====================== SOM + KMeans Analysis ======================")
    print("Running analysis with following parameters: ")
    print("Threshold: ", thr)
    print("Normalization transform: ", transform)
    print("Number of simulations: ", n_sim)
    print("Range of k solutions: ", (min_k, max_k))
    print("===================================================================")

    # get list of subjects
    f = open(subjects_filepath)
    mylist = f.read().splitlines()
    f.close()

    # run analysis in parallel
    inputs = tqdm(mylist)
    processed_list = Parallel(n_jobs=multiprocessing.cpu_count())(
        delayed(main)(working_dir, i, roi_id, transform, thr, n_sim, min_k, max_k) for i in inputs)

    # process outputs
    df_list = [i[0] for i in processed_list]
    cluster_l = [i[1] for i in processed_list]

    # save results to csv
    allSubjs_results = pd.concat(df_list)
    allSubjs_results.to_csv(pjoin(out_dir, 'roi' + str(roi_id) + '_results.csv'), index=False)

    # save clustering solutions to txt
    pickle.dump(cluster_l, open(pjoin(out_dir, 'roi' + str(roi_id) + '_cluster_labels.pkl'), "wb"))


