#!/bin/csh

#Flags:

#	--s (subject name)
#   --r (run number)
set scan_type = ();

set run = ();
set subj = ();

set boldpath = /scratch/eb1384/gsp/rest
set labeldir = /scratch/eb1384/gsp/ROIs/yeo2011

goto parse_args;
parse_args_return:



cd $labeldir
set labels = `ls`

if (! -e $boldpath/$subj/$run/yeo2011_timecourses/) then
echo hi
mkdir $boldpath/$subj/$run/yeo2011_timecourses/
endif

foreach label ($labels)
set hemi = `echo $label | cut -c1-2`

mri_label2label --srcsubject fsaverage --srclabel $labeldir/$label --trgsubject $subj --trglabel $label --regmethod surface --hemi $hemi

mri_segstats --avgwf $boldpath/$subj/$run/yeo2011_timecourses/$label.txt --slabel $subj $hemi $SUBJECTS_DIR/$subj/label/$label --id 1 --i $boldpath/$subj/$run/preproc/res4d.self.surf.${hemi}.nii.gz


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






