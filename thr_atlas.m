function thr_atlas(WD, THR, atlas_filename, orig_template, output_filename, metric)

% load atlas file
grouproipath = strcat(WD,'/','consensus_rois/',metric,'/atlas_masks/rois_filt_thr',num2str(THR),'/relabeled_cc_masks/');
filename = strcat(grouproipath,atlas_filename);
info = load_untouch_nii(filename);
img = info.img;


% threshold atlas
clusters = arrayfun(@(x)length(find(img == x)), unique(img), 'Uniform', false);
clusters=cell2mat(clusters);
cl_values=unique(img);
ids_cl=find(clusters<THR);
fprintf(['+++ Number of clusters to remove: ', num2str(length(ids_cl)), ' ... +++\n']);


% load original template file
template = load_untouch_nii(strcat(WD,'/',orig_template));
template_img = template.img;

while ~isempty(ids_cl)
    
    % get first cluster under 70 voxels
    id=ids_cl(1);
    value=cl_values(id);
    
    % get coordinates
    [r,c,v] = ind2sub(size(img),find(img == value));
    
    coordinates=r;
    coordinates(:,2)=c;
    coordinates(:,3)=v;
    
    % change labels of the cluster
    for i=1:size(coordinates,1)
        
        x=coordinates(i,1);
        y=coordinates(i,2);
        z=coordinates(i,3);
        
        % get atlas label
        voxel_value = img(x,y,z);
        
        % get original label
        orig_label = template_img(x,y,z);
        
        % change label
        img = change_label(img, voxel_value, orig_label, [x,y,z]);
    
%         % 6-connected
%         labels=[];
%         
%         labels = [labels,img(x-1,y,z)];
%         labels = [labels,img(x+1,y,z)];
%         labels = [labels,img(x,y-1,z)];
%         labels = [labels,img(x,y+1,z)];
%         labels = [labels,img(x,y,z-1)];
%         labels = [labels,img(x,y,z+1)];
%         
%         
%         % change the voxel label to the most frequent one
%         
%         [a,b]=hist(labels,unique(labels));
%         
%         % remove zero from the counts
%         zero=find(b==0);
%         if ~isempty(zero)
%             b(zero)=[];
%             a(zero)=[];
%         end
%         
%         v = find(b==voxel_value);
%         if ~isempty(v)
%             b(v)=[];
%             a(v)=[];
%         end
%         
%         id_max = find(a==max(a));
%         
%         % if there is a tie choose the label more similar to the voxel
%         if length(id_max)>1
%             diff=b-voxel_value;
%             id_min = find(diff==min(diff));
%             label_max=b(id_min);
%             
%         elseif isempty(id_max)
%             label_max=0;
%         else
%             label_max=b(id_max);
%         end
%         
%         img(x,y,z)=label_max;
        
        
    end
    
    % threshold atlas again 
    clusters = arrayfun(@(x)length(find(img == x)), unique(img), 'Uniform', false);
    clusters=cell2mat(clusters);
    cl_values=unique(img);
    ids_cl=find(clusters<THR);
    fprintf(['+++ Number of clusters to remove: ', num2str(length(ids_cl)), ' ... +++\n']);
    
end


% print final number of clusters
unique_cl= unique(img);
unique_cl=find(unique_cl);
nr_cl=size(find(unique_cl),1);
disp(nr_cl);

% save new atlas to file
info = load_untouch_nii(filename);
info.img = img;
output = strcat(grouproipath,output_filename);
save_untouch_nii(info,output);


end