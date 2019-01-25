#!/bin/csh

#Flags:

#	--s (subject name)
#   --r (run number)
setenv SUBJECTS_DIR /scratch/eb1384/gsp/recons
set scan_type = ();

set run = ();
set subj = ();
set day = ();
set f = 0;
set script_path = /home/eb1384/gsp/scripts/
goto parse_args;
parse_args_return:
set bold_path =  /scratch/eb1384/gsp/rest/Sub${subj}_GSP/r$run


if (! -e  ${bold_path}/preproc) then
mkdir  ${bold_path}/preproc
endif


cd ${bold_path}/preproc/

#create log file
set LF = ${subj}_surf_preproc.log;

set d = (`date +%m.%d.%y_%H:%M:%S`);
echo "Log file for $subj"  >> $LF
echo $d >> $LF

which fsl >> $LF
which freesurfer >> $LF




if (! -e func_reorient_rm4_mcf4_st_f.nii.gz  ||  $f) then
#filter unsmoothed data
echo "" >> $LF
echo "------------------------APPLYING BAND PASS FILTER-----------------------" >> $LF
echo "" >> $LF

set cmd = (fslmaths func_reorient_rm4_mcf4_st.nii.gz -Tmean tempMean)
echo $cmd >> $LF
$cmd >> $LF
set cmd = (fslmaths func_reorient_rm4_mcf4_st -bptf 16.67 1.67 -add tempMean func_reorient_rm4_mcf4_st_f)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1
endif



if ((! -e lat_vent_unsm.txt) || $f) then
echo "" >> $LF
echo "------------------------EXTRACTING GLOBAL SIGNAL AND TIMECOURSE FROM WM and V ROIS-----------------------" >> $LF
echo "" >> $LF
#re-extract nuissance signals from unsmoothed data
set cmd = ( fslmeants -i func_reorient_rm4_mcf4_st_f -o global_unsm.txt -m func_brain_mask.nii.gz)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1


set cmd = ( fslmeants -i func_reorient_rm4_mcf4_st_f -o wm_er1_unsm.txt -m masks/wm_er1.nii.gz)
echo $cmd >> $LF
$cmd >> $LF

set cmd = ( fslmeants -i func_reorient_rm4_mcf4_st_f -o lat_vent_unsm.txt -m masks/lat_vent.nii.gz)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1
endif





echo "" >> $LF
echo "------------------------REGRESSING OUT nuisance PARAMETERS----------------------" >> $LF
echo "" >> $LF
if (-e nuisance_unsm.feat) then
rm -r nuisance_unsm.feat
endif

cp ${script_path}/nuisance_unsm.fsf .
sed s:SubA_GSP/r1/:Sub${subj}_GSP/r$run/: <nuisance_unsm.fsf >nuisance_unsm_${subj}.fsf

feat nuisance_unsm_${subj}.fsf
rm nuisance_unsm.fsf
if ($status) exit 1





if ((! -e res4d.self.surf.rh.nii.gz) || $f) then
echo "" >> $LF
echo "------------------------PROJECTING TO SURFACE-----------------------" >> $LF
echo "" >> $LF

foreach hemi (lh rh)

set cmd = (mri_vol2surf --mov func_brain_mask.nii.gz --reg reg/temp2fs.dat  --trgsubject Sub${subj}_GSP --interp nearest --projfrac 0.5 --hemi $hemi --o brain.self.surf.${hemi}.nii.gz --noreshape --cortex)
echo $cmd >> $LF
$cmd >> $LF

set cmd = (mri_binarize --i brain.self.surf.${hemi}.nii.gz --min .00001 --o brain.self.surf.${hemi}.nii.gz)
echo $cmd >> $LF
$cmd >> $LF

set cmd = (mri_vol2surf --mov nuisance_unsm.feat/stats/res4d.nii.gz --reg reg/temp2fs.dat --trgsubject Sub${subj}_GSP --interp trilin --projfrac 0.5 --hemi $hemi --o res4d.self.surf.${hemi}.nii.gz --noreshape --cortex)
echo $cmd >> $LF
$cmd >> $LF

set cmd = (mris_fwhm --s Sub${subj}_GSP --hemi $hemi --smooth-only --i res4d.self.surf.${hemi}.nii.gz --fwhm 5 --o res4d.self.surf.${hemi}.nii.gz --mask brain.self.surf.${hemi}.nii.gz)
echo $cmd >> $LF
$cmd >> $LF

end
if ($status) exit 1
endif


echo "" >> $LF
echo "------------------------PREPROCESSING DONE-----------------------" >> $LF




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
