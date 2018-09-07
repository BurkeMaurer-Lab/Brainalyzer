clc;
clear variables;
close all;


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
inDirTev = 'E:\Raw Data\';
inDirSev = 'F:\Data\Doxy\648\';
outDir = 'D:\Brainalyzer\Results\';

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
for i = 1:size(ratsToProcess, 2)
    if analysis == 1
        toDir = [outDir, ratsToProcess(i).ID, '\'];
        
        inDirT = [inDirTev, ratsToProcess(i).ID, '\'];
        inDirS = [inDirSev, ratsToProcess(i).ID, '\'];
        
        ratInfo = Brain_FetchRatInfo(toDir, ratsToProcess(i).ID);
        blocks = Brain_FetchBlocksToProcess(inDirT, ratsToProcess(i).ID);
        
        Brain_FetchInfoToProcess(inDirT, inDirS, outDir, ratInfo, blocks);
        
        for j = 1:size(blocks, 2)
            Brain_PreProcess(inDirTev, inDirSev, toDir, ratsToProcess(i).ID, blocks(j));
        end
    
        elseif analysis > 1
        blocks = Brain_FetchBlocksToAnalyze(outDir, ratNum, analysis);
   
        for j = 1:size(blocks, 2)
            if analysis == 2
           %Run noise reduction
            elseif analysis == 3
           %Run module 3
            end
        end
    end
end
