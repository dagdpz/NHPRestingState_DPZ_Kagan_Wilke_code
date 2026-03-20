function copy_blocks_runs(block_path, run_path, data_path, Mon, SesRunBlo, target)
% copy_blocks_runs('', '', '', 'Bac', SesRunBlo,'dPul_l');
% copy_blocks_runs('', '', '', 'Mag', SesRunBlo,'dPul_l');
% SesRunBlo = xlsread('Sorting table.xlsx','Mag dPul_r','D:F'); copy_blocks_runs('', '', '', 'Mag', SesRunBlo,'dPul_l');

% block_path = 'Y:\Data\TDTtanks\Bacchus_phys';
% run_path = 'Y:\Data\Bacchus';
block_path = 'Y:\Data\TDTtanks\Magnus_phys';
run_path = 'Y:\Data\Magnus';

data_path = 'E:\g-node\ephys-resting-state-thalamus\Kagan';

SesRunBlo = unique(SesRunBlo,'rows');
Sessions  = unique(SesRunBlo(:,1));
N_sessions = length(Sessions);

diary([data_path filesep Mon filesep target '.txt']);
for k = 1:size(SesRunBlo,1)
    
    Ses = num2str(SesRunBlo(k,1));
    % Run = num2str(SesRunBlo(k,2));
    Blo = num2str(SesRunBlo(k,3));
    
    run_file = [Mon Ses(1:4) '-' Ses(5:6) '-' Ses(7:8) '_' sprintf('%02d',SesRunBlo(k,2)) '.mat'];
    
    
    RunFrom   = [run_path   filesep Ses filesep run_file];        
    BlockFrom = [block_path filesep Ses filesep 'Block-' Blo];
    
    To = [data_path filesep Mon filesep Ses filesep 'Block-' Blo];   
    
    copy_one_block_run(BlockFrom,RunFrom,To,To);
    
end
disp(['Copied ' num2str(N_sessions) ' sessions']);
diary off


function copy_one_block_run(BlockFrom,RunFrom,BlockTo,RunTo)


if exist(BlockTo,'dir')
    disp([BlockTo ' already exists, skipping' ]);
    
else
    
    disp(['Copying ' BlockFrom ' and ' RunFrom ' to ' BlockTo]);

    [SUCCESS,MESSAGE] = copyfile(BlockFrom,BlockTo);
    if ~SUCCESS, disp([MESSAGE ': ' BlockFrom]); end

    [SUCCESS,MESSAGE] = copyfile(RunFrom,RunTo);
    if ~SUCCESS, disp([MESSAGE  ': ' RunFrom]); end
    
end


