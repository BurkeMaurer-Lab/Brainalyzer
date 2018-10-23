%NMD 10/12/18 Future Development: We need to figure out how to specify
%shanks we want to run, or else shanks we don't want to run, so that we
%don't have to run spike sorting on shanks that are a waste of time.

%Brain_PostProcess
%This function takes the data previously collected in the pre-process step
%and performs operations on them. Currently, the biggest functionality is
%to implement spike sorting. 

function Brain_PostProcess(dataDir, blockID)

    %Open file where notes and data are stored
    delim_dash = strsplit(blockID, '-');
    blockDir = [dataDir, delim_dash{2}, '-', delim_dash{3}, '\'];
    
    %Get wave information
    notesDir = [blockDir, 'Notes.txt'];
    if ~exist(notesDir, 'file')
        cprintf('*err', 'ERROR:\n');
        cprintf('err', 'No text file found in block directory\n');
        return;
    else
        try
            wavesBlock = Brain_parseText(notesDir, 'ver', 'Brain', 'voi', 'waveInfo');
%             timeVector = Brain_parseText(notesDir, 'ver', 'Brain', 'voi', 'epochTimes');
        catch
            cprintf('*err', '\n\nERROR READING NOTES FILE. NOT ANALYZING BLOCK\n');
            pause(3);
            return;
        end
    end
    numWaves = size(wavesBlock.wave, 2);
    
    %Iterate through waves
    for waveIdx = 1:numWaves
        curWave = wavesBlock.wave(waveIdx);
        %%%%%%%%%%
        if waveIdx == 1; continue; end
        %%%%%%%%%%%%%%%%%%%%%
        if strcmp(curWave.Sort, 'Yes')
            Brain_SpikeSorter(blockDir, curWave);
        end
    end
    fprintf('\n')
end


function Brain_SpikeSorter(dataDir, wave)

    low_bandpass = 600;     %hard coded for beta version
    high_bandpass = 0.25;   %hard coded for beta version
    low_threshold = 20;      %hard coded for beta version
    high_threshold = 50;   %hard coded for beta version 
    spike_direction = 'negative'; %hard coded for beta version
    absThresh = 1; %hard coded for beta version. Change to 0 for relative thresholding.
    
    spikeDir = [dataDir, '02 - Spike Sorting\', char({wave.waveID}), '\'];
    if ~exist(spikeDir, 'dir')
        cprintf('*err', '\n\nERROR!! NO SPIKE DATA AVAILABLE.\nNOT SPIKE SORTING BLOCK\n');
        pause(3);
        return;
    end
    
    homeSplit = strsplit(which('Brainalyzer_Start'), 'Brainalyzer_Start');
    homeDir = [homeSplit{1}, '\00 - Interface\Constants\'];
    temp = load([homeDir, wave.Probe, '.mat']);
    probe = temp.(wave.Map);
    clear temp;
    
    fs = wave.RecoFreq;
    
    for shankIdx = 1:probe.ShankCount      
        %%%%%%%%%%%%%%%%%%%%%
        if shankIdx == 1; continue; end
        %%%%%%%%%%%%%%%%%%%%%%%
        
        clc;
        startChan = probe.Shank(shankIdx).Site(1).Number;
        endChan = probe.Shank(shankIdx).Site(end).Number;
        rawFileName = strcat("Chan_", num2str(startChan), "-", num2str(endChan));
        
        numSites = length(probe.Shank(shankIdx).Site);
        %%%Step 1: Create our geometry file for klusta. The file format
        %is .prb and we do it by calling the function
        %Brain_CreateGeomFile which conveniently also returns the
        %number of channels in the probe for future steps
        number_of_live_channels = Brain_CreateGeomFile([char(spikeDir) '\' char(rawFileName)], wave.BadChs, wave.Probe, wave.Map, shankIdx);

        %%%Step 2: Create our parameter file for klusta. The file
        %%%format is .prm and we do it by calling the function
        %%%prmGenerator 
        
        prmGenerator([char(spikeDir) '\' char(rawFileName)], rawFileName, numSites, fs, low_bandpass, high_bandpass, low_threshold, high_threshold, spike_direction);

        %%%Step 3: Run automatic klustering with klusta. We already
        %have the .prm, the .prb and the .dat files so we are ready
        %to run klusta.
        dos(['activate klusta && ' spikeDir(1) ': && cd / && cd ' char(spikeDir) '\' char(rawFileName) '&& klusta param.prm --overwrite'], '-echo');

        %%%Step 4: Create the XML file necessary for manual clustering.
        xmlGenerator([char(spikeDir) '\' char(rawFileName)], rawFileName, number_of_live_channels, fs)

        %%%Step 5: Convert Klusta output to kluster input for manual
        %%%clustering with kluster. This is done with the function
        %%%ClusteringKlusta2Neurosuite
        ConvertKlusta2Neurosuite([char(spikeDir) char(rawFileName)], rawFileName);

        % Step 6: Delete unnecessary files such as the .prm file, the
        % .prb file, the .klustakwik2 firectory, the .spikedetekt
        % directory, the kwik file and the kwx file.
        %The following code has been commented out for testing
        %purposes:
    %             fclose('all');
    %             %Delete .klustakwik2
    %             if exist([char(outDir) '\' char(rawFileName) '\.klustakwik2'],'file') ~= 0
    %                 rmdir([char(outDir) '\' char(rawFileName) '\.klustakwik2'], 's');
    %             end
    %             %Delete .spikedetekt
    %             if exist([char(outDir) '\' char(rawFileName) '\.spikedetekt'],'file') ~= 0
    %                 rmdir([char(outDir) '\' char(rawFileName) '\.spikedetekt'], 's');
    %             end
    %             %Delete param.prm
    %             if exist([char(outDir) '\' char(rawFileName) '\param.prm'],'file') ~= 0
    %                 delete([char(outDir) '\' char(rawFileName) '\param.prm']);
    %             end
    %             %Delete geom.prb 
    %             if exist([char(outDir) '\' char(rawFileName) '\geom.prb'],'file') ~= 0
    %                 delete([char(outDir) '\' char(rawFileName) '\geom.prb']);
    %             end
    %             %Delete kwik file
    %             if exist([char(outDir) '\' char(rawFileName) '\' char(rawFileName)  '.kwik'],'file') ~= 0
    %                 delete([char(outDir) '\' char(rawFileName) '\' char(rawFileName) '.kwik']);
    %             end
    %             %Delete kwx file 
    %             if exist([char(outDir) '\' char(rawFileName) '\' char(rawFileName)  '.kwx'],'file') ~= 0
    %                 delete([char(outDir) '\' char(rawFileName) '\' char(rawFileName)  '.kwx']);
    %             end

        %%% IAGO FINISHES WRITING HIS SPIKE SORTING STUFF IN HERE       
    end

    fprintf('\n')
end
