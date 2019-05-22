%this script prints the identity of the most important region-to-region connectivity features
%(the features where the absolute value of the weight is highest), along with the weight and
%p-value associated with the feature. the weights and p values were calculated in
%revision_modeling.ipynb. these results are reported in the supplement.
%had to do this in matlab because matlab and python indexing of "triu" function is different,
%and matlab triu was used to vectorize connectivity features (see weighted_graph.m in
%matlab_data_processing_scripts), which determines the ordering of the features in the files
%indicating weights and p-values.
                                                              
                                

betas = load('/Volumes/phelpslab2/Emily/gsp/python_modeling_output/discovery/betas_graph.csv');
r2r_ps = load('/Volumes/phelpslab2/Emily/gsp/python_modeling_output/discovery/ps_graph.csv');

numNodes = 85;
graph = zeros(numNodes,numNodes);
upTri = triu(true(size(graph)),1);
ind=find(upTri);



[~,betasSortInd] = sort(abs(betas),1,'descend');

%get region names
fid = fopen('fs_region_names_simple.txt');
regions2 = textscan(fid,'%s');
regions = regions2{1};
fclose(fid);

for i = 1:10
    [m,n] = ind2sub(size(graph),ind(betasSortInd(i)));
    disp([regions(m(1)) ' ' regions(n(1))  ' '  num2str(round(betas(betasSortInd(i)),4)) ' '  num2str(round(r2r_ps(betasSortInd(i)),4))])

end

