function Brain_PowerSpectralDensity(direct, waves, epochs, vbin)

    inDir = [direct, '01 - PreProcessed\'];
    outDir = [direct, '05 - Power Spectral Density\'];
    
    xx = [9, 16, 23];
    
    if ~exist(outDir, 'dir'), mkdir(outDir), end
    
    for waveIdx = 1:size(waves, 1)
        objectStr = [waves{waveIdx, 1}, '_data.mat'];
        
        for epochIdx = 1:size(epochs, 2)
            waveObject = matfile([inDir, objectStr]);
            tData = waveObject.(epochs{waveIdx, epochIdx});
            tData.fs = waveObject.fs;
            clear waveObject;
            
            binIDXs = discretize(tData.vel(1, :), vbin);
            
            [~, f, ~, ~] = spectrogram(tData.volts(1, :), ...
                            round(tData.fs), ...
                            round(tData.fs/2), ...
                            [], ...
                            tData.fs);
                        
            for currBin = 1:length(vbin)-1
                cbinIdx = find(binIDXs == currBin);
                eegBinned = tData.volts(:, cbinIdx);
            
                psdData.bin(currBin).ts = tData.ts(1, cbinIdx);
                psdData.bin(currBin).fs = f';
                psdData.bin(currBin).weight = length(vbin);
                
                psdAvg = [];
                for ch = 1:size(tData.volts, 1)
                    [~, fBin, tBin, ps1] = spectrogram(eegBinned(ch, :), ...
                                            round(tData.fs), ...
                                            round(tData.fs/2), ...
                                            [], ...
                                            tData.fs);
                                        
                    chAvg = mean(ps1, 2);
                    psdAvg = [psdAvg, chAvg];
                    powerint_val(ch, :) = trapz(fBin, chAvg);
                    powerint(ch, :) = cumtrapz(fBin, chAvg);
                    
                    psdData.bin(currBin).fSpec(ch, :) = fBin;
                    psdData.bin(currBin).tSpec(ch, :) = tBin;
                    psdData.bin(currBin).pSpec.(['ch', num2str(ch)]) = ps1;
                end
                
                psdAvg = psdAvg';
                
                psdData.bin(currBin).edges = [vbin(currBin), vbin(currBin+1)];
                psdData.bin(currBin).data = psdAvg;
                psdData.bin(currBin).cdf = powerint;
                psdData.bin(currBin).int = powerint_val;
                psdData.bin(currBin).weight = length(cbinIdx);
                psdData.bin(currBin).v_vals = tData.vel(1, cbinIdx);
                psdData.bin(currBin).v_mean = mean(tData.vel(1, cbinIdx), 'omitnan');
                

            end
            
            
            for binID = 1:length(vbin)-1
                psd_avg = [];
                psd_avg = psdData.bin(binID).data;
                %psdData.bin(binID).f_bin = fBin;
                
                colorset = varycolor(32);
        
                fig(binID) = figure('units', 'normalized', 'outerposition', [0 0 0.5 1]);
                
                set(gca, 'XScale', 'log');
                set(gca, 'YScale', 'log');
                set(gca, 'ColorOrder', colorset);
                %set(gca, 'ColorMap', colorset);
                hold on;
                plot(fBin, psd_avg(:, :), 'linewidth', 1);
                ff = gca;
                ff.LineWidth = 1;
                ff.XLim = [min(fBin) max(fBin)];
                set(ff, 'ColorOrder', colorset);
                set(ff, 'ColorMap', colorset);
        
                %for iter = 1:length(xx)
                %    Legend{iter} = channel_string{iter};
                %end
                %legend(Legend)
        
                title(strcat('PSD, V = ', num2str(vbin(binID)), '-', num2str(vbin(binID+1)), ' cm/s'));
                xlabel('Frequency', 'fontsi', 16);
                ylabel('dB', 'fontsi', 16);
                axis square;
                box off;
                colorbar;
            end
            
            saveDir = [outDir, epochs{waveIdx, epochIdx}, '\'];
    
            if ~exist(saveDir, 'dir'), mkdir(saveDir), end
    
            save(strcat(saveDir, waves{waveIdx, 1}, '_PSD.mat'), '-struct', 'psdData', '-v7.3');
    
            for figureNum = 1:length(vbin)-1
                savefig(fig(figureNum), [saveDir, waves{waveIdx, 1}, '_PSDbyV-', ...
                    num2str(figureNum), '_', ...
                    num2str(vbin(figureNum)), '-', num2str(vbin(figureNum+1)), ...
                    '_.fig']);
                
                close(fig(figureNum));
            end
            
            clear psdData;
            clear tData;
        end
    end
end