function nhprs_kw_copy_blocks_runs(block_path, run_path, data_path, Mon, SesRunBlo, target, dry_run)
%NHPRS_KW_COPY_BLOCKS_RUNS Copy selected block/run pairs into upload layout.
%   NHPRS_KW_COPY_BLOCKS_RUNS(BLOCK_PATH, RUN_PATH, DATA_PATH, MON, SESRUNBLO, TARGET, DRY_RUN)
%   copies TDT Block folders and matching behavioral run .mat files listed
%   in SESRUNBLO to:
%       DATA_PATH\MON\<Session>\Block-<BlockNumber>
%
%   Inputs
%   - BLOCK_PATH : source root of TDT block folders (organized by session).
%   - RUN_PATH   : source root of behavioral run .mat files (by session).
%   - DATA_PATH  : destination root used for data packaging.
%   - MON        : monkey prefix used in run filename (e.g. 'Bac', 'Mag').
%   - SESRUNBLO  : Nx3 numeric matrix [Session, Run, Block].
%   - TARGET     : label used for diary log filename.
%   - DRY_RUN    : logical flag. If true, prints planned actions only.
%
%   Important
%   - If BLOCK_PATH/RUN_PATH/DATA_PATH are empty, defaults are used.
%   - Existing destination block folders are skipped.
%
%   Examples
%   copy_blocks_runs('', '', '', 'Bac', SesRunBlo, 'dPul_l');
%   copy_blocks_runs('', '', '', 'Mag', SesRunBlo, 'dPul_l');
%   SesRunBlo = xlsread('Sorting table.xlsx','Mag dPul_r','D:F');
%   copy_blocks_runs('', '', '', 'Mag', SesRunBlo, 'dPul_l');

if nargin < 7 || isempty(dry_run)
    dry_run = false;
end

if isempty(block_path)
    block_path = 'Y:\Data\TDTtanks\Bacchus_phys';
    % block_path = 'Y:\Data\TDTtanks\Magnus_phys';
end
if isempty(run_path)
    run_path = 'Y:\Data\Bacchus';
    % run_path = 'Y:\Data\Magnus';
end
if isempty(data_path)
    data_path = 'D:\g-node\NHPRestingState_DPZ_Kagan_Wilke';
end


SesRunBlo = unique(SesRunBlo,'rows');
Sessions  = unique(SesRunBlo(:,1));
N_sessions = length(Sessions);

% Log copy actions for this target in a diary text file.
log_file = fullfile(data_path, Mon, [target '.txt']);
diary(log_file);
diary_guard = onCleanup(@() diary('off')); %#ok<NASGU>
for k = 1:size(SesRunBlo,1)
    
    Ses = num2str(SesRunBlo(k,1));
    % Run = num2str(SesRunBlo(k,2));
    Blo = num2str(SesRunBlo(k,3));
    
    % Behavioral run filename convention: MonYYYY-MM-DD_NN.mat
    run_file = [Mon Ses(1:4) '-' Ses(5:6) '-' Ses(7:8) '_' sprintf('%02d',SesRunBlo(k,2)) '.mat'];
    
    
    RunFrom   = fullfile(run_path, Ses, run_file);
    BlockFrom = fullfile(block_path, Ses, ['Block-' Blo]);
    
    % Destination block folder within repository layout.
    To = fullfile(data_path, Mon, Ses, ['Block-' Blo]);
    
    copy_one_block_run(BlockFrom,RunFrom,To,To,dry_run);
    
end
disp(['Copied ' num2str(N_sessions) ' sessions']);
if dry_run
    disp('Dry run mode: no files were copied.');
end


function copy_one_block_run(BlockFrom,RunFrom,BlockTo,RunTo,dry_run)

if ~exist(BlockFrom,'dir')
    disp(['Missing block source directory, skipping: ' BlockFrom]);
    return;
end

if ~exist(RunFrom,'file')
    disp(['Missing run source file, skipping: ' RunFrom]);
    return;
end


if exist(BlockTo,'dir')
    % Skip to avoid overwriting existing destination block folders.
    disp([BlockTo ' already exists, skipping' ]);
    
else
    
    disp(['Copying ' BlockFrom ' and ' RunFrom ' to ' BlockTo]);

    if dry_run
        disp('DRY RUN: block copy skipped');
        disp(['  from: ' BlockFrom]);
        disp(['  to  : ' BlockTo]);
        disp('DRY RUN: run copy skipped');
        disp(['  from: ' RunFrom]);
        disp(['  to  : ' RunTo]);
        return;
    end

    [SUCCESS,MESSAGE] = copyfile(BlockFrom,BlockTo);
    if ~SUCCESS, disp([MESSAGE ': ' BlockFrom]); end

    [SUCCESS,MESSAGE] = copyfile(RunFrom,RunTo);
    if ~SUCCESS, disp([MESSAGE  ': ' RunFrom]); end
    
end


