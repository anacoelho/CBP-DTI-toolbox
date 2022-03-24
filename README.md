# CBP-DTI-toolbox
Toolbox to perform Connectivity Based Parcellation from Diffusion MRI data used in the paper "A novel method for estimating connectivity-based parcellation of the human brain from diffusion MRI: Application to an aging cohort".

Please cite the corresponding paper, if using the code:

Coelho, A., Magalhaes, R., Moreira, P. S., Amorim, L., Portugal-Nunes, C., Castanho, T., Santos, N. C., Sousa, N., & Fernandes, H. M. (2022). A novel method for estimating connectivity-based parcellation of the human brain from diffusion MRI: Application to an aging cohort. Hum Brain Mapp. https://doi.org/10.1002/hbm.25773 

## Requirements:
- Matlab
- Cluster_Ensembles (to install: pip install -U git+https://github.com/mvr320/Cluster_Ensembles)
- FSL (follow instructions from their website: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation

## Usage:
bash pipeline.sh <path to this repository's directory> <path to folder with connectivity matrices> 
  <path to working directory> 
    <path to folder with image data> 
      <file with participants IDs> 
        <atlas name> 
          <atlas total number of regions> 
            <mininum number of clusters> 
              <maximum number of clusters> 
                <name of transform to normalize matrices> 
                  <threshold value for matrices> 
                    <number of simulations for SOMs> 
                      <minimum size for clusters> 
                        <array with the steps of the pipeline to run>
  
Input data (one folder per participant):
  - structural connectivity matrices (fdt_matrix2.dot from probtrackX)
  - b0 and anatomical images with the corresponding brain masks
  
Atlas image file should be in the working directory
