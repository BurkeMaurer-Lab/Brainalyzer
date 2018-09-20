%NMD 9/17/18 This does actually get a little annoying when doing multiple.
%Also, if you make a mistake it returns an error instead of asking for your
%input again, so you have to start over.
function blocks2process = Brain_FetchBlocksToProcess(inDir, ratNum)

    task = '\01 - PreProcessed\';

    blocks.names = [];
    blocks.times = [];
    blocks.status = [];

    %----------------------------------------------------------%
    %----------------------------------------------------------%
    %                          STEP 1                          %
    %                                                          %
    %  First, we read in all blocks in the "in" directory that %
    % are associated with the rat ID given as ratNum parameter %
    % Display "ERROR" if no blokcs found                       %
    %                                                          %
    %  ASSUMPTIONS:                                            %
    %    1) Blocks are in typical TDT Syntax (name-date-time)  %
    %    2) The 'name' portion is only the rat's number, or    %
    %        has the rat's number followed by an underscore    %
    %        preceeding additional info (648_CamKII-date-time) %
    %    3) inDir is directory where all blocks arew stored,   %
    %        ie, no additional folders or directories to parse % 
    %----------------------------------------------------------%
    %----------------------------------------------------------%
    
    files = dir(inDir);
    
    for i = 1:length(files)
        delim_dash = strsplit(files(i).name, '-');
        delim_under = strsplit(delim_dash{1}, '_');
        if strcmp(delim_under{1}, ratNum)
            ratID = delim_dash{1};
            blocks.names = [blocks.names; files(i).name];
            blocks.times = [blocks.times; [delim_dash{2}, '-', delim_dash{3}]];
        end
    end
    
    if size(blocks.names, 1) == 0
        cprintf('err', 'Error:\n');
        cprintf('text', 'No blocks for ');
        cprintf('comment', ['Rat ', ratNum]);
        cprintf('text', ' were found in the directory\n');
        return
    else
        cprintf('key', [num2str(size(blocks.names, 1)), ' Blocks']);
        cprintf('text', ' found for ');
        cprintf([0, 0.75, 0.75], ['Rat ', ratNum, '\n']);
    end
    
    
    %----------------------------------------------------------%
    %----------------------------------------------------------%
    %                          STEP 2                          %
    %                                                          %
    %  Next, display all available blocks for processing, and  %
    % their current state (processed, unprocessed). Ask the    %
    % user which blocks they would like to process             %
    %                                                          %
    %  ASSUMPTIONS:                                            %
    %    1) Only errors accounted for are user inputing block  %
    %        value that is too high or entering too many values%
    %----------------------------------------------------------%
    %----------------------------------------------------------%
    clc;
    
    for i = 1:size(blocks.names, 1)
        tempDir = [inDir, ratID, '\', blocks.times(i), task];
        cprintf('text', ['  (', sprintf('%02d', i), ')  ']);
        cprintf('magenta', ['Block ', blocks.names(i, :), ': ']);
        
        if exist(tempDir, 'dir') == 7
            cprintf('comment', 'Processed\n');
        else
            cprintf('err', 'Unprocessed\n');
        end
    end
        
    ansr = input('\nPlease list the numbers of the blocks you wish to analyze (with spaces in between)\nOr enter "all" to analyze every block\n', 's');
    if string(ansr) == "all"
        blockVec = 1:size(blocks.names, 1);
    else
        delim_space = strsplit(ansr, ' ');
        if size(delim_space, 2) > size(blocks.names, 1)
            clc;
            cprintf('*err', 'Error:\n');
            cprintf('err', 'The number of values entered is larger than the number of blocks\n');
            return
        elseif max(str2double(delim_space)) > size(blocks.names, 1)
            clc;
            cprintf('*err', 'ERROR:\n');
            cprintf('err', 'One of the values entered is too high\n');
            return;
        end
        blockVec = str2double(delim_space);
    end
    
    
    
    %----------------------------------------------------------%
    %----------------------------------------------------------%
    %                          STEP 3                          %
    %                                                          %
    %  Next, take user input and save only which blocks user   %
    % specified for analysis. This new matrix of names is then %
    % saved and output as 'blocks2process'                     %
    %                                                          %
    %  ASSUMPTIONS:                                            %
    %    - None                                                %
    %----------------------------------------------------------%
    %----------------------------------------------------------%
    
    blocks2process = ""; %Creates empty matrix for strings
    
    for i = 1:length(blockVec)
        blocks2process(i) = blocks.names(blockVec(i), :);
    end
    
end