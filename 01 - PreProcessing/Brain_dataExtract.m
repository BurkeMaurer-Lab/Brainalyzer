function dataReturn = Brain_dataExtract(outDir, inDir, chanVec, timeVec, varargin)

    % First verify all inputs are in proper format

    timeVec = reshape(timeVec.', 1, numel(timeVec));
    if sum((timeVec(2:end) - timeVec(1:(end-1))) < 0)
        cprintf('*err', 'ERROR IN DATA EXTRACTOR:\n');
        cprintf('err', '\tBlock data could not be extracted, values in time vector are not sequential\n');
        return;
    end
    
    if mod(length(timeVec), 2)
        cprintf('*err', 'ERROR IN DATA EXTRACTOR:\n');
        cprintf('err', '\tBlock data could not be extracted, time vector does not have even number of elements\n');
        return;
    elseif isempty(timeVec)
        numEpochs = 1;
    else
        numEpochs = length(timeVec) / 2;
    end
    
    

    

    %combData = [];
    %bigData = [];
    %timeCut = 0; %Will be used if there's multiple epochs to reduce memory consumption
    %numEpochs = size(timeVec, 1);

    if mod(numel(timeVec), 2) ~= 0
        fprintf('\ntimeVec needs to have an even number of values so that the start and end of each epoch is specified.\nPlease try again.')
        return;
    end

    %Make sure all the times follow eachother in order (t2 of row i is less
    %than t1 of row i + 1.
    tempTime = reshape(timeVec.', 1, numel(timeVec));
    if tempTime(end) == 0
        tempTime(end) = inf;
    end
    if sum((tempTime(2:end) - tempTime(1:(end - 1))) < 0) > 0
        fprintf('\ntimeVec should be in sequential order.\n\tt2 of every row should be less than t1\n\tt2 of row (i) should be less than t1 of row (i + 1)\nPlease try again.')
        return;
    end
    clear tempTime;

    %defaults unless changed in varargin
    varStrings = ["wave" "verbose" "saveSep" "saveComb"];
    wave = 'RSn1';
    sevStructName = 'RSn1';
    verbose = 0;
    saveSep = 1; %Make 0 to not save seperate epoch files
    saveComb = 1; %Make 0 to not save a combined epoch
    % parse varargin
    for i = 1:2:length(varargin)
        if ~ismember(varargin{i}, varStrings)
            fprintf('\n\nInput does not match allowable options.\nYou entered %s\nPlease try again.\n', string(varargin{i}))
            return;
        end
        eval([varargin{i} '= varargin{i + 1};']);
    end

%Check the file types to make sure the correct extraction script is
%used
fileType = [];
fileType = 'tev';%.tev file type
tank = char(tank);
fileTypeFiles = dir(tank);
[~, ~, fileTypeLook] = fileparts(fileTypeFiles(3).name);
if fileTypeLook == '.sev'; fileType = 'sev'; end
if verbose; fprintf('\nData type is: .%s', fileType); end

fprintf('\nOpening Raw Data')

for chan = chanVec
    if verbose; fprintf('\nOpening channel: %d', chan); end
    if fileType == 'tev'
        tempBigData = TDT2mat_NMD(tank, 'verbose', 0, 'TYPE',{'streams'}, 'CHANNEL', chan, 'T1' , 0, 'T2', 0);
        fs = floor(tempBigData.streams.(wave).fs);
        bigData = [bigData; tempBigData.streams.(wave).data];
    else
        tempBigData = SEV2mat(tank, 'verbose', 0, 'CHANNEL', chan);
        fs = floor(tempBigData.(sevStructName).fs);
        bigData = [bigData; tempBigData.(sevStructName).data];
    end
    clear tempBigData;
end

for epoch = 1:numEpochs
    t1 = timeVec(epoch, 1);
    t2 = timeVec(epoch, 2);
    %         if t2 ~= 0; t2 = t2 - timeCut; end
    
    if saveComb; bigStart = t1; end
    fprintf('\n\nCollecting and converting data from tank: %s\n\tChannels: %d - %d\n\tTime: %d - %d (sec)', tank, chanVec(1), chanVec(end), t1, t2)
    if t1 == 0
        if t2 == 0
            epochData = bigData(:, 1:end);
        else
            epochData = bigData(:, 1:(t2 * fs));
        end
    else
        if t2 == 0
            epochData = bigData(:, (t1 * fs):end);
        else
            epochData = bigData(:, (t1 * fs):(t2 * fs));
        end
    end
    
    %         if numEpochs > 1
    %             if t2 == 0
    %                 clear bigData;
    %             else
    %                 bigData = bigData(:, ((t2 * fs) + 1):end);
    % %                 timeCut = t2;
    %             end
    %         end
    
    if saveSep
        [~, fileName, ~] = fileparts(tank);
        outputName = strcat(saveFolder, '/', fileName, '_chans');
        for chan = chanVec
            outputName = strcat(outputName, '-', string(chan));
        end
        startTime = int2str(t1);
        while length(startTime) < 5; startTime = ['0' startTime]; end
        if t2 == 0
            endTime = 'End';
        else
            endTime = int2str(t2);
            while length(endTime) < 5; endTime = ['0', endTime]; end
        end
        outputName = strcat(outputName, '_Time', startTime, '-', endTime, '.mat');
        save(outputName, 'epochData', '-v7.3');
        %             writemda32(epochData, outputName);
    end
    if saveComb
        combData = [combData epochData];
        clear epochData;
    end
    fprintf('\n')
end

if saveComb
    [~, fileName, ~] = fileparts(tank);
    outputName = strcat(fileName, '_chans');
    for chan = chanVec
        outputName = strcat(outputName, '-', string(chan));
    end
    outputName = strcat(outputName, '_Time');
    for epoch = 1:size(timeVec, 1)
        startTime = int2str(timeVec(epoch, 1));
        endTime = int2str(timeVec(epoch, 2));
        if endTime == '0'
            endTime = 'End';
        else
            while length(endTime) < 5; endTime = ['0' endTime]; end
        end
        while length(startTime) < 5; startTime = ['0' startTime]; end
        
        outputName = strcat(outputName, '--', startTime, '-', endTime);
    end
    datName = outputName;
    outputName = strcat(outputName, '.dat');
    writedat(combData, strcat(saveFolder, '\', outputName));
    
end
end