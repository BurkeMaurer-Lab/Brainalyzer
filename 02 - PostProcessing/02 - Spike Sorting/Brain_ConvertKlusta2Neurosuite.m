function Brain_ConvertKlusta2Neurosuite(basepath,basename)
% Converts .kwik/kwx files from Klusta into klusters-compatible
% fet,res,clu,spk files.  Works on a single shank of a recording, assumes a
% 16bit .dat and an .xml file is present in "basepath" (home folder) and
% that they are named basename.dat and basename.xml.  Also assumes that
% subdirectories in that basepath are made for each shank with names
% specified by numbers (ie 1,2,3,4..8).  In each shank folder should be
% .kwik and .kwx files made by klusta with names as follows:
% basename_sh[shankumber].kwik/kwx.  This
%
% Inputs:
% shank - the shank number (as a number, not text) equalling the name of
% the folder under basepath with the data of interst.  Default = 1.
% basepath - directory path to the main recording folder with .dat and .xml
% as well as shank folders made by makeProbeMapKlusta2.m (default is
% current directory matlab is pointed to)
% basename - shared file name of .dat and .xml (default is last part of
% current directory path, ie most immediate folder name)
%
% Brendon Watson 2016

    if ~exist('shank','var')
        shank = 1;
    end
    if ~exist('basepath','var')
        [~,basename] = fileparts(cd);basepath = cd;
    end

    datpath = strcat(basepath,'\',basename, '.dat');


    % [~,shank]=fileparts(basepath);
    tkwik = strcat(basepath,'\', basename, '.kwik');
    tkwx = strcat(basepath, '\', basename, '.kwx');
    clu = h5read(char(tkwik),'/channel_groups/0/spikes/clusters/main');
    cluster_names = unique(clu);

    totalch = uint64(h5readatt(char(tkwik),'/application_data/spikedetekt','n_channels'));
    sbefore = uint64(h5readatt(char(tkwik),'/application_data/spikedetekt','extract_s_before'));
    safter = uint64(h5readatt(char(tkwik),'/application_data/spikedetekt','extract_s_after'));
    channellist = uint64(h5readatt(char(tkwik),'/channel_groups/0','channel_order')+1);

    %% Getting spiketimes
    spktimes = h5read(char(tkwik),'/channel_groups/0/spikes/time_samples');
    % spktimes = spktimes(1:10);

    %% From Azahara: setting noise as 0 and MUA as 1
    % Code that klustaviewa uses: 0 = noise, 1 = MUA, 2 = good
    for ind = 1:length(cluster_names)
        %disp(cluster_names(ind));
        %when some files were corrupted I was able to still read them
        %with this, not sure if all the corruption are like this one...
        kk=h5readatt(char(tkwik),['/channel_groups/0/clusters/main/' num2str(cluster_names(ind))],'cluster_group');
        cluster_group(ind) = kk(1,1);
        clear kk
    
        if cluster_group(ind) == 0 %NOISE
            %spkts(find(clu==cluster_names(ind))) = []; %this option just if I want to remove the 0
            %waveform(:,:,find(clu==cluster_names(ind))) = [];
            %features(:,:,find(clu==cluster_names(ind))) = [];
            clu(find(clu==cluster_names(ind))) = 0;
        elseif cluster_group(ind) == 1 %MUA
            clu(find(clu==cluster_names(ind))) = 1;
        end
    end
    clear ind cluster_group

    %% spike extraction from dat
    dat=memmapfile(char(datpath),'Format','int16'); %Map the data file
    tsampsperwave = (sbefore+safter); %(16 + 16) = 32
%     ngroupchans = length(channellist);%(11) = 11
%     valsperwave = tsampsperwave * ngroupchans;%(32*11) = 352
%     wvforms_all=zeros(length(spktimes)*tsampsperwave*ngroupchans,1,'int16'); %Vector with 248662spikes*32timepoints*11channels
%     wvranges = zeros(length(spktimes),ngroupchans); %Array with 11 channels x 248662 spikes
    valsperwave = tsampsperwave * totalch;%(32*11) = 352
    wvforms_all=zeros(length(spktimes)*tsampsperwave*totalch,1,'int16'); %Vector with 248662spikes*32timepoints*11channels
    wvranges = zeros(length(spktimes),totalch); %Array with 11 channels x 248662 spikes
    wvpowers = zeros(1,length(spktimes)); %Vector with 248662spikes
    for j=1:length(spktimes) %For every spike
        try
            w = dat.data((uint64(spktimes(j))-sbefore).*totalch+1:(uint64(spktimes(j))+safter).*totalch);
            %w = dat.data((double(spktimes(j))-16).*11+1:(double(spktimes(j))+16).*11);
            wvforms=reshape(w,totalch,[]); %Reshapae w into an array with 11 rows
            %select needed channels
%             wvforms = wvforms(channellist,:);
            %         % detrend
            %         wvforms = floor(detrend(double(wvforms)));
            % median subtract
            wvforms = wvforms - repmat(median(wvforms')',1,sbefore+safter);
            wvforms = wvforms(:);
        catch
            disp(['Error extracting spike at sample ' int2str(double(spktimes(j))) '. Saving as zeros']);
            disp(['Time range of that spike was: ' num2str(double(spktimes(j))-sbefore) ' to ' num2str(double(spktimes(j))+safter) ' samples'])
            wvforms = zeros(valsperwave,1);
        end
    
        %some processing for fet file
%         wvaswv = reshape(wvforms,tsampsperwave,ngroupchans);
        wvaswv = reshape(wvforms,tsampsperwave,totalch);
        wvranges(j,:) = range(wvaswv);
        wvpowers(j) = sum(sum(wvaswv.^2));
    
%         lastpoint = tsampsperwave*ngroupchans*(j-1);
        lastpoint = tsampsperwave*totalch*(j-1);
        wvforms_all(lastpoint+1 : lastpoint+valsperwave) = wvforms;
        %     wvforms_all(j,:,:)=int16(floor(detrend(double(wvforms)')));
        if rem(j,50000) == 0
            disp([num2str(j) ' out of ' num2str(length(spktimes)) ' done'])
        end
    end
    clear dat
    wvranges = wvranges';

    %% Spike features
    fets = h5read(char(tkwx),['/channel_groups/' num2str(0) '/features_masks']);
    fets = double(squeeze(fets(1,:,:)));
    %mean activity per spike
    fetmeans = mean(fets,1);
    %find first pcs, make means of those...
    %NMD 10/21/18 This needs to change to a dynamic variable. Shouldn't be
    %hard-coded
    featuresperspike = 3;
    firstpcslist = 1:featuresperspike:size(fets,1);
    firstpcmeans = mean(fets(firstpcslist,:),1);

    nfets = size(fets,1)+1;
    fets = cat(1,fets,fetmeans,firstpcmeans,wvpowers,wvranges,double(spktimes'));
    fets = fets';
    % fets = cat(1,nfets,fets);


    %% writing to clu, res, fet, spk
    cluname = strcat(basepath,'\', basename, '.clu.1');
    resname = strcat(basepath,'\', basename, '.res.1');
    fetname = strcat(basepath,'\', basename, '.fet.1');
    spkname = strcat(basepath,'\', basename, '.spk.1');

    %clu
    % if ~exist(cluname,'file')
    clu = cat(1,length(unique(clu)),double(clu));
    fid=fopen(char(cluname),'w');
    %     fprintf(fid,'%d\n',clu);
    fprintf(fid,'%.0f\n',clu);
    fclose(fid);
    clear fid
    % end

    %res
    fid=fopen(char(resname),'w');
    % fprintf(fid,'%d\n',spktimes);
    fprintf(fid,'%.0f\n',spktimes);
    fclose(fid);
    clear fid


    %fet
    Brain_SaveFetIn(char(fetname),fets);
    % dlmwrite(fetname,nfets)
    % dlmwrite(fetname,fets,'-append')
    % % fid=fopen(fetname,'w');
    % % fprintf(fid,'%i\n',nfets);
    % % for a = 1:size(fets,1)
    % %     fprintf(fid,'% i\n',fets(a,:));
    % % end
    % % fclose(fid);
    % % clear fid


    %spk
    fid=fopen(char(spkname),'w');
    fwrite(fid,wvforms_all,'int16');
    fclose(fid);
    clear fid
end