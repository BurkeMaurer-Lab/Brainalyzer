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
inDir = 'F:\Data\Doxy\648\';
outDir = 'D:\Brainalyzer\Results\';
ratNum = 648;

analysis = 1;
%Choose analysis value from list below
% 1 = Pre-Process
%    -This step loads in data from raw files
%    -This includes position, eeg by shank, and timestamps
%
% 2 = Noise Reduction
%    -Noise reduction has not yet been implemented
% 3 = Spike Sorting
%    -Spike sorting has not yet been implemented
%----------------------------------------------------------%


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

if analysis == 1
    blocks = Brain_FetchBlocksToProcess(inDir, ratNum);
elseif analysis > 1
   blocks = Brain_FetchBlocksToAnalyze(outDir, ratNum, analysis);
   for i = 1:size(blocks, 2)
       if analysis == 2
           %Run noise reduction
       elseif analysis == 3
           %Run module 3
       end
   end
end
