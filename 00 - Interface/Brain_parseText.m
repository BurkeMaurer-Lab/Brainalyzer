function voi_out = Brain_parseText(inDir, varargin)

    possVarargins = {'ver', 'voi'};
    
    possVers = {'TDT', 'Brain', 'Template', 'User'};
    possVOIs = {'epochTimes', 'runTime', 'Subject', 'Experiment', 'User', 'Date', 'All', ...
        'waveInfo'};
    
    ver = 'TDT';
    voi = 'epochTimes';
    
    for i = 1:2:length(varargin)
        if ~ismember(varargin{i}, possVarargins)
            fprintf('\n\nInput does not match allowable options.\nYou entered %s\nPlease try again.\n', string(varargin{i}))
            return;
        end
        eval([varargin{i} '= varargin{i + 1};']);
    end
    
    ver = validatestring(ver, possVers);
    voi = validatestring(voi, possVOIs);
    
    if strcmp(ver, 'TDT')
        voi_out = parseTDT(inDir, voi);
    elseif strcmp(ver, 'Brain')
        voi_out = parseBRAIN(inDir, voi);
    elseif strcmp(ver, 'Template')
        voi_out = parseTEMP(inDir, voi);
    end
end




function voi_out = parseTDT(inDir, voi)
    lines = CountLineNum(inDir);
    toParse = fopen(inDir);
    
    strPoss = {'Experiment', 'Subject', 'User'};
    x = strcmp(voi, strPoss);
    
    if any(x)
        idx = find(x, 1);
        for i = 1:lines
            line = fgetl(toParse);
            delim_colon = strsplit(line, ': ');
            if strcmp(delim_colon{1}, strPoss{idx})
                voi_out = delim_colon{2};
            end
        end
        
    elseif strcmp(voi, 'epochTimes')
        for i = 1:lines
            line = fgetl(toParse);
            delim_colon = strsplit(line, ': ');
            if strcmp(delim_colon{1}, 'Start')
                if strfind(delim_colon{2}, 'pm')
                    delim_timeStart = strsplit(delim_colon{2}, 'pm');
                    delim_colon2 = strsplit(delim_timeStart{1}, ':');
                    tStart = ((str2double(delim_colon2{1}) + 12) * 60 * 60) + ...
                        (str2double(delim_colon2{2}) * 60) + str2double(delim_colon2{3});
                elseif strfind(delim_colon{2}, 'am')
                    delim_timeStart = strsplit(delim_colon{2}, 'am');
                    delim_colon2 = strsplit(delim_timeStart{1}, ':');
                    tStart = ((str2double(delim_colon2{1}) + 0) * 60 * 60) + ...
                        (str2double(delim_colon2{2}) * 60) + str2double(delim_colon2{3});
                end
            elseif strcmp(delim_colon{1}, 'Stop')
                if strfind(delim_colon{2}, 'pm')
                    delim_timeStop = strsplit(delim_colon{2}, 'pm');
                    delim_colon2 = strsplit(delim_timeStop{1}, ':');
                    tStop = ((str2double(delim_colon2{1}) + 12) * 60 * 60) + ...
                        (str2double(delim_colon2{2}) * 60) + str2double(delim_colon2{3});
                elseif strfind(delim_colon{2}, 'am')
                    delim_timeStop = strsplit(delim_colon{2}, 'am');
                    delim_colon2 = strsplit(delim_timeStop{1}, ':');
                    tStop = ((str2double(delim_colon2{1}) + 0) * 60 * 60) + ...
                        (str2double(delim_colon2{2}) * 60) + str2double(delim_colon2{3});
                end
            end
        end
        
        frewind(toParse);
        epcs = 1;
        
        for i = 1:lines
            line = fgetl(toParse);
            delim_bracketO = strsplit(line, ' [');
            if size(delim_bracketO, 2) > 1
                %if ~isempty(delim_bracketO{2})
                delim_bracketC = strsplit(delim_bracketO{2}, '] ');
                if strcmp(delim_bracketC{1}, 'Epoch_Start')
                    delim_colon = strsplit(delim_bracketO{1}, ': ');
                    if strfind(delim_colon{2}, 'pm')
                        delim_colon{2} = erase(delim_colon{2}, 'pm');
                        delim_colon2 = strsplit(delim_colon{2}, ':');
                        tEpoc = ((str2double(delim_colon2{1}) + 12) * 60 * 60) + ...
                            (str2double(delim_colon2{2}) * 60) + str2double(delim_colon2{3});
                        voi_out(epcs, 1) = (tEpoc - tStart);
                    elseif strfind(delim_colon{2}, 'am')
                        delim_colon{2} = erase(delim_colon{2}, 'am');
                        delim_colon2 = strsplit(delim_colon{2}, ':');
                        tEpoc = ((str2double(delim_colon2{1}) + 0) * 60 * 60) + ...
                            (str2double(delim_colon2{2}) * 60) + str2double(delim_colon2{3});
                        voi_out(epcs, 1) = (tEpoc - tStart);
                    end
                elseif strcmp(delim_bracketC{1}, 'Epoch_End')
                    delim_colon = strsplit(delim_bracketO{1}, ': ');
                    if strfind(delim_colon{2}, 'pm')
                        delim_colon{2} = erase(delim_colon{2}, 'pm');
                        delim_colon2 = strsplit(delim_colon{2}, ':');
                        tEpoc = ((str2double(delim_colon2{1}) + 12) * 60 * 60) + ...
                            (str2double(delim_colon2{2}) * 60) + str2double(delim_colon2{3});
                        voi_out(epcs, 2) = (tEpoc - tStart);
                        epcs = epcs + 1;
                    elseif strfind(delim_colon{2}, 'am')
                        delim_colon{2} = erase(delim_colon{2}, 'am');
                        delim_colon2 = strsplit(delim_colon{2}, ':');
                        tEpoc = ((str2double(delim_colon2{1}) + 0) * 60 * 60) + ...
                            (str2double(delim_colon2{2}) * 60) + str2double(delim_colon2{3});
                        voi_out(epcs, 2) = (tEpoc - tStart);
                        epcs = epcs + 1;
                    end
                end
            end
        end
    
    elseif strcmp(voi, 'All')
        
        epcs = 1;
        for i = 1:lines
            line = fgetl(toParse);
            delim_colon = strsplit(line, ': ');
            if size(delim_colon, 2) > 1
                if strcmp(delim_colon{1}, 'Experiment')
                    voi_out.Experiment = delim_colon{2};
                
                elseif strcmp(delim_colon{1}, 'Subject')
                    voi_out.Subject = delim_colon{2};
            
                elseif strcmp(delim_colon{1}, 'User')
                    voi_out.User = delim_colon{2};
                
                elseif strcmp(delim_colon{1}, 'Start')
                    delim_timeStart = strsplit(delim_colon{2}, ' ');
                    voi_out.Date = delim_timeStart{2};
                    voi_out.timeStart = delim_timeStart{1};                
                
                elseif strcmp(delim_colon{1}, 'Stop')
                    delim_timeEnd = strsplit(delim_colon{2}, ' ');
                    voi_out.timeEnd = delim_timeEnd{1};  
                
                elseif strfind(delim_colon{2}, 'Epoch_Start')
                    delim_timeEpoS = strsplit(delim_colon{2}, ' ');
                    voi_out.EpochStart{epcs} = delim_timeEpoS{1};
                
                elseif strfind(delim_colon{2}, 'Epoch_End')
                    delim_timeEpoE = strsplit(delim_colon{2}, ' ');
                    voi_out.EpochEnd{epcs} = delim_timeEpoE{1};
                    epcs = epcs+1;
                end
            end
        end
        
    end
end

function voi_out = parseBRAIN(inDir, voi)
    lines = CountLineNum(inDir);
    toParse = fopen(inDir);
    
    possCares = {'Name', 'Pre_Process', 'Spike_Sort', ...
        'Start_Time', 'End_Time', 'Total_Time', 'Epoch_Times', ...
        'Record_Frequency', 'Saved_Frequency', ...
        'Channels', 'Bad_Channels', 'Probe'};
    
    if strcmp(voi, 'All')
        ratVars = {'Rat_ID'};
        for i = 1:lines
            
        end
    
    elseif strcmp(voi, 'waveInfo')
        textLine = fgetl(toParse);
        while ~feof(toParse)
                      
            if contains(textLine, ') ')
                delim_parenth = strsplit(textLine, ') ');
                waveNum = str2double(delim_parenth{1});
                voi_out.wave(waveNum).waveID = delim_parenth{2};
                textLine = fgetl(toParse);
                while ~contains(textLine, ') ') && ~feof(toParse)
                    delim_colon = strsplit(textLine, ': ');
                    delim_colon{1} = strtrim(delim_colon{1});
                    if strcmp(delim_colon{1}, 'Name')
                        voi_out.wave(waveNum).Name = delim_colon{2};
                    elseif strcmp(delim_colon{1}, 'Type')
                        voi_out.wave(waveNum).Type = delim_colon{2};
                    elseif strcmp(delim_colon{1}, 'Pre_Process')
                        voi_out.wave(waveNum).Process = delim_colon{2};
                    elseif strcmp(delim_colon{1}, 'Spike_Sort')
                        voi_out.wave(waveNum).Sort = delim_colon{2};
                    elseif strcmp(delim_colon{1}, 'Save_Dat')
                        voi_out.wave(waveNum).SaveDat = delim_colon{2};
                    elseif strcmp(delim_colon{1}, 'Probe')
                        voi_out.wave(waveNum).Probe = delim_colon{2};
                    elseif strcmp(delim_colon{1}, 'Map')
                        voi_out.wave(waveNum).Map = delim_colon{2};
                    elseif strcmp(delim_colon{1}, 'Record_Frequency')
                        voi_out.wave(waveNum).RecoFreq = str2double(erase(delim_colon{2}, " Hz"));
                    elseif strcmp(delim_colon{1}, 'Saved_Frequency')
                        voi_out.wave(waveNum).SaveFreq = str2double(erase(delim_colon{2}, " Hz"));
                    elseif strcmp(delim_colon{1}, 'Channels')
                        delim_colon{2} = strrep(delim_colon{2}, '-', ' ');
                        voi_out.wave(waveNum).TotChs = str2num(delim_colon{2});
                    elseif strcmp(delim_colon{1}, 'Bad_Channels')
                        voi_out.wave(waveNum).BadChs = str2num(erase(delim_colon{2}, ","));
                    elseif strcmp(delim_colon{1}, 'Delete_Raw_Data')
                        voi_out.wave(waveNum).DelRaw = delim_colon{2};
                    end
                    
                    textLine = fgetl(toParse);
                end
            else
                textLine = fgetl(toParse);
            end
        end
    
    elseif strcmp(voi, 'Probe')
        for i = 1:lines
            textLine = fgetl(toParse);
            
            if findstr(textLine, 'Probe')
                delim_parent = strsplit(textLine, ': ');
                
                voi_out = delim_parent{2};
            end
        end
        
    elseif strcmp(voi, 'epochTimes')
        while ~feof(toParse)
            textLine = fgetl(toParse);
            
            if contains(textLine, 'Start_Time')
                delim_colon = strsplit(textLine, ': ');
                startT = datestr(delim_colon{2}, 'HH:MM:SS');
            elseif contains(textLine, 'Total_Epochs')
                delim_colon = strsplit(textLine, ': ');
                voi_out = zeros(str2double(delim_colon{2}), 2);
            elseif contains(textLine, 'Epoch')
                if contains(textLine, 'Start')
                    epochCol = 1;
                elseif contains(textLine, 'End')
                    epochCol = 2;
                end
                delim_colon = strsplit(textLine, '- ');
                epochRow = str2double(extractBetween(textLine, 'Epoch', '_'));
                epochT = datestr(delim_colon{2}, 'HH:MM:SS');
                epochStamp = datestr(datenum(epochT) - datenum(startT), 'HH:MM:SS');
                timeVal = str2double(datestr(epochStamp, 'HH')) * 3600 + ...
                    str2double(datestr(epochStamp, 'MM')) * 60 + ...
                    str2double(datestr(epochStamp, 'SS'));
                
                voi_out(epochRow, epochCol) = timeVal;
            end
        end
    end
    
end

function voi_out = parseTEMP(inDir, voi)
    toParse = fopen(inDir);
    
    ratKeys = {'Experiment', 'Rat'};
    waveKeys = {'Type', 'ID', 'Name', 'Channels', 'Probe', 'Map'};
    
    if strcmp(voi, 'waveInfo')
        while ~feof(toParse)
            textLine = fgetl(toParse);
        
            if contains(textLine, ')')
                delim_parenth = strsplit(textLine, ')');
                indx = str2double(delim_parenth{1});
            elseif contains(textLine, ': ')
                delim_colon = strsplit(strtrim(textLine), ': ');
                xx = find(strcmp(delim_colon{1}, waveKeys));
                if ~isempty(xx)
                    voi_out.wave(indx).(waveKeys{xx}) = delim_colon{2};
                end
            end
        end
    end
    
end

function lines = CountLineNum(path)

    lines = 0;

    fileToOpen = fopen(path);
    textLine = fgetl(fileToOpen);
    
    while ischar(textLine)
        textLine = fgetl(fileToOpen);
        lines = lines+1;
    end
    
end
        