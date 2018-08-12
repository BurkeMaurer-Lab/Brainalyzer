function Brain_PreProcess(inDir1, inDir2, outDir, blockID)

    clc;
    
    %Necessary Constants 
    % -cmPERpix
    %    *Centimeter's per pixel count. Necessary for velocity and
    %    acceleration data
    cmPERpix = 0.27125;
    
    % -inputDir4TDT
    %    *Directory where raw TDT files are stored (.tev)
    inputDir4TDT = [inDir1, blockID, '\'];
    
    % -inputDir4RSV
    %    *Directory where raw RS4 files are stored (.sev)
    inputDir4RS4 = [inDir2, blockID, '\'];
    
    % -blockDir
    %    *Output directory for all files associated with this block
    blockDir = [outDir, delim_dash{1}, '\', delim_dash{2}, '-', delim_dash{3}];
    
    % -outputDir
    %    *Output directory where all files associated with this function
    %    will be saved
    outputDir = [blockDir, '\01 - PreProcessed\'];
    
    
    
    