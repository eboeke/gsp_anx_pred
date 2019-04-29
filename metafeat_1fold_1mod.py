#this script is used to create meta features for a stacked model
#it was designed for a model with 85 different feature sources, which provide
#the basis for 85 base models. It needed to be parallelized and run on hpc cluster
#due to memory constraints. this script creates "train" and "test" metafeatures for
#one cross validation fold (specified in first argument) for one feature source/
#base model (specified in second argument), running all 85 "inner" folds of stacking
#for that base model. so each fold of cv/base model combination should be submitted
#as a separate cluster job. saved metafeatures can then be loaded into python notebook
#to run the "outer"/stacked model

#Args:
    #number 0-5, indicating cv fold to run
    #number 0-84, indicating which data source/seed map to use for base model
#Output:
    #saves "train" and "test" meta features for a the given fold/base model

#example usage: python stack_array 2 17
#this would run the 3rd fold of CV, 18th base model/data source

import pandas as pd
import numpy as np
import sys
from scipy import stats
from sklearn.linear_model import Ridge
from sklearn.preprocessing import StandardScaler,Imputer
from sklearn.pipeline import Pipeline



def stack_1map_1cvfold(X,y,inner_pipeline,seed_name,cv_fold,num_models):
    #this function creates and saves the meta features
        #Args:
            #X: 2d numpy array, features for the data source/base model specified when calling the script
                #(for all subjects in discovery sample))
            #y: 1d numpy array, the  target variable
            #inner_pipeline: pipeline for the base models
            #cv fold: int, the fold of cv being run in the script
            #num_models, total number of base models--this will determine the number
                #of "inner" folds of stacking
        #returns nothing
    output_path = '/scratch/eb1384/gsp/metafeatures/' #where the metafeatures will be saved
    n_folds = 6#folds for outer cv for model evaluation
    outer_cv = cv_stratified(n_folds,y) #splits for outer cv for model evaluation

    n = len(y)

    #split data into training and test for this fold:
    train,test=outer_cv[cv_fold]
    y_train_outer = y[train]
    y_test_outer = y[test]
    X_train_outer = X[train] #training examples for cv (for model evaluation)
    X_test_outer = X[test]

    stack_split = cv_stratified(num_models,y_train_outer)#split into folds for model stacking

    #initialize arrays for metafeatures. training metafeatures are the inner/base
    #model prediction for each subject in the training fold. so 1d array, length
    #is num training samples
    #test metafeatures are the inner/base model predictions for each subject in
    #the test fold. we have one prediction for each inner fold of stacking. so
    #2d array, num test subs x num folds of stacking (85 in this case)
    meta_feat_train = np.zeros((len(y_train_outer)))
    meta_feat_test = np.zeros((len(y_test_outer),num_models))

    #for each inner fold of stacking, train the base model to generate predictions
    #for cv "train" and cv "test" subjects, to be used as metafeatres"
    for f in np.arange(num_models):

        #define "inner" train and test subs, for "inner" fold of stacking
        X_train_inner = X_train_outer[stack_split[f][0]]
        X_test_inner = X_train_outer[stack_split[f][1]]

        y_train_inner = y_train_outer[stack_split[f][0]]
        y_test_inner = y_train_outer[stack_split[f][1]]

        #fit inner model
        inner_pipeline.fit(X_train_inner, y_train_inner)

        #record predictions for train and test (meta features)
        meta_feat_train[stack_split[f][1]] = inner_pipeline.predict(X_test_inner).ravel()
        meta_feat_test[:,f] = inner_pipeline.predict(X_test_outer).ravel()

    #average test meta features across inner folds
    mean_meta_feat_test = np.mean(meta_feat_test,axis = 1)

    #write meta features to file
    np.savetxt(output_path + 'meta_feat_train_' + seed_name + '_fold' + str(cv_fold) + '.csv',meta_feat_train,delimiter=',')
    np.savetxt(output_path + 'meta_feat_test_' + seed_name + '_fold' + str(cv_fold) + '.csv',mean_meta_feat_test,delimiter=',')


def cv_stratified(n_folds,y):
    #creates stratified cross validation folds using continuous output variable (y)
    #to ensure a similar spread of y values across folds.
    #deterministic, so that when different folds of CV are run by calling this
    #script with different arguments, the CV folds will be consistent across calls


    #Args:
        #n_folds, number of folds for cv
        #y, the target variable
    #Returns:
        #CViterator, iterable of length n_folds, containing indices of training
            #and test samples for each fold
    idx = np.argsort(y,0)
    n_inst = len(y)
    all_idx = np.arange(n_inst)

    CViterator = []
    for k in range(n_folds):
        test_idx = idx[np.arange(k,n_inst,n_folds)]
        test_idx  = test_idx.ravel()
        test_bool = np.zeros(n_inst,dtype=bool)
        test_bool[test_idx]=True
        train_bool= ~test_bool
        train_idx = all_idx[train_bool]

        CViterator.append((train_idx,test_idx))
    return(CViterator)

def main():
    cv_fold = int(sys.argv[1])
    seed_number = int(sys.argv[2])
    print(cv_fold)
    print(seed_number)
    data_path = '/scratch/eb1384/gsp/seed_maps/'

    #read in anx data
    compos_anx_file = '/scratch/eb1384/gsp/composAnxDisc.csv'
    anx_data = pd.read_csv(compos_anx_file, header=None)
    anx_data = anx_data.values

    #read in fcmri data for the specified data source/seed (features that will
    #be used for base model )
    reg_table = pd.read_table('fs_regions.txt',header=None)
    seeds = reg_table[1].values
    s = seeds[seed_number]
    print(s)
    s_map =  pd.read_csv(data_path + s + '.csv',header=None)
    s_map = s_map.values
    coverage_map =  pd.read_csv(data_path  + 'coverage_masks.csv',header=None)
    coverage_map = coverage_map.values
    #zscore within subject (excluding values of 0, which indicate that subject didnt
    #have coverage in that voxel)

    s_naned = np.array(s_map)
    nan_idx = coverage_map==0
    s_naned[nan_idx] = np.nan

    #zscoring
    s_data_z = np.array(s_naned)
    for i in range(s_data_z.shape[0]):
        s_data_z[i,~np.isnan(s_naned[i,:])]= stats.zscore(s_data_z[i,~np.isnan(s_naned[i,:])])


    steps = [
             ('impute',Imputer(missing_values='NaN',strategy='mean')),
             ('standardize', StandardScaler()),
             ('regression', Ridge(alpha=1000))
             ]
    pipeline = Pipeline(steps)
    num_models= len(seeds)
    stack_1map_1cvfold(s_data_z,anx_data,pipeline,s,cv_fold,num_models)

if __name__== '__main__':
    main()
