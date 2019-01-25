#!/bin/csh



set python2pathfile = python2path.txt
set sublistfile = /Volumes/phelpslab2/Emily/gsp/processed_data_for_models/holdout/subsHoldout.csv
set outfolder = /Volumes/phelpslab2/Emily/gsp/processed_data_for_models/holdout/
set outstring = Holdout #for naming output files

#first, have to change path to use python 2.
setenv PATH `cat $python2pathfile`
#read in file with list of subs and set to subs variable
set subs = `cut -f1 $sublistfile`


#extract aseg and aparc stats and save to files
asegstats2table --subjects $subs  --segno 10 11 12 13 16 17 18 26 28 49 50 51 52 53 54 58 60 --tablefile ${outfolder}aseg_stats_${outstring}.txt

aparcstats2table --subjects $subs  --meas thickness --hemi lh --tablefile ${outfolder}aparc_stats_lh_${outstring}.txt

aparcstats2table --subjects $subs  --meas thickness --hemi rh --tablefile ${outfolder}aparc_stats_rh_${outstring}.txt
