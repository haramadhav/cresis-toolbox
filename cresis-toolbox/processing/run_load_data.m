function run_load_data(varargin)
% Script run_load_data
%
% Several examples of using load_data
%
% Author: John Paden, Hara Madhav Talasila
%
% See also load_data, pulse_compress, sim.input_full_sim

param_fn = [];

switch nargin
  case 1
    run_example = varargin{1};
  case 2
    run_example = varargin{1};
    param_fn = varargin{2};
  otherwise
    run_example = 1;
end

clear data;

if run_example == 1
  % =======================================================================
  % Setup loading parameters for example 1
  %  - Plot data in time-space, time-wavenumber, freq-space, and
  %    freq-wavenumber domains
  % =======================================================================
  
%   param = read_param_xls(ct_filename_param('rds_param_2018_Antarctica_Ground.xls'),'20181014_02');
  param = read_param_xls(ct_filename_param('snow_param_2012_Greenland_P3.xls'),'20120330_04');
  
  % Determine which records you want to load:
  frames = frames_load(param);
  frm = 62;
  param.load_data.recs = frames.frame_idxs(frm) + 0 + [0 0];
  
  %   param.load_data.imgs = {[-1j 5]};
  %   param.load_data.imgs = {[2 2; 2 3; 2 4; 2 5; 2 6; 2 7; 2 8; 2 9; 2 10; 2 11; 2 12; 2 13; 2 14; 2 15; 2 16]};
  param.load_data.imgs                  = {[2 5]};
  param.load_data.imgs                  = {[1 1]};
  param.load_data.pulse_comp            = false;
  param.load_data.raw_data              = false;
  %param.load_data.ft_wind               = @hanning;
  param.load_data.combine_rx            = false;
  
  % Load data
  [hdr,data] = load_data(param);
  
  % Plot data
  img = 1;
  wf_adc_idx = 1;
  wf = param.load_data.imgs{img}(wf_adc_idx,1);
  adc = param.load_data.imgs{img}(wf_adc_idx,2);
  
  % Convert to voltage at ADC input
  %data{img}(:,1) = data{img}(:,1) * 10^(param.radar.wfs(wf).adc_gains_dB(adc)/20));
  
  figure(1); clf;
  imagesc([],hdr.time{img}, ...
    lp(abs(data{img}(:,:,wf_adc_idx)).^2/2/50)+30);
  title('Time-space domain (dBm signal)');
  grid on;
  colorbar
  
  noise_bins = 6000:7000;
  
  figure(2); clf;
  imagesc([],fftshift(hdr.wfs(wf).freq), ...
    lp(fftshift(fft(data{img}(noise_bins,:,wf_adc_idx)),1)));
  title('Frequency-space domain (noise)');
  grid on;
  colorbar
  
  figure(3); clf;
  imagesc([],hdr.wfs(wf).time, ...
    lp(fft(data{img}(:,:,wf_adc_idx),[],2)));
  title('Time-wavenumber domain');
  grid on;
  colorbar
  
  figure(4); clf;
  imagesc([],fftshift(hdr.wfs(wf).freq), ...
    lp(fftshift(fft2(data{img}(noise_bins,:,wf_adc_idx)),1)));
  title('Frequency-wavenumber domain (noise)');
  grid on;
  colorbar
  
elseif run_example == 2
  %% Setup loading parameters for example 2
  %  - Plot raw data in time-space, pulse compress externally with
  %    pulse_compress and plot this
  % =======================================================================
  
  param = read_param_xls(ct_filename_param('rds_param_2016_Greenland_Polar6.xls'),'20160413_04');
  
  % Determine which records you want to load:
  frames = frames_load(param);
  frm = 1;
  param.load_data.recs = frames.frame_idxs(frm) - 1 + [10000 10250];
  
  param.load_data.imgs = {[ones(24,1) (1:24).'],[2*ones(24,1) (1:24).'],[3*ones(24,1) (1:24).']};
  param.load_data.pulse_comp         = false;
  param.load_data.ft_dec             = false; % Fast-time decimation
  param.load_data.ft_wind            = @hanning;
  param.load_data.ft_wind_time       = false; % Apply window on time domain chirp
  param.load_data.presums            = 1; % Coherent averaging
  param.load_data.combine_rx         = false;
  param.load_data.pulse_rfi.en       = false;
  param.load_data.pulse_rfi.inc_ave  = 101;
  param.load_data.pulse_rfi.thresh_scale = 10^(13/10);
  param.load_data.trim_vals          = [1 1];
  param.load_data.raw_data           = true;
  
  %% Load data
  [hdr,data] = load_data(param);
  
  %% Print out DC values and create DC adjust files
  if 0
    adc_mean = [];
    for img = 1:length(param.load_data.imgs)
      wf = param.load_data.imgs{img}(1,1);
      adc_mean = [];
      for wf_adc = 1:length(param.load_data.imgs{img})
        adc = param.load_data.imgs{img}(wf_adc,2);
        dd=data{img}(end-499:end,:,adc); % Assumes bottom 500 range bins contain only noise (this should always be verified by looking at the echogram)
        adc_mean{img}(wf_adc) = mean(dd(:));
      end
      fprintf('%s wf %d\n', param.day_seg, wf);
      fprintf('%.3f\t', real(adc_mean{img}(1:end-1)));
      fprintf('\n');
      fprintf('%.3f\t', imag(adc_mean{img}(1:end-1)));
      fprintf('\n');
      fprintf('[');
      fprintf('%.3f%+.3fj ', real(adc_mean{img}(1:end-1)), imag(adc_mean{img}(1:end-1)));
      fprintf('%.3f%+.3fj', real(adc_mean{img}(end)), imag(adc_mean{img}(end)));
      fprintf(']\n');
      DC_adjust = adc_mean{img};
      DC_adjust_file_en = false;
      if DC_adjust_file_en
        %% Create the DC adjust files
        fn = fullfile(ct_filename_out(param,'noise','',1),sprintf('DC_%s_wf%d.mat',param.day_seg,wf));
        save(fn, '-v6', 'DC_adjust');
      end
    end
  end
  
  %% Plot data
  img = 1;
  wf_adc_idx = 1;
  wf = abs(param.load_data.imgs{img}(wf_adc_idx,1));
  
  figure(1); clf;
  imagesc([],hdr.wfs(wf).time, ...
    lp(data{img}(:,:,wf_adc_idx)));
  title('Time-space domain');
  grid on;
  colorbar
  
  % Pulse compress data
  clear pc_param;
  pc_param.f0 = hdr.wfs(wf).f0;
  pc_param.f1 = hdr.wfs(wf).f1;
  pc_param.Tpd = hdr.wfs(wf).Tpd;
  pc_param.time = hdr.wfs(wf).time;
  pc_param.tukey = param.radar.wfs(wf).tukey;
  pc_param.presums = hdr.wfs(wf).presums;
  pc_param.bit_shifts = max(0,(14+log(hdr.wfs(wf).presums)/log(2))-16);
  [data_pc,time] = pulse_compress(data{img}(:,:,wf_adc_idx),pc_param);
  
  figure(2); clf;
  imagesc([],time, lp(data_pc));
  title('Time-space domain');
  grid on;
  colorbar
  
elseif run_example == 3
  % =======================================================================
  % Setup loading parameters for example 3
  %  - Examines waveform imbalance
  % =======================================================================
  
  param_fn = '/cresis/projects/dev/csarp_support/documents/mcords_param_2010_Greenland_DC8.xls';
  param = read_param_xls(param_fn,'20100324_01');
  
  % Determine which records you want to load:
  frames = frames_load(param);
  frm = 10;
  param.load_data.recs = frames.frame_idxs(frm) - 1 + [4001 8000];
  
  param.load_data.imgs = {[1 1; 1 2; 1 3; 1 4; 1 5], [2 1; 2 2; 2 3; 2 4; 2 5]};
  param.load_data.imgs = {[1 1], [2 1]};
  param.load_data.pulse_comp         = true;
  param.load_data.ft_dec             = true; % Fast-time decimation
  param.load_data.ft_wind            = @hanning;
  param.load_data.ft_wind_time       = false; % Apply window on time domain chirp
  param.load_data.presums            = 50; % Coherent averaging
  param.load_data.combine_rx         = true;
  param.load_data.pulse_rfi.en       = true;
  param.load_data.pulse_rfi.inc_ave  = 101;
  param.load_data.pulse_rfi.thresh_scale = 10^(13/10);
  param.load_data.trim_vals          = [1 1];
  
  % Load data
  [hdr,data] = load_data(param);
  
  % Plot data
  sig_time = [17e-6 20e-6];
  noise_time = [60e-6 70e-6];
  for img = 1:length(data)
    for wf_adc_idx = 1:size(data{img},3)
      wf = param.load_data.imgs{img}(wf_adc_idx,1);
      
      figure(10*(img-1) + wf_adc_idx); clf;
      imagesc([],hdr.wfs(wf).time, ...
        lp(data{img}(:,:,wf_adc_idx)));
      title('Time-along track domain');
      grid on;
      colorbar
      
      figure(100 + 10*(img-1) + wf_adc_idx); clf;
      sig_bins = find(hdr.wfs(wf).time > sig_time(1) & hdr.wfs(wf).time < sig_time(2));
      noise_bins = find(hdr.wfs(wf).time > noise_time(1) & hdr.wfs(wf).time < noise_time(2));
      sig_val = max(abs(data{img}(sig_bins,:,wf_adc_idx)).^2);
      noise_val = mean(abs(data{img}(noise_bins,:,wf_adc_idx)).^2);
      plot(lp(sig_val));
      hold on;
      plot(lp(noise_val),'r');
      hold off;
      title('SNR-along track domain');
      grid on;
      colorbar
    end
  end
  
elseif run_example == 4
  % =======================================================================
  % Setup loading parameters for example 4
  %  - Receiver channel equalization
  % =======================================================================
  
  %param_fn = 'C:\csarp_support\documents\mcords_param_2011_Greenland_P3.xls';
  %param_fn = '/mnt/scratch1/csarp_support/documents/mcords_param_2011_Greenland_P3.xls';
  %param_fn = '/mnt/scratch1/csarp_support/documents/seaice_param_2011_Greenland_P3.xls';
  param_fn = 'C:\csarp_support\documents\mcords_param_2011_Greenland_P3.xls';
  param = read_param_xls(param_fn,'20110317_01');
  
  % Determine which records you want to load:
  frames = frames_load(param);
  frm = 2;
  param.load_data.recs = frames.frame_idxs(frm) - 1 + [5000 17000];
  
  %   param.load_data.imgs = {[-1j 5]};
  param.load_data.imgs = {[2 2; 2 3; 2 4; 2 5; 2 6; 2 7; 2 8; 2 9; 2 10; 2 11; 2 12; 2 13; 2 14; 2 15; 2 16]};
  %   param.load_data.imgs = {[2 2; 2 3; 2 4; 2 5; 2 6; 2 7; 2 8]};
  %   param.load_data.imgs = {[1 2; 1 3; 1 4; 1 5; 1 6; 1 7; 1 8]};
  %   param.load_data.imgs = {[2 9; 2 10; 2 11; 2 12]};
  %   param.load_data.imgs = {[2 13; 2 14; 2 15; 2 16]};
  param.load_data.pulse_comp         = true;
  param.load_data.ft_dec             = true; % Fast-time decimation
  param.load_data.ft_wind            = @hanning;
  param.load_data.ft_wind_time       = false; % Apply window on time domain chirp
  param.load_data.presums            = 10; % Coherent averaging
  param.load_data.combine_rx         = false;
  param.load_data.pulse_rfi.en       = false;
  param.load_data.pulse_rfi.inc_ave  = 101;
  param.load_data.pulse_rfi.thresh_scale = 10^(13/10);
  param.load_data.trim_vals          = [0 0];
  
  % Load data
  [hdr,data] = load_data(param);
  data = data{1};
  
  old_param = param;
  clear param;
  param.plot_en = true;
  param.adcs = old_param.load_data.imgs{1}(:,2);
  fn_name = sprintf('%s recs %d to %d', old_param.day_seg, ...
    old_param.load_data.recs);
  
  % =====================================================================
  % Setup parameters for
  
  % .caxis = Color axis limits (leave empty first time since this causes it to use the
  % defaults).
  param.caxis = [];
  %param.caxis = [50 120];
  
  % .ylim = Leave empty the first time (it just uses the default limits then)
  param.ylim = [];
  %param.ylim = [1 500];
  
  % .xlim = Leave empty the first time (it just uses the default limits then)
  %   These limits are in range lines post presumming
  param.xlim = [];
  
  % .ref_adc = Reference receive channel (surface location determined from this
  %   channel and all phase measurements made relative to it)
  param.ref_adc = 3;
  % .rlines = Range lines to process
  %   These are range lines post presumming
  param.rlines = [1 inf];
  % .rbins = Range bins to search for surface in (NEEDS TO BE SET IF NOT BLANKED)
  param.rbins = [500 inf];
  % .noise_rbins = Range bins to use for noise power calculation (THIS OFTEN NEEDS TO BE SET)
  param.noise_rbins = 700:1000;
  
  % .snr_threshold = SNR threshold in dB (range lines exceeding this
  %   SNR are included in the estimate)
  param.snr_threshold = 25;
  
  if param.rbins(2) > size(data,1)
    param.rbins(2) = size(data,1);
  end
  if param.rlines(2) > size(data,2)
    param.rlines(2) = size(data,2);
  end
  param.rbins = param.rbins(1):param.rbins(2);
  param.rlines = param.rlines(1):param.rlines(2);
  
  % =======================================================================
  % Echogram plots
  % =======================================================================
  if param.plot_en
    for adc_idx = 1:size(data,3)
      figure(adc_idx); clf; set(gcf,'WindowStyle','docked','NumberTitle','off','Name',sprintf('E %d',adc_idx));
      imagesc(lp(data(:,:,adc_idx)));
      title(sprintf('ADC %d File %s\nTime-Space Relative Power', param.adcs(adc_idx), fn_name),'Interpreter','none');
      grid on;
      colorbar
      if ~isempty(param.caxis)
        caxis(param.caxis);
      end
      if ~isempty(param.ylim)
        ylim(param.ylim);
      end
      if ~isempty(param.xlim)
        xlim(param.xlim);
      end
    end
  end
  
  % =======================================================================
  % Surface tracker
  % =======================================================================
  surf_data = filter2(ones(1,10),abs(data(:,:,param.ref_adc).^2));
  [surf_vals surf_bins] = max(surf_data(param.rbins,param.rlines));
  surf_bins = param.rbins(1)-1 + surf_bins;
  
  if param.plot_en
    for adc_idx = 1:size(data,3)
      figure(adc_idx);
      hold on;
      plot(param.rlines, surf_bins,'k');
      hold off;
    end
  end
  
  % =======================================================================
  % Noise power estimate and SNR threshold
  % =======================================================================
  noise_power = mean(mean(abs(data(param.noise_rbins,param.rlines)).^2));
  wf = 1;
  clear tx_phases tx_powers;
  for adc_idx = 1:size(data,3)
    for rline_idx = 1:length(param.rlines)
      rline = param.rlines(rline_idx);
      tx_phases(adc_idx,rline_idx) = data(surf_bins(rline_idx),rline,adc_idx);
      tx_powers(adc_idx,rline_idx) = abs(data(surf_bins(rline_idx),rline,adc_idx)).^2;
    end
  end
  tx_snr = tx_powers ./ noise_power;
  good_meas = lp(tx_snr) > param.snr_threshold;
  good_rlines = zeros(size(param.rlines));
  good_rlines(sum(good_meas) == size(tx_snr,1)) = 1;
  good_rlines = logical(good_rlines);
  
  num_good_rlines = sum(good_rlines);
  fprintf('Number of good range lines: %d out of %d\n', num_good_rlines, length(good_rlines));
  fprintf('========================================================\n');
  
  % =======================================================================
  % Amplitude Settings
  % =======================================================================
  clear delta_power;
  fprintf('Relative power for each waveform (dB)\n');
  for adc_idx = 1:size(data,3)
    ref_power = tx_powers(adc_idx,:)./tx_powers(param.ref_adc,:);
    if param.plot_en
      figure(10+adc_idx); clf; set(gcf,'WindowStyle','docked','NumberTitle','off','Name',sprintf('Pow %d',adc_idx));
      plot(lp(ref_power));
    end
    delta_power(adc_idx) = lp(median(ref_power(good_rlines)));
    fprintf('%10.2f\n', delta_power(adc_idx));
    %   fprintf('WF %d: relative power: %10.2f dB\n', wf, lp(median(ref_power(good_rlines))));
    %   fprintf('    Std. dev. power: %.2f dB\n', lp(std(ref_power(good_rlines))));
    ref_power(~good_rlines) = NaN;
    if param.plot_en
      hold on;
      plot(lp(ref_power),'ro');
      hold off;
      title(sprintf('Relative Power (%d to ref %d)', adc_idx, param.ref_adc));
    end
  end
  fprintf('Recommended amplitude settings:\n');
  fprintf('%.1f\t', delta_power(1:end-1));
  fprintf('%.1f', delta_power(end));
  fprintf('\n');
  fprintf('========================================================\n');
  
  % =======================================================================
  % Phase Settings
  % =======================================================================
  clear ref_phase_median;
  for adc_idx = 1:size(data,3)
    ref_phase = angle(tx_phases(adc_idx,:)./tx_phases(param.ref_adc,:));
    if param.plot_en
      figure(20+adc_idx); clf; set(gcf,'WindowStyle','docked','NumberTitle','off','Name',sprintf('Ang %d',adc_idx));
      plot(ref_phase);
      ylim([-pi pi]);
    end
    ref_phase_median(adc_idx) = median(ref_phase(good_rlines));
    fprintf('ADC %d: relative phase: %10.4f rad, %10.1f deg\n', adc_idx, ...
      median(ref_phase(good_rlines)), median(ref_phase(good_rlines))*180/pi);
    fprintf('    Std. dev. phase: %.4f rad, %.1f deg\n', ...
      std(ref_phase(good_rlines)), std(ref_phase(good_rlines))*180/pi);
    ref_phase(~good_rlines) = NaN;
    if param.plot_en
      hold on;
      plot(ref_phase,'ro');
      hold off;
      title(sprintf('Relative Phase (%d to ref %d)', adc_idx, param.ref_adc));
    end
  end
  
  fprintf('Recommended phase settings:\n');
  fprintf('%.1f\t', ref_phase_median(1:end-1)*180/pi);
  fprintf('%.1f', ref_phase_median(end)*180/pi);
  fprintf('\n');
  fprintf('========================================================\n');
  
elseif run_example == 5
  % =======================================================================
  % Setup loading parameters for example 5
  %  - Layer data for Joe MagGregor (pulsed compressed, no presums)
  % =======================================================================
  
  base_dir = '/cresis/snfs1/scratch/paden/winnie_chu/';
  % /cresis/scratch2/mdce/OIB_internal_layer_example/';
  
  param_fn = ct_filename_param('rds_param_2011_Greenland_P3.xls');
  %   param = read_param_xls(param_fn,'20110502_01');
  params = read_param_xls(param_fn,'20110416_02'); % USE GENERIC FIELD IN params(1).cmd worksheet
  params(1).cmd.frms = 19;
  params(1).cmd.generic = 1;
  %specify the total numer of segment
  
  for idx = 1:length(params)
    param = params(idx);
    if param.cmd.generic==1
      
      fprintf('Processing segment %s (%i of %i)\n', param.day_seg, idx, length(params));
      
      % Determine which records you want to load:
      frames = frames_load(param);
      
      if isempty(param.cmd.frms)
        frms = 1:length(frames.frame_idxs);
      else
        frms = param.cmd.frms;
      end
      for frm = frms
        fprintf('  Frame %d of %d\n', frm, length(frms));
        
        if frm == length(frames.frame_idxs)
          records_fn = '';
          records_fn = ct_filename_support(param,records_fn,'records');
          load(records_fn);
          all_recs = [frames.frame_idxs(frm) length(records.lat)];
          clear records;
        else
          all_recs = [frames.frame_idxs(frm) frames.frame_idxs(frm+1)-1];
        end
        
        block_size = 8000;
        blocks = [0:block_size:diff(all_recs)+1];
        for block_idx = 1:length(blocks)
          for wf = 1:length(param.radar.wfs)
            for adc = 1:length(param.radar.wfs(wf).rx_paths)
              param.load_data.recs = all_recs(1) + blocks(block_idx) + [0 block_size-1];
              param.load_data.recs(2) = min(param.load_data.recs(2),all_recs(2));
              param.load_data.imgs = {[wf adc]};
              param.load_data.pulse_comp         = false;
              param.load_data.ft_dec             = false; % Fast-time decimation
              param.load_data.ft_wind            = @boxcar;
              param.load_data.ft_wind_time       = false; % Apply window on time domain chirp
              param.load_data.presums            = 1; % Coherent averaging
              param.load_data.combine_rx         = true;
              param.load_data.pulse_rfi.en       = false;
              param.load_data.pulse_rfi.inc_ave  = 101;
              param.load_data.pulse_rfi.thresh_scale = 10^(13/10);
              param.load_data.trim_vals          = [0 0];
              param.load_data.raw_data          = true;
              
              % Load data
              [hdr,data] = load_data(param);
              data = data{1};
              
              out_dir = fullfile(base_dir,param.season_name,param.day_seg);
              if ~exist(out_dir,'dir')
                mkdir(out_dir);
              end
              fn = fullfile(out_dir,sprintf('Data_%s_%03.0f_wf_%d_adc_%02d_block_%02d', param.day_seg, frm, wf, adc, block_idx));
              fprintf('  Saving data %s\n', fn);
              save(fn,'-v6','data','hdr');
              if 0
                % Plot data
                imagesc(lp(data));
                keyboard
              end
            end
          end
        end
      end
    end
  end
  
elseif run_example == 6
  % =======================================================================
  % Setup loading parameters for example 6
  %  - Examines BW_window (coherent ave of elev compensated raw data)
  % =======================================================================
  
  try user_window_style = get(0,'DefaultFigureWindowStyle');
    set(0,'DefaultFigureWindowStyle','docked'); end
  
  switch 3 % Check multiple specular surfaces
    case 1
      param = read_param_xls(ct_filename_param('snow_param_2017_Greenland_P3.xls'),'20170407_02'); % 2-18
      param.load_data.recs = 9124619+ [500 900]; % [-1000 +1000] frm = 486;
      pick_index = 13263; % used to remove phase variation
    case 2
      param = read_param_xls(ct_filename_param('snow_param_2017_Greenland_P3.xls'),'20170323_02'); % 2-8
      frames = load(ct_filename_support(param,'','frames'));
      frm = 363;
      param.load_data.recs = frames.frame_idxs(frm) + [2600 3100]; % [1200 3400]
      pick_index = 9200; % used to remove phase variation
    case 3
      param = read_param_xls(ct_filename_param('snow_param_2017_Greenland_P3.xls'),'20170410_01');
      % 2-8 rx saturated? operator switched from 2-18 to 2-8 for this segment
      frames = load(ct_filename_support(param,'','frames'));
      frm = 3;
      param.load_data.recs = frames.frame_idxs(frm) + [10300 11200];
      pick_index = 10363; % used to remove phase variation
  end
  
  % param to load raw data
  param = ct_set_params(param,'radar.wfs(1).deconv.en',false);
  param.radar.wfs(1).coh_noise_method = 'analysis';
  param.radar.wfs(1).coh_noise_arg.fn = 'analysis';
  param.load_data.imgs                  = {[1 1]};
  param.load_data.pulse_comp            = false;
  param.load_data.raw_data              = true;
  param.load_data.ft_wind               = @hanning;
  param.load_data.combine_rx            = false;
  
  % Load data
  [hdr,data] = load_data(param);
  % hdr.surface = sgolayfilt(hdr.surface, 2, 201); % smoothen surface in some cases
  img = 1;
  wf_adc_idx = 1;
  wf = param.load_data.imgs{img}(wf_adc_idx,1);
  adc = param.load_data.imgs{img}(wf_adc_idx,2);
  data{img} = bsxfun(@minus,data{img},mean(data{1},2)); % DC removal
  
  % radar params
  c = physical_constants('c');
  f0 = param.radar.wfs(1).f0;
  f1 = param.radar.wfs(1).f1;
  Tpd = param.radar.wfs(1).Tpd;
  chirp_rate = (f1-f0) / Tpd;
  t_ref = param.radar.wfs(1).t_ref;
  fs = param.radar.fs;
  IF_nz = [0:3];
  IF_cutoffs = [0 : 0.5 : 2]' * fs; % Hz
  range_gates = IF_cutoffs / chirp_rate *c/2; % meter
  td = hdr.surface; % twtt (radar, surface)
  R = td *c/2;
  nz = max(IF_nz(any(bsxfun(@ge,R,range_gates) ,2))); % assuming only one nz
  f_beat = chirp_rate*(td-t_ref);
  f_beat = abs(f_beat-round(f_beat/fs)*fs); % real apparent frequency
  time = hdr.time{1};
  elev = hdr.records{1}.elev; % aircraft position rel to WGS-84
  elev_td = elev *2/c; % twtt (radar, WGS-84)
  time2freq_xaxis = ( (time + t_ref) *chirp_rate + f0 )/1e9; % freq in GHz
  
  % Baseband the data
  data_f{img} = fft(data{img});
  try
    data_f{img}(round(end/2+1:end),:) = 0;
  catch
    fprintf('data_f error\n');
    Nt = size(data_f{img},1);
    data_f{img}(round(Nt/2+1:Nt),:) = 0;
  end
  data{img} = ifft(data_f{img});
  
  % Pre-compensation PLOTS
  for compressing_this = 1
    
    fig_id = 10; fig_h = figure(fig_id); clf(fig_id);
    aa(1) = subplot(1,2,1);
    imagesc([],hdr.time{img}/1e-6, lp(abs(data{img}(:,:,wf_adc_idx)).^2/2/50)+30);
    grid on; colorbar; ylabel('Fast-time, us'); xlabel('rlines');
    title('Pre-compensation Time-space domain (dBm signal)');
    
    fig_id = 20; fig_h = figure(fig_id); clf(fig_id);
    bb(1) = subplot(1,2,1);
    plot_data = lp(data_f{img});
    [~,max_idxs] = max(plot_data(2:end/2,:));
    max_idxs = max_idxs+1; % add 1 if max from 2nd rbin
    imagesc([],hdr.freq{img}/1e6,plot_data); hold on; clear plot_data data_f;
    plot(f_beat/1e6,'.-');
    plot(hdr.freq{img}(max_idxs)/1e6,'.-');
    grid on; ylabel('Freq, MHz'); xlabel('rlines'); zoom on;
    colorbar;legend('fb','max');
    title('Pre-compensation lp( FT(data) )');
    
    fig_id = 30; fig_h = figure(fig_id); clf(fig_id);
    cc(1) = subplot(1,2,1);
    imagesc([],hdr.time{img}/1e-6,angle(data{img})); hold on;
    grid on; ylabel('Fast-time, us'); xlabel('rlines'); zoom on;
    colorbar;
    title('Pre-compensation angle(data)');
    
    fig_id = 123; fig_h = figure(fig_id); clf(fig_id); hold on;
    mean_data = mean(data{img},2);
    dd(1) = subplot(2,2,1);
    plot(time2freq_xaxis, real(mean_data)); grid on; title('Pre-compensation mean');
    xlabel('Freq, in GHz'); ylabel('Voltage, V');
    dd(2) = subplot(2,2,3);
    plot(time2freq_xaxis, lp(mean_data)); grid on; title('Pre-compensation lp(mean)');
    xlabel('Freq, in GHz'); ylabel('Magnitude, dB');
    linkaxes(dd,'x'); zoom on;
    clear mean_data;
    
  end
  
  % Compensation
  ttt = (td(1)+elev_td-elev_td(1)) - td(1); %first order
  ttt2 = -(td(1)+elev_td-elev_td(1)).^2 + td(1)^2; % second order
  phase_comp = +2*pi*chirp_rate*time*(ttt) + 2*pi*f0*(ttt) + pi*chirp_rate*(ttt2);
  data{img} = data{img} .* exp(-1i* (-1)^nz *( phase_comp ));
  if 1 % enable for additional phase correction, uses row specified by pick_index
    data{img} = fir_dec(data{img}, ones(1,11),1);
    filt_phase = angle(data{img});
    pick_phase = filt_phase(pick_index,:);
    data{img} = bsxfun(@times,data{img}, exp(-1i*pick_phase));
  end
  data_f{img} = fft(data{img});
  
  clear phase_comp;
  
  % Post-compensation PLOTS
  for compressing_this = 1
    
    fig_id = 10; fig_h = figure(fig_id); %clf(fig_id);
    aa(2) = subplot(1,2,2);
    imagesc([],hdr.time{img}/1e-6, lp(abs(data{img}(:,:,wf_adc_idx)).^2/2/50)+30);
    grid on; colorbar; ylabel('Fast-time, us'); xlabel('rlines');
    title('Post-compensation Time-space domain (dBm signal)');
    
    fig_id = 20; fig_h = figure(fig_id); %clf(fig_id);
    bb(2) = subplot(1,2,2);
    plot_data = lp(data_f{img});
    [~,max_idxs] = max(plot_data(2:end/2,:));
    max_idxs = max_idxs+1; % add 1 if max from 2nd rbin
    imagesc([],hdr.freq{img}/1e6,plot_data); hold on; clear plot_data data_f;
    plot(f_beat/1e6,'.-');
    plot(hdr.freq{img}(max_idxs)/1e6,'.-');
    grid on; ylabel('Freq, MHz'); xlabel('rlines'); zoom on;
    colorbar;legend('fb','max');
    title('Post-compensation lp( FT(data) )');
    
    fig_id = 30; fig_h = figure(fig_id); %clf(fig_id);
    cc(2) = subplot(1,2,2);
    imagesc([],hdr.time{img}/1e-6,angle(data{img})); hold on;
    grid on; ylabel('Fast-time, us'); xlabel('rlines'); zoom on;
    colorbar;
    title('Post-compensation angle(data)');
    
    fig_id = 123; fig_h = figure(fig_id); % clf(fig_id); hold on;
    mean_data = mean(data{img},2);
    dd(3) = subplot(2,2,2);
    plot(time2freq_xaxis, real(mean_data)); grid on; title('Post-compensation mean');
    xlabel('Freq, in GHz'); ylabel('Voltage, V');
    dd(4) = subplot(2,2,4);
    plot(time2freq_xaxis, lp(mean_data)); grid on; title('Post-compensation lp(mean)');
    xlabel('Freq, in GHz'); ylabel('Magnitude, dB');
    linkaxes(dd,'x'); zoom on;
    clear mean_data;
    
  end
  
  try linkaxes([aa]); linkaxes([bb]); linkaxes([cc]); end
  try set(0,'DefaultFigureWindowStyle',user_window_style); end
  
  
elseif run_example == 7
  % =======================================================================
  %% Setup loading parameters for example 7
  %  - Examines data from the full simulator (sim.input_full_sim)
  %  - Plots work best for point targets
  % =======================================================================
  
  [c, WGS84] = physical_constants('c', 'WGS84');
  
  if isempty(param_fn)
    % param_fn = '/cresis/snfs1/dataproducts/ct_data/ct_tmp/sim3D/snow/2012_Greenland_P3sim/20120330/param.mat';
    % param_fn = '/cresis/snfs1/dataproducts/ct_data/ct_tmp/sim3D/snow/2013_Greenland_P3sim/20130327/param.mat';
    % param_fn = '/cresis/snfs1/dataproducts/ct_data/ct_tmp/sim3D/snow/2018_Antarctica_DC8sim/20181010/param.mat';
    % param_fn = '/cresis/snfs1/dataproducts/ct_data/ct_tmp/sim3D/rds/2014_Greenland_P3sim/20140325/param.mat';
    % param_fn = '/cresis/snfs1/dataproducts/ct_data/ct_tmp/sim3D/rds/2018_Greenland_P3sim/20180429/param.mat';
    param_fn = '/cresis/snfs1/dataproducts/ct_data/ct_tmp/sim3D/rds/2014_Greenland_P3sim/20140410/param.mat';
    param_fn = '/cresis/snfs1/dataproducts/ct_data/ct_tmp/sim3D/rds/2014_Greenland_P3sim/20140502/param.mat';
    param_fn = '/cresis/snfs1/dataproducts/ct_data/ct_tmp/sim3D/rds/2014_Greenland_P3sim/20120330/param.mat';
  end
  
  % Load parameters from the mat file
  fprintf('(%s) param_fn: %s\n Loading \t', datestr(now), param_fn);
  load(param_fn);
  fprintf('-- Loaded\n');
  
  param.radar.wfs(1).tukey = 0;
  param.radar.wfs(2).tukey = 0;
  %param.radar.wfs(3).tukey = 0;
  
  %% FullSim load data
  
  param.load_data.pulse_comp            = 1;
  param.load_data.raw_data              = 0;
  [hdr, loaded_data] = load_data(param);
  
  %% FullSim Span through all images
  
  for img = 1:length(param.load_data.imgs) % support only one for now
    for wf_adc = 1:size(param.load_data.imgs{img},1)
      wf = param.load_data.imgs{img}(wf_adc,1);
      adc = param.load_data.imgs{img}(wf_adc,2);
      %       rx = param.radar.wfs(wf).rx_paths(adc);
      %%
      alpha_oversampling = param.radar.fs / abs(diff(param.radar.wfs(wf).BW_window))
      TBP = abs(diff(param.radar.wfs(wf).BW_window)) * param.radar.wfs(wf).Tpd
      N_cycles = TBP/4
      N_zero_xings = TBP/2
      
      IRW_or_Resolution_3db = [1 0.886]./ (abs(diff(param.radar.wfs(wf).BW_window)));
      Compression_Ratio = TBP./ [1 0.886]
      
      %window_broadening_factor, beta = 0 (rectangular)
      IRW_broadening_factor = 1.18 % for PSLR of -21 dB (beta = 2.5);
      
      IRW_or_Resolution_3db_w_windowing = [1 0.886] .* IRW_broadening_factor ./ (abs(diff(param.radar.wfs(wf).BW_window)))
      
      alpha_oversampling_check = IRW_or_Resolution_3db_w_windowing * param.radar.fs
           
      
      %% FullSim hdr
      
      % Expected values for traj, range, twtt, time axis
      traj = hdr.records{img};
      
      [traj.x, traj.y, traj.z] = geodeticD2ecef(traj.lat,traj.lon,traj.elev, WGS84.ellipsoid);
      
      target  = hdr.param_load_data.target;
      try
        range   = sqrt( (traj.x - target.x).^2 + (traj.y - target.y).^2 + (traj.z - target.z).^2 );
      catch
        range = sqrt( ...
          + ( bsxfun(@minus, traj.x, target.x') ).^2 ...
          + ( bsxfun(@minus, traj.y, target.y') ).^2 ...
          + ( bsxfun(@minus, traj.z, target.z') ).^2 );
      end
      
      twtt    = 2*range/c;
      time    = hdr.time{img};
      freq    = hdr.freq{img};
      freqs   = fftshift(freq);
      
      test_range  = param.sim.range{img,wf_adc}  - range;
      test_twtt   = param.sim.twtt{img,wf_adc}  - twtt;
      test_time   = param.radar.wfs(wf).time - time;
      
      if any(test_range(:)); warning('!!! Range mismatch sum:%f m\n', sum(abs(test_range(:)))); end
      if any(test_twtt(:)); warning('!!! twtt mismatch sum:%f ns\n', sum(abs(test_twtt(:)))/1e-9); end
      if any(test_time(:)); warning('!!! time mismatch sum:%f ns\n', sum(abs(test_time(:)))/1e-9); end
      
      %% FullSim data oversampling
      
      data    = loaded_data{img}(:,:,wf_adc);
      
      if 1
        
        oversample = 1;
        NOS = oversample * size(data,1);
        % To reduce steps in time(data max in each rline) vs expected TWTT
        data    = interpft(data, NOS, 1); % Oversample in fast-time
        
        % figure; plot(time, ones(size(time)),'s'); hold on
        dt = time(2)-time(1);
        dt_OS = dt /oversample;
        time  = time(1) + dt_OS * (0:NOS-1)';
        % plot(time, ones(size(time)),'.-');
        
        % figure; plot(freq, ones(size(freq)),'s'); hold on
        df    = ( freq(2)-freq(1) ) /oversample;
        freq  = freq(1) + ... % or hdr.param_load_data.radar.wfs(wf).fc
          ifftshift( -floor(NOS/2)*df : df : floor((NOS-1)/2)*df ).';
        freqs = fftshift(freq);
        % plot(freq, ones(size(freq)),'.-');
        
      end
      
      tmp     = 20*log10(abs(data));
      fdata   = fftshift(fft(data));
      ftmp    = 20*log10(abs(fdata));
      
      [data_max, data_max_idx]    = max(data,[],1);
      [fdata_max, fdata_max_idx]  = max(fdata,[],1);
      [tmp_max, tmp_max_idx]      = max(tmp,[],1);
      [ftmp_max, ftmp_max_idx]    = max(ftmp,[],1);
      [twtt_min, twtt_min_idx]    = min(twtt,[],2); % in second dimension
      
      twtt_min_idx_linear = sub2ind(size(twtt), 1:size(twtt,1), twtt_min_idx');
      
      [Nt,Nx] = size(data);
      x       = 1:Nx;
      
      %% Checks + debug figures
      
      if 0 || sum(cellfun(@numel,param.sim.imgs))/2 > 4 % || length(param.target.x) > 4
        skip_figures = 1;  
      else
        skip_figures = 0;  
      end
      
      %% FullSim hdr checks
      for compressing_this = 1  %continue; % FullSim hdr checks
        
        if 0 || skip_figures; continue; end
        
        call_sign = sprintf('FullSim hdr checks wfs_%02d_adc_%02d',wf,adc);
        fig_title = sprintf('%s_%s',mfilename, call_sign);
        fig_h = figure('Name',fig_title);
        subplot(131);
        plot(param.traj{img,wf_adc}.lon, param.traj{img,wf_adc}.lat, 'x'); hold on; grid on;
        plot(traj.lon, traj.lat, 'o');
        plot(param.gps.lon, param.gps.lat, '+', 'LineWidth', 2);
        xlabel('Longitude, Degrees');
        ylabel('Latitude, Degrees');
        legend('Simulated', 'Loaded', 'Reference');
        title('Trajectories');
        subplot(132);
        plot(param.sim.range{img,wf_adc}.', '.'); hold on; grid on;
        plot(range.', 'o');
        xlabel('Along-track position, rlines');
        ylabel('Range, meters');
        legend('... Simulated', 'ooo Calculated');
        title('Range to target');
        subplot(133);
        plot(param.sim.twtt{img,wf_adc}.'./1e-6, '.'); hold on; grid on;
        plot(twtt.'./1e-6, 'o');
        xlabel('Along-track position, rlines');
        ylabel('TWTT, us');
        legend('... Simulated', 'ooo Calculated');
        title('TWTT to target');
        try
          sgtitle(fig_title,'FontWeight','Bold','FontSize',14,'Interpreter','None');
        end
        set(findobj(fig_h,'type','axes'),'FontWeight', 'Bold', 'FontSize',14);
        set(fig_h, 'Position', get(0, 'Screensize'));
        %     print(gcf, '-dpng', fig_title, '-r300');
        
      end % for compressing_this % FullSim hdr checks
      
      %% FullSim Time Domain
      for compressing_this = 1  %continue; % FullSim Time Domain
        
        if 0 || skip_figures; continue; end
        
        call_sign = sprintf('FullSim Time Domain wfs_%02d_adc_%02d',wf,adc);
        fig_title = sprintf('%s_%s',mfilename, call_sign);
        fig_h = figure('Name',fig_title);
        subplot(121);
        if 0
          imagesc(x, time/1e-6, tmp-max(tmp(:)) ,[-30,0] );
          cb = colorbar; cb.Label.String = 'Relative Power, dB';
        else
          imagesc(x, time/1e-6, tmp);
          cb = colorbar; cb.Label.String = 'Power, dB';
        end
        grid on; hold on; axis tight;
        plot(x, twtt.'/1e-6, '--', 'Color', 'g');
        plot(twtt_min_idx, twtt(twtt_min_idx_linear)/1e-6, 's','LineWidth',2);
        xlabel('Along-track position, rlines'); ylabel('Fast-time, us');
        title('PhaseHistory Magnitude');
        subplot(122);
        imagesc(x, time/1e-6, angle(data) );
        cb = colorbar; cb.Label.String = 'Radians';
        grid on; hold on; axis tight;
        plot(x, twtt.'/1e-6, '--', 'Color', 'g');
        plot(twtt_min_idx, twtt(twtt_min_idx_linear)/1e-6, 's','LineWidth',2);
        xlabel('Along-track position, rlines'); ylabel('Fast-time, us');
        title('PhaseHistory Phase');
        if 0
          plot(time/1e-6, angle(data(:,twtt_min_idx)) ); hold on;
          plot(twtt_min/1e-6, angle(data(data_max_idx(twtt_min_idx), twtt_min_idx)) , 's','LineWidth',2);
          xlabel('Fast-time, us');
          ylabel('Phase, Radians');
          legend('rline','expected');
          title('At closest range');
        end
        try
          sgtitle(fig_title,'FontWeight','Bold','FontSize',14,'Interpreter','None');
        end
        set(findobj(fig_h,'type','axes'),'FontWeight', 'Bold', 'FontSize',14);
        set(fig_h, 'Position', get(0, 'Screensize'));
        %     print(gcf, '-dpng', fig_title, '-r300');
        
      end % for compressing_this % FullSim Time Domain
      
      %% FullSim Freq Domain
      for compressing_this = 1  %continue; % FullSim Freq Domain
        
        if 0 || skip_figures; continue; end
        
        call_sign = sprintf('FullSim Freq Domain wfs_%02d_adc_%02d',wf,adc);
        fig_title = sprintf('%s_%s',mfilename, call_sign);
        fig_h = figure('Name',fig_title);
        subplot(121);
        imagesc(x, freqs/1e6, ftmp-max(ftmp(:)) ,[-30,0] );
        cb = colorbar; cb.Label.String = 'Relative Power, dB';
        grid on; hold on; axis tight;
        xlabel('Along-track position, rlines'); ylabel('Freq, MHz');
        title('fft(PhaseHistory) Magnitude');
        subplot(122);
        imagesc(x, freqs/1e6, angle(fdata) );
        cb = colorbar; cb.Label.String = 'Radians';
        grid on; hold on; axis tight;
        xlabel('Along-track position, rlines'); ylabel('Freq, MHz');
        title('fft(PhaseHistory) Phase');
        try
          sgtitle(fig_title,'FontWeight','Bold','FontSize',14,'Interpreter','None');
        end
        set(findobj(fig_h,'type','axes'),'FontWeight', 'Bold', 'FontSize',14);
        set(fig_h, 'Position', get(0, 'Screensize'));
        %     print(gcf, '-dpng', fig_title, '-r300');
        
      end % for compressing_this % FullSim Freq Domain
      
      %% FullSim Time checks
      for compressing_this = 1  %continue; % FullSim Time checks
        
        if 0 || skip_figures; continue; end
        
        time_error = time(data_max_idx) - twtt.';
        if any(abs(time_error)>dt)
          warning('Time+Phase Analysis found something bad.. Breaking bad!!');
        end
        
        err_ceil = time_error>=0;
        err_floor = time_error<0;
        err_bars = dt.*(err_ceil - err_floor);
        
        call_sign = sprintf('FullSim Time checks wfs_%02d_adc_%02d',wf,adc);
        fig_title = sprintf('%s_%s',mfilename, call_sign);
        fig_h = figure('Name',fig_title);
        
        subplot(311);
        plot(x, time(data_max_idx)/1e-6, '.-b'); hold on;
        plot(x, twtt.'/1e-6, 's')
        xlabel('Along-track position, rlines');
        ylabel('Fast-time, us');
        legend('fast-time(max(data))', 'TWTT');
        grid on; axis tight;
        title('Time checks');
        
        subplot(312);
        plot(x, time_error/1e-9, '.-b'); hold on;
        plot(x, dt*err_ceil/1e-9, '-');
        plot(x, -dt*err_floor/1e-9, '-');
        xlabel('Along-track position, rlines');
        ylabel('Fast-time [+dt, -dt], ns');
        legend('fast-time(max(data)) - TWTT','ceil (+dt)','floor (-dt)');
        grid on; axis tight;
        title(sprintf('Time error for dt = %0.3f ns',dt/1e-9));
       
        subplot(313);
        hold on;
        errorbar(x, twtt.'/1e-6, -dt*err_floor/1e-6, dt*err_ceil/1e-6, [], [], ":.g");
        plot(x, time(data_max_idx)/1e-6, '.-b'); 
        xlabel('Along-track position, rlines');
        ylabel('Fast-time, us');
        legend('TWTT error bars', 'fast-time(max(data))');
        grid on; axis tight;
        title('Time error bars');
        
        try
          sgtitle(fig_title,'FontWeight','Bold','FontSize',14,'Interpreter','None');
        end
        set(findobj(fig_h,'type','axes'),'FontWeight', 'Bold', 'FontSize',14);
        set(fig_h, 'Position', get(0, 'Screensize'));
        %     print(gcf, '-dpng', fig_title, '-r300');
        
      end % for compressing_this % FullSim Time checks
      
      %% FullSim Phase checks
      for compressing_this = 1  %continue; % FullSim Phase checks
        
        if 0 || skip_figures; continue; end
        
        % To compare data_max with expected phase
        wave_number = 2*pi/ (c/hdr.param_load_data.radar.wfs(wf).fc);
        expected_phase = exp(1i * wave_number * bsxfun(@plus, -range, range(twtt_min_idx)) );
        expected_phase = exp(1i * wave_number * bsxfun(@plus, -range, 0) );
        % expected phase is data dependent % find the reason for this offset
        %   expected_phase = exp(1i * wave_number * (-range + range(twtt_min_idx)) ) * data_max(twtt_min_idx);
        phase_error = angle(data_max) - angle(expected_phase);
        phase_error_unwrap = unwrap(angle(data_max)) - unwrap(angle(expected_phase));
        
        corrected_phase = exp(1i * hdr.param_load_data.radar.wfs(wf).fc * time_error );
        
        call_sign = sprintf('FullSim Phase checks wfs_%02d_adc_%02d',wf,adc);
        fig_title = sprintf('%s_%s',mfilename, call_sign);
        fig_h = figure('Name',fig_title);
        
        subplot(311);
        plot(x, unwrap(angle(data_max)),'.'); hold on;
        plot(x, unwrap(angle(expected_phase.')),'s');
        plot(x, unwrap(angle(expected_phase.' ./ corrected_phase)),'o');
        xlabel('Along-track position, rlines');
        ylabel('Radians');
        legend('UnwrapPhase(max(data))', 'Expected', 'Corrected');
        grid on; axis tight;
        
        subplot(312);
        plot(x, angle(data_max),'.'); hold on;
        plot(x, angle(expected_phase.'),'s');
        plot(x, angle(expected_phase.' ./ corrected_phase),'o');
        xlabel('Along-track position, rlines');
        ylabel('Radians');
        legend('Phase(max(data))', 'Expected', 'Corrected');
        grid on; axis tight;
        
        subplot(313);
        plot(x, unwrap(angle(data_max)),'.'); hold on;
        plot(x, unwrap(angle(expected_phase.')),'s');
        xlabel('Along-track position, rlines');
        ylabel('Radians');
        legend('UnwrapPhase(max(data))', 'Expected', 'Corrected');
        grid on; axis tight;
        
        try
          sgtitle(fig_title,'FontWeight','Bold','FontSize',14,'Interpreter','None');
        end
        set(findobj(fig_h,'type','axes'),'FontWeight', 'Bold', 'FontSize',14);
        set(fig_h, 'Position', get(0, 'Screensize'));
        %     print(gcf, '-dpng', fig_title, '-r300');
        
      end % for compressing_this % FullSim Phase checks
      
      %% FullSim TD FD windows
      for compressing_this = 1  %continue; % FullSim TD FD windows
        
        if 0 || skip_figures; continue; end
        
        if 0 || skip_figures || length(param.target.x) > 4; continue; end
        
        if ~exist('fig_h_windows', 'var')
          call_sign = sprintf('FullSim TD FD windows');
          fig_title = sprintf('%s_%s',mfilename, call_sign);
          fig_h_windows = figure('Name',fig_title);
          leg_str_TD = {};
          leg_str_FD = {};
        else
          figure( fig_h_windows );
        end
        subplot(121);
        plot(time/1e-6, tmp(:,twtt_min_idx),'.-' ); hold on;
        plot(twtt_min/1e-6, tmp(tmp_max_idx(twtt_min_idx), twtt_min_idx) , 's','LineWidth',2);
        xlabel('Fast-time, us');
        ylabel('Magnitude, dB');
        leg_str_TD = [leg_str_TD {sprintf('[%02d %02d] rline',wf,adc) sprintf('[%02d %02d] expected',wf,adc)} ];
        legend(leg_str_TD);
        grid on;
        title('At closest range');
        subplot(122);
        plot(freqs/1e6, ftmp(:,twtt_min_idx) ); hold on;
        xlabel('Freq, MHz');
        ylabel('Magnitude, dB');
        leg_str_FD = [leg_str_FD {sprintf('[%02d %02d]',wf,adc)} ];
        legend(leg_str_FD);
        grid on;
        title('At closest range');
        try
          sgtitle(fig_title,'FontWeight','Bold','FontSize',14,'Interpreter','None');
        end
        set(findobj(fig_h_windows,'type','axes'),'FontWeight', 'Bold', 'FontSize',14);
        set(fig_h_windows, 'Position', get(0, 'Screensize'));
        %     print(gcf, '-dpng', fig_title, '-r300');
        
      end % for compressing_this % FullSim TD FD windows
      
    end % for wf_adc
  end % for img
  
end %% for run_example

