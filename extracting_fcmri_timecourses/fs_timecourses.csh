#!/bin/csh

#Flags
#   --s
#   --r

set subj = ()
set scan = ()

goto parse_args;
parse_args_return:

set masks = `cut -f2 fs_regions.txt`
set IDs = `cut -f1 fs_regions.txt`
set count = 1
set data_path = /scratch/eb1384/gsp/rest/$subj/$scan

cd ${data_path}
if (! -e  masks) then
mkdir masks
endif

if (! -e  masks/fs_graphs) then
mkdir masks/fs_graphs
endif


foreach mask ($masks)

if (! -e  masks/fs_graphs/${mask}_${scan}_$subj.nii.gz) then
mri_binarize --i preproc/aparc+aseg.nii.gz --match $IDs[$count]  --o masks/fs_graphs/${mask}_${scan}_$subj.nii.gz
#mask by brain mask to make sure not including voxels in the roi that have been masked out of the res4d file

fslmaths masks/fs_graphs/${mask}_${scan}_$subj.nii.gz -mas preproc/func_brain_mask masks/fs_graphs/${mask}_${scan}_$subj.nii.gz



endif

#extract timeseries
if (! -e  fs_timecourses) then
mkdir fs_timecourses
endif


fslmeants -i preproc/nuisance.feat/stats/res4d.nii.gz -o fs_timecourses/${mask}_${scan}_$subj.txt -m masks/fs_graphs/${mask}_${scan}_$subj.nii.gz
@ count++
end

exit 0

parse_args:

set cmdline = ($argv);
while($#argv != 0)

set flag = $argv[1]; shift;

switch($flag)
echo 1
case "--s":
set subj = $argv[1]; shift;
breaksw

case "--r":
set scan = $argv[1]; shift;
breaksw


endsw

end

goto parse_args_return;



