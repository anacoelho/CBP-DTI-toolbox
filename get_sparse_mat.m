function get_sparse_mat(in_dir, out_dir, subj_file, nrois)

clear Q master
clear subjID master
clear subj_list

nrois = str2num(nrois);


% Open file with subjects ids
flogs = fopen(subj_file);
logno = textscan(flogs,'%s');
fclose(flogs);

% Create array with paths to subjects folders
for index_log=1:size(logno{1},1)
    subj = cell2mat(logno{1}(index_log));
    subjID(index_log,:) = subj;
    subj = [in_dir '/' subj];
    Q(index_log,:) = subj;
    
end

for master = 1:numel(Q(:,1))

    fprintf(['Subject ', subjID(master,:), '\n']);

    % create directory to save new matrix
    subj_out_dir=[out_dir,'/',subjID(master,:)];
    if ~exist(subj_out_dir, 'dir')
       mkdir(subj_out_dir)
    end

    if ~exist([subj_out_dir,'/matrices'], 'dir')
       mkdir([subj_out_dir,'/matrices'])
    end


    % load matrix of each ROI
    for i=1:nrois
    
        roi_mat = load([deblank(Q(master,:)),'/seed',num2str(i)'/fdt_matrix2.dot']);

        % to use in python
        roi_mat(:,1)=roi_mat(:,1)-1;
        roi_mat(:,2)=roi_mat(:,2)-1;
        	
        % save matrix
        save([out_dir,'/',subjID(master,:),'/matrices/roi',num2str(i),'_sparse_mat.mat'],'roi_mat');
    end
        	

end

end
