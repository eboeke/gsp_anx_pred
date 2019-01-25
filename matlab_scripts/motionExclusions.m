function [excludeBool,numBad] = motionExclusions(subs)
    %motionExclusions determines subjects who should be excluded for
    %motion (fewer than 90 "good" frames). when just one run should be
    %excluded, the script prints the name of the subject/run and this file
    %should be manually moved.
    %Args: 
        %subs, cell with subject strings, length N
    %Output:
        %excludeBool, boolean of length  N indicating subjects to exclude
        %bc neither run meets criteria
        %numBad, vector of length N listing number of bad timepoints per
        %run. if 2 runs, averaged across the 2.
    
    
    restFolder = '/Volumes/phelpslab2/Emily/gsp/rest';

    outlierPath = '/preproc/censor/func_reorient_rm4_mcf4_FDRMS0.2_DVARS50_motion_outliers.txt';
    numSubs = size(subs,1);
    numGood = nan(numSubs,2);

    for i = 1:numSubs
        if(exist([restFolder '/'  subs{i} '/r1/'],'file')>0)
            nonOutliers = load([restFolder '/'  subs{i} '/r1/' outlierPath ]);
            numGood(i,1) = sum(nonOutliers);
        end
        if(exist([restFolder '/'  subs{i} '/r2/'],'file')>0)
            nonOutliers = load([restFolder '/'  subs{i} '/r2/' outlierPath]);
            numGood(i,2) = sum(nonOutliers);
        end 
    end

    under90Ind = find((numGood(:,1)<90) & (numGood(:,2)<90 |  isnan(numGood(:,2))));%people who must be excluced

    under90Subs = cell(size(under90Ind));
    for i = 1:length(under90Ind)
        under90Subs{i} = subs{under90Ind(i)};
    end

    secondGoodInd =  find((numGood(:,1)<90) & (numGood(:,2)>=90));
    secondGoodSubs = cell(size(secondGoodInd));
    for i = 1:length(secondGoodInd)
        secondGoodSubs{i} = subs{secondGoodInd(i)};
    end
    firstGoodInd =  find((numGood(:,1)>=90) & (numGood(:,2)<90));
    firstGoodSubs = cell(size(firstGoodInd));

    for i = 1:length(firstGoodInd)
        firstGoodSubs{i} = subs{firstGoodInd(i)};
    end

    disp('subjects for whom first run is ok, second must be excluded')
    disp(firstGoodSubs)
    disp('subjects for whom second run is ok, first must be excluded')
    disp(secondGoodSubs)

    %manually moved these bad runs out of their original folders
    
    numGoodMean = nanmean(numGood,2);
    numBad = 120-numGoodMean;
    excludeBool = ~((numGood(:,1)>=90) |  (numGood(:,2)>=90));

end