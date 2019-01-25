%% set path where we will write the data

outputDataPath = '/Volumes/phelpslab2/Emily/gsp/processed_data_for_models/discovery/';
restFolder = '/Volumes/phelpslab2/Emily/gsp/rest/';
%% get original sub list for discovery sample

gspData = readtable('/Volumes/phelpslab2/Emily/gsp/GSP_extended_p1.csv');
gspData.MRI_ID = gspData.Subject_ID;
for i = 1:size(gspData,1)
    gspData.MRI_ID{i} = strrep(gspData.MRI_ID{i},'S1','GSP');
end

subs = gspData.MRI_ID;

%% get freesurfer graph matrix without any exclusions
groupMat = groupGraphMat(subs, 'fs_timecourses');

%% determine people that have to be excluded 

%for motion (if fewer than 90 good frames, excluded)
[excludeBool,numBad] = motionExclusions(subs); 
%returns logical array indicating subjects to exlude, along with num bad
%timepoints for each subject

%nan values
nonNanSubs = ~(sum(isnan(groupMat)))';
%logical array indicating which subs have nan values

goodSubs = ~excludeBool & nonNanSubs;
csvwrite([outputDataPath 'goodSubs.csv'],goodSubs);

subs = subs(goodSubs);
numSubs = length(subs);
writetable(table(subs),[outputDataPath 'subsDisc.csv'] , 'WriteVariableNames',0)
%% compute composite anxiety scores

staiZ  = zscore(gspData.STAI_tAnxiety(goodSubs));
neoNZ  = zscore(gspData.NEO_N(goodSubs));
bisZ  = zscore(gspData.BISBAS_BIS(goodSubs));
tciHAZ  = zscore(gspData.TCI_HarmAvoidance(goodSubs));

composAnx = mean([staiZ  neoNZ  bisZ tciHAZ],2);
csvwrite([outputDataPath 'composAnxDisc.csv'],composAnx);

%% make confound matrix

gspDataGoodSubs = gspData(goodSubs,:);

maxRMSMot = nan(numSubs,2);
for i = 1:numSubs
    if(exist([restFolder '/'  subs{i} '/r1/'],'file')>0)
        maxRMSMot(i,1) =  max(plot_par( [restFolder '/' subs{i} '/r1/preproc/func_reorient_rm4_mcf4.par']));
    end
    if(exist([restFolder '/'  subs{i} '/r2/'],'file')>0)
        maxRMSMot(i,2) =  max(plot_par( [restFolder '/' subs{i} '/r2/preproc/func_reorient_rm4_mcf4.par']));
    end
end
maxRMSMot = nanmean(maxRMSMot,2);
dummiesScanner = [strcmp(gspDataGoodSubs.Scanner_Bin,'A') strcmp(gspDataGoodSubs.Scanner_Bin,'B') ...
    strcmp(gspDataGoodSubs.Scanner_Bin,'C') strcmp(gspDataGoodSubs.Scanner_Bin,'D')];
%note: E purposely left out because it's the "reference" level

dummiesConsole = [strcmp(gspDataGoodSubs.Console,'B13') strcmp(gspDataGoodSubs.Console,'B17')]; %here 15 is the ref level
dummySex = strcmp(gspDataGoodSubs.Sex,'F');
numBadGoodSubs = numBad(goodSubs); %number of bad timepoints (for included subs)
confMat = [ones(numSubs,1) dummiesScanner dummiesConsole gspDataGoodSubs.Age_Bin dummySex numBadGoodSubs maxRMSMot];
csvwrite([outputDataPath 'confMatDisc.csv'],confMat);



%% remake freesurfer graph matrix and write it. make other parcellation matrices
groupGraphMat(subs, 'fs_timecourses', [outputDataPath 'fsDisc.csv']);
groupGraphMat(subs, 'schaefer_timecourses', [outputDataPath 'schaeferDisc.csv']);
groupGraphMat(subs, 'schaefer_fs_timecourses', [outputDataPath 'schaeferFsDisc.csv']);
groupGraphMat(subs, 'shen_timecourses', [outputDataPath 'shenDisc.csv']);
groupGraphMat(subs, 'yeo2011_timecourses',[outputDataPath 'yeo17Disc.csv']);
groupGraphMat(subs, 'yeo2011_7_surf_timecourses', [outputDataPath 'yeo7FsDisc.csv']);

%for power parcellation, 1 sub has nans.
groupMat = groupGraphMat(subs, 'power_timecourses');
nonNanSubsPower = ~(sum(isnan(groupMat)))';
subsPower = subs(nonNanSubsPower);
composAnxPower = composAnx(nonNanSubsPower);
groupGraphMat(subsPower, 'power_timecourses', [outputDataPath 'powerDisc.csv']);
csvwrite([outputDataPath 'composAnxPowerDisc.csv'],composAnxPower);


%% save timecourses (rather than r values) for tangent matrix approach
for i = 1:numSubs
        saveTimecourses(subs{i},'fs_timecourses'); 
end

%% extract voxelwise data--for 85 seeds-- and put into table for each subject
fid = fopen('../fs_regions.txt');
regions = textscan(fid,'%s\t%s');
seeds = regions{2};
fclose(fid);

voxelConnToMat(subs,seeds,'seed_maps',[outputDataPath 'seed_maps/'])
%% do the same for bl amygdala seed
amygseed = cell(1);
amygseed{1} = 'Amygdala';

voxelConnToMat(subs,amygseed,'amyg_seed_map',[outputDataPath 'seed_maps/']);

