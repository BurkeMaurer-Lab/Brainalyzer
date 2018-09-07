function Brain_FetchInfoToProcess(inDirTev, inDirSev, outDir, ratInfo, blocks)

    for i = 1:size(blocks, 2)
        blockID = char(blocks(i));
        
        delim_dash = strsplit(blockID, '-');
        
        ratNum = delim_dash{1};
        blockNum = [delim_dash{2}, '-', delim_dash{3}];
        txtDir = [outDir, ratNum, '\', blockNum, '\'];
        
        printTitle(blockID);
        
        analysisFlag = 1;
        
        if exist([txtDir, 'Notes.txt'], 'file')
            cprintf('text', 'Notes file from previous run found, would you like to run\n');
            cprintf('text', 'the pre-processing again using same settings? (Y/N)');
            ansr = input('\n', 's');
            validatedAnswer = validatestring(ansr, {'yes', 'no'});
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
                    cprintf('text', ['\tFrequency: ~', num2str(floor(holderData.streams.(streamIDs(k, :)).fs/1000)), ' KHz\n\n']);
                    cprintf('text', 'Would you like to process this waveform?');
                    ansr = input('\n', 's');
                    validatedAnsr = validatestring(ansr, {'yes', 'no'});
                    
                    fprintf(notes, ['\t', sprintf('%02d', k), ') ', streamIDs(k, :), '\n']);
                                        
                    if strcmp(validatedAnsr, 'no')
                        fprintf(notes, '\t\tName: - \n');                        
                        fprintf(notes, '\t\tPre_Processed: No\n');
                        fprintf(notes, '\t\tSpike_Sorted: No\n\n');
                        
                        fprintf(notes, '\t\tRecord_Frequency: - \n');
                        fprintf(notes, '\t\tSaved_Frequency: - \n');
                        fprintf(notes, '\t\tChannels: - \n');
                        fprintf(notes, '\t\tBad_Channels: - \n\n');
                    else
                        fprintf(notes, ['\t\tName: ', ratInfo.wave(xx).Name, '\n']);
                        fprintf(notes, '\t\tPre_Processed: Yes\n');
                        
                        ansr = input('Would you like to sort this waveform for spikes?\n', 's');
                        validatedAnsr = validatestring(ansr, {'Yes', 'No'});
                        
                        fprintf(notes, ['\t\tSpike_Sorted: ', validatedAnsr, '\n']);
                        
                        if strcmp(validatedAnsr, 'Yes')
                            fprintf(notes, ['\t\t\tProbe: ', ratInfo.wave(xx).Probe, '\n']);
                            fprintf(notes, ['\t\t\tMap: ', ratInfo.wave(xx).Map, '\n']);
                        end
                        
                        fprintf(notes, ['\n\t\tRecord_Frequency: ~', num2str(floor(holderData.streams.(streamIDs(k, :)).fs/1000)), ' KHz\n']);
                        
                        ansr = input('Enter Frequency you want to down sample data to (just interger, in KHz)\n', 's');
                        if isempty(ansr)
                            user_downFreq = 2;
                        else
                            user_downFreq = str2num(ansr);
                        end
                            
                        fprintf(notes, ['\t\tSaved_Frequency: ~', num2str(user_downFreq), ' KHz\n']);
                        
                        fprintf(notes, ['\t\tChannels: ', num2str(size(holderData.streams.(streamIDs(k, :)).data, 1)), '\n']);
                        
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
end        
            
        
        
%         if exist(strcat(inDirSev, blocks(i)), 'dir')
%             %Run function to analyze chunks of sev
%         else
%             inputDir = [inDirTev, blockID, '\'];
%             %inputDir = 'C:\Users\HAL2\Desktop\iago_temp\626-180115-175914\';
%             holderData = TDT2mat(inputDir, 'T1', 1, 'T2', 2, 'VERBOSE', 0);
%             streamIDs = fieldnames(holderData.streams);
%                     
%             for k = 1:size(streamIDs, 2)
%                 cprintf('*text', num2str(size(streamIDs, 2)));
%                 cprintf('text', ' stream found\n');
%                 cprintf('blue', [streamIDs{k}, '\n']);
%                 cprintf('text', ['\tChannels: ', num2str(size(holderData.streams.(streamIDs{i}).data, 1)), '\n']);
%                 cprintf('text', ['\tFrequency: ~', num2str(floor(holderData.streams.(streamIDs{i}).fs/1000)), 'KHz\n\n']);
%                 
%                 %cprintf(
%                 ansr = input('\n', 's');
%                 
%                 validAnsr = validatestring(ansr, {'yes', 'no'});
%                 if strcmp(validAnsr, 'yes')
%                     
%                 elseif strcmp(validAnsr, 'no')
%                 
%                 end
%                 
%             end    
%                 
%             cprintf('text', ' streams found\n');
%                 
%                 
%             cprintf('text', 'Which ');
%             cprintf('blue', 'streams ');
%             cprintf('text', 'would you like to sort for spikes? (Seperated by spaces)\n');
%             cprintf('text', 'If you would like to sort them all, enter ''all''\n');
%             
%             for j = 1:size(streamIDs, 2)
%                 cprintf('text', ['  (', sprintf('%02d', i), ')  ']);
%                 cprintf('blue', [streamIDs{i}, '\n']);
%                 cprintf('text', ['\tChannels: ', num2str(size(holderData.streams.(streamIDs{i}).data, 1)), '\n']);
%                 cprintf('text', ['\tFrequency: ~', num2str(floor(holderData.streams.(streamIDs{i}).fs/1000)), 'KHz\n']);
%             end
%             ansrSort = input('\n', 's');
%         
%             cprintf('text', '\nWould you like to process and save all streams as well?');
%             cprintf([1, 0.5, 0], '(Y/N)');
%             ansrYN = input('\n', 's');


function printTitle(blockID)

    clc;
    cprintf('-blue', ['Block ', blockID, ': Preparing Pre-Processing\n\n']);
    
end