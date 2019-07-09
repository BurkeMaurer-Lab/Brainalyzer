function numGood = Brain_CreateGeomFile(outDir, badChannels, prbType, mapType, shank_number)
    %Remember that this version of the code deals with a specific shank
    %only. 
    
    geomChanStart = 0;
 
    availablePrbs = {'Cam_eSeries64', 'Cam_fSeries64'};
    availableMaps = {'Linear', 'UShaped', 'General'};
    
    validStrPrb = validatestring(prbType, availablePrbs);
    validStrMap = validatestring(mapType, availableMaps);
    
    tempDir = which('Brainalyzer_Start');
    homeSplit = strsplit(tempDir, 'Brainalyzer_Start');
    homeDir = [homeSplit{1}, '\00 - Interface\Constants\'];
    
    temp = load([homeDir, validStrPrb, '.mat']);
    shankSett = temp.(validStrMap);
    clear temp;
    
    
    i = shank_number;
    currShank = shankSett.Shank(i);
    adjacent = [];
    
    
    totSites = size(currShank.Site, 2); %number of channels
    numGood = currShank.Site(totSites).Number - (currShank.Site(1).Number-1) - ...
        sum(ismember(currShank.Site(1).Number:currShank.Site(totSites).Number, badChannels));
    
    badSites = [];
    badIDs = [];
    for j = 1:totSites
        if any(currShank.Site(j).Number == badChannels(:))
            badSites = [badSites, j];
            badIDs = [badIDs, currShank.Site(j).ID];
        end
    end
    
    prbFile = fopen([char(outDir) '\geom.prb'], 'wt');
    fprintf(prbFile, 'channel_groups = {\n');
    fprintf(prbFile, '\t# Shank Index.\n');
    fprintf(prbFile, '\t0:\n\t\t{\n');
    fprintf(prbFile, '\t\t\t# List of channels to keep for spike detection.\n');
    fprintf(prbFile, '\t\t\t''channels'': [');
    for siteIdx=1:length(currShank.Site)
        if ismember(currShank.Site(siteIdx).ID, badIDs)==0 %If the channel is a good channel
            if geomChanStart; fprintf(prbFile, ', '); end
            fprintf(prbFile, '%d', currShank.Site(siteIdx).ID);
            if ~geomChanStart; geomChanStart = 1; end
        end
    end
    fprintf(prbFile, ']');
    fprintf(prbFile, ',\n\n');
    fprintf(prbFile, '\t\t\t# Adjacency graph. Dead channels will be automatically discarded\n');
    fprintf(prbFile, '\t\t\t# by considering the corresponding subgraph.\n');
    fprintf(prbFile, '\t\t\t''graph'': [\n');
    
    %  First, go through Adjacent_ID list and get all adjacencies without
    %adding duplicates to list
    badIDs = [];
    badSites = [];
    
    for j = 1:size(currShank.Site, 2)
        val_1 = currShank.Site(j).ID;
        for k = 1:size(currShank.Site(j).Adjacent_ID, 2)
            val_2 = currShank.Site(j).Adjacent_ID(k);
            
            if val_1 ~= val_2
                to_analyze = [val_1, val_2];
                [v1FND_r, ~] = find(adjacent == val_1);
                if isempty(v1FND_r)
                    if ~any(ismember(badIDs, (to_analyze)))
                        adjacent = [adjacent; to_analyze];
                    end
                else
                    checker = 0;
                    for ii = 1:size(v1FND_r, 2)
                        if checker == 0
                            to_compare = adjacent(v1FND_r(ii), :);
                            finder = ismember(to_compare, val_2);
                            if any(finder(:), 1)
                                checker = 1;
                            end
                        end
                    end
                    
                    if ~checker
                        
                        if ~any(ismember(badIDs, (to_analyze)))
                            adjacent = [adjacent; to_analyze];
                        end
                    end
                end
            end
        end
    end
    
    % Sort adjacent array into numerical order
    adjacent = sort(adjacent, 2);
    adjacent = sortrows(adjacent);
    
    adjacent = unique(adjacent, 'rows');
    
    % Print adjacencies
    for j = 1:size(adjacent, 1)
        fprintf(prbFile, ['\t\t\t\t\t\t(', num2str(adjacent(j, 1)), ', ', num2str(adjacent(j, 2)), '),\n']);
    end
    
    fprintf(prbFile, '\t\t\t],\n\n');
    fprintf(prbFile, '# 2D positions of channels, only for visualization purposes\n');
    fprintf(prbFile, '# in Klustaviewa. The unit does not matter.\n');
    fprintf(prbFile, '''geometry'': {\n');
    
    for j = 1:size(currShank.Site, 2)
        if ~any(ismember(badChannels, currShank.Site(j).Number))
            fprintf(prbFile, ['\t\t\t\t\t\t', num2str(currShank.Site(j).ID), ': (']);
            fprintf(prbFile, [num2str(currShank.Site(j).Geo.x), ', ', num2str(currShank.Site(j).Geo.y)]);
            fprintf(prbFile, '),\n');
        end
    end
    
    
    %Scan geometry here
    
    fprintf(prbFile, '\t\t\t}\n');
    fprintf(prbFile, '\t\t}\n');
    fprintf(prbFile, '}');
    fclose(prbFile);
end


%         pbrName = ['shank', sprintf('%02d', i), '.prb'];
%         pbrFile = fopen([outDir, '\', pbrName], 'w');
%         fprintf(pbrFile, 'channel_groups = {\n');
%         fprintf(pbrFile, '\t# Shank Index.\n');
%         fprintf(pbrFile, '\t0:\n\t\t{\n');
%         fprintf(pbrFile, '\t\t\t# List of channels to keep for spike detection.\n');
%         fprintf(pbrFile, ['\t\t\t''channels'': list(range(', num2str(sum(not(isnan(shankSett.shankMap{i}(:))))), ')),\n\n']);
%         fprintf(pbrFile, '\t\t\t# Adjacency graph. Dead channels will be automatically discarded\n');
%         fprintf(pbrFile, '\t\t\t# by considering the corresponding subgraph.\n');
%         fprintf(pbrFile, '\t\t\t''graph'': [\n');


%         adj_i = 1;
%
%         for row = 1:r
%             for col = 1:c
%                 %if shankHolder(row, col) == 0
%                 %    break;
%                 %end
%
%                 currVal = shankSett.shankMap{i}(row, col);
%                 %if isnan(currVal)
%                 %    col = max(c, col);
%                 %    if c == col
%                 %        break;
%                 %    end
%                 %end
%
%                 poss_i = 1;
%
%                 possVal = [];
%
%                 row1 = max(1, row-1);
%                 row2 = min(r, row+1);
%                 col1 = max(1, col-1);
%                 col2 = min(c, col+1);
%                 square = shankSett.shankMap{i}(row1:row2, col1:col2);
%                 for sqr_r = 1:size(square, 1)
%                     if isnan(currVal)
%                         break;
%                     end
%                     for sqr_c = 1:size(square, 2)
%                         if currVal ~= square(sqr_r, sqr_c) && isnan(square(sqr_r, sqr_c)) == 0
%                             possVal(poss_i, :) = [currVal, square(sqr_r, sqr_c)];
%                             poss_i = poss_i + 1;
%                         end
%                     end
%                 end
%
%                 [indc_r, ~] = find(adjacent == currVal);
%                 %indc_r = indc_r + adj_i - 1;
%                     %for cnt_curr = 1:length(indc_r)
%                 if isempty(indc_r)
%                     adjacent = [adjacent; possVal];
%                     %(adj_i:size(possVal, 1), :) = possVal(:, :);
%                     adj_i = adj_i + size(possVal, 1);
%                 else
%                     checker = 0;
%                     %analyzing = possVal(poss_r, :);
%
%                     for poss_r = 1:size(possVal, 1)
%                         checker = 0;
%                         analyzing = possVal(poss_r, :);
%
%                         for cnt_indc = 1:size(indc_r, 1)
%                             comparing = adjacent(indc_r(cnt_indc), :);
%                             if possVal(poss_r, 2) ~= currVal
%                                 if checker == 0
%                                     voi = analyzing(1, 2);
%                                     rr = ismember(comparing, voi);
%                                     if any(rr(:), 1)
%                                         checker = 1;
%                                     end
%                                 end
%                             end
%                         end
%
%                         if ~checker
%                             adjacent = [adjacent; possVal(poss_r, :)];
%                         %(adj_i, :) = possVal(poss_r, :);
%                         %adj_i = adj_i + 1;
%                         end
%                     end
%
%
%
%                 end
%
%             end
%         end
%
%         adjacent = sort(adjacent, 2);
%         adjacent = sortrows(adjacent);
%

%         if ~isempty(badChannels)
%             for k = 1:size(adjacent, 1)
%                 %for j = 1:size(badChannels, 2)
%                     tt = ismember(adjacent(k, :), badChannels(:));
%                     if ~any(tt(:), 1)
%                         fprintf(pbrFile, ['\t\t\t\t\t\t(', num2str(adjacent(k, 1)), ', ', num2str(adjacent(k, 2)), '),\n']);
%                     end
%                 %end
%             end
%         else
%             for k = 1:size(adjacent, 1)
%                 fprintf(pbrFile, ['\t\t\t\t\t\t(', num2str(adjacent(k, 1)), ', ', num2str(adjacent(k, 2)), '),\n']);
%             end
%         end