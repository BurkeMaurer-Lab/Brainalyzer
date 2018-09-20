function Brain_FetchInfoToProcess(inDirTev, inDirSev, outDir, ratInfo, block)

%     blockID = char(block(blockIdx));
    blockID = char(block);

    delim_dash = strsplit(blockID, '-');

    ratNum = delim_dash{1};
    blockNum = [delim_dash{2}, '-', delim_dash{3}];
    txtDir = [outDir, ratNum, '\', blockNum, '\'];

    printTitle(blockID);

    analysisFlag = 1;

    %NMD 9/15/18 Future idea: Every time this gets run it shouldn't
    %write over the previous notes file, it should just append it so
    %that we maintain a record of processing.
    if exist([txtDir, 'Notes.txt'], 'file')
        cprintf('text', 'Notes file from previous run found, would you like to run\n');
        cprintf('text', 'the pre-processing again using same settings? (Y/N)');
        userPrompt = '\n';
        validatedAnswer = Brain_validateString(userPrompt, {'yes', 'no'});
        if strcmp(validatedAnswer, 'yes')
            analysisFlag = 0;
        end
    %elseif ~exist([inDirTev, 'Notes.txt'], 'file')
    %    cprintf('*err', 'ERROR:\n');
    %    cprintf('err', ['No text file found for block ', blockID, '\n']);
    %    return;
    end

    if analysisFlag
        exp = Brain_parseText([inDirTev, blockID, '\Notes.txt'], ...
            'voi', 'all');

        printTitle(blockID);
        userComment = input('Please enter any special comments or notes you want entered into text file\n', 's');

        if ~exist(txtDir, 'dir')
            mkdir(txtDir)
        end

        %  First, let's verify that all info from TDT matches what we expect from the template file
        % return an error if there is a mismatch

        holderData = TDT2mat([inDirTev, blockID, '\'], 'T1', 1, 'T2', 2, 'VERBOSE', 0);
        streamIDs = [];

        for j = 1:size(ratInfo.wave, 2)
            if strcmp(ratInfo.wave(j).Type, 'tev')
                inputDir = [inDirTev, blockID, '\'];
                ratInfo.wave(j).ID = validatestring(ratInfo.wave(j).ID, fieldnames(holderData.streams));
                if size(holderData.streams.(ratInfo.wave(j).ID).data, 1) ~= str2double(ratInfo.wave(j).Channels)
                    cprintf('*err', 'ERROR:\n');
                    cprintf('err', 'Waveform channel counts do not match up\n');
                end
                streamIDs = [streamIDs; ratInfo.wave(j).ID];
            elseif strcmp(ratInfo.wave(j).Type, 'sev')
                inputDir = [inDirSev, blockID, '\'];
                contents = dir(inputDir);
            end
        end

        notes = fopen([txtDir, 'Notes.txt'], 'wt');
        fprintf(notes, ['Experiment: ', exp.Experiment, '\n']);
        fprintf(notes, ['Rat_ID: ', exp.Subject, '\n']);
        fprintf(notes, ['Date: ', exp.Date, '\n\n']);

        fprintf(notes, ['Notes: \n', userComment, '\n\n']);

        fprintf(notes, ['Recording Info:\n\tStart_Time: ', exp.timeStart, '\n']);
        fprintf(notes, ['\tEnd_Time: ', exp.timeEnd, '\n']);

        timest = datestr(exp.timeStart, 'HH:MM:SS');
        timend = datestr(exp.timeEnd, 'HH:MM:SS');

        timeTot = datestr(datenum(timend) - datenum(timest), 'HH:MM:SS');

        fprintf(notes, ['\tTotal_Time: ', timeTot, '\n']);

        fprintf(notes, ['\n\tTotal_Epochs: ', num2str(size(exp.EpochStart, 2)), '\n']);
        for j = 1:size(exp.EpochStart, 2)
            fprintf(notes, ['\t\tEpoch', sprintf('%02d', j), '_Start- ', exp.EpochStart{j}, '\n']);
            fprintf(notes, ['\t\tEpoch', sprintf('%02d', j), '_End- ', exp.EpochEnd{j}, '\n\n']);
        end

        if exist([inDirSev, blockID], 'dir')
            %Run function to analyze chunks of sev
        else
            fprintf(notes, 'Waveform Info:\n');

            %inputDir = [inDirTev, blockID, '\'];
            %holderData = TDT2mat(inputDir, 'T1', 1, 'T2', 2, 'VERBOSE', 0);
            %possStreamIDs = fieldnames(holderData.streams);


            if size(streamIDs, 1) == 1
                cprintf('*text', num2str(size(streamIDs, 1)));
                cprintf('text', ' stream found\n');
            else
                cprintf('*text', num2str(size(streamIDs, 1)));
                cprintf('text', ' streams found\n');
            end

            for k = 1:size(streamIDs, 1)
                printTitle(blockID);

                cprintf('text', ['(', sprintf('%02d', k), ') ']);
                cprintf('-text', [streamIDs(k, :), '\n']);
                xx = find(strcmp(streamIDs(k, :), {ratInfo.wave(:).ID}));
                cprintf('text', ['\tName: ', ratInfo.wave(xx).Name, '\n']);
                cprintf('text', ['\tChannels: ', num2str(size(holderData.streams.(streamIDs(k, :)).data, 1)), '\n']);
                cprintf('text', ['\tFrequency: ', num2str(holderData.streams.(streamIDs(k, :)).fs), ' Hz\n\n']);

                userPrompt = 'Would you like to process this waveform?\n';
                validatedAnsr = Brain_validateString(userPrompt, {'yes', 'no'});

                fprintf(notes, ['\t', sprintf('%02d', k), ') ', streamIDs(k, :), '\n']);

                if strcmp(validatedAnsr, 'no')
                    fprintf(notes, '\t\tName: - \n');
                    fprintf(notes, '\t\tType: - \n');
                    fprintf(notes, '\t\tPre_Process: No\n');
                    fprintf(notes, '\t\tSpike_Sort: No\n\n');

                    fprintf(notes, '\t\tRecord_Frequency: - \n');
                    fprintf(notes, '\t\tSaved_Frequency: - \n');
                    fprintf(notes, '\t\tChannels: - \n');
                    fprintf(notes, '\t\tBad_Channels: - \n\n');
                else
                    fprintf(notes, ['\t\tName: ', ratInfo.wave(xx).Name, '\n']);
                    fprintf(notes, ['\t\tType: ', ratInfo.wave(xx).Type, '\n']);


                    fprintf(notes, '\t\tPre_Process: Yes\n');
%                         fprintf(notes, '\t\tPre_Process: No\n');

                    userPrompt = '\nWould you like to sort this waveform for spikes?\n';
                    validatedAnsr = char(Brain_validateString(userPrompt, {'Yes', 'No'}));

                    fprintf(notes, ['\t\tSpike_Sort: ', validatedAnsr, '\n']);
%                         fprintf(notes, '\t\tSpike_Sorted: No\n');

                    %I think this always needs to be validated
%                         if strcmp(validatedAnsr, 'Yes')
                    validatedProbe = validatestring(ratInfo.wave(xx).Probe, {'Cam_eSeries64', 'Cam_fSeries64', 'NN_32Linear'});
                    validatedMap = validatestring(ratInfo.wave(xx).Map, {'Linear', 'UShaped'});

                    fprintf(notes, ['\t\t\tProbe: ', validatedProbe, '\n']);
                    fprintf(notes, ['\t\t\tMap: ', validatedMap, '\n']);
%                         end

                    %NMD 9/15/18 Flooring the sampling frequency to the
                    %nearest kHz can introduce large sampling errors
                    %with the data not lining up with time stamps. This new function
                    %will use the input from the user and find the
                    %closeset possible sampling frequency.
                    fprintf(notes, ['\n\t\tRecord_Frequency: ', num2str(holderData.streams.(streamIDs(k, :)).fs), ' Hz\n']);

                    user_downFreq = getUserDownFreq(holderData.streams.(streamIDs(k, :)).fs);

                    fprintf(notes, ['\t\tSaved_Frequency: ', num2str(user_downFreq), ' Hz\n']);

                    fprintf(notes, ['\t\tChannels: 1-', num2str(size(holderData.streams.(streamIDs(k, :)).data, 1)), '\n']);

                    ansr = input('Enter bad channels for this waveform\n', 's');
                    user_badCh = '';
                    if isempty(ansr)
                        user_badCh = '-';
                    else
                        bad = str2num(ansr);
                        user_badCh = strcat(user_badCh, num2str(bad(1)));
                        for j = 2:length(bad)
                            user_badCh = strcat(user_badCh, [', ', num2str(bad(j))]);
                        end
                    end

                    fprintf(notes, ['\t\tBad_Channels: ', user_badCh, '\n\n']);
                end
            end
        end
    end
end        
            

function printTitle(blockID)

    clc;
    cprintf('-blue', ['Block ', blockID, ': Preparing Pre-Processing\n\n']);
    
end

function userDownFreq = getUserDownFreq(fs)

    while 1
        numPosFreq = 4;
        userAns = input('Enter Frequency you want to down sample data to in Hz\n', 's');
        if isempty(userAns)
            %Keeps the default frequency as the recording
            %frequency so the user can just hit enter if
            %they don't want to downsample.
            userDownFreq = fs;
            break;
        else
            userDownFreq = str2double(userAns);
            if userDownFreq == fs; break; end
        end
        
        lowPosFreq = fs;
        sampTMult = 0;
        while lowPosFreq >= userDownFreq
            sampTMult = sampTMult + 1;
            lowPosFreq = (1 / (1 / fs * sampTMult));
        end
        posFreq1 = (1 / (1 / fs * (sampTMult + 1)));
        posFreq2 = (1 / (1 / fs * sampTMult));
        posFreq3 = (1 / (1 / fs * (sampTMult - 1)));
        posFreq4 = (1 / (1 / fs * (sampTMult - 2)));
        posFreq = [posFreq1 posFreq2 posFreq3 posFreq4];
        cprintf('text', '\nThese are the available frequencies based on\nyour input and the recording sampling frequency.');
        cprintf('text', ['\n\t1) ', num2str(posFreq1), ' Hz']);
        cprintf('text', ['\n\t2) ', num2str(posFreq2), ' Hz']);
        if posFreq3 < fs
            cprintf('text', ['\n\t3) ', num2str(posFreq3), ' Hz']);
            if posFreq4 < fs
                cprintf('text', ['\n\t4) ', num2str(posFreq4), ' Hz']);
            else
                cprintf('text', ['\n\t4) ', num2str(fs), ' Hz']);
            end
        else
            cprintf('text', ['\n\t3) ', num2str(fs), ' Hz']);
            numPosFreq = 3;
        end
        cprintf('text', '\nAre one of these acceptable? If neither works please enter "None".\nYou will be asked to enter a new sampling frequency.');
        cprintf('text', '\nIf one will work, please enter that number');
        userAns = input('\n', 's');
        if numPosFreq == 4
            validateAns = validatestring(userAns, {'1', '2', '3', '4', 'None'});
        else
            validateAns = validatestring(userAns, {'1', '2', '3', 'None'});
        end
        if string(validateAns) ~= "None"
            userDownFreq = posFreq(str2double(validateAns));
            break;
        end
    end
end