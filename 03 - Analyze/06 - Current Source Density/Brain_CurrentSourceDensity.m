function Brain_CurrentSourceDensity(direct, waves, epochs, vbin)

    %waveInfo.
    %epochData = load([inDir, '01 - PreProcessed\']);
    
    preDir = [direct, '01 - PreProcessed\'];
    outDir = [direct, '06 - Current Source Density\'];
    
    xx = [9, 16, 23];
    
    if ~exist(outDir, 'dir'), mkdir(outDir), end
    
    for waveIdx = 1:size(waves, 1)
        objectStr = [waves{waveIdx, 1}, '_data.mat'];

        for epochIdx = 1:size(epochs, 2)
            waveObject = matfile([preDir, objectStr]);
            tData = waveObject.(epochs{waveIdx, epochIdx});
            clear waveObject;
            
            binIDXs = discretize(tData.vel(1, :), vbin);
            
            for currBin = 1:(length(vbin)-1)
                cbinIdx = find(binIDXs == currBin);
                eegBinned = tData.volts(:, cbinIdx);
                csdData.ts = tData.ts(1, cbinIdx);
                                
                count = 1; % ??
                for ch = 3:size(tData.volts, 1)
                    csdData.data(count, :) = eegBinned(ch-2, :) ...
                        + eegBinned(ch, :) ...
                        - 2*eegBinned(ch-1, :);
                    count = count + 1;
                end
                
                pcolor(csdData.data(:, 1:20000));
                hold on;
                for coi = 1:length(xx)
                    eegT = (eegBinned(xx(coi), :).*1000) + (xx(coi)+1);
                    plot(eegT(1:20000), 'r');
                end
            end
            
            
            %imagesc(csdData.data(:, 1:20000));
            
        end
    end
end