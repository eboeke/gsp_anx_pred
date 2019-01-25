#!/bin/csh


#Flags:

#   --s (subject name)
#   --r (run number)
#   --f (whether to force processing if files already exist)


set run = ();
set subj = ();
set f = 0;
set script_path = /home/eb1384/gsp/scripts

goto parse_args;
parse_args_return:

set bold_path = /scratch/eb1384/gsp/rest/Sub${subj}_GSP/r$run
set t1_path = /scratch/eb1384/gsp/T1/Sub${subj}_GSP
set t1_name = (Sub${subj}_GSP_T1.nii)


if (! -e  ${bold_path}/preproc) then
mkdir  ${bold_path}/preproc
endif


cd ${bold_path}/preproc/

#create log file
set LF = ${subj}_${run}_preproc.log;
set d = (`date +%m.%d.%y_%H:%M:%S`);
echo "Log file for $subj"  >> $LF
echo $d >> $LF
which fsl >> $LF
which freesurfer >> $LF


if (! -e $t1_path/t1_reorient.nii.gz) then
#process t1 if necessary
echo "" >> $LF
echo "------------------------REORIENTING T1-----------------------" >> $LF
echo "" >> $LF
#reorient t1
set cmd = (fslreorient2std ${t1_path}/${t1_name} ${t1_path}/t1_reorient)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1
endif


if (! -e ${t1_path}/brainmaskFS.nii.gz || $f) then
echo "" >> $LF
echo "------------------------GET T1 BRAIN MASK-----------------------" >> $LF
echo "" >> $LF
#move fs brain mask here and convert to nii.gz
set cmd = (mri_convert $SUBJECTS_DIR/Sub${subj}_GSP/mri/brainmask.mgz ${t1_path}/brainmaskFS.nii.gz)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1
endif


if ((! -e func_reorient.nii.gz) || $f) then
echo "" >> $LF
echo "------------------------REORIENTING-----------------------" >> $LF
echo "" >> $LF
#reorient functional
set cmd = (fslreorient2std ../func.nii func_reorient)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1
endif

if ((! -e func_reorient_rm4.nii.gz) || $f) then

echo "" >> $LF
echo "------------------------DROPPING FIRST 4 VOLUMES-----------------------" >> $LF
echo "" >> $LF
#remove first 4 volumes
set cmd = (fslroi func_reorient func_reorient_rm4 4 -1)
echo $cmd >> $LF
$cmd >> $LF

if ($status) exit 1
endif
set num_vols = `fslnvols func_reorient_rm4`

if ((! -e func_reorient_rm4_mcf4.nii.gz) || $f) then
echo "" >> $LF
echo "------------------------MOTION CORRECTING-----------------------" >> $LF
echo "" >> $LF
#motion correct with 4 stages
set cmd = (mcflirt -in func_reorient_rm4 -o func_reorient_rm4_mcf4 -stages 4 -sinc_final -mats -plots)
echo $cmd >> $LF
$cmd >> $LF
if (-e m1.txt) then
rm m*.txt
endif



#put columns of par file into individual text files
cut -f1 -d' ' func_reorient_rm4_mcf4.par >> m1.txt
cut -f3 -d' ' func_reorient_rm4_mcf4.par >> m2.txt
cut -f5 -d' ' func_reorient_rm4_mcf4.par >> m3.txt
cut -f7 -d' ' func_reorient_rm4_mcf4.par >> m4.txt
cut -f9 -d' ' func_reorient_rm4_mcf4.par >> m5.txt
cut -f11 -d' ' func_reorient_rm4_mcf4.par >> m6.txt

if ($status) exit 1
endif

if ((! -e func_reorient_rm4_mcf4_st.nii.gz) || $f) then
echo "" >> $LF
echo "------------------------SLICE TIME CORRECTING-----------------------" >> $LF
echo "" >> $LF
#slice time correct
set cmd = (slicetimer -i func_reorient_rm4_mcf4 -r 3 -o func_reorient_rm4_mcf4_st --ocustom=${script_path}/st.txt)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1
endif


if ((! -e func_template.nii.gz) || $f) then
echo "" >> $LF
echo "------------------------MAKING TEMPLATE AND BRAIN MASK-----------------------" >> $LF
echo "" >> $LF
#make template from middle timepoint


set tempnum = 60


set cmd = (fslroi func_reorient_rm4_mcf4_st func_template $tempnum 1)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1


set cmd = (bet func_template func_brain -m -f .1)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1
endif


if ((! -e func_reorient_rm4_mcf4_st_sm5.nii.gz) || $f) then

echo "" >> $LF
echo "------------------------SMOOTHING-----------------------" >> $LF
echo "" >> $LF
#smooth by 5 mm (sigma = 2.123)
set cmd = (fslmaths func_reorient_rm4_mcf4_st -s 2.123 func_reorient_rm4_mcf4_st_sm5)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1
endif

if (! -e reg/MNI1522fsreorient_warp.nii.gz || $f) then
echo "" >> $LF
echo "------------------------REGISTERING TO T1 AND STANDARD-----------------------" >> $LF
echo "" >> $LF

if (! -e reg) then
mkdir reg
endif
cd reg

#register func to t1
set cmd = (bbregister --s Sub{$subj}_GSP --mov ../func_template.nii.gz --init-fsl --bold --reg temp2fs.dat)
echo $cmd >> ../$LF
$cmd >> ../$LF

#turn this into an fsl .mat file
set cmd = (tkregister2 --mov ../func_template.nii.gz --targ ${t1_path}/brainmaskFS.nii.gz --reg temp2fs.dat --fslregout temp2fs.mat --noedit)
echo $cmd >> ../$LF
$cmd >> ../$LF
if ($status) exit 1



#register t1 to standard with fnirt.
cd ..
echo "" >> $LF
echo "------------------------combining temp to t1 and fs2reorient transforms, and making an inverted version-----------------------" >> $LF
echo "" >> $LF
set cmd = (convert_xfm -omat reg/temp2fsreorient.mat -concat  ${script_path}/fs_reorient.mat reg/temp2fs.mat)
#fs2reorient is a transform that reorients an image from freesurfer space to the fslreorient2std orientation
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1


set cmd = (convert_xfm -omat reg/fsreorient2temp.mat -inverse reg/temp2fsreorient.mat)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1


echo "" >> $LF
echo "------------------------reorienting structural brain mask to std orientation-----------------------" >> $LF
echo "" >> $LF
set cmd = (fslreorient2std ${t1_path}/brainmaskFS ${t1_path}/brainmaskFS_reorient)

echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1


echo "" >> $LF
echo "------------------------computing registration between structural brain mask and mni152 template (with fnirt)-----------------------" >> $LF
echo "" >> $LF
#first linear
set cmd = (flirt -ref $FSL_DIR/data/standard/MNI152_T1_2mm_brain -in ${t1_path}/brainmaskFS_reorient.nii.gz -out reg/fsreorient2MNI152 -omat reg/fsreorient2MNI152.mat)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1

#then nonlinear
set cmd = (fnirt --in=${t1_path}/brainmaskFS_reorient.nii.gz --config=T1_2_MNI152_2mm --warpres=6,6,6 --iout=reg/fsreorient2MNI152_fnirt --cout=reg/fsreorient2MNI152_warp --aff=reg/fsreorient2MNI152.mat)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1


echo "" >> $LF
echo "------------------------combining temp to t1 (reoriented) and t1 (reoriented) to MNI152 transforms-----------------------" >> $LF
echo "" >> $LF
set cmd = (applywarp --ref=$FSL_DIR/data/standard/MNI152_T1_2mm_brain --in=func_template.nii.gz --out=reg/temp2MNI152_fnirt --warp=reg/fsreorient2MNI152_warp.nii.gz --premat=reg/temp2fsreorient.mat)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1


echo "" >> $LF
echo "------------------------inverting this transform-----------------------" >> $LF
echo "" >> $LF
set cmd = (invwarp  -r ${t1_path}/brainmaskFS_reorient.nii.gz -o reg/MNI1522fsreorient_warp -w reg/fsreorient2MNI152_warp)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1
endif



if (! -e aparc+aseg.nii.gz || $f) then
echo "" >> $LF
echo "------------------------CONVERTING ASEG TO FUNCTIONAL SPACE-----------------------" >> $LF
echo "" >> $LF
#move aseg+aparc to native func space
set cmd = (mri_label2vol --temp func_template.nii.gz --aparc+aseg --o aparc+aseg.nii.gz --reg reg/temp2fs.dat)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1
endif



if ((! -e masks/wm_er1.nii.gz) || $f) then
echo "" >> $LF
echo "------------------------MAKING WHITE MATTER AND VENTRICLE ROIS-----------------------" >> $LF
echo "" >> $LF
if (! -e masks) then
mkdir masks
endif
set cmd = (mri_binarize --i aparc+aseg.nii.gz --match 2 41 --o masks/wm_er1.nii.gz --erode 1)
echo $cmd >> $LF
$cmd >> $LF
set cmd = (mri_binarize --i aparc+aseg.nii.gz --match 4 43 --o masks/lat_vent.nii.gz)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1
endif



if ((! -e func_reorient_rm4_mcf4_st_sm5_f.nii.gz) || (! -e m1_bptf) ||  $f) then
echo "" >> $LF
echo "------------------------APPLYING BAND PASS FILTER-----------------------" >> $LF
echo "" >> $LF

#high pass filter (want to look at fluctuations between .01 and .1 hz, which corresponds to 100 and 10 seconds, corresponding to a sigma of 16.67 and 1.67 volumes. using sigma conversion of 2 to be consistent w/ fsl implementation)
#fslmaths' filter function now removes the mean, so must save the mean and then add it back in.
set cmd = (fslmaths func_reorient_rm4_mcf4_st_sm5.nii.gz -Tmean tempMean)
echo $cmd >> $LF
$cmd >> $LF
set cmd = (fslmaths func_reorient_rm4_mcf4_st_sm5 -bptf 16.67 1.67  -add tempMean func_reorient_rm4_mcf4_st_sm5_f)
echo $cmd >> $LF
$cmd >> $LF
rm tempMean.nii.gz

#filter mot params
foreach reg (m1 m2 m3 m4 m5 m6)
fslascii2img ${reg}.txt 1 1 1 ${num_vols} 1 1 1 2 ${reg}_img
fslmaths ${reg}_img -Tmean tempMean
fslmaths ${reg}_img -bptf 16.67 1.67  -add tempMean ${reg}_img_bptf
fslmeants -i ${reg}_img_bptf -o ${reg}_bptf -c 0 0 0
end

if ($status) exit 1
endif

if ((! -e lat_vent.txt) || $f) then
echo "" >> $LF
echo "------------------------EXTRACTING GLOBAL SIGNAL AND TIMECOURSE FROM WM and V ROIS-----------------------" >> $LF
echo "" >> $LF
set cmd = ( fslmeants -i func_reorient_rm4_mcf4_st_sm5_f -o global.txt -m func_brain_mask.nii.gz)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1


set cmd = ( fslmeants -i func_reorient_rm4_mcf4_st_sm5_f -o wm_er1.txt -m masks/wm_er1.nii.gz)
echo $cmd >> $LF
$cmd >> $LF

set cmd = ( fslmeants -i func_reorient_rm4_mcf4_st_sm5_f -o lat_vent.txt -m masks/lat_vent.nii.gz)
echo $cmd >> $LF
$cmd >> $LF
if ($status) exit 1
endif


if ((! -e nuisance.feat/stats/res4d.nii.gz) || $f) then
echo "" >> $LF
echo "------------------------REGRESSING OUT nuisance PARAMETERS----------------------" >> $LF
echo "" >> $LF
if (-e nuisance.feat) then
rm -r nuisance.feat
endif

cp ${script_path}/nuisance.fsf .
sed s:SubA_GSP/r1/:Sub${subj}_GSP/r$run/: <nuisance.fsf >nuisance_${subj}.fsf

feat nuisance_${subj}.fsf
rm nuisance.fsf
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

case "--f":
set f = 1;
breaksw


endsw

end

goto parse_args_return;
