function Brain_NoiseFilter(direct, waves, epochs)

    inDir = [direct, '01 - PreProcessed\'];
    outDir = [direct, '03 - Noise Filtering\'];
    
    mode = 'Draconian';
    
    if ~exist(outDir, 'dir'), mkdir(outDir), end
    
    for waveIDx = 1:size(waves, 1)
        objectStr = [waves{waveIdx, 1}, '_data.mat'];
        
        for epochIdx = 1:size(epochs, 2)
            waveObject = matfile([inDir, objectStr]);
            tData = waveObject.(epochs{waveIdx, epochIdx});
            tData.fs = waveObject.fs;
            clear waveObject;
            
            
        end
    end    
        

end 