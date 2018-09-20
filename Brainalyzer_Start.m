clc;
clear variables;
close all;

ratBlocks = {};
%----------------------------------------------------------%
%----------------------------------------------------------%
%                          STEP 0                          %
%                                                          %
%  Here we want to read and save the step, directory, and  %
% variables of interest from the user or other method for  %
% our analyses. (rat number, directory of raw files, save  %
% directory, etc.                                          %
%--------------------Editable Constants--------------------%
%----------------------------------------------------------%
inDirTev = 'D:\HPC-LEC\Raw-Data\';
inDirSev = '';
outDir = 'D:\HPC-LEC\Converted_Data\';

analysis = 1;
%Choose analysis value from list below
% 1 = Pre-Process
%    -This step loads in data from raw files
%    -This includes position, eeg by shank, and timestamps
%
% 2 = Noise Reduction
%    -Noise reduction has not yet been implemented
% 3 = Position Heat Map
%    -Spike sorting has not yet been implemented
%----------------------------------------------------------%

if analysis == 1
    ratsToProcess = Interface_ReturnRatsToProcess(inDirTev);
    %ratPoss = dir(inDirTev);
else
    ratsToProcess = Interface_ReturnRatsToProcess(outDir);
end
ratBlocks = cell(size(ratsToProcess, 2), 1);
%Collect the numbers of the rats that get an error during processing. This
%will eventually be converted to an error message in future iterations of
%the code.
errRats = [];
ratIdx = 0;


%----------------------------------------------------------%
%----------------------------------------------------------%
%                          STEP 1                          %
%                                                          %
%  First, we read in and evaluate the step, directory, and %
% variables of interest from the user of other method for  %
% our analyses. (rat number, directory of raw files, save  %
% directory, etc.                                          %
%--------------------Editable Constants--------------------%
%----------------------------------------------------------%

while ratIdx < size(ratsToProcess, 2)
    ratIdx = ratIdx + 1;
    blockIdx = 0;
    if analysis == 1
        toDir = [outDir, ratsToProcess(ratIdx).ID, '\'];
        
        inDirT = [inDirTev, ratsToProcess(ratIdx).ID, '\'];
        inDirS = [inDirSev, ratsToProcess(ratIdx).ID, '\'];
        
        ratInfo = Brain_FetchRatInfo(toDir, ratsToProcess(ratIdx).ID);
        
%         blocks = Brain_FetchBlocksToProcess(inDirT, ratsToProcess(ratIdx).ID);
        try
            blocks = Brain_FetchBlocksToProcess(inDirT, ratsToProcess(ratIdx).ID);
        catch 
            
            cprintf('*err', '\n\nERROR:');
            cprintf('*err', ['\nUnable to run function "Brain_FetchBlocksToProcess" for rat: ', num2str(ratsToProcess(ratIdx).ID),... 
                '\nContinuing to next rat.']);
            errRats = [errRats [string(ratsToProcess(ratIdx).ID), "all blocks"]];
            ratsToProcess(ratIdx) = [];
            ratBlocks(ratIdx) = [];
            ratIdx = ratIdx - 1;
            pause(3);
            continue;
        end
        
%         Brain_FetchInfoToProcess(inDirT, inDirS, outDir, ratInfo, blocks);
        while blockIdx < size(blocks, 2)
            blockIdx = blockIdx + 1;
            try
                Brain_FetchInfoToProcess(inDirT, inDirS, outDir, ratInfo, blocks(blockIdx));
            catch
                cprintf('*err', '\n\nERROR:');
                cprintf('*err', ['\nUnable to run function "Brain_FetchInfoToProcess" for block ' num2str(blocks(blockIdx)), ...
                    ' of rat: ', num2str(ratsToProcess(ratIdx).ID),... 
                    '\nContinuing to next block.\n']);
                errRats = [errRats; [string(ratsToProcess(ratIdx).ID), string(blocks(blockIdx))]];
                blocks(blockIdx) = [];
                blockIdx = blockIdx - 1;
                pause(3);
                continue;
            end
        end
    elseif analysis > 1
        blocks = Brain_FetchBlocksToAnalyze(outDir, ratNum, analysis);
    end
    ratBlocks{ratIdx} = blocks;
end

for ratIdx = 1:size(ratsToProcess, 2)
    if analysis == 1
        toDir = [outDir, ratsToProcess(ratIdx).ID, '\'];
        blocks = ratBlocks{ratIdx};
        
        %Iterate through rat's blocks
        for j = 1:size(blocks, 2)
            Brain_PreProcess(inDirTev, inDirSev, toDir, ratsToProcess(ratIdx).ID, blocks(j));
        end
    elseif analysis > 1
        for j = 1:size(blocks, 2)
            if analysis == 2
           %Run noise reduction
            elseif analysis == 3
           %Run module 3
            end
        end
    end
end
fprintf('\n');
