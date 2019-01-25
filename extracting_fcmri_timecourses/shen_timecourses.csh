#!/bin/csh

#Flags
#	--s (subject number)
#   --r (run number)

set subj = ()
set run = ()

goto parse_args;
parse_args_return:

set bold_path = /scratch/eb1384/gsp/rest/Sub${subj}_GSP/r$run/
set mask_path = ../masks/shen_masks
set MNImaskdir = /scratch/eb1384/gsp/ROIs/shenROIs
cd ${bold_path}/preproc/

if (! -e  ${mask_path}) then
mkdir $mask_path
endif


if (! -e  ../shen_timecourses) then
mkdir ../shen_timecourses
endif

foreach roiIdx (`seq 1 268`)
set mask = ${roiIdx}_shen
#move roi from std space to native space
applywarp -i $MNImaskdir/$mask -r func_template -o ${mask_path}/${mask} -w reg/MNI1522fsreorient_warp --postmat=reg/fsreorient2temp.mat
fslmaths ${mask_path}/${mask} -thr .5 -bin ${mask_path}/${mask}

#mask by brain mask to make sure not including voxels in the roi that have been masked out of the res4d file
fslmaths ${mask_path}/${mask} -mas func_brain_mask ${mask_path}/${mask}

#extract timeseries
fslmeants -i nuisance.feat/stats/res4d.nii.gz -o ../shen_timecourses/${mask}.txt -m ${mask_path}/${mask}.nii.gz

end


exit 0

parse_args:

set cmdline = ($argv);
while($#argv != 0)

set flag = $argv[1]; shift;

switch($flag)

case "--s":
set subj = $argv[1]; shift;
breaksw

case "--r":
set run = $argv[1]; shift;
breaksw

endsw

end

goto parse_args_return;
