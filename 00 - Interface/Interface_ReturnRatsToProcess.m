%These inputs need to be checked to make sure they're valid at some point.
function rats = Interface_ReturnRatsToProcess(inDir)

    rats = [];
    
    ratFolders = dir(inDir);
    ratFolders = ratFolders(~contains({ratFolders.name}, {'.', '..'}));
    
    cprintf('text', 'Select which rats you would like to analyze (Seperated by spaces)\nEnter "all" to process all rats\n');
       
    for i = 1:size(ratFolders, 1)
        cprintf('text', ['\t', sprintf('%02d', i), ')  ']);
        cprintf('text', [ratFolders(i).name, '\n']);
    end
    
    ansr = input('\n', 's');
    try
        ansr = validatestring(ansr, "all");
        for i = 1:size(ratFolders, 1)
            rats(i).ID = ratFolders(i).name;
        end
    catch
        ansr = str2num(ansr);

        for i = 1:length(ansr)
            rats(i).ID = ratFolders(ansr(i)).name;
        end
    end
end