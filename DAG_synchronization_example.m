% DAG_SYNCHRONIZATION_EXAMPLE
% Minimal example for aligning one behavioral run to one TDT ephys block.
%
% Assumptions:
% - behavior_file ends with "_NN.mat" where NN is run number.
% - TDT epoc stores SVal/Tnum/RunN exist in the selected block.

behavior_file = 'D:\g-node\NHPRestingState_DPZ_Kagan_Wilke\Bac\20210714\Block-2\Bac2021-07-14_04.mat';
ephys_folder = 'D:\g-node\NHPRestingState_DPZ_Kagan_Wilke\Bac\20210714\Block-2';

%% Read in ephys data
% TDTbin2mat_working is a DAG-specific variant of the TDT readout function (previous version):
% https://github.com/tdtneuro/TDTMatlabSDK/blob/master/TDTbin2mat.m
% Here we use it to load only stores required for synchronization.
% If you want to load all ephys data, use TDTbin2mat (vendor version)
% or remove the EXCLUSIVELYREAD argument below.
ephys_data = TDTbin2mat_working(ephys_folder, 'EXCLUSIVELYREAD', {'SVal','Tnum','RunN','Sess'});

behavioral_data=load(behavior_file,'trial'); % load the trial structure from the behavioral file

behavioral_data.run=str2num(behavior_file(end-5:end-4)); % storing run number in the data to ensure avoiding certain mismatch

% synchronize the data
try
    % try to run without debug mode (last input) to catch exceptions
[continuous_timestamps, continuous_data, Trial_timestamps] = ph_synchronization(ephys_data,behavioral_data,0);
catch err
    disp([ephys_folder ' needed debug'])
[continuous_timestamps, continuous_data, Trial_timestamps] = ph_synchronization(ephys_data,behavioral_data,1);
end
%
% Output format (from ph_synchronization):
% - continuous_timestamps: [N x 1 double], seconds from ephys block start,
%   concatenated across all trials.
% - continuous_data: struct with concatenated fields:
%   state, x_eye, y_eye, x_hnd, y_hnd, sen_L, sen_R, jaw, body.
% - Trial_timestamps: [T x 1 double], one timestamp per trial (state 2 anchor).