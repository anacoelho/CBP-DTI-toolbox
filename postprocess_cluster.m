function [nr_cl_final] = postprocess_cluster(WD,METRIC,ROI_ID,CL_NUM)

disp(strcat('Running postprocess for roi: ',num2str(ROI_ID),'...'));

grouproipath = strcat(WD,'/','consensus_rois/',METRIC,'/');

%if ~exist(strcat(num2str(VOX_SIZE),'mm_',ROI,'_',LR,'_',num2str(CL_NUM),'_MPM_thr',num2str(MPM_THRES),'_group_smoothed.nii.gz'),'file')
filename = strcat(grouproipath,'roi',num2str(ROI_ID),'_consensus.nii.gz');


info = load_untouch_nii(filename);
img = info.img;
[m n p] = size(img);
coordinates = zeros(0,0);
z = 1;
for i = 1:m
    for j = 1:n
        for k = 1:p
            if img(i,j,k) ~= 0
                coordinates(z,1) = i;
                coordinates(z,2) = j;
                coordinates(z,3) = k;
                z = z + 1;
            end
        end
    end
end

label = zeros(1,CL_NUM + 1);
max_index=0;
max_num=0;
%values = zeros(length(coordinates),2);
for i = 1:length(coordinates)
    voxel_value = img(coordinates(i,1),coordinates(i,2),coordinates(i,3));
    %values(i,1)=voxel_value;
    label = zeros(1,CL_NUM + 1);
    % 6-connected
    label_value1 = img(coordinates(i,1)-1,coordinates(i,2),coordinates(i,3)) + 1;
    label(label_value1) = label(label_value1) + 1;
    
    label_value2 = img(coordinates(i,1)+1,coordinates(i,2),coordinates(i,3)) + 1;
    label(label_value2) = label(label_value2) + 1;
    
    label_value3 = img(coordinates(i,1),coordinates(i,2)-1,coordinates(i,3)) + 1;
    label(label_value3) = label(label_value3) + 1;
    
    label_value4 = img(coordinates(i,1),coordinates(i,2)+1,coordinates(i,3)) + 1;
    label(label_value4) = label(label_value4) + 1;
    
    label_value5 = img(coordinates(i,1),coordinates(i,2),coordinates(i,3)-1) + 1;
    label(label_value5) = label(label_value5) + 1;
    
    label_value6 = img(coordinates(i,1),coordinates(i,2),coordinates(i,3)+1) + 1;
    label(label_value6) = label(label_value6) + 1;
    
    % 18-connected
    label_value7 = img(coordinates(i,1)-1,coordinates(i,2)-1,coordinates(i,3)) + 1;
    label(label_value7) = label(label_value7) + 1;
    
    label_value8 = img(coordinates(i,1)+1,coordinates(i,2)+1,coordinates(i,3)) + 1;
    label(label_value8) = label(label_value8) + 1;
    
    label_value9 = img(coordinates(i,1)+1,coordinates(i,2)-1,coordinates(i,3)) + 1;
    label(label_value9) = label(label_value9) + 1;
    
    label_value10 = img(coordinates(i,1)-1,coordinates(i,2)+1,coordinates(i,3)) + 1;
    label(label_value10) = label(label_value10) + 1;
    
    label_value11 = img(coordinates(i,1)-1,coordinates(i,2),coordinates(i,3)-1) + 1;
    label(label_value11) = label(label_value11) + 1;
    
    label_value12 = img(coordinates(i,1)+1,coordinates(i,2),coordinates(i,3)+1) + 1;
    label(label_value12) = label(label_value12) + 1;
    
    label_value13 = img(coordinates(i,1)-1,coordinates(i,2),coordinates(i,3)+1) + 1;
    label(label_value13) = label(label_value13) + 1;
    
    label_value14 = img(coordinates(i,1)+1,coordinates(i,2),coordinates(i,3)-1) + 1;
    label(label_value14) = label(label_value14) + 1;
    
    label_value15 = img(coordinates(i,1),coordinates(i,2)-1,coordinates(i,3)-1) + 1;
    label(label_value15) = label(label_value15) + 1;
    
    label_value16 = img(coordinates(i,1),coordinates(i,2)+1,coordinates(i,3)+1) + 1;
    label(label_value16) = label(label_value16) + 1;
    
    label_value17 = img(coordinates(i,1),coordinates(i,2)+1,coordinates(i,3)-1) + 1;
    label(label_value17) = label(label_value17) + 1;
    
    label_value18 = img(coordinates(i,1),coordinates(i,2)-1,coordinates(i,3)+1) + 1;
    label(label_value18) = label(label_value18) + 1;
    wjs = max(label);
    jsh = find(label == wjs);
    if length(jsh)>=2
        b = jsh(1,2) - 1;
    else
        b = jsh - 1;
    end
    
    diff_values=label;
    diff_values(voxel_value+1)=[];
    %diff_values(1)=[];
    sum_diff=sum(diff_values);
    
    neighbor_nz = sum(label(2:end));
    
    if b ~= voxel_value && sum_diff > (2*neighbor_nz/3) % majority voting (4 for 6-connected, 12 for 18-connected)
        
        
        %values(i,2)=b;
        if b~=0
            img(coordinates(i,1),coordinates(i,2),coordinates(i,3)) = b;
        else
            [aa,indices]=sort(label,'descend');
            jsh=indices(2);
            if length(jsh)>=2
                b = jsh(1,2) - 1;
            else
                b = jsh - 1;
            end
            img(coordinates(i,1),coordinates(i,2),coordinates(i,3)) = b;
            
        end
    end
end

img_MPM = img;
info = load_untouch_nii(filename);
info.img = img_MPM;
output = strcat(grouproipath,'roi',num2str(ROI_ID),'_consensus_smoothed18.nii.gz');
save_untouch_nii(info,output);

unique_cl= unique(img_MPM);
unique_cl=find(unique_cl);
nr_cl_final=size(find(unique_cl),1);

disp(' Done!');
%end


