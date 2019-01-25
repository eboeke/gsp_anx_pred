#!/bin/csh

#	--s (subject name)
#   --r (run number)

set run = ();
set subj = ();
set script_dir =  ~/gsp/scripts
set standard_dir = /$FSL_DIR/data/standard/
goto parse_args;
parse_args_return:

set bold_path = /scratch/eb1384/gsp/rest/Sub${subj}_GSP/r$run


cd ${bold_path}/preproc/



if  (! -e amyg_seed_map) then
mkdir amyg_seed_map
endif


set reg = Amygdala

if (! -e nuisance.feat/stats/res4d_masked.nii.gz) then
#mask res4d file
fslmaths nuisance.feat/stats/res4d.nii.gz -mas func_brain_mask nuisance.feat/stats/res4d_masked.nii.gz
endif

mri_binarize --i aparc+aseg.nii.gz --match 18 54  --o amyg_seed_map/${reg}_r${run}_Sub${subj}_GSP.nii.gz
#mask by brain mask to make sure not including voxels in the roi that have been masked out of the res4d file

fslmaths amyg_seed_map/${reg}_r${run}_Sub${subj}_GSP.nii.gz -mas func_brain_mask amyg_seed_map/${reg}_r${run}_Sub${subj}_GSP.nii.gz
fslmeants -i nuisance.feat/stats/res4d.nii.gz -o amyg_seed_map/${reg}_r${run}_Sub${subj}_GSP.txt -m amyg_seed_map/${reg}_r${run}_Sub${subj}_GSP.nii.gz

#make seed map for each region. (alter fsf file and run feat, using amyg as a seed)
cp ${script_dir}/seed_map.fsf amyg_seed_map/

if (-e amyg_seed_map/seed_map_${reg}.fsf) then
rm amyg_seed_map/seed_map_${reg}.fsf
endif

if (-e amyg_seed_map/${reg}.feat) then
rm -r amyg_seed_map/${reg}.feat
endif
sed s:SubA_GSP/r1/:Sub${subj}_GSP/r$run/: <amyg_seed_map/seed_map.fsf >amyg_seed_map/seed_map_$reg.fsf
perl -pi -e "s:Left-Amygdala:${reg}:"  amyg_seed_map/seed_map_$reg.fsf
perl -pi -e "s:seed_maps:amyg_seed_map:"  amyg_seed_map/seed_map_$reg.fsf
perl -pi -e "s:fs_timecourses:preproc/amyg_seed_map:"  amyg_seed_map/seed_map_$reg.fsf
perl -pi -e "s:r1_SubA:r${run}_Sub${subj}:"  amyg_seed_map/seed_map_$reg.fsf
rm amyg_seed_map/seed_map.fsf
feat amyg_seed_map/seed_map_$reg.fsf

#get rid of all files we are not using to save space
if (-e amyg_seed_map/$reg.feat/stats/zstat1.nii.gz) then
mv amyg_seed_map/$reg.feat/stats/zstat1.nii.gz amyg_seed_map/
rm -r amyg_seed_map/$reg.feat/*
rm -r amyg_seed_map/$reg.feat/.files
mv amyg_seed_map/zstat1.nii.gz amyg_seed_map/$reg.feat/
endif

##move map to standard space

applywarp -i amyg_seed_map/${reg}.feat/zstat1.nii.gz -r ${standard_dir}/MNI152_T1_2mm_brain.nii.gz -o amyg_seed_map/${reg}.feat/zstat12MNI152_fnirt.nii.gz -w reg/fsreorient2MNI152_warp.nii.gz --premat=reg/temp2fsreorient.mat

mri_convert  amyg_seed_map/${reg}.feat/zstat12MNI152_fnirt.nii.gz  amyg_seed_map/${reg}.feat/zstat12MNI152_fnirt.nii

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
