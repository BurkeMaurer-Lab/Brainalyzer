%These inputs need to be checked to make sure they're valid at some point.
function rats = Interface_ReturnRatsToProcess(inDir)

    ratFolders = dir(inDir);
    ratFolders = ratFolders(~ismember({ratFolders.name}, {'.', '..'}));
    
    cprintf('text', 'Select which rats you would like to analyze (Seperated by spaces)\n');
    
    for i = 1:size(ratFolders, 1)
        cprintf('text', ['\t', sprintf('%02d', i), ')  ']);
        cprintf('text', [ratFolders(i).name, '\n']);
    end
    
    ansr = input('\n', 's');
    ansr = str2num(ansr);
    rats = [];
    
    for i = 1:length(ansr)
        rats(i).ID = ratFolders(ansr(i)).name;
    end
end