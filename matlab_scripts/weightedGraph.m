function [assoc assocV] =  weightedGraph(subj,folder)
    %produces out a weighted,  untreshresholded connectivity graph using a
    %specified parcellation. if two runs exist, makes 2 graphs and averages them.
    %Args: 
        %subj: subject string
        %folder: parcellation folder name
    %Output:
        %assoc: association matrix (graph)
        %assocV: association matrix, upper diagonal in vectorized form.
        

    datapath = ['/Volumes/phelpslab2/Emily/gsp/rest/' subj '/r1/' folder];

    datapath2 = ['/Volumes/phelpslab2/Emily/gsp/rest/' subj '/r2/' folder];

    if exist(datapath)>0
    %load files
    files1 = dir(datapath);
    files = files1(3:end);
    numReg = length(files);

    %extract timecourses
    timepoints = length(load([datapath '/' files(1).name]));
    timecourses = zeros(timepoints,numReg);
    for i = 1:numReg
        timecourses(:,i) = load([datapath '/' files(i).name]);
    end

    %make association matrix
    assoc = corr(timecourses); %matrix of r values and p values
    assoc(logical(eye(size(assoc)))) = 0;
    assocV = assoc(triu(true(size(assoc)),1)); %takes the top right triangle and vectorizes it
    end
    if exist(datapath2)>0
        files1 = dir(datapath2);
    files = files1(3:end);
    numReg = length(files);

        timepoints = length(load([datapath2 '/' files(1).name]));

        %extract timecourses
        timecourses = zeros(timepoints,numReg);
        for i = 1:numReg
            timecourses(:,i) = load([datapath2 '/'  files(i).name]);
        end

        %make association matrix
        assoc2 = corr(timecourses); %matrix of r values and p values
        assoc2(logical(eye(size(assoc2)))) = 0;
        assocV2 = assoc2(triu(true(size(assoc2)),1)); %takes the top right triangle and vectorizes it

        if exist(datapath)>0 % if r1 exists, avg them
        catAssoc = cat(3,assoc,assoc2);
        catAssocV = horzcat(assocV,assocV2);
        assoc  = mean(catAssoc,3);
        assocV = mean(catAssocV,2);
        else %if not, take r2 alone
            assoc = assoc2;
            assocV = assocV2;
        end

    end


end