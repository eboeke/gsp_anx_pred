function voxelConnToMat(subs,seeds,base_folder,out_folder)
    %voxelConnToMat: for a list of subjects, and a list of seed regions, 
    %extracts the whole brain connectivity pattern (for a given seed),
    %using gray matter mask, and stores it in a N x M matrix,where N - num
    %subkects and M = num voxels in grey matter mask. writes to csv file
    %Args:
        %subs, cell, length N
        %seeds, cell with string naming each seed
        %base_folder, folder within each subject's preproc folder that
        %contains feat folder.
        %out_folder, folder where output will be saved
    
    num_subs = length(subs);
    mask_path = '/Volumes/phelpslab2/Emily/gsp/ROIs/gray_matter_mask_wager_thr25_bin.nii'; %grey matter mask
    vox_indices = get_mask_ind(mask_path);
    num_voxels = length(vox_indices);

    for s = 1:length(seeds)
        seed = seeds{s}
        data_mat = zeros(num_subs, num_voxels);

        for i = 1:num_subs

            subj = subs{i};

            map_path = ['/Volumes/phelpslab2/Emily/gsp/rest/' subj '/r1/preproc/' base_folder '/' seed '.feat/zstat12MNI152_fnirt.nii'] ;
            if exist(map_path)>0
                 vox_vals = map2vec(vox_indices,map_path);
            end
            map_path2 = ['/Volumes/phelpslab2/Emily/gsp/rest/' subj '/r2/preproc/' base_folder '/' seed '.feat/zstat12MNI152_fnirt.nii'] ;

            if exist(map_path2)>0
                if exist(map_path)>0
                    vox_vals = mean(horzcat(vox_vals,map2vec(vox_indices,map_path2)),2);
                else  
                    vox_vals = map2vec(vox_indices,map_path2);
                end
            end

            data_mat(i,:) = vox_vals;
            clear vox_vals
        end

           writepath = [out_folder seed '.csv'];
           csvwrite(writepath,data_mat);
    end
end
