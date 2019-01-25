function [groupMat] = groupGraphMat(subs, folder, varargin)
    %groupGraphMat makes a matrix of connectivity graph edge values across 
    %subjects. it will have size M x N where M = number of edges,
    %N = number of subjects. thus it extracts the graph in vectorized form for
    %each subject before putting it into the matrix. It also fisher
    %transforms the connectivity values.
    
    %Args:
        %subs; cell of length N that lists subject strings
        %folder; string with folder name for parcellation
        %varargin: optional variable, supply filename here if you desire to
        %save matrix to a csv file
    %Output: 
        %groupMat, M x N matrix with graph edge values for each subject.
    
        
    %determine if extra argument was supplied and assign to fileName
    if nargin==3
        fileName = varargin{1};
        write = 1;
    elseif nargin>3
        error('too many arguments')
    else
        write = 0;
    end

    %make a single graph to determine groupMat size, initialize groupMat
    numSubs = length(subs);
    [singleGraph] = weightedGraph(subs{1},folder); 
    numNodes = size(singleGraph,1) ;
    numEdges = (numNodes*(numNodes-1))/2;
    groupMat = zeros(numEdges,numSubs);

    %fill the matrix
    for i = 1:numSubs
        [~, groupMat(:,i)] = weightedGraph(subs{i},folder); 
    end
    
    %fisher transform
    groupMat = .5*(log(1+groupMat)-log(1-groupMat));

    if(write)
        csvwrite(fileName,groupMat);
    end
end