function blocks2analyze = Brain_FetchBlocksToAnalyze(inDir, ratNum, analysis)

    tasks = {'\01 - PreProcessed\', '\02 - Noise Reduction\'};
    
    blocks.names = [];
    blocks.status = [];

    %----------------------------------------------------------%
    %----------------------------------------------------------%
    %                          STEP 1                          %
    %                                                          %
    %  First, we read in all folder names in the directory to  %
    % find the folder that corresponds to the rat we wish to   %
    % analyze. Then, locate all analyzed blocks for that rat   %
    % and save that name                                       %
    %                                                          %
    %  ASSUMPTIONS:                                            %
    %    1) Folders for each rat are saved as 'ratNum' only,   %
    %        or start with 'ratNum', an underscore, and other  %
    %        information (ie, 713 or 648_CamKII)               %
    %----------------------------------------------------------%
    %----------------------------------------------------------%
    
    status_Unprocessed = 1;
    status_Processed = 2;
    folders = dir(inDir);
    
    for i = 1:length(folders)
        delim_under = strsplit(folders(i).name, '_'); %delim_under{1} will always be rats number/id
        if strcmp(delim_under{1}, num2str(ratNum))
            ratID = folders(i).name;
        end
    end
    clear folders;
    
    files = dir([inDir, ratID, '\']);
    for i = 1:length(files)
        delim_dash = strsplit(files(i).name, '-'); %delim_dash{1} is date, delim_dash{2} is time of folder
        %checkDir = [inDir, ratID, '\', files(i).name, '\'];
        blocks.names = [blockNames; files(i).name];
    end
    
    for i = 1:size(blocks.names, 1)
        preDir = [inDir, ratID, '\', blocks.names(i, :), tasks{1}];
        taskDir = [inDir, ratID, '\', blocks.names(i, :), tasks{analysis}];
    
        cprintf('text', ['  (', num2str(i), ')  ']);
        cprintf('magenta', ['Block ', blocks.names(i, :), ':  ']);
        
        if exist(preDir, 'dir') == 7
            cprintf('comment', 'Processed\n');
            blocks.status(i) = status_Processed;
        else
            cprintf('err', 'Unprocessed\n');
            blocks.status(i) = status_Unprocessed;
        end
    end
    
    
    %----------------------------------------------------------%
    %----------------------------------------------------------%
    %                          STEP 2                          %
    %                                                          %
    %  Next, analyze the block names to see which blocks are   %
    % processed and 'ready' for the analysis we wish to run.   %
    % If no blocks were found, return error. Display each      %
    % blocks status (processed or unprocessed) to the user     %
    %                                                          %
    %                                                          %
    %  ASSUMPTIONS:                                            %
    %    1) Next function that runs the analysis will see      %
    %        which epochs have been run and which haven't      %
    %----------------------------------------------------------%
    %----------------------------------------------------------%
    
    if size(blockNames, 1) == 0
        cprintf('err', 'Error:\n');
        cprintf('text', 'No blocks for ');
        cprintf('comment', ['Rat ', num2str(ratNum)]);
        cprintf('text', ' were found in the directory\n');
        return
    else
        cprintf('key', [num2str(size(blocks.name, 1)), ' Blocks']);
        cprintf('text', ' found for ');
        cprintf([0, 0.75, 0.75], ['Rat ', num2str(ratNum), '\n']);
    end
    
    
    %----------------------------------------------------------%
    %----------------------------------------------------------%
    %                          STEP 3                          %
    %                                                          %
    %  Next, ask user which blocks they would like to analyze  %
    % from all blocks. Currently accounts for user inputing    %
    % values above the highest block value, and more values    %
    % there are blocks. No other verification / idiot proofing %
    %                                                          %
    %                                                          %
    %  ASSUMPTIONS:                                            %
    %    1) User isn't an idiot and inputs values of blocks    %
    %        properly. IE, no extra spaces between values, no  %
    %        spaces before the first rat value, etc.           %
    %    2) User does not want to run analysis on unprocessed  %
    %        blocks                                            %
    %                                                          %    
    %  FUTURE GOALS:                                           %
    %    1) Allow user to input 'all' if they wish to analyze  %
    %        all processed and unanalyzed blocks               % 
    %----------------------------------------------------------%
    %----------------------------------------------------------%
    
    ansr = input('\n\nPlease list the numbers of the blocks you wish to analyze (with spaces in between)\nOr enter "all" to analyze every block\n', 's');
    cprintf('text', '\n');
    delim_space = strsplit(ansr, ' ');
    if size(delim_space, 2) > size(blocks.name, 1)
        clc;
        cprintf('*err', 'ERROR:\n');
        cprintf('err', 'The number of values entered is larger than the number of blocks\n');
        return;
    elseif max(str2double(delim_space)) > size(blocks.name, 1)
        clc;
        cprintf('*err', 'ERROR:\n');
        cprintf('err', 'One of the values entered is too high\n');
        return;
    end
    
    blocks2analyze = ""; %Creates empty matrix for strings
    j = 1;
    for i = 1:size(delim_space, 2)
        block_id = str2double(delim_space{i});
        if blocks.names(block_id) == status_Unprocessed
            %cprintf('*err', 'ERROR:\n');
            cprintf('err', ['Block ', blocks.names(block_id), ' has not been processed and can not be analyzed\n']);
        else
            blocks2analyze(j) = blocks.names(block_id);
            j = j + 1;
        end
    end
end