#!/bin/csh
#this script moves each subject's functional brain mask (indicating where the
#subject has coverage) into standard space

set sublistfile = /Volumes/phelpslab2/Emily/gsp/processed_data_for_models/holdout/subsHoldout.csv
set subjects = `cut -f1 $sublistfile`

set standard_dir = /$FSL_DIR/data/standard/

foreach s ($subjects)
echo $s
foreach run (1 2)
set bold_path = /Volumes/phelpslab2/Emily/gsp/rest/${s}/r$run/preproc

if (-e ${bold_path}) then
cd ${bold_path}

#move functional brain mask into standard space with warp from fnirt
applywarp -i func_brain_mask.nii.gz -r ${standard_dir}/MNI152_T1_2mm_brain.nii.gz \
-o func_mask2MNI152_fnirt.nii.gz -w reg/fsreorient2MNI152_warp.nii.gz \
--premat=reg/temp2fsreorient.mat

fslmaths func_mask2MNI152_fnirt.nii.gz -thr .5 -bin func_mask2MNI152_fnirt.nii.gz

mri_convert func_mask2MNI152_fnirt.nii.gz func_mask2MNI152_fnirt.nii

rm func_mask2MNI152_fnirt.nii.gz

endif
end
end
