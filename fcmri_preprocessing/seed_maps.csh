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

#mask res4d file
fslmaths nuisance.feat/stats/res4d.nii.gz -mas func_brain_mask nuisance.feat/stats/res4d_masked.nii.gz
#set regions
set regions = `cut -f2 ${script_dir}/fs_regions.txt`
if  (! -e seed_maps) then
mkdir seed_maps
endif

#make seed map for each region. (alter fsf file and run feat, using each region as a seed)
cp ${script_dir}/seed_map.fsf seed_maps/

foreach reg ($regions)
if (-e seed_maps/seed_map_${reg}.fsf) then
rm seed_maps/seed_map_${reg}.fsf
endif

if (-e seed_maps/${reg}.feat) then
rm -r seed_maps/${reg}.feat
endif
sed s:SubA_GSP/r1/:Sub${subj}_GSP/r$run/: <seed_maps/seed_map.fsf >seed_maps/seed_map_$reg.fsf
perl -pi -e "s:Left-Amygdala:${reg}:"  seed_maps/seed_map_$reg.fsf
perl -pi -e "s:r1_SubA:r${run}_Sub${subj}:"  seed_maps/seed_map_$reg.fsf
feat seed_maps/seed_map_$reg.fsf

#get rid of all files we are not using to save space
if (-e seed_maps/$reg.feat/stats/zstat1.nii.gz) then
mv seed_maps/$reg.feat/stats/zstat1.nii.gz seed_maps/
rm -r seed_maps/$reg.feat/*
mv seed_maps/zstat1.nii.gz seed_maps/$reg.feat/
endif

end


##move map to standard space (for each seed)
foreach reg ($regions)
applywarp -i seed_maps/${reg}.feat/zstat1.nii.gz -r ${standard_dir}/MNI152_T1_2mm_brain.nii.gz -o seed_maps/${reg}.feat/zstat12MNI152_fnirt.nii.gz -w reg/fsreorient2MNI152_warp.nii.gz --premat=reg/temp2fsreorient.mat
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
