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
inDirMetaNPos = 'F:\CA1-CA3_Age\Raw_Tracking_Data\'; %The location of the position tracking and meta data. Typically, where the TDT files are stored. 
inDirEEG = 'F:\CA1-CA3_Age\Raw_EEG_Data\'; %Where the EEG data is stored. If the data isn't stored as SEV files it will be the same as posNmetaDataDir.
outDir = 'F:\CA1-CA3_Age\Converted_Data\'; %Where the data will be stored.

if inDirMetaNPos(end) ~= '\'; inDirMetaNPos = [inDirMetaNPos, '\']; end
if inDirEEG(end) ~= '\'; inDirEEG = [inDirEEG, '\']; end
if outDir(end) ~= '\'; outDir = [outDir, '\']; end

analysis = 1;
%Choose analysis value from list below
% 1 = Pre-Process
%    -This step loads in data from raw files
%    -This includes position, eeg by shank, and timestamps
%
% 2 = Noise Reduction
%    -Noise reduction has not yet been implemented
% 3 = Position Heat Map
%
%----------------------------------------------------------%

if analysis == 1
    ratsToProcess = Interface_ReturnRatsToProcess(inDirMetaNPos);
    %ratPoss = dir(inDirTev);
else
    ratsToProcess = Interface_ReturnRatsToProcess(outDir);
end
ratBlocks = cell(size(ratsToProcess, 2), 1);
%Collect the numbers of the rats that get an error during processing. This
%will eventually be converted to an error message in future iterations of
%the code. Dylan is a butt
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
        %Make sure output directory exists.
        %If it doesn't exist throw an error
        toDir = [outDir, ratsToProcess(ratIdx).ID, '\'];
        if ~mkdir(toDir)
            cprintf('*err', ['\nERROR:\nUnable to create output directory:\n\t', ...
                toDir, '\nContinuing to next rat.']);
            errRats = [errRats [string(ratsToProcess(ratIdx).ID), "all blocks"]];
            ratsToProcess(ratIdx) = [];
            ratBlocks(ratIdx) = [];
            ratIdx = ratIdx - 1;
            pause(5);
            continue;
        end
        %Make sure template file exists. If not, create one.
        if ~exist([toDir, 'Template.txt'], 'file')
            mkTemplate(toDir, inDirMetaNPos);
        end
        ratInfo = Brain_FetchRatInfo(toDir, ratsToProcess(ratIdx).ID);
        
        curRatInDirMeta = [inDirMetaNPos, ratsToProcess(ratIdx).ID, '\'];
        curRatInDirEEG = [inDirEEG, ratsToProcess(ratIdx).ID, '\'];
                
%       blocks = Brain_FetchBlocksToProcess(inDirT, ratsToProcess(ratIdx).ID);
%         try
            blocks = Brain_FetchBlocksToProcess(curRatInDirMeta, ratsToProcess(ratIdx).ID);
%         catch 
%             cprintf('*err', '\n\nERROR:');
%             cprintf('*err', ['\nUnable to run function "Brain_FetchBlocksToProcess" for rat: ', num2str(ratsToProcess(ratIdx).ID),... 
%                 '\nContinuing to next rat.']);
%             errRats = [errRats [string(ratsToProcess(ratIdx).ID), "all blocks"]];
%             ratsToProcess(ratIdx) = [];
%             ratBlocks(ratIdx) = [];
%             ratIdx = ratIdx - 1;
%             pause(5);
%             continue;
%         end
        
%         Brain_FetchInfoToProcess(inDirT, inDirS, outDir, ratInfo, blocks);
        while blockIdx < size(blocks, 2)
            blockIdx = blockIdx + 1;

            %These try-catch statements needs to be more specific about the
            %errors. If it's a matlab error we should display that error,
            %but if it's one of our error statements we should return that.
            curBlockInDirMeta = [curRatInDirMeta, char(blocks(blockIdx)), '\'];
            curBlockInDirEEG = [curRatInDirEEG, char(blocks(blockIdx)), '\'];
            Brain_FetchInfoToProcess(curBlockInDirMeta, curBlockInDirEEG, outDir, ratInfo, blocks(blockIdx));
%             try
%                 %NMD 10/11/18 I need to figure out to modify info
%                 %collection for both SEV and TDT files. This will be
%                 %temporary.
%                 Brain_FetchInfoToProcess(curInDirMeta, curInDirEEG, outDir, ratInfo, blocks(blockIdx));
% %                 Brain_FetchInfoToProcess(curInDirMeta, outDir, ratInfo, blocks(blockIdx));
%             catch
%                 cprintf('*err', '\n\nERROR:');
%                 cprintf('*err', ['\nUnable to run function "Brain_FetchInfoToProcess" for block ' num2str(blocks(blockIdx)), ...
%                     ' of rat: ', num2str(ratsToProcess(ratIdx).ID),... 
%                     '\nContinuing to next block.\n']);
%                 errRats = [errRats; [string(ratsToProcess(ratIdx).ID), string(blocks(blockIdx))]];
%                 blocks(blockIdx) = [];
%                 blockIdx = blockIdx - 1;
%                 pause(3);
%                 continue;
%             end
        end
    elseif analysis > 1
        blocks = Brain_FetchBlocksToAnalyze(outDir, ratsToProcess(ratIdx).ID, analysis);
    end
    ratBlocks{ratIdx} = blocks;
end

%----------------------------------------------------------%
%----------------------------------------------------------%
%                          STEP 2                          %
%                                                          %
%  Second, we read in the information using the parameters %
%  the user specified and run preprocessing to extract and %
%  roughly clean the data.                                 %
%--------------------Editable Constants--------------------%
%----------------------------------------------------------%

for ratIdx = 1:size(ratsToProcess, 2)
    
    
    toDir = [outDir, ratsToProcess(ratIdx).ID, '\'];
    blocks = ratBlocks{ratIdx};
    
    %Iterate through rat's blocks   
    blockIdx = 0;
    while blockIdx < size(blocks, 2)
        blockIdx = blockIdx + 1;
        curBlock = char(ratBlocks{ratIdx}(blockIdx));
        
        % -inputDir4TDT'
        %    *Directory where raw TDT files are stored (.tev)
        curRatBlockMetaNPos = [inDirMetaNPos, ratsToProcess(ratIdx).ID, '\', char(curBlock), '\'];
        
        % -inputDir4RSV
        %    *Directory where raw RS4 files are stored (.sev)
        curRatBlockEEG = [inDirEEG, ratsToProcess(ratIdx).ID, '\', char(curBlock), '\'];
        
        % -blockDir
        %    *Output directory for all files associated with this block
        delim_dash = strsplit(char(curBlock), '-');
        curRatBlockOutDir = [toDir, delim_dash{2}, '-', delim_dash{3}, '\'];
        if analysis == 1
%             try
                Brain_PreProcess(curRatBlockMetaNPos, curRatBlockEEG, curRatBlockOutDir, curBlock);
%             catch
%                 cprintf('*err', '\n\nERROR:');
%                 cprintf('*err', ['\nUnable to run function "Brain_PreProcess" for block ' num2str(blocks(blockIdx)), ...
%                     ' of rat: ', num2str(ratsToProcess(ratIdx).ID),... 
%                     '\nContinuing to next block.\n']);
%                 errRats = [errRats; [string(ratsToProcess(ratIdx).ID), string(blocks(blockIdx))]];
%                 blocks(blockIdx) = [];
%                 blockIdx = blockIdx - 1;
%                 pause(5);
%                 continue;
%             end
        end

    end
end


%----------------------------------------------------------%
%----------------------------------------------------------%
%                           STEP 3                         %
%                                                          %
%  Process the data saved in the previous step. This can   % 
%  be used to re-run data that had been previously been    %
%  preprocessed but the processing step changed.           %
%  Spike sorting goes here.                                %
%------------------Editable Constants----------------------%
%----------------------------------------------------------%

for ratIdx = 1:size(ratsToProcess, 2)
    dataDir = [outDir, ratsToProcess(ratIdx).ID, '\'];
    ratInfo = Brain_FetchRatInfo(dataDir, ratsToProcess(ratIdx).ID);
    blocks = ratBlocks{ratIdx};
    
    %Iterate through rat blocks
    blockIdx = 0;
    while blockIdx < size(blocks, 2)
        blockIdx = blockIdx + 1;
        curBlock = char(ratBlocks{ratIdx}(blockIdx));
        delim_dash = strsplit(curBlock, '-');
        ratBlockDataDir = [dataDir, delim_dash{2}, '-', delim_dash{3}, '\'];
        try
            Brain_PostProcess(ratBlockDataDir);
        catch
            cprintf('*err', '\n\nERROR:');
            cprintf('*err', ['\nUnable to run function "Brain_PreProcess" for block ' num2str(blocks(blockIdx)), ...
                ' of rat: ', num2str(ratsToProcess(ratIdx).ID),... 
                '\nContinuing to next block.\n']);
            errRats = [errRats; [string(ratsToProcess(ratIdx).ID), string(blocks(blockIdx))]];
            blocks(blockIdx) = [];
            blockIdx = blockIdx - 1;
            pause(5);
            continue;
        end
        
        if analysis > 1
            [wave, epochs] = Brain_PickWaveAndEpoch([toDir, curBlock, '\'], ratInfo);
            if analysis == 2
                %Run noise reduction
            elseif analysis == 3
                Brain_NoiseFiltering
            elseif analysis == 5
                Brain_PowerSpectralDensity([toDir, curBlock, '\'], wave, epochs, [0, 3, 5, 15, 35, 100], 'MODE', 'clean');
            elseif analysis == 6
                Brain_CurrentSourceDensity([toDir, curBlock, '\'], wave, epochs, [-1000 1000]);
            end
        end
    end
end
    
fprintf('\n');
