%NMD 10/12/18 Future Development: We need to figure out how to specify
%shanks we want to run, or else shanks we don't want to run, so that we
%don't have to run spike sorting on shanks that are a waste of time.

%Brain_PostProcess
%This function takes the data previously collected in the pre-process step
%and performs operations on them. Currently, the biggest functionality is
%to implement spike sorting. 

function Brain_PostProcess(blockDir)

    %Open file where notes and data are stored
%     delim_dash = strsplit(blockID, '-');
%     blockDir = [dataDir, delim_dash{2}, '-', delim_dash{3}, '\'];
    
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
        if strcmp(curWave.SaveDat, 'Yes')
            Brain_SpikeSorter(blockDir, curWave);
        end   
    end
    fprintf('\n')
end


function Brain_SpikeSorter(dataDir, wave)

    low_bandpass = 600;     %hard coded for beta version
    high_bandpass = 0.25;   %hard coded for beta version
    low_threshold = 20;      %microVolts. hard coded for beta version
    high_threshold = 50;   %microVolts. hard coded for beta version 
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
    lfpFS = wave.SaveFreq;
    
    for shankIdx = 1:probe.ShankCount              
        clc;
        startChan = probe.Shank(shankIdx).Site(1).Number;
        endChan = probe.Shank(shankIdx).Site(end).Number;
        rawFileName = strcat("Chan_", num2str(startChan), "-", num2str(endChan));
        
        %Check if spike sorting has already occured. If so, prompt user to
        %double check if they really want to run it again.
        if isfile([char(spikeDir), '\', rawFileName, '\', rawFileName, '.fet.1'])
            cprintf('\n\nWARNING!!!! Shank has already been sorted.\nContinuing will delete all previous work.');
            userPrompt = '\nWould you like to continue anyway?:';
            validatedAnsr = Brain_validateString(userPrompt, {'yes', 'no'});
            if string(validatedAnsr) == "no"
                continue;
            end
        end            
        
        numSites = length(probe.Shank(shankIdx).Site);
        %%%Step 1: Create our geometry file for klusta. The file format
        %is .prb and we do it by calling the function
        %Brain_CreateGeomFile which conveniently also returns the
        %number of channels in the probe for future steps
        number_of_live_channels = Brain_CreateGeomFile([char(spikeDir) '\' char(rawFileName)], wave.BadChs, wave.Probe, wave.Map, shankIdx);

        %%%Step 2: Create our parameter file for klusta. The file
        %%%format is .prm and we do it by calling the function
        %%%prmGenerator 
        
        Brain_prmGenerator([char(spikeDir) '\' char(rawFileName)], rawFileName, numSites, fs, low_bandpass, high_bandpass, low_threshold, high_threshold, spike_direction);

        %%%Step 3: Run automatic klustering with klusta. We already
        %have the .prm, the .prb and the .dat files so we are ready
        %to run klusta.
        if strcmp(wave.Sort, 'Yes')
            dos(['activate klusta && ' spikeDir(1) ': && cd / && cd ' char(spikeDir) '\' char(rawFileName) '&& klusta param.prm --overwrite'], '-echo');
        end

        %%%Step 4: Create the XML file necessary for manual clustering.
%         xmlGenerator([char(spikeDir) '\' char(rawFileName)], rawFileName, number_of_live_channels, fs)
        Brain_xmlGenerator([char(spikeDir) '\' char(rawFileName)], rawFileName, startChan, endChan, wave.BadChs, fs, lfpFS)

        %%%Step 5: Convert Klusta output to kluster input for manual
        %%%clustering with kluster. This is done with the function
        %%%ClusteringKlusta2Neurosuite
        if strcmp(wave.Sort, 'Yes')
            Brain_ConvertKlusta2Neurosuite([char(spikeDir) char(rawFileName)], rawFileName);
        end

        % Step 6: Delete unnecessary files such as the .prm file, the
        % .prb file, the .klustakwik2 firectory, the .spikedetekt
        % directory, the kwik file, the kwx file.
        
        %Delete .klustakwik2 and all files and subfolders it contains
        fclose('all');
        
        if strcmp(wave.Sort, 'Yes')
            try rmdir(strcat(string(spikeDir), "\", string(rawFileName), "\", ".klustakwik2"), 's')
            catch
                cprintf('*err', '\n\nCould not delete ".klustakwik2" file.');
                pause(5);
            end
            %Delete .spikedetekt and all files and subfolders it contains
            try rmdir(strcat(string(spikeDir), "\", char(rawFileName), "\", ".spikedetekt"), 's')
            catch
                cprintf('*err', '\n\nCould not delete ".spikedetekt" file.');
                pause(5);
            end
%             %Delete kwik file
%             try delete(strcat(string(spikeDir), "\", string(rawFileName), "\", string(rawFileName), ".kwik"))
%             catch
%                 cprintf('*err', '\n\ncould not delete ".kwik" file.');
%                 pause(5); 
%             end
%             %Delete kwx file
%             try delete(strcat(string(spikeDir), "\", string(rawFileName), "\", string(rawFileName), ".kwx"))
%             catch
%                 cprintf('*err', '\n\nCould not delete ".kwx" file.');
%                 pause(5); 
%             end    
        end
    end

    fprintf('\n')
end
