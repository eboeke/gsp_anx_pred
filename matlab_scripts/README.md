Matlab scripts 

These are used for various data processing steps on the neuroimaging data after it is processed with FSL. I also compute the composite anxiety scores in these scripts, and create confound matrices. 

All of these processing steps can be run by running wrapperDiscSample.m (for the discovery sample) and wrapperHoldout.m (for the holdout sample.) This makes necessary files for the modeling Jupyter notebook.

It is necessary to run all of the scripts in the fcmri_preprocessing folder before running the Matlab wrapper scripts.
