function [vox_indices] = get_mask_ind(mask)
%GET_MASK_IND gives matrix indices associated with a mask. 
    % args: 
        % mask, path to 3d mask file
    %output:
        % vox indices, indices of matlab array where mask value = 1


% Create the nifti file object for mask file, open it, create array
nfdin = niftifile(mask);
nfdin = fopen(nfdin,'read');
mask_mat = zeros(nfdin.ny, nfdin.nx, nfdin.nz);
 
% Read the data 
[nfdin, databuff] = fread(nfdin, nfdin.nx*nfdin.ny*nfdin.nz);
mask_mat = permute(reshape(databuff, [nfdin.nx nfdin.ny nfdin.nz]), [2 1 3]);

nfdin = fclose(nfdin);


%identify voxels in mask
vox_indices = find(mask_mat~=0);

end