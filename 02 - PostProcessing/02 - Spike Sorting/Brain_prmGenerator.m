function prmGenerator(destinationFolder, data_name, number_of_channels, samplingFrequency, filter_low, filter_high_factor, threshold_weak, threshold_strong, spike_direction)
    
    prmFile = fopen([destinationFolder '\param.prm'],'wt');
    fprintf(prmFile, ['experiment_name = ''' char(data_name) '''']);
    fprintf(prmFile,'\n');
    fprintf(prmFile,'prb_file = ''geom.prb''');
    fprintf(prmFile,'\n');
    fprintf(prmFile,'\n');
    fprintf(prmFile, 'traces = dict(');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     raw_data_files=[experiment_name + ''.dat''],');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     voltage_gain=10.,');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     sample_rate=%d,',samplingFrequency);
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     n_channels=%d', number_of_channels);

    fprintf(prmFile, ',');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     dtype=''int16'',');
    fprintf(prmFile,'\n');
    fprintf(prmFile, ')');
    fprintf(prmFile,'\n');
    fprintf(prmFile,'\n');
    fprintf(prmFile, 'spikedetekt = dict(');
    fprintf(prmFile,'\n');
    fprintf(prmFile,'     filter_low=%d.,', filter_low);
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     filter_high_factor=%d,', filter_high_factor);
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     filter_butter_order=6,');
    fprintf(prmFile,'\n');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     filter_lfp_low=0,');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     filter_lfp_high=300,');
    fprintf(prmFile,'\n');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     chunk_size_seconds=1,');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     chunk_overlap_seconds=.015,');
    fprintf(prmFile,'\n');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     n_excerpts=50,');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     excerpt_size_seconds=1,');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     threshold_strong_std_factor=%d,', threshold_strong );
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     threshold_weak_std_factor=%d,', threshold_weak);
    fprintf(prmFile,'\n');
    fprintf(prmFile, ['     detect_spikes=''', char(spike_direction), ''',']);
    fprintf(prmFile,'\n');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     connected_component_join_size=1,');
    fprintf(prmFile,'\n');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     extract_s_before=16,');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     extract_s_after=16,');
    fprintf(prmFile,'\n');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     n_features_per_channel=3,');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     pca_n_waveforms_max=10000,');
    fprintf(prmFile,'\n');
    fprintf(prmFile, ')');
    fprintf(prmFile,'\n');
    fprintf(prmFile,'\n');
    fprintf(prmFile, 'klustakwik2 = dict(');
    fprintf(prmFile,'\n');
    fprintf(prmFile, '     num_starting_clusters=100,');
    fprintf(prmFile,'\n');
    fprintf(prmFile, ')');
    fprintf(prmFile,'\n');
    fclose(prmFile);

end