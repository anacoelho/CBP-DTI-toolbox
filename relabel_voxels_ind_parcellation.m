
function relabel_voxels_ind_parcellation(wd, subj_list, atlas_file, out_dir, metric)

% Open file with subjects ids
flogs = fopen(subj_list);
logno = textscan(flogs,'%s');
fclose(flogs);

% Create array with paths to subjects folders
for index_log=1:size(logno{1},1)
    subj = cell2mat(logno{1}(index_log));
    subjID(index_log,:) = subj;
    subj = [wd subj];
    Q(index_log,:) = subj;
    
end

% load atlas image
atlas = load_untouch_nii(atlas_file);
atlas_img = atlas.img;
    
parfor master = 1:numel(Q(:,1))
   
    % get subject parcellation image
    subj_parc = load_untouch_nii([deblank(Q(master,:)),'/',metric,'/mni2009c_asym/',subjID(master,:),'_dkt40_parcellation_filtered.nii.gz']);
    subj_parc_img = subj_parc.img;
    
    % get voxels IDs for subject parcellation image
    voxels_subj = find(subj_parc_img);
    
    % get voxels from subject parcellation image that overlap with different
    % region in the original atlas
    voxels_error=[];
    for i=1:length(voxels_subj)
        id=voxels_subj(i);
        if atlas_img(id) ~= round(subj_parc_img(id)/10)
            voxels_error=[voxels_error,id];
        end
    end
    
    new_parcellation_img = subj_parc_img; % to save relabeled image
    
    tic;
    
    % for each voxel with different overlap get labels of neighbourhood and
    % relabel with the most occurent
    for i = 1:length(voxels_error)
        
        % get label of original atlas
        orig_label = atlas_img(voxels_error(i));
        
        % get coordinates from subject image that correspond to original label
        subj_voxels_orig_roi=find(fix(subj_parc_img/10)==orig_label);
        
        % get coordinates of voxel being relabeled
        [x1,y1,z1] = ind2sub(size(subj_parc_img),voxels_error(i));
        
        % compute distance between voxel to be relabeled and voxels from
        % cluster with correct correspondence with original atlas
        dist_orig_relabel=[];
        for j=1:length(subj_voxels_orig_roi)
            [x2,y2,z2] = ind2sub(size(subj_parc_img),subj_voxels_orig_roi(j));
            dist_orig_relabel(j)=sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2 + (z1 - z2) ^ 2);
        end
        
        [min_voxel, min_id] = min(dist_orig_relabel);
        voxel_new_label=subj_voxels_orig_roi(min_id);
        new_label = subj_parc_img(voxel_new_label);
        
        if ~isempty(new_label)
            new_parcellation_img(voxels_error(i)) = new_label;
        else
            new_parcellation_img(voxels_error(i)) = 0;
        end
        
        %formatSpec = 'Voxel %d of %d relabeled \n';
        %fprintf(formatSpec,i,length(voxels_error))
        
    end
    toc;
    
    subj_new_parc = subj_parc;
    subj_new_parc.img = new_parcellation_img;
    outputfile = strcat(out_dir,'/',subjID(master,:),'/',metric,'/mni2009c_asym/',subjID(master,:),'_parc_filt_relabeled.nii.gz');

    save_untouch_nii(subj_new_parc,outputfile);
    fprintf(subjID(master,:));
end

end