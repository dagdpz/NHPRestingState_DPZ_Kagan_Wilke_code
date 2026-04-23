function [continuous_timestamps, continuous_data, Trial_timestamps, report]=ph_synchronization(ephys_data,behavioral_data,debug_on)
%PH_SYNCHRONIZATION Align behavioral timing to ephys block time.
%   This function maps timing from behavioral trial structure to timestamps
%   relative to the start of a given TDT ephys block.
%
%   Stream mapping used in this function:
%   - Behavioral stream: behavioral_data.trial(t).state and
%     behavioral_data.trial(t).tSample_from_time_start
%   - Ephys trial/run stream: ephys_data.epocs.Tnum and ephys_data.epocs.RunN
%   - Ephys state stream: ephys_data.epocs.SVal

% INPUTS:
% behavioral_data - struct containing:
%                   behavioral_data.trial (trial structure array)
%                   behavioral_data.run   (run number)
% ephys_data      - struct created by reading a TDT block (TDTbin2mat or
%                   TDTbin2mat_working)

% OUTPUTS:
% continuous_timestamps - timestamps of continuous behavior data relative
%                         to ephys block start
% continuous_data       - struct containing concatenated continuous
%                         behavioral parameters across trials
% Trial_timestamps      - trial-wise timestamps (state 2 alignment points)
% report                - string array with all displayed messages in order

if nargin < 3 || isempty(debug_on)
    debug_on = true;
end

% Initialize outputs for safe early returns.
continuous_timestamps = [];
Trial_timestamps = [];
continuous_data = [];

% Collect all displayed messages for optional downstream logging/QA.
report = '';

% Early input sanity checks: behavioral/ephys trial and block identifiers
% must be available and non-empty.
if ~isfield(behavioral_data,'trial') || isempty(behavioral_data.trial)
    log_message('Behavioral trial data is missing or empty.');
    return
end
if ~isfield(behavioral_data,'run') || isempty(behavioral_data.run)
    log_message('Behavioral run/block identifier is missing or empty.');
    return
end
if ~isfield(ephys_data,'epocs') || ~isfield(ephys_data.epocs,'Tnum') || ~isfield(ephys_data.epocs.Tnum,'data') || isempty(ephys_data.epocs.Tnum.data)
    log_message('Ephys trial numbers (Tnum) are missing or empty.');
    return
end
if ~isfield(ephys_data,'epocs') || ~isfield(ephys_data.epocs,'RunN') || ~isfield(ephys_data.epocs.RunN,'data') || isempty(ephys_data.epocs.RunN.data)
    log_message('Ephys run/block identifiers (RunN) are missing or empty.');
    return
end
if ~isfield(ephys_data,'epocs') || ~isfield(ephys_data.epocs,'SVal') || ...
        ~isfield(ephys_data.epocs.SVal,'data') || isempty(ephys_data.epocs.SVal.data) || ...
        ~isfield(ephys_data.epocs.SVal,'onset') || isempty(ephys_data.epocs.SVal.onset)
    log_message('Ephys state stream (SVal) is missing or empty.');
    return
end

if ~isfield(ephys_data.epocs,'Tnum')
    log_message('No trials associated to this block');
    return 
end

% Extract behavioral and ephys metadata used for alignment
behavior_trials = behavioral_data.trial;
behavior_trial_numbers = [behavior_trials.n];
behavior_run_number = behavioral_data.run;
ephys_trial_numbers = ephys_data.epocs.Tnum.data;
ephys_run_numbers = ephys_data.epocs.RunN.data;
ephys_trial_onsets = [ephys_data.epocs.Tnum.onset];

if debug_on 
    % handling of known historical acquisition anomalies:
    if ~isfield(ephys_data.epocs, 'Sess') || ~isfield(ephys_data.epocs.Sess, 'data') || isempty(ephys_data.epocs.Sess.data)
        log_message('Ephys session stream (Sess) is missing or empty; skipping Sess-specific debug checks.');
        Session = [];
    else
        Session = ephys_data.epocs.Sess.data;
    end
    % Correct trial/run counters if the first trial was initialized incorrectly.
    if ~isempty(Session) && numel(ephys_trial_numbers)>1 && ephys_trial_numbers(1)~=1
        log_message('First incorrectly initialized trial corrected');
        ephys_trial_numbers(1) = ephys_trial_numbers(2)-1;
        ephys_run_numbers(1) = ephys_run_numbers(2);
        ephys_trial_onsets(1) = 0;
        Session(1)  = Session(2);
    end
    
    % Remove one spurious initial trial in a known legacy recording issue (Linus_20150703, Block-5).
    if ~isempty(Session) && numel(ephys_trial_numbers)>1 && ephys_trial_numbers(2)==1
        ephys_trial_numbers(1) = [];
        ephys_run_numbers(1) = [];
        Session(1)      =[];
        ephys_trial_onsets(1) = [];
        log_message('Additional trial in the beginning removed');
    end
    
    % If multiple initial trial counters are invalid, reject this block.
    % Example known case: Bac_20210826.
    if ~isempty(Session) && numel(ephys_trial_numbers)>1 && (any(ephys_trial_numbers<1) || any( Session<100000 | Session>800000) || any(Session~=Session(end)))
        log_message('Synchronization impossible due to corrupted ephys state information - entire run invalid');
        continuous_timestamps=[];
        Trial_timestamps=[];
        continuous_data=[];
        return;
    end
        
    % Remove ephys trial onsets that do not correspond to the behavioral run.
    % This can occur when an ephys block spans multiple behavioral runs.
    if any(ephys_run_numbers~=behavior_run_number)
        log_message(['Warning: multiple runs in one block! Run onsets at TDT trials: ' mat2str(find(ephys_trial_numbers==1))]);
        matching_trials=ephys_run_numbers==behavior_run_number;
        ephys_trial_numbers = ephys_trial_numbers(matching_trials);
        ephys_trial_onsets = ephys_trial_onsets(matching_trials);
        log_message(['Retained TDT trials corresponding to the requested behavioral run: ' mat2str(find(matching_trials))]);
    end
    
    % Keep only behavioral trials that are in the ephys data as well - rare case
    % of a last behavioral trial was initiated, but not streamed to ephys
    if numel(behavior_trial_numbers)>numel(ephys_trial_numbers)
        overlapping_trials=arrayfun(@(x) any(ephys_trial_numbers==x),behavior_trial_numbers);
        behavior_trial_numbers = behavior_trial_numbers(overlapping_trials);
        log_message(['Too many behavioral trials: ' mat2str(numel(overlapping_trials) - sum(overlapping_trials)) ' behavioral trial(s) removed']);
    end
    
end



% Compute sample-wise and trial-wise timestamps in one pass
% (same state-2 alignment anchor used for both outputs).
ephys_state_onsets = ephys_data.epocs.SVal.onset;
ephys_state_values = ephys_data.epocs.SVal.data;

continuous_timestamps=[];
Trial_timestamps=[];
aligned_trial_indices = [];
for t=behavior_trial_numbers
    % Align to state 2 (not state 1), because state 1 is used for trial
    % initiation/signaling and has different onset timing properties.
    trial_idx = find(behavior_trial_numbers==t, 1, 'first');
    if isempty(trial_idx)
        log_message(['Behavioral trial index not found for trial id: ' num2str(t)]);
        continue;
    end
    
    behavior_state2_idx = find(behavior_trials(trial_idx).state==2,1,'first');
    if isempty(behavior_state2_idx)
        log_message(['No behavioral state==2 found for trial id: ' num2str(t)]);
        continue;
    end
    behavior_state2_time = behavior_trials(trial_idx).tSample_from_time_start(behavior_state2_idx);
    
    trial_onset_idx = find(ephys_trial_numbers==t, 1, 'first');
    if isempty(trial_onset_idx)
        log_message(['No ephys trial onset found for trial id: ' num2str(t)]);
        continue;
    end
    ephys_state2_idx = find(ephys_state_onsets>ephys_trial_onsets(trial_onset_idx) & ephys_state_values==2,1,'first');
    if isempty(ephys_state2_idx)
        log_message(['No ephys state==2 onset found after trial onset for trial id: ' num2str(t)]);
        continue;
    end
    ephys_state2_onset = ephys_state_onsets(ephys_state2_idx);
    
    behavior_timestamps_in_ephys_time = behavior_trials(trial_idx).tSample_from_time_start - behavior_state2_time + ephys_state2_onset;
    continuous_timestamps=[continuous_timestamps; behavior_timestamps_in_ephys_time];
    Trial_timestamps=[Trial_timestamps; ephys_state2_onset];
    aligned_trial_indices(end+1,1) = trial_idx;
end

% Concatenate per-trial continuous behavioral streams
fields_to_concat={'state','x_eye', 'y_eye', 'x_hnd', 'y_hnd', 'sen_L', 'sen_R', 'jaw', 'body' };
for f=1:numel(fields_to_concat)
    current_field=fields_to_concat{f};
    if isempty(aligned_trial_indices)
        continuous_data.(current_field) = [];
    else
        continuous_data.(current_field)=vertcat(behavior_trials(aligned_trial_indices).(current_field));
    end
end

    function log_message(msg)
        % Keep legacy console output behavior while storing a report copy.
        disp(msg);
        report = [report ' | ' msg];
    end
end
