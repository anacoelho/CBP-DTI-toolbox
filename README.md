# CBP-DTI-toolbox
Toolbox to perform Connectivity Based Parcellation from Diffusion MRI data used in the paper "A novel method for estimating connectivity-based parcellation of the human brain from diffusion MRI: Application to an aging cohort".

Please cite the corresponding paper, if using the code:

Coelho, A., Magalhaes, R., Moreira, P. S., Amorim, L., Portugal-Nunes, C., Castanho, T., Santos, N. C., Sousa, N., & Fernandes, H. M. (2022). A novel method for estimating connectivity-based parcellation of the human brain from diffusion MRI: Application to an aging cohort. Hum Brain Mapp. https://doi.org/10.1002/hbm.25773 

## Requirements:
- Matlab
- FSL (follow instructions from their website: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation
- Python with the following libraries (all available to install with pip):
  - `numpy`
  - `nipype`
  - `nibabel`
  - `cc3d`
  - `pandas`
  - `pickle`
  - `scipy`
  - `matplotlib`
  - `sklearn`
  - `SimpSOM`
  - `Cluster_Ensembles`
  - `tqdm`
  - `multiprocessing`
  - `joblib`

## Usage:
``` bash pipeline.sh code_dir in_dir wd data_dir subj_list atlas nrois min_k max_k transform thr nsim size_thr steps```

Parameters: 
- `code_dir`: path to this repository's directory
- `in_dir`: path to folder with connectivity matrices
- `wd`:path to working directory 
- `data_dir`: path to folder with image data
- `subj_list`: file with participants IDs
- `atlas`: atlas name
- `nrois`: atlas total number of regions
- `min_k`: mininum number of clusters
- `max_k`: maximum number of clusters
- `transform`: name of transform to normalize matrices
- `thr`: threshold value for matrices
- `nsim`: number of simulations for SOMs
- `size_thr`: minimum size for clusters
- `steps`: array with the steps of the pipeline to run
  
Input data (one folder per participant):
  - structural connectivity matrices (fdt_matrix2.dot from probtrackX)
  - b0 and anatomical images with the corresponding brain masks
  
Atlas image file should be in the working directory
