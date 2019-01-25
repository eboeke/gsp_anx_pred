function [timecourses] =  saveTimecourses(subj,folder)
    %saveTimecourses makes a matrix of all timecourses (for all regions)
    %for a given subject, and saves this matrix to a csv file. 
    %it concatenates timecourses across runs if there are 2 runs.
    %Args
        %subj: subject string
        %folder: parcellation folder name 
    %Output:
        %timecourses, a T X R matrix where T = number of timepoints, R =
        %number of regions.

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


    end

    if exist(datapath2)>0
        files1 = dir(datapath2);
    files = files1(3:end);
    numReg = length(files);

    timepoints = length(load([datapath2 '/' files(1).name]));

    %extract timecourses
    timecourses2 = zeros(timepoints,numReg);
    for i = 1:numReg
        timecourses2(:,i) = load([datapath2 '/'  files(i).name]);
    end




    if exist(datapath)>0 % if r1 exists, concat
        timecourses = vertcat(timecourses,timecourses2);
    else %if nto, take r2 alone
        timecourses =  timecourses2;
    end

    end
    mkdir(['/Volumes/phelpslab2/Emily/gsp/rest/' subj '/allreg_timecourse_files/']);
    csvwrite(['/Volumes/phelpslab2/Emily/gsp/rest/' subj '/allreg_timecourse_files/' folder '.csv'],timecourses)

end