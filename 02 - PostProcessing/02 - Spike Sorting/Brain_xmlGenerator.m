function xmlGenerator(destinationFolder, data_name, startChan, endChan, BadChs, samplingFrequency, lfpSamplingFrequency)
    slashLoc = regexp(char(destinationFolder), '\\|/');
    if slashLoc(end) ~= length(destinationFolder)
        destinationFolder = [destinationFolder, '\'];
    elseif strcmp(destinationFolder(end), '/')
        destinationFolder(end) = '\';
    end
    xmlFile = fopen([char(destinationFolder) char(data_name) '.xml'],'wt');
    fprintf(xmlFile, '<?xml version=''1.0''?>');
    fprintf(xmlFile, '\n<parameters version="1.0" creator="ndManager-">');
    fprintf(xmlFile, '\n <generalInfo>');
    fprintf(xmlFile, ['\n  <date>' datestr(now,'yyyy-mm-dd') '</date>']);
    fprintf(xmlFile, '\n  <experimenters>Burke-Maurer</experimenters>');
    fprintf(xmlFile, '\n  <description/>');
%     fprintf(xmlFile, '\n <notes/>  \n</generalInfo> \n<acquisitionSystem>');
    fprintf(xmlFile, '\n </generalInfo>');
    fprintf(xmlFile, '\n <acquisitionSystem>');
    fprintf(xmlFile, '\n  <nBits>16</nBits>');
    fprintf(xmlFile, '\n  <nChannels>%d</nChannels>', endChan-startChan+1);
    fprintf(xmlFile, '\n  <samplingRate>%d</samplingRate>', samplingFrequency);
    fprintf(xmlFile, '\n  <voltageRange>10</voltageRange>');
    fprintf(xmlFile, '\n  <amplification>1000</amplification>');
    fprintf(xmlFile, '\n  <offset>0</offset>');
    fprintf(xmlFile, '\n </acquisitionSystem>');
    fprintf(xmlFile, '\n <fieldPotentials>');
    fprintf(xmlFile, '\n  <lfpSamplingRate>%.2f</lfpSamplingRate>', lfpSamplingFrequency);
    fprintf(xmlFile, '\n </fieldPotentials>');
    fprintf(xmlFile, '\n <anatomicalDescription>');
    fprintf(xmlFile, '\n  <channelGroups>');
    fprintf(xmlFile, '\n   <group>');
    %Change the bad channel numbers so that they are indexed starting from
    %the starting channel
    BadChs = BadChs - startChan;
    for channel = 0:(endChan-startChan)
        if (ismember(channel, BadChs))
            fprintf(xmlFile, '\n    <channel skip="1">%d</channel>', channel);
        else
            fprintf(xmlFile, '\n    <channel skip="0">%d</channel>', channel);
        end
    end
    fprintf(xmlFile, '\n   </group>');
    fprintf(xmlFile, '\n  </channelGroups>');
    fprintf(xmlFile, '\n </anatomicalDescription>');
    fprintf(xmlFile, '\n <spikeDetection>');
    fprintf(xmlFile, '\n  <channelGroups>');
    fprintf(xmlFile, '\n   <group>');
    fprintf(xmlFile, '\n    <channels>');
    for channel = 0:(endChan-startChan)
        fprintf(xmlFile, '\n     <channel>%d</channel>', channel);
    end
    fprintf(xmlFile, '\n    </channels>');
    fprintf(xmlFile, '\n    <nSamples>32</nSamples>');
    fprintf(xmlFile, '\n    <peakSampleIndex>16</peakSampleIndex>');
    fprintf(xmlFile, '\n    <nFeatures>3</nFeatures>');
    fprintf(xmlFile, '\n   </group>');
    fprintf(xmlFile, '\n  </channelGroups>');
    fprintf(xmlFile, '\n </spikeDetection>');
    fprintf(xmlFile, '\n <units></units>');
    fprintf(xmlFile, '\n <neuroscope version="1.2.5">');
    fprintf(xmlFile, '\n  <miscellaneous>');
    fprintf(xmlFile, '\n   <screenGain>0.200000</screenGain>');
    fprintf(xmlFile, '\n   <traceBackgroundImage></traceBackgroundImage>');
    fprintf(xmlFile, '\n  </miscellaneous>');
    fprintf(xmlFile, '\n  <video>');
    fprintf(xmlFile, '\n   <rotate>0</rotate>');
    fprintf(xmlFile, '\n   <flip>0</flip>');
    fprintf(xmlFile, '\n   <videoImage></videoImage>');
    fprintf(xmlFile, '\n   <positionsBackground>0</positionsBackground>');
    fprintf(xmlFile, '\n  </video>');
    fprintf(xmlFile, '\n  <spikes>');
    fprintf(xmlFile, '\n   <nSamples>32</nSamples>');
    fprintf(xmlFile, '\n   <peakSampleIndex>16</peakSampleIndex>');
    fprintf(xmlFile, '\n  </spikes>');
    fprintf(xmlFile, '\n  <channels>');
    for channel = 0:(endChan-startChan)
        fprintf(xmlFile, '\n   <channelColors>');
        fprintf(xmlFile, '\n    <channel>%d</channel>', channel);
        fprintf(xmlFile, '\n    <color>#0080ff</color>');
        fprintf(xmlFile, '\n    <anatomyColor>#0080ff</anatomyColor>');
        fprintf(xmlFile, '\n    <spikeColor>#0080ff</spikeColor>');
        fprintf(xmlFile, '\n   </channelColors>');
        fprintf(xmlFile, '\n   <channelOffset>');
        fprintf(xmlFile, '\n    <channel>%d</channel>', channel);
        fprintf(xmlFile, '\n    <defaultOffset>0</defaultOffset>');
        fprintf(xmlFile, '\n   </channelOffset>');
    end
    fprintf(xmlFile, '\n  </channels>');
    fprintf(xmlFile, '\n </neuroscope>');
    fprintf(xmlFile, '\n <programs>');

    % ndm_extractspikes
    fprintf(xmlFile, '\n  <program>');
    fprintf(xmlFile, '\n   <name>ndm_extractspikes</name>');
    fprintf(xmlFile, '\n   <parameters>');
    fprintf(xmlFile, '\n    <parameter>\n     <name>thresholdFactor</name>\n     <value>1.5</value>\n     <status>Mandatory</status>\n    </parameter>');
    fprintf(xmlFile, '\n    <parameter>\n     <name>refractoryPeriod</name>\n     <value>16</value>\n     <status>Mandatory</status>\n    </parameter>');
    fprintf(xmlFile, '\n    <parameter>\n     <name>peakSearchLength</name>\n     <value>32</value>\n     <status>Mandatory</status>\n    </parameter>');
    fprintf(xmlFile, '\n    <parameter>\n     <name>start</name>\n     <value>0</value>\n     <status>Mandatory</status>\n    </parameter>');
    fprintf(xmlFile, '\n    <parameter>\n     <name>duration</name>\n     <value>60</value>\n     <status>Mandatory</status>\n    </parameter>');
    fprintf(xmlFile, '\n   </parameters>');
    fprintf(xmlFile, '\n   <help>Extract spikes from high-pass filtered .fil file (this creates .res and .spk files).First, the program automatically computes a baseline ''noise'' level, using a subset of the data. Then, spikes are extracted whenever the signal crosses a threshold proportional to the baseline ''noise'' level. To avoid spurious detections, the signal must have a local maximum (or minimum, depending on the sign of the signal) within a fixed search window starting at threshold crossing. Also, the duration between consecutive spikes must be greater than a fixed ''refractory'' period. PARAMETERS # thresholdFactor Threshold = thresholdFactor * baseline ''noise'' level # refractoryPeriod Number of samples to skip after a spike, before trying to detect a new spike # peakSearchLength Length of the peak search window (in number of samples) # start Starting point in the file (in s) for computation of baseline ''noise'' level # duration Duration (in s) for computation of baseline ''noise'' level </help>');
    fprintf(xmlFile, '\n  </program>');

    % ndm_hipass program
    fprintf(xmlFile, '\n  <program>');
    fprintf(xmlFile, '\n   <name>ndm_hipass</name>');
    fprintf(xmlFile, '\n   <parameters>');
    fprintf(xmlFile, '\n    <parameter>');
    fprintf(xmlFile, '\n     <name>windowHalfLength</name>');
    fprintf(xmlFile, '\n     <value>10</value>');
    fprintf(xmlFile, '\n     <status>Mandatory</status>');
    fprintf(xmlFile, '\n    </parameter>');
    fprintf(xmlFile, '\n   </parameters>');
    fprintf(xmlFile, '\n   <help>High-pass filter a .dat file (required for spike extraction). The program uses a median-based (non-linear) filter to minimize spike waveform distortion. PARAMETERS # windowHalfWidth Determines the cutoff frequency </help>');
    fprintf(xmlFile, '\n  </program>');

    % ndm_pca program
    fprintf(xmlFile, '\n  <program>');
    fprintf(xmlFile, '\n   <name>ndm_pca</name>');
    fprintf(xmlFile, '\n   <parameters></parameters>');
    fprintf(xmlFile, '\n   <help>Compute principal component analysis (PCA). PARAMETERS All parameters are defined in the ''Acquisition System'' and ''Spike Groups'' tab. </help>');
    fprintf(xmlFile, '\n  </program>');
    
    % ndm_start program
    fprintf(xmlFile, '\n  <program>');
    fprintf(xmlFile, '\n   <name>ndm_start</name>');
    fprintf(xmlFile, '\n   <parameters>');
    fprintf(xmlFile, '\n    <parameter>');
    fprintf(xmlFile, '\n     <name>suffixes</name>');
    fprintf(xmlFile, '\n     <value></value>');
    fprintf(xmlFile, '\n     <status>Mandatory</status>');
    fprintf(xmlFile, '\n    </parameter>');
    fprintf(xmlFile, '\n   </parameters>');
    fprintf(xmlFile, '\n   <help>Perform all processing steps for a multiple sets of multiple-session recordings: format conversion, channel extraction and reordering, video transcoding and tracking, data concatenation, spike detection and extraction, etc. PARAMETERS # suffixes List of suffixes for the individual files to convert OPTIONAL PARAMETERS Note: To keep the interface simpler, optional parameters have default values and are not listed in the ''Parameters'' tab; to choose custom values, click the ''Add'' button and manually add the required parameters (and custom values) to the list. # wideband Process the wideband data files recorded by the acquisition system: convert to .dat format, resample, merge, extract and reorder channels (default = true) # video Process video files recorded by the acquisition system: transcode and extract LEDs (default = true) # events Process event files recorded by the acquisition system: convert to .evt format and rename events (default = true) # spikes Process spikes: detect and extract spike waveforms, perform PCA (default = true) # lfp Downsample wideband signals to produce LFP files (default = true) # clean Remove intermediate files after pre-processing is complete (default = false)</help>');
    fprintf(xmlFile, '\n  </program>');
    fprintf(xmlFile, '\n </programs>');
    fprintf(xmlFile, '\n</parameters>');
    fclose(xmlFile);
    
end