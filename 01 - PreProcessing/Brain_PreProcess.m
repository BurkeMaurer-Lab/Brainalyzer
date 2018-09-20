function Brain_PreProcess(inDirTev, inDirSev, outDir, ratNum, blockID)
    % Testing testing: 1, 2, and even 3
    clc; 

    blockID = char(blockID);
    %Necessary Constants
    % -cmPERpix
    %    *Centimeter's per pixel count. Necessary for velocity and
    %    acceleration data
    
    % -inputDir4TDT
    %    *Directory where raw TDT files are stored (.tev)
    inputDirT = [inDirTev, ratNum, '\', blockID, '\'];
    
    % -inputDir4RSV
    %    *Directory where raw RS4 files are stored (.sev)
    inputDirS = [inDirSev, blockID, '\'];
    
    % -blockDir
    %    *Output directory for all files associated with this block
    delim_dash = strsplit(blockID, '-');
    blockDir = [outDir, delim_dash{2}, '-', delim_dash{3}, '\'];
    
    % -outputDir
    %    *Output directory where all files associated with this function
    %    will be saved
    outputDir = [blockDir, '\01 - PreProcessed\'];
    
    
    %  First, verify that notes.txt exists in the block directory. If yes, open it
    % and the template.txt file for the rat, getting the time vectors and
    % waveform information necessary for this rat and block
    notesDir = [blockDir, 'Notes.txt'];
    
    if ~exist(notesDir, 'file')
        cprintf('*err', 'ERROR:\n');
        cprintf('err', 'No text file found in block directory\n');
        return;
    else
        try
            wavesBlock = Brain_parseText(notesDir, 'ver', 'Brain', 'voi', 'waveInfo');
            timeVector = Brain_parseText(notesDir, 'ver', 'Brain', 'voi', 'epochTimes');
        catch
            cprintf('*err', '\n\nERROR READING NOTES FILE. NOT ANALYZING BLOCK\n');
            pause(3);
            return;
        end
    end
    dataInfo = TDT2mat_NMD(inputDirT, 'T1', 1, 'T2', 1.05, 'STORE', {wavesBlock.wave(1).waveID}, 'VERBOSE', 0);
    
    totalTime = str2double(dataInfo.info.duration(4:5))*60 ...
        + str2double(dataInfo.info.duration(1:2))*60*60 ...
        + str2double(dataInfo.info.duration(7:8));
    
    %NMD 9/15/18 Possible conflict in following line. This assumes the two
    %waves have equal sampling frequency when it's possible they don't.
    %NMD 9/16/18 Possible problem with flooring the sampling frequency. 
%     eeg.fs = floor(dataInfo.streams.(wavesBlock.wave(1).waveID).fs);

    %Iterate through waves
    for i = 1:size(wavesBlock.wave, 2)
        if strcmp(wavesBlock.wave(i).Process, 'Yes')
            %Clear eeg for each new block
            eeg = [];
            if strcmp(wavesBlock.wave(i).Type, 'tev')
                inDir = inputDirT;
            elseif strcmp(wavesBlock.wave(i).Type, 'sev')
                inDir = inputDirS;
            end
            
            %Extract the eeg data for both spikesorting and epochs
%             eeg.(wavesBlock.wave(i).Name) = Brain_LoadWaveform(inDir, blockDir, blockID, wavesBlock.wave(i), timeVector, totalTime);
            try eeg.(wavesBlock.wave(i).Name) = Brain_LoadWaveform(inDir, blockDir, blockID, wavesBlock.wave(i), timeVector, totalTime);
            catch
                cprintf('err', '\n\nSkipping block because of error in loading the eeg data.');
                continue;
            end
            
            %Perform noise reduction on EEG data
%             eeg.(wavesBlock.wave(i).Name) = Brain_NoiseReduction(eeg.(wavesBlock.wave(i).Name), wavesBlock.wave(i), timeVector);
            
            %Load the position data (commented for now until next push)
            eeg.(wavesBlock.wave(i).Name) = Brain_LoadPosition(inputDirT, eeg.(wavesBlock.wave(i).Name), timeVector);
%             try eeg.(wavesBlock.wave(i).Name) = Brain_LoadPosition(inputDirT, eeg.(wavesBlock.wave(i).Name), wavesBlock.wave(i), timeVector);
%             catch
%                 cprintf('err', '\n\nSkipping position extraction because of error in function');
%             end
            %Save block
            fprintf('\n\nSaving data from block')
            saveName = [blockDir, wavesBlock.wave(i).Name, '_data.mat'];
            save(saveName, '-struct', 'eeg', '-v7.3');
            fprintf('\nData saved.\n')
            pause(3);
        end
    end       
end

function eeg = Brain_LoadWaveform(inDir, outDir, blockID, wave, timeVector, totalTime)

    waveInfo = TDT2mat_NMD(inDir, 'T1', 1, 'T2', 1.05, 'STORE', {wave.waveID}, 'VERBOSE', 0);
    fs = waveInfo.streams.(wave.waveID).fs;
    eeg.data = [];
    msg = [];
    eeg.fs = wave.SaveFreq;
    
    gap = round(wave.RecoFreq / wave.SaveFreq);
    bigChanIdx = 0;
    numEpochs = size(timeVector, 1);
    epochNames = strcat(repmat("epoch", numEpochs, 1), num2str((1:numEpochs).'));    
    eeg.epochNames = epochNames;
    for epochIdx = 1:numEpochs
        eeg.data.(char(epochNames(epochIdx))).volts = [];
        eeg.data.(char(epochNames(epochIdx))).ts = [];
    end
    fullTS = [];
    epochTS = [];
    
%     chunkSize = 25;
    
    %wave = waveInfo.wave;
    %clear waveInfo;
    
    %Sort by shank, then throw at spike sorter, then down sample
    homeSplit = strsplit(which('Brainalyzer_Start'), 'Brainalyzer_Start');
    homeDir = [homeSplit{1}, '\00 - Interface\Constants\'];
    temp = load([homeDir, wave.Probe, '.mat']);
    probe = temp.(wave.Map);
    nChan = probe.NChan;
    clear temp;
    
    for shankIdx = 1:probe.ShankCount
        clc;
        cprintf('-blue', ['Block: ', blockID, '\nWave: ', char(wave.Name), '\nShank: ', char(num2str(shankIdx)), '\nPre-Processing\n\n']);

        numSites = length(probe.Shank(shankIdx).Site);
        %NMD 9/16/18 I think this was the reason for the trailing
        %zeros. You're using the floored sampling frequency. For
        %example, if you assume a two hour recording, the
        %difference between a sampling frequency of 24414 and
        %24414.0625 (the actual sampling frequency) is about 450
        %points. I'm pretty sure that's the same order of magnitude
        %of the zeros you were finding.
        shankData = [];

        %%Load all channels from shank at recoding frequency
        for siteIdx = 1:numSites
            %check memory usage and ask the user to close programs that are
            %using unnecessary memory if you're below 1 Gbytes of usable
            %RAM
            while 1
                [~, sysMem] = memory;
                availMem = sysMem.PhysicalMemory.Available; %Bytes
                availMem = availMem / (1000 ^ 3); %GigaBytes
                if availMem > 1
                    break;
                else
                    fprintf(repmat('\b', 1, length(msg)))
                    msg = sprintf('\n\nYou are about to run out of RAM.\nPlease close unnecessary programs\n(DO NOT CLOSE MATLAB!!!)');
                    fprintf(msg);
                end
            end
            bigChanIdx = bigChanIdx + 1;
            ch = probe.Shank(shankIdx).Site(siteIdx).Number;
            cprintf('text', ['\nLoading channel ', sprintf('%02d', ch), ':    0.0%% Complete']);  
            %tStart = tic;

            %To not time chunk data
            if strcmp(wave.Type, 'tev')
                tempData = TDT2mat_NMD(inDir, 'TYPE', {'streams'}, ...
                        'STORE', {wave.waveID}, ...
                        'CHANNEL', ch, ...
                        'T1', 0, 'T2', 0, 'VERBOSE', 0);
                tempData = tempData.streams.(wave.waveID).data;
            elseif strcmp(wave.Type, 'sev')
                tempData = SEV2mat(inDir, 'verbose', 0, 'CHANNEL', chan);
                tempData = tempData.(wave.waveID).data;
            else
                errorMsg = ['\nNo data extraction library is available for wave type: ', wave.Type];
                error(errorMsg);
            end
            
            if isempty(fullTS); fullTS = (0:1/fs:((1/fs)*(size(tempData, 2)-1))); end
            
            %Store spike data
            if strcmp(wave.Sort, 'Yes')
                if isempty(shankData)
                    shankData = NaN(nChan, length(tempData));
                end
                shankData(siteIdx, :) = tempData;                
            end
            
            %Store epoch data
            tempData = tempData(1:gap:end);
            %Create downsampled time stamps if not created already
            if isempty(epochTS); epochTS = fullTS(1:gap:end); end
            for epochIdx = 1:numEpochs
                idx1 = find(epochTS >= timeVector(epochIdx, 1), 1, 'first');
                idx2 = find(epochTS <= timeVector(epochIdx, 2), 1, 'last');
                if isempty(eeg.data.(char(epochNames(epochIdx))).volts)
                    eeg.data.(char(epochNames(epochIdx))).volts = NaN(nChan, (idx2 - idx1 + 1));
                end
                eeg.data.(char(epochNames(epochIdx))).volts(bigChanIdx, :) = tempData(idx1:idx2);
                
                %Store epoch time stamp data if not done so already
                if isempty(eeg.data.(char(epochNames(epochIdx))).ts) 
                    eeg.data.(char(epochNames(epochIdx))).ts = epochTS(idx1:idx2); 
                end
            end
            
            
        end
        
        %Cut and save spike-sort data if required
        if strcmp(wave.Sort, 'Yes')            
            for epchs = 1:(numEpochs + 1)
                if epchs == 1
                    index1 = 1;
                    %index2 = fs * timeVector(epchs, 1);
                    index2 = find(fullTS <= timeVector(epchs, 1), 1, 'last') - 1;    %timeVector(epchs, 1) * eeg.fs;
                elseif epchs == size(timeVector, 1)+1
                    %index1 = fs * timeVector(epchs-1, 2);
                    %index2 = size(eegTemp, 2) * fs;
                    index1 = find(fullTS >= timeVector(epchs-1, 2), 1, 'first'); %timeVector(epchs-1, 2) * eeg.fs;
                    index2 = size(fullTS, 2);
                else
                    %index1 = fs * timeVector(epchs-1, 2);
                    %index2 = fs * timeVector(epchs, 1);
                    index1 = find(fullTS >= timeVector(epchs-1, 2), 1, 'first'); %timeVector(epchs-1, 2) * eeg.fs;
                    index2 = find(fullTS <= timeVector(epchs, 1), 1, 'last') - 1;    %timeVector(epchs, 1) * eeg.fs;     
                end

                shankData(:, index1:index2) = NaN;
                fullTS(:, index1:index2) = NaN;
            end
            shankData(:, isnan(shankData(1, :))) = [];
            startChan = probe.Shank(shankIdx).Site(1).Number;
            endChan = probe.Shank(shankIdx).Site(end).Number;
            outputName = strcat("rawData_Chan", num2str(startChan), "-", num2str(endChan), ".dat");
            writedat(shankData, strcat(outDir, '\', outputName))
            %If this is the last shank to look at save the time vector.
            if shankIdx == probe.ShankCount
                fullTS(:, isnan(fullTS(1, :))) = [];
                outputName = "rawTime.dat";
                writedat(fullTS, strcat(outDir, '\', outputName));
            end
        end
    end %shank indexing
end

function eeg = Brain_LoadPosition(inDir, eeg, timeVector)

    %Should be a user
    cmPERpix = 0.27125;
    %Fill should be a user input.
    fill = 1; %Constant for if you want to try to fill in missing data points
    %Extra padding in case the first couple of values are missing from the
    %epoch data. This is included so that "inpaintn" will have a reference.
    %Might become an advanced user input later.
    posPad = 60; %Samples. Currently this would be about two seconds.

    epochNames = eeg.epochNames;
    numEpochs = length(epochNames);
    
    tempData = TDT2mat_NMD(inDir, 'TYPE', {'scalars'}, 'T1', 0, 'T2', 0, 'VERBOSE', 0);
    %NMD 9/18/18 I'm pretty sure the wave type of the position tracking
    %doesn't ever change. Not 100% though.
    %Extract position and convert from pixels to cm
    posMat = tempData.scalars.RVn1.data .* cmPERpix;
    posTS = tempData.scalars.RVn1.ts;
    eegFS = eeg.fs;
    
    %Iterate through the epochs
    for epochIdx = 1:numEpochs
        
        %Collect the position data sampled at the framerate of the camera
        T1 = timeVector(epochIdx, 1);
        T2 = timeVector(epochIdx, 2);
        
        %Find the time indexes before and after the start of the
        %epoch. Pad them for interpolation. They'll be trimmed down later.
        index1 = find(posTS >= T1, 1, 'first') - posPad;
        if index1 < 0; index1 = 0; end
        index2 = find(posTS <= T2, 1, 'last') + posPad;
        if index2 > size(posMat, 2); index2 = size(posMat, 2); end
        
        epochPosTS = posTS(index1:index2);
       
        xposR = posMat(3, index1:index2);
        yposR = posMat(4, index1:index2);
        
        xposG = posMat(6, index1:index2);
        yposG = posMat(7, index1:index2);

        if fill
            lostlocR = find(xposR == -1);
            xposR(lostlocR) = NaN;
            xposR = inpaintn(xposR);
            yposR(lostlocR) = NaN;
            yposR = inpaintn(yposR);

            lostlocG = find(xposG == -1);
            xposG(lostlocG) = NaN;
            xposG = inpaintn(xposG);
            yposG(lostlocG) = NaN;
            yposG = inpaintn(yposG);
        end
        
        %If position tracking noise reduction is turned on, it should go
        %here.

        %Upsample position data to the downsampled recording frequency
        eegTS = eeg.data.(char(epochNames(epochIdx))).ts;
        
%         interpPosTS = interp1([eeg.ts(1) posTS eeg.ts(end)], [eeg.ts(1) posTS eeg.ts(end)], eeg.ts, 'spline');

        xposR = interp1(epochPosTS, xposR, eegTS, 'spline');
        yposR = interp1(epochPosTS, yposR, eegTS, 'spline');
        
        xposG = interp1(epochPosTS, xposG, eegTS, 'spline');
        yposG = interp1(epochPosTS, yposG, eegTS, 'spline');
        
        eeg.data.(char(epochNames(epochIdx))).redPos = [xposR; yposR];
        eeg.data.(char(epochNames(epochIdx))).greenPos = [xposG; yposG];
    end
end