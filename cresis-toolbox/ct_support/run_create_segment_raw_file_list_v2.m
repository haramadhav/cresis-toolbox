% script run_create_segment_raw_file_list_v2.m
%
% Runs script create_segment_raw_file_list_v2.m
%
% Instructions:
% 1. Find your radar in the "user settings" section below
% 2. Enable it ("if 1") and disable all others ("if 0")
% 3. Change settings in the radar section as required (usually
%    just path changes to match the current date).
% 4. Run the script
%
% Author: John Paden

% User Settings
% =========================================================================

param = [];
counter_correction_en = false;

% Enable Just One Radar Setup
radar_setup = 'MCORDS5';

%% Accum 1
if strcmpi(radar_setup,'ACCUM')
  param.radar_name = 'accum';
  adcs = 1;
  param.file_version = 5;
  raw_file_suffix = '.dat';
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  counter_correction_en = true;
  
  % Parameters below this point OFTEN NEEDS TO BE CHANGED
  param.season_name = '2010_Greenland_P3';
  base_dir = '/cresis/snfs1/data/Accum_Data/2010_Greenland_P3/';
  param.adc_folder_name = '20100513B';
  file_midfix = ''; % Data files must contain this string in the middle of their name (usually should be empty)
  day_string = '20100513'; % Only used for stdout print of the vectors worksheet
  % file_prefix_override = ''; % most of the time (most of 2011)
  file_prefix_override = 'data'; % (pre 2011, and beginning of 2011)
end

%% Ka-band 3
if strcmpi(radar_setup,'KABAND3')
  param.radar_name = 'kaband3';
  param.clk = 125e6;
  adcs = 1;
  param.file_version = 5;
  raw_file_suffix = '.bin';
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  file_prefix_override = '';
  counter_correction_en = true;
  
  % Parameters below this point OFTEN NEEDS TO BE CHANGED
  param.season_name = '2015_Greenland_C130';
  base_dir = '/cresis/snfs1/data/kaband/';
  param.adc_folder_name = '20150328';
  file_midfix = ''; % Data files must contain this string in the middle of their name (usually should be empty)
  day_string = '20150328'; % Only used for stdout print of the vectors worksheet
end

%% Kuband 1
if strcmpi(radar_setup,'KUBAND1')
  param.radar_name = 'kuband';
  adcs = 1;
  param.file_version = 1; % 2 for 2012
  raw_file_suffix = '.dat'; % kuband3, snow3
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  counter_correction_en = true;
  
  % Parameters below this point OFTEN NEEDS TO BE CHANGED
  param.season_name = '2011_Greenland_P3';
  base_dir = '/cresis/snfs1/data/Ku-Band/2011_Greenland_P3/';
  param.adc_folder_name = '20110316';
  file_midfix = ''; % Data files must contain this string in the middle of their name (usually should be empty)
  day_string = '20110316'; % Only used for stdout print of the vectors worksheet  
  % file_prefix_override = ''; % most of the time (most of 2011)
  file_prefix_override = 'data'; % (pre 2011, and beginning of 2011)
end

%% Kuband 2
if strcmpi(radar_setup,'KUBAND2')
  param.radar_name = 'kuband2';
  param.clk = 125e6;
  adcs = 1;
  param.file_version = 2; % 2 for 2012
  raw_file_suffix = '.bin';
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  file_prefix_override = 'kuband';
  counter_correction_en = true;
  
  % Parameters below this point OFTEN NEEDS TO BE CHANGED
  param.season_name = '2012_Greenland_P3';
  base_dir = '/cresis/snfs1/data/Ku-Band/';
  param.adc_folder_name = '20120316';
  file_midfix = ''; % Data files must contain this string in the middle of their name (usually should be empty)
  day_string = '20120316'; % Only used for stdout print of the vectors worksheet
end

%% Ku-band 3
if strcmpi(radar_setup,'KUBAND3')
  param.radar_name = 'kuband3';
  param.clk = 125e6;
  adcs = 1;
  param.file_version = 5; % 3 for 2013 Gr, 5 for after that
  raw_file_suffix = '.bin';
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  file_prefix_override = '';
  counter_correction_en = true;
  
  % Parameters below this point OFTEN NEEDS TO BE CHANGED
  param.season_name = '2015_Greenland_C130';
  base_dir = '/cresis/snfs1/data/Ku-Band/';
  param.adc_folder_name = '20150328';
  file_midfix = ''; % Data files must contain this string in the middle of their name (usually should be empty)
  day_string = '20150328'; % Only used for stdout print of the vectors worksheet
end

%% RDS: ACORDS
if strcmpi(radar_setup,'ACORDS')
  param.radar_name = 'acords';
  adcs = 1;
  param.file_version = 406;
  raw_file_suffix = '';
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  counter_correction_en = true;
  
  % Parameters below this point OFTEN NEEDS TO BE CHANGED
  param.season_name = '2004_Antarctica_P3chile';
  % base_dir = '/cresis/snfs1/data/ACORDS/airborne2005/';
  base_dir = '/cresis/snfs1/data/ACORDS/Chile_2004/';
  param.adc_folder_name = 'nov21_04';
  file_midfix = ''; % Data files must contain this string in the middle of their name (usually should be empty)
  day_string = '20041121'; % Only used for stdout print of the vectors worksheet
  file_prefix_override = 'nov21_04'; % most of the time
  file_regexp = '\.[0-9]*$';
end

%% RDS: MCoRDS 4
if strcmpi(radar_setup,'MCORDS4')
  base_dir = '/N/dc2/projects/cresis/2013_Antarctica_DC3/20131216/mcords4/';
  param.radar_name = 'mcords4';
  adc_folder_names = {'chan1'};

  param.file_version = 404;

  file_midfix = ''; % Can often be left empty
  day_string = '20131216'; % Only used during printing of the segments
  param.season_name = '2013_Antarctia_Basler';
  raw_file_suffix = '.bin';
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  % file_prefix_override = ''; % most of the time (most of 2011)
  file_prefix_override = 'mcords4'; 
end

%% RDS: MCORDS5
if strcmpi(radar_setup,'MCORDS5')
  param.radar_name = 'mcords5';
  param.clk = 1.6e9/8;
  adcs = 1:24;
  raw_file_suffix = '.bin';
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  file_prefix_override = ''; % most of the time
  counter_correction_en = true;
  presum_bug_fixed = true; % Seasons from 2015 Greenland Polar6 onward should be set to true
  union_time_epri_gaps = true;
  
  % Parameters below this point OFTEN NEEDS TO BE CHANGED
  param.season_name = '2017_Antarctica_Polar6';
  base_dir = '/cresis/snfs1/scratch/2016_Germany_AWI_tests/AWI_ICE_bak/test_flight/';
  param.adc_folder_name = 'chan%d';
  file_midfix = ''; % Data files must contain this string in the middle of their name (usually should be empty)
  day_string = '20160830'; % Only used for stdout print of the vectors worksheet
end

%% Snow 1
if strcmpi(radar_setup,'SNOW1')
  param.radar_name = 'snow';
  adcs = 1;
  param.file_version = 1; % 2 for 2012
  raw_file_suffix = '.dat'; % kuband3, snow3
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  counter_correction_en = true;
  
  % Parameters below this point OFTEN NEEDS TO BE CHANGED
  param.season_name = '2011_Greenland_P3';
  base_dir = '/cresis/snfs1/data/SnowRadar/2011_Greenland_P3/';
  param.adc_folder_name = '20110316';
  file_midfix = ''; % Data files must contain this string in the middle of their name (usually should be empty)
  day_string = '20110316'; % Only used for stdout print of the vectors worksheet  end
  % file_prefix_override = ''; % most of the time (most of 2011)
  file_prefix_override = 'data'; % (pre 2011, and beginning of 2011)
end

%% Snow 2
if strcmpi(radar_setup,'SNOW2')
  param.radar_name = 'snow2';
  param.clk = 125e6;
  adcs = 1;
  param.file_version = 2; % 2 for 2012
  raw_file_suffix = '.bin';
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  file_prefix_override = 'snow';
  counter_correction_en = true;
  
  % Parameters below this point OFTEN NEEDS TO BE CHANGED
  param.season_name = '2012_Greenland_P3';
  base_dir = '/cresis/snfs1/data/SnowRadar/';
  param.adc_folder_name = '20120316';
  file_midfix = '20120316'; % Data files must contain this string in the middle of their name (usually should be empty)
  day_string = '20120316'; % Only used for stdout print of the vectors worksheet
end

%% Snow 3 (OIB)
if strcmpi(radar_setup,'SNOW3')
  param.radar_name = 'snow3';
  param.clk = 125e6;
  adcs = 1;
  param.file_version = 5; % 3 for 2013 Gr, 5 for after that
  raw_file_suffix = '.bin';
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  file_prefix_override = '';
  counter_correction_en = true;
  
  % Parameters below this point OFTEN NEEDS TO BE CHANGED
  param.season_name = '2015_Greenland_C130';
  base_dir = '/cresis/snfs1/data/SnowRadar/';
  param.adc_folder_name = '20150328';
  file_midfix = '20150328'; % Data files must contain this string in the middle of their name (usually should be empty)
  day_string = '20150328'; % Only used for stdout print of the vectors worksheet
end

%% Snow 3 (NRL)
if strcmpi(radar_setup,'SNOW3_NRL')
  param.radar_name = 'snow3';
  param.clk = 125e6;
  adcs = 1:10;
  param.file_version = 5; % 3 for 2013 Gr, 5 for after that
  raw_file_suffix = '.bin';
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  file_prefix_override = '';
  counter_correction_en = true;
  
  % Parameters below this point OFTEN NEEDS TO BE CHANGED
  param.season_name = '2015_Alaska_TOnrl';
  base_dir = '/cresis/snfs1/data/SnowRadar/';
  param.adc_folder_name = '20150328/chan%02d';
  file_midfix = '20150328'; % Data files must contain this string in the middle of their name (usually should be empty)
  day_string = '20150328'; % Only used for stdout print of the vectors worksheet
end

%% SNOW5
if strcmpi(radar_setup,'SNOW5')
  param.radar_name = 'snow5';
  param.clk = 125e6;
  adcs = 1:2;
  raw_file_suffix = '.bin';
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  file_prefix_override = ''; % most of the time
  counter_correction_en = false;
  
  % Parameters below this point OFTEN NEEDS TO BE CHANGED
  param.season_name = '2016_Greenland_Polar6';
  base_dir = '/mnt/HDD6/';
  param.adc_folder_name = '1604180601/UWBM/chan%d';
  file_midfix = ''; % Data files must contain this string in the middle of their name (usually should be empty)
  day_string = '20160418'; % Only used for stdout print of the vectors worksheet
  expected_rec_sizes = [60480      120864      181296];
end

%% User Settings that should not generally be changed
% You may have to set to false to read some of the results from this function when it was first written (should always be true)
tmp_fn_uses_adc_folder_name = true;

MIN_SEG_SIZE = 2;
MAX_TIME_GAP = 1000/75;
MIN_PRF = 100;

%% Automated Section
% =========================================================================

create_segment_raw_file_list_v2;

return;
