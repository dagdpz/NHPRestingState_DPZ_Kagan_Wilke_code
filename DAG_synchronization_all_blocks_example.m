function [synchronization_results, synchronization_report] = DAG_synchronization_all_blocks_example(main_folder)
% DAG_SYNCHRONIZATION_ALL_BLOCKS_EXAMPLE
% Example call:
%   [results, report] = DAG_synchronization_all_blocks_example('D:\...\Bac');
%
% This function:
% 1) Starts from main_folder (subject-level folder, e.g. ...\Bac)
% 2) Finds all day folders matching YYYYMMDD inside main_folder
% 3) Finds all Block-* folders inside each day folder
% 4) Finds behavioral MAT files in each block using subject/date prefix
% 5) Runs ph_synchronization for each block
% 6) Stores outputs/errors in synchronization_results

if nargin < 1 || isempty(main_folder)
    warning('Provide main_folder (subject-level folder, e.g. D:\...\Bac). Returning empty results.');
    synchronization_results = empty_results_struct();
    synchronization_report = empty_report_struct();
    return;
end

[~, subject_name] = fileparts(main_folder);

%% Discover and sort day folders (YYYYMMDD)
day_dirs = dir(main_folder);
day_dirs = day_dirs([day_dirs.isdir]);
day_names = {day_dirs.name};
is_day = ~ismember(day_names, {'.', '..'}) & ~cellfun(@isempty, regexp(day_names, '^\d{8}$', 'once'));
day_dirs = day_dirs(is_day);

if isempty(day_dirs)
    warning('No day folders (YYYYMMDD) found in: %s. Returning empty results.', main_folder);
    synchronization_results = empty_results_struct();
    synchronization_report = empty_report_struct();
    return;
end

[~, day_sort_idx] = sort({day_dirs.name});
day_dirs = day_dirs(day_sort_idx);

%% Preallocate results container
synchronization_results = empty_results_struct();
synchronization_report = empty_report_struct();

%% Process all days and all blocks
for d = 1:numel(day_dirs)
    day_token = day_dirs(d).name;
    day_folder = fullfile(main_folder, day_token);
    
    day_token_dashed = sprintf('%s-%s-%s', day_token(1:4), day_token(5:6), day_token(7:8));
    behavior_prefix = [subject_name day_token_dashed '_'];
    
    block_dirs = dir(fullfile(day_folder, 'Block-*'));
    block_dirs = block_dirs([block_dirs.isdir]);
    
    if isempty(block_dirs)
        day_warning = sprintf('[%s] No Block-* folders found.', day_token);
        warning('%s', day_warning);
        
        result_entry.day_folder = day_folder;
        result_entry.block_folder = '';
        result_entry.behavior_file = '';
        result_entry.continuous_timestamps = [];
        result_entry.continuous_data = struct();
        result_entry.Trial_timestamps = [];
        report_entry.day_folder = day_folder;
        report_entry.block_folder = '';
        report_entry.behavior_file = '';
        report_entry.messages = append_report('', day_warning);
        synchronization_results(end+1) = result_entry; 
        synchronization_report(end+1) = report_entry; 
        continue;
    end
    
    block_numbers = nan(numel(block_dirs), 1);
    for i = 1:numel(block_dirs)
        block_numbers(i) = parse_block_number(block_dirs(i).name);
    end
    [~, block_sort_idx] = sort(block_numbers);
    block_dirs = block_dirs(block_sort_idx);
    
    for i = 1:numel(block_dirs)
        block_name = block_dirs(i).name;
        block_path = fullfile(day_folder, block_name);
        
        % Restrict behavioral candidates to the expected subject/day prefix.
        mat_candidates = dir(fullfile(block_path, [behavior_prefix '*.mat']));
        
        result_entry.day_folder = day_folder;
        result_entry.block_folder = block_path;
        result_entry.behavior_file = '';
        result_entry.continuous_timestamps = [];
        result_entry.continuous_data = struct();
        result_entry.Trial_timestamps = [];
        report_entry.day_folder = day_folder;
        report_entry.block_folder = block_path;
        report_entry.behavior_file = '';
        report_entry.messages = '';
        
        if isempty(mat_candidates)
            msg = sprintf('[%s/%s] No behavioral MAT file matching "%s*.mat"', day_token, block_name, behavior_prefix);
            report_entry.messages = append_report(report_entry.messages, msg);
            synchronization_results(end+1) = result_entry; 
            synchronization_report(end+1) = report_entry; 
            warning('%s', msg);
            continue;
        end
        
        % Prefer deterministic ordering if multiple candidates are present.
        [~, name_order] = sort({mat_candidates.name});
        mat_candidates = mat_candidates(name_order);
        behavior_file = fullfile(block_path, mat_candidates(1).name);
        result_entry.behavior_file = behavior_file;
        report_entry.behavior_file = behavior_file;
        
        if numel(mat_candidates) > 1
            msg = sprintf('[%s/%s] Multiple MAT files matched. Using: %s', day_token, block_name, mat_candidates(1).name);
            report_entry.messages = append_report(report_entry.messages, msg);
            warning('%s', msg);
        end
        
        try
            ephys_data = TDTbin2mat_working(block_path, 'EXCLUSIVELYREAD', {'SVal','Tnum','RunN','Sess'});
            behavioral_data = load(behavior_file, 'trial');
            
            run_number = parse_run_number(mat_candidates(1).name);
            if isnan(run_number)
                msg = sprintf('[%s/%s] Could not parse run number from file: %s', day_token, block_name, mat_candidates(1).name);
                report_entry.messages = append_report(report_entry.messages, msg);
                warning('%s', msg);
            elseif ~isfield(behavioral_data, 'trial') || isempty(behavioral_data.trial)
                msg = sprintf('[%s/%s] Behavioral MAT file missing ''trial'' variable: %s', day_token, block_name, mat_candidates(1).name);
                report_entry.messages = append_report(report_entry.messages, msg);
                warning('%s', msg);
            else
                behavioral_data.run = run_number;
                
                [continuous_timestamps, continuous_data, Trial_timestamps, report] = ph_synchronization(ephys_data, behavioral_data);
                
                result_entry.continuous_timestamps = continuous_timestamps;
                result_entry.continuous_data = continuous_data;
                result_entry.Trial_timestamps = Trial_timestamps;
                report_entry.messages = append_report(report_entry.messages, report);
            end
        catch ME
            msg = sprintf('[%s/%s] Synchronization failed: %s', day_token, block_name, ME.message);
            report_entry.messages = append_report(report_entry.messages, msg);
            warning('%s', msg);
        end
        
        synchronization_results(end+1) = result_entry; 
        synchronization_report(end+1) = report_entry; 
    end
end


%% Save one-line-per-block report text file in main_folder
report_file = fullfile(main_folder, 'synchronization_report.txt');
write_text_report(report_file, synchronization_report);
fprintf('Text report saved: %s\n', report_file);

%% Optional quick summary
num_fail = sum(arrayfun(@has_failure, synchronization_report));
num_ok = numel(synchronization_results) - num_fail;
fprintf('Done. %d days scanned, %d blocks processed: %d successful, %d failed.\n', numel(day_dirs), numel(synchronization_results), num_ok, num_fail);

end

% -------------------------- Local helper functions --------------------------
function n = parse_block_number(block_name)
token = regexp(block_name, '^Block-(\d+)$', 'tokens', 'once');
if isempty(token)
    n = inf;
else
    n = str2double(token{1});
end
end

function run_number = parse_run_number(file_name)
token = regexp(file_name, '_(\d+)\.mat$', 'tokens', 'once');
if isempty(token)
    run_number = NaN;
else
    run_number = str2double(token{1});
end
end

function report = append_report(report, msg)
if isempty(msg)
    return;
end
if isempty(report)
    report = msg;
else
    report = [report ' | ' msg];
end
end

function tf = has_failure(report_entry)
if isempty(report_entry.messages)
    tf = false;
    return;
end
report_text = lower(strjoin(cellstr(report_entry.messages), ' '));
failure_markers = {'corrupted', 'failed', 'no behavioral mat file', 'no block-* folders found', 'could not parse run number', 'missing ''trial'' variable'};
for f=1:numel(failure_markers)
    tf = any(strfind(report_text, failure_markers{f}));
    if tf
        break;
    end
end
end

function s = empty_results_struct()
s = struct( ...
    'day_folder', {}, ...
    'block_folder', {}, ...
    'behavior_file', {}, ...
    'continuous_timestamps', {}, ...
    'continuous_data', {}, ...
    'Trial_timestamps', {} );
end

function s = empty_report_struct()
s = struct( ...
    'day_folder', {}, ...
    'block_folder', {}, ...
    'behavior_file', {}, ...
    'messages', {} );
end

function write_text_report(report_file, synchronization_report)
fid = fopen(report_file, 'wt');
if fid == -1
    warning('Could not create report file: %s', report_file);
    return;
end
cleanup_obj = onCleanup(@() fclose(fid)); 

% Tab-separated output keeps columns visually aligned for all block numbers.
fprintf(fid, 'output_folder\tbehavior_file\tmessage\n');

for i = 1:numel(synchronization_report)
    entry = synchronization_report(i);
    output_folder = entry.block_folder;
    if isempty(output_folder)
        % Day-level entry when no Block-* folders were found.
        output_folder = entry.day_folder;
    end
    
    [~, behavior_name, behavior_ext] = fileparts(entry.behavior_file);
    if isempty(behavior_name)
        behavior_file_name = 'N/A';
    else
        behavior_file_name = [behavior_name behavior_ext];
    end
    
    if isempty(entry.messages)
        message_text = 'OK';
    else
        message_text = entry.messages;
    end
    
    % Keep one physical line per block by stripping newline characters.
    message_text = strrep(message_text, sprintf('\r'), ' ');
    message_text = strrep(message_text, sprintf('\n'), ' ');
    
    fprintf(fid, '%s\t%s\t%s\n', output_folder, behavior_file_name, message_text);
end
end
