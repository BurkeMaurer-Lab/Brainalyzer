function Brain_PreProcess(inDirTev, inDirSev, outDir, ratNum, blockID)
    % Testing testing: 1, 2, and even 3
    clc;
    
    chunkSize = 100;
    fill = 1; %Constant for if you want to try to fill in missing data points
    
    posX = [];
    posY = [];
    posTS = [];
     
    blockID = char(blockID);
    %Necessary Constants
    % -cmPERpix
    %    *Centimeter's per pixel count. Necessary for velocity and
    %    acceleration data
    cmPERpix = 0.27125;
    
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
        wavesBlock = Brain_parseText(notesDir, 'ver', 'Brain', 'voi', 'waveInfo');
        timeVector = Brain_parseText(notesDir, 'ver', 'Brain', 'voi', 'epochTimes');
    end
    
    dataInfo = TDT2mat(inputDirT, 'T1', 1, 'T2', 1.05, 'STORE', {wavesBlock.wave(1).waveID}, 'VERBOSE', 0);
    
    totalTime = str2double(dataInfo.info.duration(4:5))*60 ...
        + str2double(dataInfo.info.duration(1:2))*60*60 ...
        + str2double(dataInfo.info.duration(7:8));
    
    eeg.fs = floor(dataInfo.streams.(wavesBlock.wave(1).waveID).fs);
    
    for i = 1:size(wavesBlock.wave, 2)
        
        if strcmp(wavesBlock.wave(i).Processed, 'Yes')
            if strcmp(wavesBlock.wave(i).Type, 'tev')
                inDir = inputDirT;
            elseif strcmp(wavesBlock.wave(i).Type, 'sev')
                inDir = inputDirS;
            end
            
            eeg.(wavesBlock.wave(i).Name) = Brain_LoadWaveform(inDir, blockID, wavesBlock.wave(i), timeVector, totalTime, eeg.fs);
        end
    end
    
    eeg.ts = [0 ...
        : 1/eeg.(wavesBlock.wave(i).Name).fs ...
        : (1/eeg.(wavesBlock.wave(i).Name).fs)*(size(eeg.(wavesBlock.wave(i).Name).data, 2)-1)];
    
    for epchs = 1:size(timeVector, 1)+1
        if epchs == 1
            index1 = 1;
            index2 = find(eeg.ts < timeVector(epchs, 1), 1, 'last');    %timeVector(epchs, 1) * eeg.fs;
        elseif epchs == size(timeVector, 1)+1
            index1 = find(eeg.ts > timeVector(epchs-1, 2), 1, 'first'); %timeVector(epchs-1, 2) * eeg.fs;
            index2 = size(eeg.ts, 2) * eeg.fs;
        else
            index1 = find(eeg.ts > timeVector(epchs-1, 2), 1, 'first'); %timeVector(epchs-1, 2) * eeg.fs;   
            index2 = find(eeg.ts < timeVector(epchs, 1), 1, 'last');    %timeVector(epchs, 1) * eeg.fs;     
        end
                
        for i = 1:size(wavesBlock.wave, 2)
            eeg.(wavesBlock.wave(i).Name).data(:, index1:index2) = [];
        end
        eeg.ts(:, index1:index2) = [];
        
    end
    
    for i = 1:size(wavesBlock.wave, 2)
        
        if strcmp(wavesBlock.wave(i).Sorted, 'Yes')
            % Step 1: Convert eeg data to .dat and save
            
            % Step 2: Create / Generate PRM file based on probe, mapping,
            % and bad channels
               
            % Step 3: Launch klusta using current .dat file functions and
            % save in proper directory
             
            % Step 4: Create / Generate XML Files
                
            % Step 5: Convert Klusta output to Kluster input
            
            % Step 6: Delete unnecessary files
        end
    end    
            
    for T1 = 0:chunkSize:(totalTime-chunkSize)
        
        T2 = T1 + chunkSize;
        
        tempData = TDT2mat(inputDirT, 'TYPE', {'scalars'}, 'T1', T1, 'T2', T2, 'VERBOSE', 0);
    
        xposR = tempData.scalars.RVn1.data(3, :);
        yposR = tempData.scalars.RVn1.data(4, :);
    
        xposG = tempData.scalars.RVn1.data(6, :);
        yposG = tempData.scalars.RVn1.data(7, :);
        posTS = [posTS, tempData.scalars.RVn1.ts];
    
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
            
        posX = [posX, xposR];
        posY = [posY, yposR];
            
    end
    
            %temp_ts = mean([posTS(2:end); posTS(1:end-1)], 1);
    interp = interp1([eeg.ts(1) posTS eeg.ts(end)], [eeg.ts(1) posTS eeg.ts(end)], eeg.ts, 'spline');
        
    eeg.pos(1, :) = interp1(posTS, posX, interp, 'spline');
    eeg.pos(2, :) = interp1(posTS, posY, interp, 'spline');
            
    for i = 1:size(timeVector, 2)
        strt = find(eeg.ts >= timeVector(i, 1), 1, 'first');
        endr = find(eeg.ts >= timeVector(i, 2), 1, 'first');
        
        label = strcat(outputDir, 'Epoch', sprintf('%02d', i));
        
        gap = wavesBlock.wave(1).RecoFreq / wavesBlock.wave(1).SaveFreq;
        
        epoch.ts = eeg.ts(strt:gap:endr);
        epoch.pos = eeg.pos(strt:gap:endr);
        
        for k = 1:size(wavesBlock.waves, 2)
            epoch.(wavesBlock.wave(k).Name).data = eeg.(wavesBlock.wave(k).Name).data(strt:gap:endr);
        end
        
        epoch.fs = floor(eeg.fs / gap);
        
        save(label, '-struct', 'epoch', '-v7.3');
    end
    
    %%save
    
    xx = 44;
    
    %----------------------------------------------------------%
    %----------------------------------------------------------%
    %                          STEP 1                          %
    %                                                          %
    %  Here,load all of the data from the block of interest.   %
    % Load in the data at it's original 24k resolution, then   %
    % ask the user if they would like to run the spike sorter  %
    %--------------------Editable Constants--------------------%
    %----------------------------------------------------------%
    
    
        
        %for i = 1:
        %extractedStream = Brain_dataExtract(outDir, inputDirForTDT, streamIDs{to_sort(i)}, 
        % assume that we are using a .tev file only
        
end

function eeg = Brain_LoadWaveform(inDir, blockID, wave, timeVector, totalTime, freq)

    eeg.data = [];
    eeg.ts = [];
    
    chunkSize = 25;
    
    %wave = waveInfo.wave;
    %clear waveInfo;
    
    clc;
    cprintf('-blue', ['Block ', blockID, ': Pre-Processing\n\n']);
    
    
    if strcmp(wave.Type, 'tev')
        if strcmp(wave.Sorted, 'Yes')
            %Sort by shank, then throw at spike sorter, then down sample
            homeSplit = strsplit(which('Brainalyzer_Start'), 'Brainalyzer_Start');
            homeDir = [homeSplit{1}, '\00 - Interface\Constants\'];
            temp = load([homeDir, 'Cam_eSeries64', '.mat'], wave.Map);
            probe = temp.(wave.Map);
            clear temp;
            
            for i = 1:probe.ShankCount
                clc;
                cprintf('-blue', ['Block ', blockID, ': Pre-Processing\n\n']);
                
                sites = length(probe.Shank(i).Site);
                eegTemp.data = NaN(sites, (totalTime+1)*freq);
                
                %%Load all channels from shank at 24K
                for j = 1:2 % sites
                    ch = probe.Shank(i).Site(j).Number;
                    cprintf('text', ['Loading channel ', sprintf('%02d', ch), ':    0.0%% Complete']);  
                    %tStart = tic;
        
                    startID = 1;
                    
                    for T1 = 0:chunkSize:totalTime
                        tStart = tic;
                        T2 = T1 + chunkSize;
                        
                        if T2 > totalTime; T2=totalTime; end
                        if T2 == T1; break; end
            
                        dataTemp = TDT2mat_NMD(inDir, 'TYPE', {'streams'}, ...
                            'STORE', {wave.waveID}, ...
                            'CHANNEL', ch, ...
                            'T1', T1, 'T2', T2, 'VERBOSE', 0);
            
                        sz = size(dataTemp.streams.(wave.waveID).data(1, :), 2);
                        endID = (startID + sz) - 1;
            
                        %for ch  = 1:(wave.TotChs(2)-wave.TotChs(1)+1)
                        eegTemp.data(j, startID:endID) = dataTemp.streams.(wave.waveID).data(1, :);
                        
                        if T1 ~= 0
                            cprintf('text', '\b\b\b\b\b\b');
                        end
                        
                        startID = endID + 1;
                        printPercentage(T2, totalTime);
                        
                        tEnd = toc(tStart);
                        cprintf('text', [', ', sprintf('%02d', floor(tEnd)), ' s']);
                    end
                    cprintf('text', '\n');                 
                end
                %36 backspaces
                cprintf('text', '\n');
                %cprintf('text', '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
                
                fs = dataTemp.streams.(wave.waveID).fs;
                
                % Trim the recordings based on timeVector and extra 0's at end
                if isnan(eegTemp.data(1, end))
                    xx = find(~isnan(eegTemp.data(1, :)), 1, 'last');
                    eegTemp.data(:, (xx+1):end) = [];
                end
                if eegTemp.data(1, end) == 0
                    yy = find(eegTemp.data(1, :) ~= 0, 1, 'last');
                    eegTemp.data(:, (yy+1):end) = [];
                end
                
                ts = (0 ...
                    : 1/fs ...
                    : (1/fs)*(size(eegTemp.data, 2)-1));
                
                for epchs = 1:size(timeVector, 1)+1
                    if epchs == 1
                        index1 = 1;
                        %index2 = fs * timeVector(epchs, 1);
                        index2 = find(ts <= timeVector(epchs, 1), 1, 'last') - 1;    %timeVector(epchs, 1) * eeg.fs;
                    elseif epchs == size(timeVector, 1)+1
                        %index1 = fs * timeVector(epchs-1, 2);
                        %index2 = size(eegTemp, 2) * fs;
                        index1 = find(ts >= timeVector(epchs-1, 2), 1, 'first'); %timeVector(epchs-1, 2) * eeg.fs;
                        index2 = size(ts, 2);
                    else
                        %index1 = fs * timeVector(epchs-1, 2);
                        %index2 = fs * timeVector(epchs, 1);
                        index1 = find(ts >= timeVector(epchs-1, 2), 1, 'first'); %timeVector(epchs-1, 2) * eeg.fs;
                        index2 = find(ts <= timeVector(epchs, 1), 1, 'last') - 1;    %timeVector(epchs, 1) * eeg.fs;     
                    end
                    
                    eegTemp.data(:, index1:index2) = NaN;
                    ts(:, index1:index2) = NaN;
                end
                
                eegTemp.data(:, isnan(eegTemp.data(1, :))) = [];
                ts(:, isnan(ts(1, :))) = [];
                
                %Klustering Stuff
                
                %Downsample eeg to make room for more data
                %Save downsampled data to eeg, clear eegTemp
                gap = wave.RecoFreq / wave.SaveFreq;
        
                eeg.data = eegTemp.data(1:gap:end);
                
                clc;
                
            end
            
            eeg.ts = ts(1:gap:end);
        end
                
    end
            
            
            
%         elseif strcmp(wave.Sorted, 'No')
%             %Load in one channel at a time and down sample to save memory
%             
%             
%         end
%         cprintf('text', ['Preallocating for waveform ', wave.waveID, ':  ']);
%         channelNum = wave.TotChs(2) - wave.TotChs(1) + 1;
%         eegTemp.data = NaN(channelNum, (freq*(totalTime+1)));
%         cprintf('text', 'Complete\n');
%         
%         cprintf('text', ['Loading waveform ', wave.waveID, ':    0.0%% Complete']);
%         startID = 1;
%         
%         %printPercentage(0, totalTime);
%         
%         tStart = tic;
%         
%         for T1 = 0:chunkSize:totalTime
%             T2 = T1 + chunkSize;
%             
%             if T2 > totalTime
%                 T2 = totalTime;
%             end
%             
%             if T2 == T1
%                 break;
%             end
%             
%             dataTemp = TDT2mat_NMD(inDir, 'TYPE', {'streams'}, 'STORE', {wave.waveID}, ...
%                 'T1', T1, 'T2', T2, 'VERBOSE', 0);
%             
%             sz = size(dataTemp.streams.(wave.waveID).data(1, :), 2);
%             endID = (startID + sz) - 1;
%             
%             for ch  = 1:(wave.TotChs(2)-wave.TotChs(1)+1)
%                 eegTemp.data(ch, startID:endID) = dataTemp.streams.(wave.waveID).data(ch, :);
%             end
%             
%             startID = endID + 1;
%             
%             printPercentage(T2, totalTime);
%         end
%         
%         cprintf('text', ['\nTrimming waveform ', wave.waveID, ':  ']);
%         xx = find(~isnan(eegTemp.data(1, :)), 1, 'last');
%         eegTemp.data(:, xx:end) = [];
%         yy = find(eegTemp.data(1, :) ~= 0, 1, 'last');
%         eegTemp.data(:, yy:end) = [];
%         cprintf('text', 'Complete\n');
%         
%         tEnd = toc(tStart);
%         cprintf('text', [sprintf('%02d', floor(tEnd)), ' seconds to complete\n']);
%         
%     elseif strcmp(dataType, 'sev')
%         
%     end
%             
%   
%     for i = wave.TotChs(1, 1):wave.TotChs(1, 2)
%         cprintf('text', ['Loading Channel ', sprintf('%02d', i), ':\t']);
%         
%         if strcmp(dataType, 'tev')
%             dataHolder = [];
%             tStart = tic;
%             for T1 = 0:chunkSize:totalTime
%                 
%                 T2 = T1 + chunkSize;
%                 if T2 > totalTime
%                     T2 = totalTime;
%                 end
%                 
%                 if T2 == T1
%                     break;
%                 end
%                 
%                 %tStart = tic;
%                 dataTemp = TDT2mat(inDir, 'TYPE', {'streams'}, 'STORE', {wave.waveID}, ...
%                     'T1', T1, 'T2', T2, 'VERBOSE', 0);
%                 
% 
%                 %tEnd = toc(tStart);
%                 
%                 %cprintf('text', [sprintf('%02d', floor(tEnd)), ' seconds to complete\n']);
%                 
%                 fs = floor(dataTemp.streams.(wave.waveID).fs);
%         
%                 if wave.RecoFreq ~= (floor(fs/1000))
%                     cprintf('*err', 'ERROR:\n');
%                     cprintf('err', 'Frequency in template and recorded frequency in raw files do not match\n');
%                 end
%                 
%                 %if isempty(dataHolder)
%                 %    dataHolder = zeros(1, (dataTemp.streams.(wave.waveID).fs*totalTime));
%                 %end
%                 
%                 dataHolder = [dataHolder, dataTemp.streams.(wave.waveID).data(1, :)];
%             
%                 
%             end
%             tEnd = toc(tStart);
%             cprintf('text', [sprintf('%02d', floor(tEnd)), ' seconds to complete\n']);
%             
%             endIndex = find(dataHolder > 0, 1, 'last');
%             dataHolder((endIndex+1):end) = [];
%             %endIndex = find(dataTemp.streams.(wave.waveID).data(1, :) > 0, 1, 'last');
%             %dataTemp.streams.(wave.waveID).data((endIndex+1):end) = [];
%             %eegTemp.data(i, :) = dataTemp.streams.(wave.waveID).data(1, :); %dataHolder; %dataTemp.streams.(wave.waveID).data(1, 1:gap:end);
%             eegTemp.data(i, :) = dataHolder;
%             
%             clear dataTemp;
%             clear dataHolder;
%             
%         elseif strcmp(dataType, 'sev')
%             dataTemp = SEV2mat(inDir, 'CHANNEL', i, 'VERBOSE', 0);
%             fs = floor(dataTemp.(wave.waveID).fs);
%             if wave.RecoFreq == (floor(fs/1000))
%                 gap = floor((fs / wave.SaveFreq)/1000);
%             else
%                 cprintf('*err', 'ERROR:\n');
%                 cprintf('err', 'Frequency in template and recorded frequency in raw files do not match\n');
%             end
%             
%             eegTemp.data(i, :) = [eegTemp.data(i, :), dataTemp];
%                 
%             clear dataTemp;
%         end
%     end
    
    %eegTemp.fs = fs;
end