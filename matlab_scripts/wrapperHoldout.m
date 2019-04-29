
outputDataPath = '/Volumes/phelpslab2/Emily/gsp/processed_data_for_models/holdout/';
restFolder = '/Volumes/phelpslab2/Emily/gsp/rest/';
%% get holdout data table
gspDataTest = readtable('/Volumes/phelpslab2/Emily/gsp/GSP_extended_p2.csv');

gspDataTest.MRI_ID = gspDataTest.Subject_ID;
for i = 1:size(gspDataTest,1)
    gspDataTest.MRI_ID{i} = strrep(gspDataTest.MRI_ID{i},'S1','GSP');
end
subsTest = gspDataTest.MRI_ID;

%% get freesurfer graph matrix without any exclusions
groupMat = groupGraphMat(subsTest, 'fs_timecourses');

%% figure out who has to be excluded

%for motion (fewer than 90 good frames)
[excludeBool,numBad] = motionExclusions(subsTest);

%nan values
nonNanSubs = ~(sum(isnan(groupMat)))';

goodSubs = ~excludeBool & nonNanSubs;
csvwrite([outputDataPath 'goodSubs.csv'],goodSubs);
subsTest = subsTest(goodSubs);
numSubs = length(subsTest);
writetable(table(subsTest),[outputDataPath 'subsHoldout.csv'] , 'WriteVariableNames',0)
%% compute compos anx scores for test sample (using calculations made on discovery sample only)

gspDataTestGoodSubs = gspDataTest(goodSubs,:);% table for included subs in the holdout sample
gspData = readtable('/Volumes/phelpslab2/Emily/gsp/GSP_extended_p1.csv'); % table with discovery sample subs
goodSubsTrain = logical(load('../../processed_data_for_models/discovery/goodSubs.csv')) % logical array indicating subs included in disc sample

stai_mean  = mean(gspData.STAI_tAnxiety(goodSubsTrain))
neoN_mean  = mean(gspData.NEO_N(goodSubsTrain))
bis_mean  = mean(gspData.BISBAS_BIS(goodSubsTrain))
tci_mean  = mean(gspData.TCI_HarmAvoidance(goodSubsTrain))


stai_std  = std(gspData.STAI_tAnxiety(goodSubsTrain))
neoN_std  = std(gspData.NEO_N(goodSubsTrain))
bis_std  = std(gspData.BISBAS_BIS(goodSubsTrain))
tci_std  = std(gspData.TCI_HarmAvoidance(goodSubsTrain))

%z score holdout sample questionnaires using mean and std calculated on
%discovery sample
staiZ = (gspDataTestGoodSubs.STAI_tAnxiety - stai_mean)/stai_std
neoNZ = (gspDataTestGoodSubs.NEO_N - neoN_mean)/neoN_std
bisZ = (gspDataTestGoodSubs.BISBAS_BIS - bis_mean)/bis_std
tciZ = (gspDataTestGoodSubs.TCI_HarmAvoidance - tci_mean)/tci_std

%compute compos anxiety score with the z scored questionnaires 
composAnxTest = mean([staiZ  neoNZ  bisZ tciZ],2)
csvwrite([outputDataPath 'composAnxTest.csv'],composAnxTest)
%% make confound matrix

maxRMSMot = nan(numSubs,2);
for i = 1:numSubs
    if(exist([restFolder '/'  subsTest{i} '/r1/'],'file')>0)
        maxRMSMot(i,1) =  max(plot_par( [restFolder '/' subsTest{i} '/r1/preproc/func_reorient_rm4_mcf4.par']));
    end
    if(exist([restFolder '/'  subsTest{i} '/r2/'],'file')>0)
        maxRMSMot(i,2) =  max(plot_par( [restFolder '/' subsTest{i} '/r2/preproc/func_reorient_rm4_mcf4.par']));
    end
end
maxRMSMot = nanmean(maxRMSMot,2);
dummiesScanner = [strcmp(gspDataTestGoodSubs.Scanner_Bin,'A') strcmp(gspDataTestGoodSubs.Scanner_Bin,'B') ...
    strcmp(gspDataTestGoodSubs.Scanner_Bin,'C') strcmp(gspDataTestGoodSubs.Scanner_Bin,'D')];
%note: E purposely left out because it's the "reference" level

dummiesConsole = [strcmp(gspDataTestGoodSubs.Console,'B13') strcmp(gspDataTestGoodSubs.Console,'B17')]; %here 15 is the ref level
dummySex = strcmp(gspDataTestGoodSubs.Sex,'F');
numBadGoodSubs = numBad(goodSubs);
confMat = [ones(numSubs,1) dummiesScanner dummiesConsole gspDataTestGoodSubs.Age_Bin dummySex numBadGoodSubs maxRMSMot];
csvwrite([outputDataPath 'confMatHoldout.csv'],confMat);

%% make freesurfer graph matrix with only included subjects

groupGraphMat(subsTest, 'fs_timecourses', [outputDataPath 'fsHoldout.csv']);

%% make amyg conn features
amygseed = cell(1);
amygseed{1} = 'Amygdala';

voxelConnToMat(subsTest,amygseed,'amyg_seed_map',outputDataPath);
%% make matrix indicating coverage of each voxel for each subject (same shape as tables above)
coverageMat(subsTest,outputDataPath)