function [wave, epoch] = Brain_PickWaveAndEpoch(toDir, ratInfo)

    cprintf('-blue', 'Waveform and Epoch Selector for block \n\n');
    cprintf('text', 'Select which waveform(s) you would like to analyze\n');
    
    %wave = '';
    
    %toDir = char(toDir);
    
    for i = 1:size(ratInfo.wave, 2)
        cprintf('text', ['  (', sprintf('%02d', i), ')  ']);
        cprintf('magenta', ['Waveform ', ratInfo.wave(i).ID, ': ', ratInfo.wave(i).Name, '\n']);
    end
    
    ansrW = input('\n', 's');
    respW = str2num(ansrW);
       
    for i = 1:length(respW)
        wave{i, 1} = ratInfo.wave(respW(i)).Name;
        cprintf('text', 'Loading Epoch ID''s');
        waveObject = matfile([toDir, '01 - PreProcessed\', ratInfo.wave(respW(i)).Name, '_data.mat']);
        varlist = waveObject.epochNames;
        clear waveObject;
        cprintf('text', repmat('\b', 1, 18));
        cprintf('text', 'Select which epochs from wave ');
        cprintf('-text', ratInfo.wave(respW(i)).Name);
        cprintf('text', ' you would like to analyze\n');
        
        for j = 1:size(varlist, 1)
            cprintf('text', ['  (', sprintf('%02d', j), ')  ']);
            cprintf('magenta', [char(varlist(j, :)), '\n']);
        end
        
        ansrE = input('\n', 's');
        respE = str2num(ansrE);
        
        for j = 1:length(respE)
            epoch(i, j) = {char(varlist(respE(j), :))};
        end
    end
    
end