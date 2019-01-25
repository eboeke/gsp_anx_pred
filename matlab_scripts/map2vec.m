function [vox_vals] = map2vec(vox_indices,map)
%MAP2VEC takes in 3d brain map and spits out a vector of values
%associated with specified voxels.
    %Args:
        %vox indices: indices associated with mask from which we are extracting
        %data
        %map: path to 3d image with data  that we wish to vectorize
    %Output:
        % vector of values associated with vox_indices

     
% Create the nifti file object for map file, open it, create array
nfdin = niftifile(map);
nfdin = fopen(nfdin,'read');
map_mat = zeros(nfdin.ny, nfdin.nx, nfdin.nz);
%read the file
[nfdin, databuff] = fread(nfdin, nfdin.nx*nfdin.ny*nfdin.nz);
map_mat = permute(reshape(databuff, [nfdin.nx nfdin.ny nfdin.nz]), [2 1 3]);

nfdin = fclose(nfdin);

%get a vector with the values from the map at the given indices
vox_vals = map_mat(vox_indices);
end