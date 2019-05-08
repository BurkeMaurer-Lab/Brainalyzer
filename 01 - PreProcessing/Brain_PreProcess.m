function Brain_PreProcess(inputDirMeta, inputDirEEG, blockDir, blockID)
    % Testing testing: 1, 2, and even 3
    clc; 

    blockID = char(blockID);
%     %Necessary Constants
%     % -cmPERpix
%     %    *Centimeter's per pixel count. Necessary for velocity and
%     %    acceleration data
%     
%     % -inputDir4TDT'
%     %    *Directory where raw TDT files are stored (.tev)
%     inputDirMeta = [inDirMeta, ratNum, '\', blockID, '\'];
%     
%     % -inputDir4RSV
%     %    *Directory where raw RS4 files are stored (.sev)
%     inputDirEEG = [inDirEEG, ratNum, '\', blockID, '\'];
%     
%     % -blockDir
%     %    *Output directory for all files associated with this block
%     delim_dash = strsplit(blockID, '-');
%     blockDir = [outDir, delim_dash{2}, '-', delim_dash{3}, '\'];
    
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
            pause(5);
            return;
        end
    end
    numWaves = size(wavesBlock.wave, 2);
    dataInfo = TDT2mat_NMD(inputDirMeta, 'T1', 1, 'T2', 1.05, 'STORE', {wavesBlock.wave(1).waveID}, 'VERBOSE', 0);
    
    totalTime = str2double(dataInfo.info.duration(4:5))*60 ...
        + str2double(dataInfo.info.duration(1:2))*60*60 ...
        + str2double(dataInfo.info.duration(7:8));
    
    %  NMD 9/15/18 Possible conflict in following line. This assumes the two
    %waves have equal sampling frequency when it's possible they don't.
    %  NMD 9/16/18 Possible problem with flooring the sampling frequency. 
    %eeg.fs = floor(dataInfo.streams.(wavesBlock.wave(1).waveID).fs);

    %Iterate through waves
    for waveIdx = 1:numWaves
        if strcmp(wavesBlock.wave(waveIdx).Process, 'Yes')
            %Clear eeg for each new block
            eeg = [];
            
            %Extract the eeg data for both spikesorting and epochs
            %NMD 10/10/2018 This is super dirty but I don't have time to
            %control for SEV file formats so I'm just going to add 64 to
            %all of the channels for wave 2 for a data check in tomorrow.
            %Yell at me if this is still here at commit time.
%             eeg.(wavesBlock.wave(waveIdx).Name) = Brain_LoadWaveform(inputDirMeta, inputDirEEG, blockDir, blockID, wavesBlock.wave(waveIdx), timeVector, totalTime);
            eeg.(wavesBlock.wave(waveIdx).Name) = Brain_LoadWaveform(inputDirEEG, blockDir, blockID, wavesBlock.wave(waveIdx), waveIdx, timeVector);
            
%             try eeg.(wavesBlock.wave(waveIdx).Name) = Brain_LoadWaveform(inDir, blockDir, blockID, wavesBlock.wave(waveIdx), timeVector, totalTime);
%             catch
%                 cprintf('err', '\n\nSkipping block because of error in loading the eeg data.');
%                 continue;
%             end
            
            %Perform noise reduction on EEG data
%             eeg.(wavesBlock.wave(waveIdx).Name) = Brain_NoiseReduction(eeg.(wavesBlock.wave(waveIdx).Name), wavesBlock.wave(waveIdx), timeVector);
            
            %Load the position data (commented for now until next push)
            eeg = Brain_LoadPosition(inputDirMeta, eeg.(wavesBlock.wave(waveIdx).Name), totalTime, timeVector);
%             try eeg.(wavesBlock.wave(waveIdx).Name) = Brain_LoadPosition(inputDirT, eeg.(wavesBlock.wave(waveIdx).Name), wavesBlock.wave(waveIdx), timeVector);
%             catch
%                 cprintf('err', '\n\nSkipping position extraction because of error in function');
%             end
            %Save block
            fprintf('\n\nSaving data from block')
            
            if ~exist(outputDir, 'dir'), mkdir(outputDir), end
            
            saveName = [outputDir, wavesBlock.wave(waveIdx).Name, '_data.mat'];
            save(saveName, '-struct', 'eeg', '-v7.3');
            fprintf('\nData saved.\n')
            pause(3);
        end
    end       
    %NMD 2/23/19 This was moved from Brain_PostProcess. Right now the user
    %has to specify that they want to delete the raw data in the first
    %wave. This is obviously not ideal and is just a dirty workaround until
    %a better system is implimented. 
    %If user specified, delete raw data to save space on drive.
    curWave = wavesBlock.wave(1);
    if strcmp(curWave.DelRaw, 'Yes')
        clc;
        fprintf('\n\n!!!!!!!!!!!!!!!!!!!!!!!');
        fprintf('\nDELETING RAW META AND POSITION DATA IN 20 SECONDS!!!\n\n\n');
        pause(20);
        try rmdir(inputDirMeta); catch; end
        clc;
        fprintf('\n\n!!!!!!!!!!!!!!!!!!!!!!!');
        fprintf('\nDELETING RAW EEG DATA IN 20 SECONDS!!!\n\n\n');
        pause(20);
        try rmdir(inputDirEEG); catch; end
    end
end

function eeg = Brain_LoadWaveform(inDirEEG, outDir, blockID, wave, waveIdx, timeVector)

    fs = wave.RecoFreq;
    eeg = [];
    msg = [];
    eeg.fs = wave.SaveFreq;
    
    if strcmp(wave.SaveDat, 'Yes')  
        spikeDir = [outDir, '02 - Spike Sorting\', char({wave.waveID}), '\'];
        if ~exist(spikeDir, 'dir'), mkdir(spikeDir), end
    end
    
    gap = round(wave.RecoFreq / wave.SaveFreq);
    bigChanIdx = 0;
    numEpochs = size(timeVector, 1);
    epochNames = strcat(repmat("epoch", numEpochs, 1), num2str((1:numEpochs).'));    
    eeg.epochNames = epochNames;
    for epochIdx = 1:numEpochs
        eeg.(char(epochNames(epochIdx))).volts = [];
        eeg.(char(epochNames(epochIdx))).ts = [];
    end
    fullTS = [];
    epochTS = [];
    
%     chunkSize = 25;
    
    %wave = waveInfo.wave;
    %clear waveInfo;
    
    %Sort by shank, save spike sorter data if necessary, then down sample
    homeSplit = strsplit(which('Brainalyzer_Start'), 'Brainalyzer_Start');
    homeDir = [homeSplit{1}, '\00 - Interface\Constants\'];
    temp = load([homeDir, wave.Probe, '.mat']);
    probe = temp.(wave.Map);
    nChan = probe.NChan;
    clear temp;
    
    for shankIdx = 1:probe.ShankCount        
               
        clc;
        cprintf('-blue', ['Block: ', blockID, '\nWave: ', char(wave.Name), '\nShank: ', char(num2str(shankIdx)), '\nPre-Processing\n\n']);
        %cprintf('text', 'Loading waveform complete\nLoading position data\n');
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
            chan = probe.Shank(shankIdx).Site(siteIdx).Number;
            cprintf('text', ['\nLoading channel ', sprintf('%02d', chan), ':    0.0%% Complete']);  
            %tStart = tic;

            %To not time chunk data
            if strcmp(wave.Type, 'tev')
                tempData = TDT2mat_NMD(inDirEEG, 'TYPE', {'streams'}, ...
                        'STORE', {wave.waveID}, ...
                        'CHANNEL', chan, ...
                        'T1', 0, 'T2', 0, 'VERBOSE', 0);
                tempData = tempData.streams.(wave.waveID).data;
            elseif strcmp(wave.Type, 'sev')
                %This is temporary until I can get a cleaner way to use
                %both sev and tdt files.
                tempData = SEV2mat(inDirEEG, 'verbose', 0, 'CHANNEL', (chan + (waveIdx - 1) * 64));
%                 tempData = SEV2mat(inDirEEG, 'verbose', 0, 'CHANNEL', chan);
                %This step is temporary because the waveID's won't match
                %for TDT and SEV files.
%                 tempData = tempData.(wave.waveID).data;
                tempData = tempData.RSn1.data;
            else
                errorMsg = ['\nNo data extraction library is available for wave type: ', wave.Type];
                error(errorMsg);
            end
            
%             if isempty(fullTS); fullTS = (0:1/fs:((1/fs)*(size(tempData, 2)-1))); end
            if isempty(fullTS); fullTS = [0:(size(tempData, 2) - 1)] ./ fs; end
            

            
            %Store spike data
            if strcmp(wave.SaveDat, 'Yes')
                startIdx = find(fullTS >= timeVector(1, 1), 1, 'first');
                endIdx = find(fullTS <= timeVector(end, 2), 1, 'last');%             
%                             
                if isempty(shankData)
                    outIdxVecNumel = numSites * length(tempData(startIdx:endIdx));
                    shankData = NaN(outIdxVecNumel, 1);
                    outIdxVec = 1:numSites:(outIdxVecNumel - numSites + 1);
%                     shankData = NaN(numSites, length(tempData(startIdx:endIdx)));
                end
                shankData(outIdxVec + (siteIdx - 1)) = tempData(startIdx:endIdx).' .* 10^6;                
            end
            
            %Store epoch data
            tempData = tempData(1:gap:end);
            %Create downsampled time stamps if not created already
            if isempty(epochTS); epochTS = fullTS(1:gap:end); end
            for epochIdx = 1:numEpochs
                idx1 = find(epochTS >= timeVector(epochIdx, 1), 1, 'first');
                idx2 = find(epochTS <= timeVector(epochIdx, 2), 1, 'last');
                if isempty(eeg.(char(epochNames(epochIdx))).volts)
                    eeg.(char(epochNames(epochIdx))).volts = NaN(nChan, (idx2 - idx1 + 1));
                end
                eeg.(char(epochNames(epochIdx))).volts(bigChanIdx, :) = tempData(idx1:idx2);
                
                %Store epoch time stamp data if not done so already
                if isempty(eeg.(char(epochNames(epochIdx))).ts) 
                    eeg.(char(epochNames(epochIdx))).ts = epochTS(idx1:idx2); 
                end
            end
            
            tempData = [];
        end
        
        %Cut and save spike-sort data if required
        if strcmp(wave.SaveDat, 'Yes')            

            startChan = probe.Shank(shankIdx).Site(1).Number;
            endChan = probe.Shank(shankIdx).Site(end).Number;
            %If this changes make sure to change the file name in the spike
            %sorting code as well.
            outputName = strcat("Chan_", num2str(startChan), "-", num2str(endChan));
            
            %%%Step 1: Delete any existing spikesorting data and create a 
            %directory for our shank 
            if exist([char(spikeDir) '\' char(outputName)],'file') == 0 %If spike sorting data exists
                 mkdir(char(spikeDir), char(outputName)); %Make a directory for this shank's spike sorting data
            end
     
%             writedat(shankData(:, startIdx:endIdx), strcat(spikeDir, '\',outputName,'\', outputName, ".dat")) 
            outFileName = strcat(spikeDir, '\',outputName,'\', outputName, ".dat");
            fID = fopen(outFileName, 'w');
            fwrite(fID, shankData, 'int16');
            fclose(fID);
             
            if shankIdx == probe.ShankCount
                eeg.spikeFS = fs;
                fullTS = fullTS(startIdx:endIdx);
%                 fullTS(:, isnan(fullTS(1, :))) = [];
                outputName = "rawTime.mat";
                save(strcat(spikeDir, '\', outputName), 'fullTS', '-v7.3')
%                 writedat(fullTS, strcat(spikeDir, '\', outputName));
            end
        end
    end %shank indexing
end

function eeg = Brain_LoadPosition(inDir, eeg, totalTime, timeVector)
   
    %cprintf('-blue', ['Block: ', blockID, '\nWave: ', char(wave.Name), '\nPre-Processing\n\n']);
    cprintf('text', '\nLoading waveform complete\nLoading position data\n');
    %cprintf('text', 'All channels loaded\nLoading position data\n');
    %Should be a user
    strongThresh = 3;
    weakThresh = 1;
    coordSmoothWinSize = .5; %seconds
    cmPERpix = 0.27125;
    padTime = 5; %seconds
    maxVel = 150; %cm/sec
    chunkSize = 1200;
    %Fill should be a user input.
    fill = 1; %Constant for if you want to try to fill in missing data points
    %Extra padding in case the first couple of values are missing from the
    %epoch data. This is included so that "inpaintn" will have a reference.
    %Might become an advanced user input later.
    
    %spikeDir = [blockDir, '02 - Spike Sorting\'];
    %if ~exist(spikeDir, 'dir'), mkdir(spikeDir), end
    
    epochNames = eeg.epochNames;
    numEpochs = length(epochNames);
    posMat = [];
    posTS = [];

    for T1 = 0:chunkSize:(totalTime-chunkSize)
        T2 = T1 + chunkSize;
        
        tempData = TDT2mat_NMD(inDir, 'TYPE', {'scalars'}, 'T1', T1, 'T2', T2, 'VERBOSE', 0);
        %NMD 9/18/18 I'm pretty sure the wave type of the position tracking
        %doesn't ever change. Not 100% though.
        
        if isempty(tempData.scalars)
            return;
        end
        
        posMat = [posMat, tempData.scalars.RVn1.data];
        posTS = [posTS, tempData.scalars.RVn1.ts];
    end    
%     posData = TDT2mat_NMD(inDir, 'TYPE', {'scalars'}, 'T1', 0, 'T2', 0, 'VERBOSE', 0);
%     posMat = posData.scalars.RVn1.data;
%     posTS = posData.scalars.RVn1.ts;
    
%   NaN the missing data
    if fill
        lostlocR = find(posMat(3, :) == -1);
        posMat(3, lostlocR) = NaN;
%         posMat(3, :) = inpaintn(posMat(3, :));
        posMat(4, lostlocR) = NaN;
%         posMat(4, :) = inpaintn(posMat(4, :));

        lostlocG = find(posMat(6, :) == -1);
        posMat(6, lostlocG) = NaN;
%         posMat(6, :) = inpaintn(posMat(6, :));
        posMat(7, lostlocG) = NaN;
%         posMat(7, :) = inpaintn(posMat(7, :));
    end
    
    %Save the indices of the values that were saved by the camera to see
    %what values have been interpolated and what values are recorded.
    nonInterpRedIndices = ~isnan(posMat(3, :));
    nonInterpGreenIndices = ~isnan(posMat(6, :));
    
    %Get rid of periods of very high velocity that would be caused by the
    %incorrect LED identification. Another way to do this is to predict the
    %values using inpaintn and then measure the error between the actual
    %and predicted value. A very high error would be caused by a false
    %positive of LED selection.
    curXRed = posMat(3, :) .* cmPERpix;
    curYRed = posMat(4, :) .* cmPERpix;
    curXGreen = posMat(6, :) .* cmPERpix;
    curYGreen = posMat(7, :) .* cmPERpix;
    i = 1;
    while i < length(curXRed)
        if isnan(curXRed(i))
            i = i + 1;
            continue; 
        end
        j = i + 1;
        curVel = sqrt((curXRed(j) - curXRed(i))^2 + (curYRed(j) - curYRed(i))^2) ./ (posTS(j) - posTS(i));
        while isnan(curVel) || curVel > maxVel
            if ~isnan(curXRed(j))
                curXRed(j) = nan;
                curYRed(j) = nan;
                curXGreen(j) = nan;
                curYGreen(j) = nan;
            end
            j = j + 1;
            if j > length(curXRed)
                break;
            end
            curVel = sqrt((curXRed(j) - curXRed(i))^2 + (curYRed(j) - curYRed(i))^2) ./ (posTS(j) - posTS(i));
        end
        i = j;
    end

    %Fill in missing values. Hopefully the incorrectly selected values were
    %removed so that the interpolated values are not filling in the spaces
    %of bad data.
    curXRed = inpaintn(curXRed);
    curYRed = inpaintn(curYRed);
    curXGreen = inpaintn(curXGreen);
    curYGreen = inpaintn(curYGreen);
    
    %Smooth the coordinates to reduce spurious velocity reading from jitter
    %detection noise
    avgRF = 1 / mean(diff(posTS));
    coordSmoothWinSize = floor(coordSmoothWinSize * avgRF);
    if mod(coordSmoothWinSize, 2) == 0
        coordSmoothWinSize = coordSmoothWinSize + 1;
    end
    coordSmoothWin = gausswin(coordSmoothWinSize);
    coordSmoothWin = coordSmoothWin ./ sum(coordSmoothWin);
    %Pad the beginning and end of the vectors with the first and last
    %element of said vectors to reduce error from smoothing over the
    %automatic padding, which is a string of zeros. 
    %Smooth the coordinates with a Gaussian window. We're going to do one
    %dimensional smoothing, but I think two dimensional smoothing could be
    %implimented here for better accuracy. For the future, we could also
    %get a camera with a much higher frame rate and then calculate the
    %center of mass over a range of frames. We can't do that here because
    %the jitter induced by the LEDs and tracking program are within the
    %bounds of normal velocity. But very high velocities should give us a
    %better idea of center of mass.
    padRedXStart = repmat(curXRed(1), 1, (length(coordSmoothWin) - 1) / 2);
    padRedXEnd = repmat(curXRed(end), 1, (length(coordSmoothWin) - 1) / 2);
    curXRed = [padRedXStart curXRed padRedXEnd];
    curXRed = conv(curXRed, coordSmoothWin, 'same');
    curXRed = curXRed(((length(coordSmoothWin) - 1) / 2 + 1):(end - ((length(coordSmoothWin) - 1) / 2)));
    
    padRedYStart = repmat(curYRed(1), 1, (length(coordSmoothWin) - 1) / 2);
    padRedYEnd = repmat(curYRed(end), 1, (length(coordSmoothWin) - 1) / 2);
    curYRed = [padRedYStart curYRed padRedYEnd];
    curYRed = conv(curYRed, coordSmoothWin, 'same');
    curYRed = curYRed(((length(coordSmoothWin) - 1) / 2 + 1):(end - ((length(coordSmoothWin) - 1) / 2)));
    
    padGreenXStart = repmat(curXGreen(1), 1, (length(coordSmoothWin) - 1) / 2);
    padGreenXEnd = repmat(curXGreen(end), 1, (length(coordSmoothWin) - 1) / 2);
    curXGreen = [padGreenXStart curXGreen padGreenXEnd];
    curXGreen = conv(curXGreen, coordSmoothWin, 'same');
    curXGreen = curXGreen(((length(coordSmoothWin) - 1) / 2 + 1):(end - ((length(coordSmoothWin) - 1) / 2)));
    
    padGreenYStart = repmat(curYGreen(1), 1, (length(coordSmoothWin) - 1) / 2);
    padGreenYEnd = repmat(curYGreen(end), 1, (length(coordSmoothWin) - 1) / 2);
    curYGreen = [padGreenYStart curYGreen padGreenYEnd];
    curYGreen = conv(curYGreen, coordSmoothWin, 'same');
    curYGreen = curYGreen(((length(coordSmoothWin) - 1) / 2 + 1):(end - ((length(coordSmoothWin) - 1) / 2)));    
    
    %Calculate acceleration as the next step in identifying periods of
    %false positive LED findings
    curVel = sqrt(diff(curXRed).^2 + diff(curYRed).^2) ./ diff(posTS);
    tempTS = posTS(1:(end - 1)) + (diff(posTS) ./ 2);
    curVel = interp1(tempTS, curVel, posTS, 'pchip');
    
    curAcc = diff(curVel) ./ diff(posTS);
    tempTS = posTS(1:(end - 1)) + (diff(posTS) ./ 2);
    curAcc = abs(interp1(tempTS, curAcc, posTS, 'pchip'));
    
    meanAcc = mean(curAcc);
    stdAcc = std(curAcc);
    
    accBoolStrong = curAcc >= (meanAcc + (strongThresh * stdAcc));
    accBoolWeak = curAcc >= (meanAcc + (weakThresh * stdAcc));
    accAdjustCount = 0;
    prevSumBad = sum(accBoolStrong);
    while sum(accBoolStrong) > 1
        accIdx = 1;
        while accIdx < (length(accBoolStrong))
            accIdx = accIdx + 1;
            if accBoolStrong(accIdx)
                minIdx = 0;
                minStartIdx = minIdx;
                minEndIdx = minIdx;
                while ~minStartIdx || ~minEndIdx
                    minIdx = minIdx + 1;

                    if ~minStartIdx && (accIdx == minIdx)
                        minStartIdx = minIdx - 1;
                    end

                    if ~minEndIdx && (accIdx + minIdx > length(accBoolStrong))
                        minEndIdx = minIdx - 1;
                    end

                    if ~minStartIdx && ~accBoolWeak(accIdx - minIdx); minStartIdx = minIdx; end
                    if ~minEndIdx && ~accBoolWeak(accIdx + minIdx); minEndIdx = minIdx; end
                end
                startIdx = accIdx - minStartIdx;
                endIdx = accIdx + minEndIdx;

                curXRed(startIdx:endIdx) = NaN;
                curYRed(startIdx:endIdx) = NaN;
                curXGreen(startIdx:endIdx) = NaN;
                curYGreen(startIdx:endIdx) = NaN;
                accIdx = accIdx + minEndIdx;
            end
        end
        curXRed = inpaintn(curXRed);
        curYRed = inpaintn(curYRed);
        curXGreen = inpaintn(curXGreen);
        curYGreen = inpaintn(curYGreen);

        curVel = sqrt(diff(curXRed).^2 + diff(curYRed).^2) ./ diff(posTS);
        tempTS = posTS(1:(end - 1)) + (diff(posTS) ./ 2);
        curVel = interp1(tempTS, curVel, posTS, 'pchip');

        curAcc = diff(curVel) ./ diff(posTS);
        tempTS = posTS(1:(end - 1)) + (diff(posTS) ./ 2);
        curAcc = abs(interp1(tempTS, curAcc, posTS, 'pchip'));

        accBoolStrong = curAcc >= (meanAcc + (strongThresh * stdAcc));
        accBoolWeak = curAcc >= (meanAcc + (weakThresh * stdAcc));

        accAdjustCount = accAdjustCount + 1;
        if abs(prevSumBad - sum(accBoolStrong)) < 5
            break;
        elseif accAdjustCount > 10
            break;
        end
        prevSumBad = sum(accBoolStrong);
    end
    
    %Iterate through the epochs
    for epochIdx = 1:numEpochs
        
        %Collect the position data sampled at the framerate of the camera
        T1 = timeVector(epochIdx, 1);
        T2 = timeVector(epochIdx, 2);
        
        %Find the time indexes before and after the start of the
        %epoch. Pad them for interpolation. They'll be trimmed down later.
%         index1 = find(posTS >= T1, 1, 'first') - posPadIdx;
%         if index1 < 1; index1 = 1; end
%         index2 = find(posTS <= T2, 1, 'last') + posPadIdx;
%         if index2 > size(posMat, 2); index2 = size(posMat, 2)-1; end
        
        index1 = find(posTS >= T1, 1, 'first');
        if index1 < 1; index1 = 1; end
        index2 = find(posTS <= T2, 1, 'last');
        if index2 > size(posMat, 2); index2 = size(posMat, 2)-1; end
        
        epochPosTS = posTS(index1:index2);

        vel.v = curVel(index1:index2);
        vel.ts = posTS(index1:index2);
        epochXRed = curXRed(index1:index2);
        epochYRed = curYRed(index1:index2);
        epochXGreen = curXGreen(index1:index2);
        epochYGreen = curYGreen(index1:index2);
        %If position tracking noise reduction is turned on, it should go
        %here.

        %Upsample position data to the downsampled recording frequency
        eegTS = eeg.(char(epochNames(epochIdx))).ts;
        
%         interpPosTS = interp1([eeg.ts(1) posTS eeg.ts(end)], [eeg.ts(1) posTS eeg.ts(end)], eeg.ts, 'spline');
%         interp = interp1([eegTS(1) vel.ts eegTS(end)], [eegTS(1) vel.ts eegTS(end)], eegTS, 'spline');
        vel.v = interp1(vel.ts, vel.v, eegTS, 'pchip');
        vel.ts = eegTS;
        
        curXRed = interp1(epochPosTS, epochXRed, eegTS, 'pchip');
        curYRed = interp1(epochPosTS, epochYRed, eegTS, 'pchip');
        curXGreen = interp1(epochPosTS, epochXGreen, eegTS, 'pchip');
        curYGreen = interp1(epochPosTS, epochYGreen, eegTS, 'pchip');
        
%         xposR = interp1(epochPosTS, xposR, eegTS, 'spline');
%         yposR = interp1(epochPosTS, yposR, eegTS, 'spline');
%         
%         xposG = interp1(epochPosTS, xposG, eegTS, 'spline');
%         yposG = interp1(epochPosTS, yposG, eegTS, 'spline');

        eeg.(char(epochNames(epochIdx))).redPos = [epochXRed; epochYRed];
        eeg.(char(epochNames(epochIdx))).greenPos = [epochXGreen; epochYGreen];
        eeg.(char(epochNames(epochIdx))).vel = vel.v;
        eeg.(char(epochNames(epochIdx))).velTS = vel.ts;
        
        eeg.(char(epochNames(epochIdx))).raw.redPos = [posMat(3, index1:index2); posMat(4, index1:index2)];
        eeg.(char(epochNames(epochIdx))).raw.greenPos = [posMat(6, index1:index2); posMat(7, index1:index2)];
        eeg.(char(epochNames(epochIdx))).raw.posTS = epochPosTS;
        eeg.(char(epochNames(epochIdx))).raw.cmPERpix = cmPERpix;

    end
    
    eeg.raw.redPos = [posMat(3, :); posMat(4, :)];
    eeg.raw.greenPos = [posMat(6, :); posMat(7, :)];
    eeg.raw.cmPERpix = cmPERpix;
    eeg.raw.posTS = posTS;
%     eeg.raw.velV = velV;
%     eeg.raw.velTS = velTS;
end