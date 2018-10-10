function xmlGenerator(destinationFolder, data_name, numberChannels, samplingFrequency)

    xmlFile = fopen([char(destinationFolder) '\' char(data_name) '.xml'],'wt');
    fprintf(xmlFile, '<?xml version=''1.0''?><parameters version="1.0" creator="ndManager-"> <generalInfo>');
    fprintf(xmlFile, [' <date>' datestr(now,'yyyy-mm-dd') '</date>']);
    fprintf(xmlFile, '  <experimenters>Burke-Maurer</experimenters>');
    fprintf(xmlFile, '  <description/>');
    fprintf(xmlFile, ' <notes/>  </generalInfo> <acquisitionSystem>');
    fprintf(xmlFile, ' <nBits>16</nBits>');
    fprintf(xmlFile, ' <nChannels>%d</nChannels>', numberChannels);
    fprintf(xmlFile, '  <samplingRate>%d</samplingRate>', samplingFrequency);
    fprintf(xmlFile, '  <voltageRange>10</voltageRange>');
    fprintf(xmlFile, ' <amplification>1000</amplification>');
    fprintf(xmlFile, ' <offset>0</offset>');
    fprintf(xmlFile, ' </acquisitionSystem>');
    fprintf(xmlFile, ' <fieldPotentials>');
    fprintf(xmlFile, '  <lfpSamplingRate>6000</lfpSamplingRate>');
    fprintf(xmlFile, ' </fieldPotentials>');
    fprintf(xmlFile, ' <anatomicalDescription>  <channelGroups>   <group>');
    for channel = 0:numberChannels-1
        fprintf(xmlFile, '    <channel skip="0">%d</channel>', channel);
    end
    fprintf(xmlFile, '   </group>  </channelGroups> </anatomicalDescription>');
    fprintf(xmlFile, ' <spikeDetection>  <channelGroups>   <group>    <channels>');
    for channel = 0:numberChannels-1
        fprintf(xmlFile, '     <channel>%d</channel>', channel);
    end
    fprintf(xmlFile, '    </channels>');
    fprintf(xmlFile, '    <nSamples>32</nSamples>');
    fprintf(xmlFile, '    <peakSampleIndex>16</peakSampleIndex>');
    fprintf(xmlFile, '    <nFeatures>3</nFeatures>');
    fprintf(xmlFile, '   </group>  </channelGroups> </spikeDetection>');
    fprintf(xmlFile, ' <units/> <neuroscope version="1.2.5">');
    fprintf(xmlFile, '  <miscellaneous>');
    fprintf(xmlFile, '   <screenGain>0.200000</screenGain> ');
    fprintf(xmlFile, '  <traceBackgroundImage></traceBackgroundImage>');
    fprintf(xmlFile, '  </miscellaneous>');
    fprintf(xmlFile, '  <video>   <rotate>0</rotate>   <flip>0</flip>   <videoImage></videoImage>   <positionsBackground>0</positionsBackground>  </video>');
    fprintf(xmlFile, '  <spikes>');
    fprintf(xmlFile, '   <nSamples>32</nSamples> ');
    fprintf(xmlFile, '  <peakSampleIndex>16</peakSampleIndex>');
    fprintf(xmlFile, '  </spikes>');
    fprintf(xmlFile, '  <channels>');
    for channel= 0:numberChannels-1
        fprintf(xmlFile, '   <channelColors>    <channel>%d</channel>    <color>#0080ff</color>    <anatomyColor>#0080ff</anatomyColor>    <spikeColor>#0080ff</spikeColor>   </channelColors>   <channelOffset>    <channel>%d</channel>    <defaultOffset>0</defaultOffset>   </channelOffset>', channel, channel);
    end
    fprintf(xmlFile, '  </channels> </neuroscope>');
    fprintf(xmlFile, ' <programs>');

    % ndm_extractspikes
    fprintf(xmlFile, '  <program>');
    fprintf(xmlFile, '   <name>ndm_extractspikes</name>');
    fprintf(xmlFile, '   <parameters>');
    fprintf(xmlFile, '    <parameter>     <name>thresholdFactor</name>     <value>1.5</value>     <status>Mandatory</status>    </parameter>');
    fprintf(xmlFile, '    <parameter>     <name>refractoryPeriod</name>    <value>16</value>     <status>Mandatory</status>    </parameter>');
    fprintf(xmlFile, '    <parameter>     <name>peakSearchLength</name>     <value>32</value>     <status>Mandatory</status>    </parameter>');
    fprintf(xmlFile, '    <parameter>     <name>start</name>     <value>0</value>     <status>Mandatory</status>    </parameter>');
    fprintf(xmlFile, '    <parameter>     <name>duration</name>     <value>60</value>     <status>Mandatory</status>    </parameter>');
    fprintf(xmlFile, '   </parameters>');
    fprintf(xmlFile, '   <help>Extract spikes from high-pass filtered .fil file (this creates .res and .spk files).First, the program automatically computes a baseline ''noise'' level, using a subset of the data. Then, spikes are extracted whenever the signal crosses a threshold proportional to the baseline ''noise'' level. To avoid spurious detections, the signal must have a local maximum (or minimum, depending on the sign of the signal) within a fixed search window starting at threshold crossing. Also, the duration between consecutive spikes must be greater than a fixed ''refractory'' period. PARAMETERS # thresholdFactor Threshold = thresholdFactor * baseline ''noise'' level # refractoryPeriod Number of samples to skip after a spike, before trying to detect a new spike # peakSearchLength Length of the peak search window (in number of samples) # start Starting point in the file (in s) for computation of baseline ''noise'' level # duration Duration (in s) for computation of baseline ''noise'' level </help>');
    fprintf(xmlFile, '  </program>');

    % ndm_hipass program
    fprintf(xmlFile, '  <program>');
    fprintf(xmlFile, '   <name>ndm_hipass</name>');
    fprintf(xmlFile, '   <parameters>');
    fprintf(xmlFile, '    <parameter>     <name>windowHalfLength</name>     <value>10</value>     <status>Mandatory</status>    </parameter>');
    fprintf(xmlFile, '   </parameters>');
    fprintf(xmlFile, '   <help>High-pass filter a .dat file (required for spike extraction). The program uses a median-based (non-linear) filter to minimize spike waveform distortion. PARAMETERS # windowHalfWidth Determines the cutoff frequency </help>');
    fprintf(xmlFile, '  </program>');

    % ndm_pca program
    fprintf(xmlFile, '  <program>');
    fprintf(xmlFile, '   <name>ndm_pca</name>');
    fprintf(xmlFile, '   <parameters/>');
    fprintf(xmlFile, '   <help>Compute principal component analysis (PCA). PARAMETERS All parameters are defined in the ''Acquisition System'' and ''Spike Groups'' tab. </help>');
    fprintf(xmlFile, '   </program>');
    
    % ndm_start program
    fprintf(xmlFile, '  <program>');
    fprintf(xmlFile, '   <name>ndm_start</name>');
    fprintf(xmlFile, '   <parameters>');
    fprintf(xmlFile, '    <parameter>     <name>suffixes</name>     <value/>     <status>Mandatory</status>    </parameter>');
    fprintf(xmlFile, '   </parameters>');
    fprintf(xmlFile, '   <help>Perform all processing steps for a multiple sets of multiple-session recordings: format conversion, channel extraction and reordering, video transcoding and tracking, data concatenation, spike detection and extraction, etc. PARAMETERS # suffixes List of suffixes for the individual files to convert OPTIONAL PARAMETERS Note: To keep the interface simpler, optional parameters have default values and are not listed in the ''Parameters'' tab; to choose custom values, click the ''Add'' button and manually add the required parameters (and custom values) to the list. # wideband Process the wideband data files recorded by the acquisition system: convert to .dat format, resample, merge, extract and reorder channels (default = true) # video Process video files recorded by the acquisition system: transcode and extract LEDs (default = true) # events Process event files recorded by the acquisition system: convert to .evt format and rename events (default = true) # spikes Process spikes: detect and extract spike waveforms, perform PCA (default = true) # lfp Downsample wideband signals to produce LFP files (default = true) # clean Remove intermediate files after pre-processing is complete (default = false)</help>');
    fprintf(xmlFile, '  </program>');
    fprintf(xmlFile, ' </programs>');
    fprintf(xmlFile, '</parameters>');
    fclose(xmlFile);
    
end