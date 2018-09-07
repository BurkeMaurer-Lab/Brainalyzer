function ratInfo = Brain_FetchRatInfo(toDir, ratID)

    toParse = [toDir, 'Template.txt'];
    
    if ~exist([toDir, 'Template.txt'], 'file')
        cprintf('*err', 'ERROR:\n');
        cprintf('err', 'No template file found for ');
        cprintf('-err', ['Rat ', ratID, '\n']);
        return;
    end
    
    ratInfo = Brain_parseText(toParse, 'ver', 'Template', 'voi', 'waveInfo');
        
end