function remove_isolated_components(wd,roi_file,atlas_file,orig_template, thr)

roi_values = load(roi_file)

voxels_remove=[];
for i=1:length(roi_values)
    
    % load file of region with labeled connected components
    roi_cc_file = load_untouch_nii(strcat(wd,'/roi',num2str(roi_values(i)),'_cc.nii.gz'));
    roi_cc = roi_cc_file.img;

    % get size of connected components
    counts = histcounts(reshape(roi_cc, [], size(roi_cc,3)),numel(unique(roi_cc)));
    counts(2,:) = unique(roi_cc);
    
    % identify connected components to remove
    ids_remove=counts(2,find(counts(1,:)<thr));

    % get voxels to remove
    if ~isempty(ids_remove)
        if isempty(voxels_remove)
            voxels_remove=find(roi_cc==ids_remove(1));
            if numel(ids_remove)>1
                for j=2:length(ids_remove)
                    voxels_remove=cat(1,voxels_remove,find(roi_cc==ids_remove(j)));
                end
            end
        else
            for j=1:length(ids_remove)
                voxels_remove=cat(1,voxels_remove,find(roi_cc==ids_remove(j)));
            end
            
        end
    end

end

% load atlas file
atlas = load_untouch_nii(atlas_file);
atlas_img = atlas.img;
new_atlas_img = atlas_img;


% load original template file
template = load_untouch_nii(orig_template);
template_img = template.img;

disp(length(voxels_remove));

% for each voxel with different overlap get labels of neighbourhood and
% relabel with the most occurent
for i = 1:length(voxels_remove)
    
    
    % get coordinates of voxel being relabeled
    [x,y,z] = ind2sub(size(atlas_img),voxels_remove(i));
    
    % get atlas label
    atlas_label = atlas_img(voxels_remove(i));
    
    % get original label
    orig_label = template_img(voxels_remove(i));
    
    % change label
    new_atlas_img = change_label(new_atlas_img, atlas_label, orig_label, [x,y,z]);
    
    
end

new_atlas = atlas;
new_atlas.img = new_atlas_img;
outputfile = strcat(wd,'/atlas_filt_thr',num2str(thr),'.nii.gz');

save_untouch_nii(new_atlas,outputfile);

end