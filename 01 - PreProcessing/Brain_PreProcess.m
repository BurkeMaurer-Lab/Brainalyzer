function Brain_PreProcess(inDirTev, inDirSev, outDir, ratInfo, blockID)

    clc;
    
    fill = 1; %Constant for if you want to try to fill in missing data points
    
    %Necessary Constants
    % -cmPERpix
    %    *Centimeter's per pixel count. Necessary for velocity and
    %    acceleration data
    cmPERpix = 0.27125;
    
    % -inputDir4TDT
    %    *Directory where raw TDT files are stored (.tev)
    inputDirT = [inDirTev, blockID, '\'];
    
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
            if strcmp(waveBlock.wave(i).Type, 'tev')
                inDir = inputDirT;
            elseif strcmp(wavesBlock.wave(i).Type, 'sev')
                inDir = inputDirS;
            end
            
            eeg.(waveBlock.wave(i).Name) = Brain_LoadWaveform(inDir, wavesBlock.wave(i), dataType);
        
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
        
            tempData = TDT2mat(inDirT, 'TYPE', {'scalars'}, 'T1', 0, 'T2', 0, 'VERBOSE', 0);

            xposR = tempData.scalars.RVn1.data(3, :);
            yposR = tempData.scalars.RVn1.data(4, :);
    
            xposG = tempData.scalars.RVn1.data(6, :);
            yposG = tempData.scalars.RVn1.data(7, :);
            posTS = tempData.saclars.RVn1.ts;
    
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
        end
    end
    
    
    
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

function eegTemp = Brain_LoadWaveform(inDir, waveInfo, dataType)

    eegTemp = [];
    
    wave = waveInfo.wave;
    clear waveInfo;
    
    dataType = validatestring(dataType, {'tev', 'sev'});
    
    for i = wave.Channels(1, 1):wave.Channels(1, 2)
        cprintf('text', ['Loading Channel ', sprintf('%02d', i), '\n']);
        
        if strcmp(dataType, 'tev')
            dataTemp = TDT2mat(inDir, 'CHANNEL', i, 'TYPE', {'streams'}, 'STORE', {wave.ID}, ...
                'T1', 0, 'T2', 0, 'VERBOSE', 0);
            fs = floor(dataTemp.streams.(wave.ID).fs);
            if wave.RecoFreq == (floor(fs/1000))
                gap = fs / wave.SaveFreq;
            else
                cprintf('*err', 'ERROR:\n');
                cprintf('err', 'Frequency in template and recorded frequency in raw files do not match\n');
            end
            
            eegTemp(i, :) = dataTemp(1, 1:gap:end);
            
            clear dataTemp;
            
        elseif strcmp(dataType, 'sev')
            dataTemp = SEV2mat(inDir, 'CHANNEL', i, 'VERBOSE', 0);
            fs = floor(dataTemp.(wave.ID).fs);
            if wave.RecoFreq == (floor(fs/1000))
                gap = fs / wave.SaveFreq;
            else
                cprintf('*err', 'ERROR:\n');
                cprintf('err', 'Frequency in template and recorded frequency in raw files do not match\n');
            end
            
            eegTemp(i, :) = [eegTemp(i, :), dataTemp];
                
            clear dataTemp;
        end
    end
    eegTemp.fs = fs / gap;
end
    