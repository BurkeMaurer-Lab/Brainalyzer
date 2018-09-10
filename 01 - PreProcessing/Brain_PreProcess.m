function Brain_PreProcess(inDirTev, inDirSev, outDir, ratNum, blockID)

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
    
    for i = 1:size(wavesBlock.wave, 2)
        
        if strcmp(wavesBlock.wave(i).Processed, 'Yes')
            if strcmp(wavesBlock.wave(i).Type, 'tev')
                inDir = inputDirT;
            elseif strcmp(wavesBlock.wave(i).Type, 'sev')
                inDir = inputDirS;
            end
            
            dataInfo = TDT2mat(inputDirT, 'T1', 1, 'T2', 2, 'VERBOSE', 0);
    
            totalTime = str2double(dataInfo.info.duration(4:5))*60 ...
                + str2double(dataInfo.info.duration(1:2))*60*60 ...
                + str2double(dataInfo.info.duration(7:8));
            
            eeg.(wavesBlock.wave(i).Name) = Brain_LoadWaveform(inDir, wavesBlock.wave(i), wavesBlock.wave(i).Type, totalTime);
            
            eeg.ts = [0 ...
                : 1/eeg.(wavesBlock.wave(i).Name).fs ...
                : (1/eeg.(wavesBlock.wave(i).Name).fs)*(size(eeg.(wavesBlock.wave(i).Name).data, 2)-1)];
            %Cut out timeframes between epochs using timeVector
            %Need:
            %   Probe settings to generate prb files and organize channels by
            %   shank
        
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
            
        end
        

        
        
    end
    
    for j = 1:size(timeVector, 2)
        strt = find(eeg.ts >= timeVector(j, 1), 'FIRST');
        endr = find(eeg.ts >= timeVector(j, 2), 'FIRST');
            
        label = strcat(outputDir, 'Epoch', sprintf('%02d', j));
            
        epoch.ts = eeg.ts(strt:endr);
        epoch.pos = eeg.pos(strt:endr);
        for k = 1:size(wavesBlock.waves, 2)
            epoch.(wavesBlock.wave(k).Name).data = eeg.(wavesBlock.wave(k).Name).data(strt:endr);
            epoch.(wavesBlock.wave(k).Name).fs = eeg.(wavesBlock.wave(k).Name).fs;
        end
        
        save(label, -struct', 'epoch', '-v7.3');
    end
    
    %%save
    
    
    
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

function eegTemp = Brain_LoadWaveform(inDir, wave, dataType, totalTime)

    eegTemp.data = [];
    chunkSize = 500;
    
    %wave = waveInfo.wave;
    %clear waveInfo;
    
    dataType = validatestring(dataType, {'tev', 'sev'});
    
    for i = wave.TotChs(1, 1):wave.TotChs(1, 2)
        cprintf('text', ['Loading Channel ', sprintf('%02d', i), '\n']);
        
        if strcmp(dataType, 'tev')
            dataHolder = [];
            for T1 = 0:chunkSize:totalTime
                
                T2 = T1 + chunkSize;
                if T2 > totalTime
                    T2 = totalTime;
                end
                
                if T2 == T1
                    break;
                end
                
                dataTemp = TDT2mat(inDir, 'CHANNEL', i, 'TYPE', {'streams'}, 'STORE', {wave.waveID}, ...
                    'T1', T1, 'T2', T2, 'VERBOSE', 0);
                
                fs = floor(dataTemp.streams.(wave.waveID).fs);
        
                if wave.RecoFreq == (floor(fs/1000))
                    gap = floor((fs / wave.SaveFreq)/1000);
                else
                    cprintf('*err', 'ERROR:\n');
                    cprintf('err', 'Frequency in template and recorded frequency in raw files do not match\n');
                end
                
                %if isempty(dataHolder)
                %    dataHolder = zeros(1, (dataTemp.streams.(wave.waveID).fs*totalTime));
                %end
                
                dataHolder = [dataHolder, dataTemp.streams.(wave.waveID).data(1, 1:gap:end)];
            
                
            end
            
            eegTemp.data(i, :) = dataHolder; %dataTemp.streams.(wave.waveID).data(1, 1:gap:end);
            clear dataHolder;
            
        elseif strcmp(dataType, 'sev')
            dataTemp = SEV2mat(inDir, 'CHANNEL', i, 'VERBOSE', 0);
            fs = floor(dataTemp.(wave.waveID).fs);
            if wave.RecoFreq == (floor(fs/1000))
                gap = floor((fs / wave.SaveFreq)/1000);
            else
                cprintf('*err', 'ERROR:\n');
                cprintf('err', 'Frequency in template and recorded frequency in raw files do not match\n');
            end
            
            eegTemp.data(i, :) = [eegTemp.data(i, :), dataTemp];
                
            clear dataTemp;
        end
    end
    eegTemp.fs = fs / gap;
end