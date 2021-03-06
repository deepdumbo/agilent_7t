clear all; close all;

%% Experiment folder
experiment_folder = '/Users/jepelh/data/s_20150716_MouseBold07';

%% Convert the .fdf files to .nii
[data,names] = fdf_to_nifti(experiment_folder);

%% Compute the snr maps
output_dir = '/Users/jepelh/Desktop/snr_maps';
if ~exist(output_dir,'dir'), mkdir(output_dir), end
cd(output_dir)
snr_maps = compute_snr_maps (data,names);
