function create_surfdata(param,mdata)
% tomo.create_surfdata(param,mdata)
%
% Description: Usually this function is called from tomo_collate_task.
%   Using a surface DEM and an ice mask, this function adds an aligned
%   surface dem and ice mask to a file.
%
% Inputs:
% param: struct from parameter spreadsheet
%  .tomo_collate: struct which control create_surfdata
%   .out_dir: ct_filename_out directory to which output
%     surfData will be exported. Default is surfData.
%   .layer_params: opsLoadLayers parameter struct array. The first element
%     should load the ice top (surface) layer and the second element
%     should load the ice bottom.
%   .surfData_mode: surfData mode string, can be one of:
%     'overwrite': will overwrite the whole file
%     'append': will only update the specified layers
%     'fillgaps': will only update the specified layers if they did not
%       already exist
%   .surfdata_cmds: struct of surfdata commands to run
%     .cmd: String with command: 'detect', 'dem', 'extract', 'viterbi', or 'trws'
%     .surf_names: String or cell array of strings with surface names to be
%       updated by the results of the command
%     .visible: The visibility setting for this layer
%     .plot_name_values: Plot name-value property fields
%     DETECT parameters
%     .data_threshold: pixel values above this will be clipped (default is 13.5)
%     DEM parameters
%     .dem_fn: filename to geotiff with DEM
%     EXTRACT parameters
%     .data_threshold: pixel values above this will be clipped (default is 13.5)
%     VITERBI parameters
%     .smooth_weight: smoothness weight (scalar, default is 55)
%     .smooth_var: smoothness variance (scalar, default is -1)
%     .repulsion: surface repulsion scaling factor (scalar, default is 150)
%     .egt_weight: extra ground-truth weight (scalar, default is 10)
%     .ice_bin_thr: ice_mask scanning threshold (scalar, default is 3)
%     TRWS parameters
%     .smooth_weight: smoothness weight [] (default is [22 22])
%     .smooth_var: Gaussian weighting in the elevation angle bin dimension (default is 32)
%     .max_loops: number of loops to run for (default is 50)
%   .bounds_relative: DOA bins and along-track slices to trim off from each edge [top bottom left right]
%     E.g. [0 0 0 0] would use all pixels, [1 0 0 0] would ignore the first row.
%     Usually trimming a few rows off the top/bottom is a good idea if
%     these represent angles out to +/- 90 deg.
%
% mdata: 3D data file struct (Data_YYYYMMDD_SS_FFF.mat with Tomo)
%   field)
%
% Outputs:
%   NONE
%
% See also: tomo.run_collate, tomo.collate, tomo_collate_task,
%   tomo.fuse_images, tomo.add_icemask_surfacedem, tomo.create_surfdata,
%
% Author: John Paden, Jordan Sprick, Mingze Xu, and Victor Berger

if ~isfield(param.tomo_collate,'surf_out_path') || isempty(param.tomo_collate.surf_out_path)
  param.tomo_collate.surf_out_path = 'surfData';
end

%% Load surface and bottom information
param_load_layers = param;
param_load_layers.cmd.frms = round([-1,0,1] + param.load.frm);

layers = opsLoadLayers(param_load_layers,param.tomo_collate.layer_params);

%% Interpolate surface and bottom information to mdata
master = [];
master.GPS_time = mdata.GPS_time;
master.Latitude = mdata.Latitude;
master.Longitude = mdata.Longitude;
master.Elevation = mdata.Elevation;
for lay_idx = 1:length(layers)
  ops_layer = [];
  ops_layer{1}.gps_time = layers(lay_idx).gps_time;
  
  ops_layer{1}.type = layers(lay_idx).type;
  ops_layer{1}.quality = layers(lay_idx).quality;
  ops_layer{1}.twtt = layers(lay_idx).twtt;
  ops_layer{1}.type(isnan(ops_layer{1}.type)) = 2;
  ops_layer{1}.quality(isnan(ops_layer{1}.quality)) = 1;
  lay = opsInterpLayersToMasterGPSTime(master,ops_layer,[300 60]);
  layers(lay_idx).twtt_ref = lay.layerData{1}.value{2}.data;
end
Surface = layers(1).twtt_ref;
Bottom = layers(2).twtt_ref;

if length(Bottom)~=size(mdata.Tomo.img,3)
  error('This should not happen.');
  Bottom = mdata.Bottom;
end
if length(Surface)~=size(mdata.Tomo.img,3)
  error('This should not happen.');
  Surface = mdata.Surface;
end

%% Interpolate Bottom, mdata.twtt from twtt to bins
Bottom_bin = interp1(mdata.Time, 1:length(mdata.Time), Bottom);
if isfield(mdata,'ice_mask')
  ice_mask = mdata.ice_mask;
else
  ice_mask = ones(size(mdata.twtt));
end
Bottom_bin(isnan(Bottom_bin)) = -1;

%% Surface tracking prep: Convert img to double and log-scale
data = 10*log10(double(mdata.Tomo.img));

%% Surface tracking prep
% 1. Convert from twtt to bins
twtt_bin = round(interp1(mdata.Time, 1:length(mdata.Time), mdata.twtt));
% 2. The tracking software assumes that the surface never approaches
%    within mu_length of the top/bottom of the range line, so we truncate
%    surface to ensure this never happens.
mu_length = 11;
twtt_bin(isnan(twtt_bin) | twtt_bin > length(mdata.Time)-mu_length) = length(mdata.Time)-mu_length;

%% Create output filename
out_dir = ct_filename_out(param,param.tomo_collate.surf_out_path,'');
if ~isdir(out_dir)
  mkdir(out_dir);
end
out_fn_name = sprintf('Data_%s_%03.0f.mat',param.day_seg,param.load.frm);
out_fn = fullfile(out_dir,out_fn_name);
fprintf('  Updating %s\n', out_fn);
if any(strcmpi(param.tomo_collate.surfData_mode,{'append','fillgaps'}))
  if ~exist(out_fn,'file')
    warning('%s mode selected, but output file does not exist. Switching to "overwrite" mode.',param.tomo_collate.surfData_mode);
    param.tomo_collate.surfData_mode = 'overwrite';
  else
    try
      sd = tomo.surfdata(out_fn);
    catch ME
      % Output file is not good, so we need to create
      warning('Output surfData file exists, but could not be loaded. Run "dbcont" to overwrite the file.');
      keyboard
      param.tomo_collate.surfData_mode = 'overwrite';
    end
  end
elseif ~strcmpi(param.tomo_collate.surfData_mode,'overwrite')
  error('Invalid surfData_mode %s.', param.tomo_collate.surfData_mode);
end

if strcmpi(param.tomo_collate.surfData_mode,'overwrite')
  %% Create surfData
  sd = tomo.surfdata();
  sd.radar_name = mdata.param_array.radar_name;
  sd.season_name = mdata.param_array.season_name;
  sd.day_seg = mdata.param_array.day_seg;
  sd.frm = mdata.param_array.load.frm;
  sd.gps_time = mdata.GPS_time;
  sd.theta = mdata.Tomo.theta(:,1);
  sd.time = mdata.Time(:); % Make a column vector
  sd.FCS.origin = mdata.param_array.array_proc.fcs{1}{1}.origin;
  sd.FCS.x = mdata.param_array.array_proc.fcs{1}{1}.x;
  sd.FCS.y = mdata.param_array.array_proc.fcs{1}{1}.y;
  sd.FCS.z = mdata.param_array.array_proc.fcs{1}{1}.z;
end

Nsv = size(mdata.Tomo.img,2);

try
  surf = sd.get_surf('top');
  if strcmpi(param.tomo_collate.surfData_mode,'overwrite')
    surf.y = twtt_bin;
    sd.set_surf(surf);
  end
catch ME
  surf = tomo.surfdata.empty_surf();
  surf.x = repmat((1:Nsv).',[1 size(mdata.twtt,2)]);
  surf.y = twtt_bin;
  surf.plot_name_values = {'color','black','marker','x'};
  surf.name = 'top';
  sd.insert_surf(surf);
end

try
  surf = sd.get_surf('bottom');
  if strcmpi(param.tomo_collate.surfData_mode,'overwrite')
    surf.y = NaN * zeros(size(twtt_bin));
    sd.set_surf(surf);
  end
catch ME
  surf = tomo.surfdata.empty_surf();
  surf.x = repmat((1:Nsv).',[1 size(mdata.twtt,2)]);
  surf.y = NaN * zeros(size(twtt_bin));
  surf.plot_name_values = {'color','blue','marker','^'};
  surf.name = 'bottom';
  sd.insert_surf(surf);
end

try
  surf = sd.get_surf('ice mask');
  if strcmpi(param.tomo_collate.surfData_mode,'overwrite')
    surf.y = mdata.ice_mask;
    sd.set_surf(surf);
  end
catch ME
  surf = tomo.surfdata.empty_surf();
  surf.x = repmat((1:Nsv).',[1 size(mdata.twtt,2)]);
  surf.y = mdata.ice_mask;
  surf.plot_name_values = {'color','white','marker','x'};
  surf.name = 'ice mask';
  sd.insert_surf(surf);
end

try
  surf = sd.get_surf('bottom gt');
  if strcmpi(param.tomo_collate.surfData_mode,'overwrite')
    surf.y = NaN * zeros(size(twtt_bin));
    surf.y(ceil(Nsv/2)+1,:) = interp1(mdata.Time,1:length(mdata.Time),Bottom);
    sd.set_surf(surf);
  end
catch ME
  surf = tomo.surfdata.empty_surf();
  surf.x = repmat((1:Nsv).',[1 size(mdata.twtt,2)]);
  surf.y = NaN * zeros(size(twtt_bin));
  surf.y(ceil(Nsv/2)+1,:) = interp1(mdata.Time,1:length(mdata.Time),Bottom);
  surf.plot_name_values = {'color','magenta','marker','+'};
  surf.name = 'bottom gt';
  sd.insert_surf(surf);
end

try
  surf = sd.get_surf('top gt');
  if strcmpi(param.tomo_collate.surfData_mode,'overwrite')
    surf.y = NaN * zeros(size(twtt_bin));
    surf.y(ceil(Nsv/2)+1,:) = interp1(mdata.Time,1:length(mdata.Time),Surface);
    sd.set_surf(surf);
  end
catch ME
  surf = tomo.surfdata.empty_surf();
  surf.x = repmat((1:Nsv).',[1 size(mdata.twtt,2)]);
  surf.y = NaN * zeros(size(twtt_bin));
  surf.y(ceil(Nsv/2)+1,:) = interp1(mdata.Time,1:length(mdata.Time),Surface);
  surf.plot_name_values = {'color','magenta','marker','^'};
  surf.name = 'top gt';
  sd.insert_surf(surf);
end

try
  surf = sd.get_surf('top quality');
  if strcmpi(param.tomo_collate.surfData_mode,'overwrite')
    surf.y = ones(size(twtt_bin));
    sd.set_surf(surf);
  end
catch ME
  surf = tomo.surfdata.empty_surf();
  surf.x = repmat((1:Nsv).',[1 size(mdata.twtt,2)]);
  surf.y = ones(size(twtt_bin));
  surf.plot_name_values = {'color','red','marker','x'};
  surf.name = 'top quality';
  sd.insert_surf(surf);
end

try
  surf = sd.get_surf('bottom quality');
  if strcmpi(param.tomo_collate.surfData_mode,'overwrite')
    surf.y = ones(size(twtt_bin));
    sd.set_surf(surf);
  end
catch ME
  surf = tomo.surfdata.empty_surf();
  surf.x = repmat((1:Nsv).',[1 size(mdata.twtt,2)]);
  surf.y = ones(size(twtt_bin));
  surf.plot_name_values = {'color','red','marker','^'};
  surf.name = 'bottom quality';
  sd.insert_surf(surf);
end

sd.set({'bottom','ice mask','bottom gt','bottom quality'}, ...
  'top','top','active','bottom','mask','ice mask','gt','bottom gt','quality','bottom quality');

sd.set({'top','top gt','top quality'}, ...
  'active','top','gt','top gt','quality','top quality');

sd.save_surfdata(out_fn);

mu = [];
sigma = [];

for cmd_idx = 1:length(param.tomo_collate.surfdata_cmds)
  cmd = param.tomo_collate.surfdata_cmds(cmd_idx).cmd;
  surf_names = param.tomo_collate.surfdata_cmds(cmd_idx).surf_names;
  if ischar(surf_names)
    surf_names = {surf_names};
  end
  visible = param.tomo_collate.surfdata_cmds(cmd_idx).visible;
  if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'plot_name_values') ...
      && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).plot_name_values)
    plot_name_values = param.tomo_collate.surfdata_cmds(cmd_idx).plot_name_values;
  else
    plot_name_values = {'color','black','marker','^'};
  end
  
  if any(strcmpi(cmd,{'detect','extract'})) && isempty(mu)
    %% Training parameters for image template's mu and sigma
    
    if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'data_threshold') ...
        && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).data_threshold)
      data_threshold = param.tomo_collate.surfdata_cmds(cmd_idx).data_threshold;
    else
      data_threshold = 13.5;
    end
    
    for rline = 1:size(mdata.Tomo.img,3)
      if ~mod(rline-1,100)
        fprintf('  Training %d of %d (%s)\n', rline, size(mdata.Tomo.img,3), datestr(now));
      end
      thresh_data = data(:,:,rline);
      thresh_data(thresh_data>data_threshold) = data_threshold;
      [m, s] = tomo.train_model(thresh_data, ...
        double(twtt_bin(:,rline)));
      mu(:,rline) = m;
      sigma(:,rline) = s;
    end
    %   mu = repmat([11.6734184113247 11.8357634315107 11.7477015213467 11.5642270542054 11.3655718245298 11.2178010788707 11.11172116154 11.0442549382899 10.9800832668574 10.9047999009164 10.8000063888223],size(mdata.Tomo.img,3),1);
    %   sigma = repmat([17.9297614680615 18.5178215941504 17.1485050463076 15.8106528912151 14.7936777080171 14.146975962117 13.9673485950864 13.9574519525412 13.5837122364561 13.0310380580007 12.2855990897649],size(mdata.Tomo.img,3),1);
    mdata.Tomo.mu = mu;
    mdata.Tomo.sigma = sigma;
    
    % in_dir: Directory where 3D image files are at
    in_dir = ct_filename_out(param,param.tomo_collate.in_dir);
    
    % combined_fn: Filename with 3D data
    combined_fn = fullfile(in_dir,sprintf('Data_%s_%03.0f.mat',param.day_seg,param.load.frm));
    
    Tomo = mdata.Tomo;
    save(combined_fn,'-append','Tomo');
  end
  
  if strcmpi(cmd,'detect')
    %% Run detect
    
    if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'data_threshold') ...
        && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).data_threshold)
      data_threshold = param.tomo_collate.surfdata_cmds(cmd_idx).data_threshold;
    else
      data_threshold = 13.5;
    end
    
    detect_surface = zeros(size(mdata.Tomo.img,2),size(mdata.Tomo.img,3));
    mu            = mdata.Tomo.mu;
    sigma         = mdata.Tomo.sigma;
    
    for rline = 1:size(mdata.Tomo.img,3)
      if ~mod(rline-1,500)
        fprintf('  Detect %d of %d (%s)\n', rline, size(mdata.Tomo.img,3), datestr(now));
      end
      
      % data_threshold: log scale data will be clipped to this threshold
      thresh_data = data(:,:,rline);
      thresh_data(thresh_data>data_threshold) = data_threshold;
      
      labels = tomo.detect(thresh_data, double(twtt_bin(:,rline)), double(Bottom_bin(rline)), ...
        [], double(ice_mask(:,rline)), double(mu(:,rline)), double(sigma(:,rline)));
      
      detect_surface(:,rline) = labels;
    end
    
    for surf_name_idx = 1:length(surf_names)
      surf_name = surf_names{surf_name_idx};
      try
        surf = sd.get_surf(surf_name);
        if ~strcmpi(param.tomo_collate.surfData_mode,'fillgaps')
          surf.y = detect_surface;
          surf.plot_name_values = plot_name_values;
          surf.visible = visible;
          sd.set_surf(surf);
        end
      catch ME
        surf = tomo.surfdata.empty_surf();
        surf.x = repmat((1:Nsv).',[1 size(mdata.twtt,2)]);
        surf.y = detect_surface;
        surf.name = surf_name;
        surf.plot_name_values = plot_name_values;
        surf.visible = visible;
        sd.insert_surf(surf);
      end
      sd.set(surf_name,'top','top','active','bottom','mask','ice mask', ...
        'gt','bottom gt','quality','bottom quality');
    end
    
  elseif strcmpi(cmd,'dem')
    %% Run DEM
    
    param.tomo_collate.surfdata_cmds(cmd_idx).dem_bad_value = -32767;
    param.tomo_collate.surfdata_cmds(cmd_idx).dem_guard = 12e3;
    param.tomo_collate.surfdata_cmds(cmd_idx).dem_per_slice_guard = 240;
    
    % Load Geotiff projection information
    proj = geotiffinfo(param.tomo_collate.surfdata_cmds(cmd_idx).dem_fn);
    
    % Load Geotiff raster, convert to double, set bad values to NaN
    [DEM, R, ~] = geotiffread(param.tomo_collate.surfdata_cmds(cmd_idx).dem_fn);
    DEM = double(DEM);
    DEM(DEM==param.tomo_collate.surfdata_cmds(cmd_idx).dem_bad_value) = NaN;
    
    % Create Geotiff axes
    DEM_x = R(3,1) + R(2,1)*(0:size(DEM,2)-1);
    DEM_y = R(3,2) + R(1,2)*(0:size(DEM,1)-1);
    
    DEM_x_mesh = repmat(DEM_x,[size(DEM,1) 1]);
    DEM_y_mesh= repmat(DEM_y',[1 size(DEM,2)]);

    % Project flight line to DEM coordinates
    [mdata.x,mdata.y] = projfwd(proj,mdata.Latitude,mdata.Longitude);

    % Process inputs
    dem_guard = param.tomo_collate.surfdata_cmds(cmd_idx).dem_guard;
    dem_per_slice_guard = param.tomo_collate.surfdata_cmds(cmd_idx).dem_per_slice_guard;
    
    top_idx = sd.get_index('top');
    
    theta = mdata.Tomo.theta(:,1);
    if isfield(param.tomo_collate,'sv_cal_fn') && ~isempty(param.tomo_collate.sv_cal_fn)
      theta_cal = load(param.tomo_collate.sv_cal_fn);
      theta = theta_cal.theta;
      theta_cal = theta;
    end

    % Loop to create dem_surface from DEM one range line at a time
    dem_surface = NaN*zeros(size(mdata.Tomo.img,2),size(mdata.Tomo.img,3));
    for rline = 1:size(mdata.Tomo.img,3)
      if ~mod(rline-1,500)
        fprintf('  DEM %d of %d (%s)\n', rline, size(mdata.Tomo.img,3), datestr(now));
      end
      
      DEM_mask = DEM_x_mesh > mdata.x(rline)-dem_guard & DEM_x_mesh < mdata.x(rline)+dem_guard ...
        & DEM_y_mesh > mdata.y(rline)-dem_guard & DEM_y_mesh < mdata.y(rline)+dem_guard ...
        & ~isnan(DEM);
      DEM_idxs = find(DEM_mask);
      
      if numel(DEM_idxs)==0
        % warning('Range Line %d of Frame %d is not spanned by DEM.',rline,param.load.frm);
        continue;
      end
      
      % Convert from projection to geodetic (lat,lon,elev)
      [DEM_lat,DEM_lon] = projinv(proj,DEM_x_mesh(DEM_idxs),DEM_y_mesh(DEM_idxs));
      DEM_elev = DEM(DEM_idxs);
      
      if all(isnan(DEM(DEM_idxs)))
        continue;
      end
      
      % Convert from geodetic (lat,lon,elev) to ECEF (x,y,z)
      physical_constants;
      [DEM_ecef_x,DEM_ecef_y,DEM_ecef_z] = geodetic2ecef(single(DEM_lat)/180*pi,single(DEM_lon)/180*pi,single(DEM_elev),WGS84.ellipsoid);
      
      origin = mdata.param_array.array_proc.fcs{1}{1}.origin(:,rline);
      
      % Convert from ECEF to FCS/SAR
      Tfcs_ecef = [mdata.param_array.array_proc.fcs{1}{1}.x(:,rline), ...
        mdata.param_array.array_proc.fcs{1}{1}.y(:,rline), ...
        mdata.param_array.array_proc.fcs{1}{1}.z(:,rline)];
      Tecef_fcs = inv(Tfcs_ecef);
      
      tmp = Tecef_fcs * [DEM_ecef_x.'-origin(1); DEM_ecef_y.'-origin(2); DEM_ecef_z.'-origin(3)];
      DEM_fcs_x = tmp(1,:);
      DEM_fcs_y = tmp(2,:);
      DEM_fcs_z = tmp(3,:);
      
      slice_mask = DEM_fcs_x > -dem_per_slice_guard & DEM_fcs_x < dem_per_slice_guard;
      
      x = DEM_fcs_x(slice_mask);
      y = DEM_fcs_y(slice_mask);
      z = DEM_fcs_z(slice_mask);
      
      if(numel(x)>=3)
        faces = delaunay(double(x),double(y));
        vertices = [double(x).' double(y).' double(z).'];  % vertices stored as Nx3 matrix
        vert1 = vertices(faces(:,1),:);
        vert2 = vertices(faces(:,2),:);
        vert3 = vertices(faces(:,3),:);
        
        twtt = NaN*zeros(size(mdata.Tomo.img,2),1);
        for theta_idx = 1:length(theta)
          % Find the point on the top surface
          top_twtt = interp1(1:length(mdata.Time),mdata.Time,sd.surf(top_idx).y(theta_idx,rline));
          top_orig = [0 sin(theta(theta_idx))*top_twtt*c/2 -cos(theta(theta_idx))*top_twtt*c/2];
          
          % Calculate refraction
          theta_refract = asin(sin(theta(theta_idx))/sqrt(er_ice));
          
          dir_v = [0 sin(theta_refract) -cos(theta_refract)];
          
          [intersect, t] = TriangleRayIntersection(top_orig, dir_v, vert1, vert2, vert3);
          
          intersect_idx = find(intersect);
          
          if isempty(intersect_idx)
            twtt(theta_idx) = NaN;
          else
            twtt(theta_idx) = top_twtt + t(intersect_idx(1))/(c/2/sqrt(er_ice));
          end
        end
        dem_surface(:,rline) = interp1(mdata.Time,1:length(mdata.Time),twtt);
        
      end
      
    end
    
    for surf_name_idx = 1:length(surf_names)
      surf_name = surf_names{surf_name_idx};
      try
        surf = sd.get_surf(surf_name);
        if ~strcmpi(param.tomo_collate.surfData_mode,'fillgaps')
          surf.y = dem_surface;
          surf.plot_name_values = plot_name_values;
          surf.visible = visible;
          sd.set_surf(surf);
        end
      catch ME
        surf = tomo.surfdata.empty_surf();
        surf.x = repmat((1:Nsv).',[1 size(mdata.twtt,2)]);
        surf.y = dem_surface;
        surf.name = surf_name;
        surf.plot_name_values = plot_name_values;
        surf.visible = visible;
        sd.insert_surf(surf);
      end
      sd.set(surf_name,'top','top','active','bottom','mask','ice mask', ...
        'gt','bottom gt','quality','bottom quality');
    end
    
  elseif strcmpi(cmd,'extract')
    %% Run extract
    fprintf('  Extract (%s)\n', datestr(now));
    
    if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'data_threshold') ...
        && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).data_threshold)
      data_threshold = param.tomo_collate.surfdata_cmds(cmd_idx).data_threshold;
    else
      data_threshold = 13.5;
    end
    
    mu            = mdata.Tomo.mu;
    sigma         = mdata.Tomo.sigma;
    
    % data_threshold: log scale data will be clipped to this threshold
    thresh_data = data;
    thresh_data(thresh_data>data_threshold) = data_threshold;
    
    Extra_bin = [];
    
    extract_surface = tomo.extract(double(thresh_data), double(twtt_bin), double(Bottom_bin), ...
      double(Extra_bin), double(ice_mask), double(mean(mu,2)), double(mean(sigma,2)));
    
    extract_surface = reshape(extract_surface,size(mdata.Tomo.img,2),size(mdata.Tomo.img,3));
    
    for surf_name_idx = 1:length(surf_names)
      surf_name = surf_names{surf_name_idx};
      try
        surf = sd.get_surf(surf_name);
        if ~strcmpi(param.tomo_collate.surfData_mode,'fillgaps')
          surf.y = extract_surface;
          surf.plot_name_values = plot_name_values;
          surf.visible = visible;
          sd.set_surf(surf);
        end
      catch ME
        surf = tomo.surfdata.empty_surf();
        surf.x = repmat((1:Nsv).',[1 size(mdata.twtt,2)]);
        surf.y = extract_surface;
        surf.name = surf_name;
        surf.plot_name_values = plot_name_values;
        surf.visible = visible;
        sd.insert_surf(surf);
      end
      sd.set(surf_name,'top','top','active','bottom','mask','ice mask', ...
        'gt','bottom gt','quality','bottom quality');
    end
    
  elseif strcmpi(cmd,'viterbi')
    %% Run Viterbi
    viterbi_surface = zeros(size(mdata.Tomo.img,2),size(mdata.Tomo.img,3));
    % Check for smoothness weight
    if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'smooth_weight') ...
        && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).smooth_weight)
      smooth_weight = param.tomo_collate.surfdata_cmds(cmd_idx).smooth_weight;
    else
      smooth_weight = 55; % schu
    end
    % Check for smoothness variance
    if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'smooth_var') ...
        && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).smooth_var)
      smooth_var = param.tomo_collate.surfdata_cmds(cmd_idx).smooth_var;
    else
      smooth_var = -1;
    end
    % Check for repulsion weight
    if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'repulsion') ...
        && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).repulsion)
      repulsion = param.tomo_collate.surfdata_cmds(cmd_idx).repulsion;
    else
      repulsion = 150; % schu
    end
    % Check for extra ground truth weight
    if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'egt_weight') ...
        && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).egt_weight)
      egt_weight = param.tomo_collate.surfdata_cmds(cmd_idx).egt_weight;
    else
      egt_weight = 10;
    end
    % Check for ice_mask scanning threshold
    if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'ice_bin_thr') ...
        && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).ice_bin_thr)
      ice_bin_thr = param.tomo_collate.surfdata_cmds(cmd_idx).ice_bin_thr;
    else
      ice_bin_thr = 3;
    end
    % Check for slope
    if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'slope') ...
        && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).slope)
      slope = param.tomo_collate.surfdata_cmds(cmd_idx).slope;
    else
      slope = zeros(1, size(data,2)-1);
    end
    
    mu_size = 11;
    mu      = sinc(linspace(-1.5, 1.5, mu_size));
    sigma   = sum(mu)/20*ones(1,mu_size);
    
    %% Distance-to-Ice-Margin model
    % Obtained from geostatistical analysis of 2014 Greenland P3
    prob.DIM_means = [    16.0582   27.3381   34.0492   40.5714...
      46.9463   52.3826   58.4664   63.7750   70.5143   76.3140...
      81.3519   86.9523   92.2285   98.1430   102.8310  107.0558...
      112.4538  116.3923  121.0109  125.1486  128.7611  133.3286...
      136.3500  139.5058  142.3812  146.1565  148.3781  151.1398...
      153.5642  155.2606  157.4824  159.8529  161.0239  163.1799...
      164.2849  166.1013  166.0728  167.3132  168.1448  169.1323...
      169.7559  170.3869  171.4264  171.8926  171.5201  171.8870...
      171.6407  172.3505  171.3533  171.6161];
    
    prob.DIM_vars  = [     20.5619   24.9082   28.0037   32.0840...
      35.6021   38.9544    42.4034   45.3588   48.9714   52.1360...
      55.0826   57.5144    60.3847   63.1485   65.1199   67.3734...
      69.3662   71.2849    72.9471   74.3759   75.5521   76.9737...
      77.9961   79.3596    79.9999   81.0342   81.6340   82.2424...
      82.9658   83.4794    84.1632   84.4168   85.0014   85.3065...
      85.7757   86.1880    86.3563   86.5577   86.7289   87.0748...
      87.1360   87.2473    87.2828   86.6350   86.5453   86.2989...
      86.4736   86.7318    87.1606   87.6966];
    
    costm = ones(1201, 101);
    fd = 18 * fir_dec(1:101, ones(1,5)/3.7.');
    
    for t = 1:1200
      for i = 1:101
        costm(t,i) = 200 * exp(-0.075 .* t) - 200 * exp(-0.075 * 50);
        if t > fd(i)
          costm(t,i) = 200;
    end
    end
    end
    
    prob.DIM_means = [prob.DIM_means prob.DIM_means(end)* ones(1,50)];
    prob.DIM_vars  = [prob.DIM_vars  prob.DIM_vars(end) * ones(1,50)];
    
    DIM_costmatrix = ones(1200, 100);
    for DIM = 1 : 100
      for T = 1 : 1200
        var = DIM * 0.05 * prob.DIM_vars(end);
        cost = 0.1 ./ normpdf(T, prob.DIM_means(DIM), var);
        cost(cost > 800) = 800;
        DIM_costmatrix(T, DIM) = cost;
    end
    end
    
    for k = 1:100
      DIM_costmatrix(1:50, k) = DIM_costmatrix(1:50, k) + 0.06 * k * costm(1:50, k);
    end
    
    DIM_costmatrix(DIM_costmatrix < 0) = 0;
    DIM_costmatrix(DIM_costmatrix > 800) = 800;
    
    DIM_costmatrix = DIM_costmatrix(3:end, :);
    DIM_costmatrix(end+1, :) = DIM_costmatrix(end,:);
    DIM_costmatrix(end+1, :) = DIM_costmatrix(end,:);
    DIM_costmatrix = DIM_costmatrix ./ 4;
    
    % Visualization of DIM_costmatrix
    if 0
      figure; (imagesc(DIM_costmatrix)); colorbar; hold on;
      xlabel('Distance to nearest ice-margin [m]');
      ylabel('Ice thickness distribution [range-bin]')
      title('Added cost');
    end
    
    %% DoA-to-DoA transition model
    % Obtained from geostatistical analysis of 2014 Greenland P3
    transition_mu = [0.000000, 0.000000, 2.590611, 3.544282, 4.569263, 5.536577, 6.476430, 7.416807, 8.404554, 9.457255, 10.442658, 11.413710, 12.354409, 13.332689, 14.364614, 15.381671, 16.428969, 17.398906, 18.418794, 19.402757, 20.383026, 21.391834, 22.399259, 23.359765, 24.369957, 25.344982, 26.301805, 27.307530, 28.274756, 28.947572, 29.691010, 32.977387, 34.203212, 34.897994, 35.667128, 36.579019, 37.558978, 38.548659, 39.540715, 40.550138, 41.534781, 42.547407, 43.552700, 44.537758, 45.553618, 46.561057, 47.547331, 48.530976, 49.516588, 50.536075, 51.562886, 52.574938, 53.552979, 54.554206, 55.559657, 56.574029, 57.591999, 58.552986, 59.562937, 60.551616, 61.549909, 62.551092, 63.045791, 63.540490];
    transition_sigma = [0.457749, 0.805132, 1.152514, 1.213803, 1.290648, 1.370986, 1.586141, 1.626730, 1.785789, 1.791043, 1.782936, 1.727153, 1.770210, 1.714973, 1.687484, 1.663294, 1.633185, 1.647318, 1.619522, 1.626555, 1.649593, 1.628138, 1.699512, 1.749184, 1.809822, 1.946782, 2.126822, 2.237959, 2.313358, 2.280555, 1.419753, 1.112363, 1.426246, 2.159619, 2.140899, 2.083267, 1.687420, 1.574745, 1.480296, 1.443887, 1.415708, 1.356100, 1.401891, 1.398477, 1.365730, 1.418647, 1.407810, 1.430151, 1.391357, 1.403471, 1.454194, 1.470535, 1.417235, 1.455086, 1.436509, 1.378037, 1.415834, 1.333177, 1.298108, 1.277559, 1.358260, 1.483521, 1.674642, 1.865764];
    
    % Visualization of mean and variance vectors
    if 0
      figure; (plot(transition_mu)); hold on;
      plot(transition_sigma); xlim([1 64])
      legend('Mean', 'Variance', 'Location', 'northwest');
      xlabel('DoA bins');
    end
    
    for rline = 1:size(mdata.Tomo.img,3)
      if ~mod(rline-1,500)
        fprintf('  Viterbi %d of %d (%s)\n', rline, size(mdata.Tomo.img,3), datestr(now));
      end
      
      detect_data    = data(:,:,rline);
      surf_bins      = twtt_bin(:,rline).';
      bottom_bin     = Bottom_bin(rline);
      gt             = [32; bottom_bin + 0.5];
      
      % Check for viterbi weight
      if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'viterbi_weight') ...
          && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).viterbi_weight)
        viterbi_weight = param.tomo_collate.surfdata_cmds(cmd_idx).viterbi_weight;
      else
        viterbi_weight = ones([1 size(data,2)]);
        viterbi_weight(gt(1, :)) = 2;
      end

      threshold = 13.5;
      detect_data(detect_data>threshold) = threshold;
      detect_data = fir_dec(detect_data.',hanning(3).'/3,1).';
      
      mask = ice_mask(:,rline);
      mask_dist = round(bwdist(mask == 0));

      bounds = [1 length(surf_bins)];

      %% Call viterbi.cpp
      labels = tomo.viterbi(double(detect_data), double(surf_bins), ...
        double(bottom_bin), double(gt), double(mask), double(mu), ...
        double(sigma), double(egt_weight), double(smooth_weight), ...
        double(smooth_var), double(slope), int64(bounds), ...
        double(viterbi_weight), double(repulsion), double(ice_bin_thr), ...
        double(mask_dist), double(DIM_costmatrix), ...
        double(transition_mu), double(transition_sigma));
      
      viterbi_surface(:,rline) = labels;
    end

    for surf_name_idx = 1:length(surf_names)
      surf_name = surf_names{surf_name_idx};
      try
        surf = sd.get_surf(surf_name);
        if ~strcmpi(param.tomo_collate.surfData_mode,'fillgaps')
          surf.y = viterbi_surface;
          surf.plot_name_values = plot_name_values;
          surf.visible = visible;
          sd.set_surf(surf);
        end
      catch ME
        surf = tomo.surfdata.empty_surf();
        surf.x = repmat((1:Nsv).',[1 size(mdata.twtt,2)]);
        surf.y = viterbi_surface;
        surf.name = surf_name;
        surf.plot_name_values = plot_name_values;
        surf.visible = visible;
        sd.insert_surf(surf);
      end
      sd.set(surf_name,'top','top','active','bottom','mask','ice mask', ...
        'gt','bottom gt','quality','bottom quality');
    end
    
  elseif strcmpi(cmd,'trws')
    %% Run TRW-S
    fprintf('  TRW-S (%s)\n', datestr(now));
    % Check for smoothness weight
    if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'smooth_weight') ...
        && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).smooth_weight)
      smooth_weight = param.tomo_collate.surfdata_cmds(cmd_idx).smooth_weight;
    else
      smooth_weight = [22 22];
    end
    % Check for smoothness variance
    if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'smooth_var') ...
        && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).smooth_var)
      smooth_var = param.tomo_collate.surfdata_cmds(cmd_idx).smooth_var;
    else
      smooth_var = 32;
    end
    % Check for max number of loops
    if isfield(param.tomo_collate.surfdata_cmds(cmd_idx),'max_loops') ...
        && ~isempty(param.tomo_collate.surfdata_cmds(cmd_idx).max_loops)
      max_loops = param.tomo_collate.surfdata_cmds(cmd_idx).max_loops;
    else
      max_loops = 50;
    end
    
    smooth_slope = [];
    mu_size = 11;
    mu = sinc(linspace(-1.5,1.5,mu_size));
    sigma = sum(mu)/20*ones(1,mu_size);
    bounds = [param.tomo_collate.bounds_relative(1) size(data,2)-1-param.tomo_collate.bounds_relative(2) -1 -1];
    
    mask_dist      = round(bwdist(ice_mask == 0));
    %% Obtained from geostatistical analysis of 2014 Greenland P3
    prob.DIM_means = [    16.0582   27.3381   34.0492   40.5714...
      46.9463   52.3826   58.4664   63.7750   70.5143   76.3140...
      81.3519   86.9523   92.2285   98.1430   102.8310  107.0558...
      112.4538  116.3923  121.0109  125.1486  128.7611  133.3286...
      136.3500  139.5058  142.3812  146.1565  148.3781  151.1398...
      153.5642  155.2606  157.4824  159.8529  161.0239  163.1799...
      164.2849  166.1013  166.0728  167.3132  168.1448  169.1323...
      169.7559  170.3869  171.4264  171.8926  171.5201  171.8870...
      171.6407  172.3505  171.3533  171.6161];
    
    prob.DIM_vars  = [     20.5619   24.9082   28.0037   32.0840...
      35.6021   38.9544    42.4034   45.3588   48.9714   52.1360...
      55.0826   57.5144    60.3847   63.1485   65.1199   67.3734...
      69.3662   71.2849    72.9471   74.3759   75.5521   76.9737...
      77.9961   79.3596    79.9999   81.0342   81.6340   82.2424...
      82.9658   83.4794    84.1632   84.4168   85.0014   85.3065...
      85.7757   86.1880    86.3563   86.5577   86.7289   87.0748...
      87.1360   87.2473    87.2828   86.6350   86.5453   86.2989...
      86.4736   86.7318   87.1606   87.6966];
    
    costm = ones(1201, 101);
    fd = 18 * fir_dec(1:101, ones(1,5)/3.7.');
    
    for t = 1:1200
      for i = 1:101
        costm(t,i) = 200 * exp(-0.075 .* t) - 200 * exp(-0.075 * 50);
        if t > fd(i)
          costm(t,i) = 200;
        end
      end
    end
    
    prob.DIM_means = [prob.DIM_means prob.DIM_means(end)* ones(1,50)];
    prob.DIM_vars  = [prob.DIM_vars  prob.DIM_vars(end) * ones(1,50)];
    
    DIM_costmatrix = ones(1200, 100);
    for DIM = 1 : 100
      for T = 1 : 1200
        var = DIM * 0.05 * prob.DIM_vars(end);
        cost = 0.1 ./ normpdf(T, prob.DIM_means(DIM), var);
        cost(cost > 800) = 800;
        DIM_costmatrix(T, DIM) = cost;
      end
    end
    
    for k = 1:100
      DIM_costmatrix(1:50, k) = DIM_costmatrix(1:50, k) + 0.06 * k * costm(1:50, k);
    end
    
    DIM_costmatrix(DIM_costmatrix < 0) = 0;
    DIM_costmatrix(DIM_costmatrix > 800) = 800;
    
    DIM_costmatrix = DIM_costmatrix(3:end, :);
    DIM_costmatrix(end+1, :) = DIM_costmatrix(end,:);
    DIM_costmatrix(end+1, :) = DIM_costmatrix(end,:);
    DIM_costmatrix = DIM_costmatrix ./ 4;
    
    % Visualization of DIM_costmatrix
    if 0
      figure; (imagesc(DIM_costmatrix)); colorbar; hold on;
      xlabel('Distance to nearest ice-margin [m]');
      ylabel('Ice thickness distribution [range-bin]')
      title('Added cost');
    end
    
    %% DoA-to-DoA transition model
    % Obtained from geostatistical analysis of 2014 Greenland P3
    transition_mu = [0.000000, 0.000000, 2.590611, 3.544282, 4.569263, 5.536577, 6.476430, 7.416807, 8.404554, 9.457255, 10.442658, 11.413710, 12.354409, 13.332689, 14.364614, 15.381671, 16.428969, 17.398906, 18.418794, 19.402757, 20.383026, 21.391834, 22.399259, 23.359765, 24.369957, 25.344982, 26.301805, 27.307530, 28.274756, 28.947572, 29.691010, 32.977387, 34.203212, 34.897994, 35.667128, 36.579019, 37.558978, 38.548659, 39.540715, 40.550138, 41.534781, 42.547407, 43.552700, 44.537758, 45.553618, 46.561057, 47.547331, 48.530976, 49.516588, 50.536075, 51.562886, 52.574938, 53.552979, 54.554206, 55.559657, 56.574029, 57.591999, 58.552986, 59.562937, 60.551616, 61.549909, 62.551092, 63.045791, 63.540490];
    transition_sigma = [0.457749, 0.805132, 1.152514, 1.213803, 1.290648, 1.370986, 1.586141, 1.626730, 1.785789, 1.791043, 1.782936, 1.727153, 1.770210, 1.714973, 1.687484, 1.663294, 1.633185, 1.647318, 1.619522, 1.626555, 1.649593, 1.628138, 1.699512, 1.749184, 1.809822, 1.946782, 2.126822, 2.237959, 2.313358, 2.280555, 1.419753, 1.112363, 1.426246, 2.159619, 2.140899, 2.083267, 1.687420, 1.574745, 1.480296, 1.443887, 1.415708, 1.356100, 1.401891, 1.398477, 1.365730, 1.418647, 1.407810, 1.430151, 1.391357, 1.403471, 1.454194, 1.470535, 1.417235, 1.455086, 1.436509, 1.378037, 1.415834, 1.333177, 1.298108, 1.277559, 1.358260, 1.483521, 1.674642, 1.865764];
    
    % Visualization of mean and variance vectors
    if 0
      figure; (plot(transition_mu)); hold on;
      plot(transition_sigma); xlim([1 64])
      legend('Mean', 'Variance', 'Location', 'northwest');
      xlabel('DoA bins');
    end
    
    gt = ones(3, length(Bottom_bin));
    gt(1, :) = 0 : length(Bottom_bin) - 1;
    gt(2, :) = 32 * ones(1, length(Bottom_bin));
    gt(3, :) = Bottom_bin(:) + 0.5;
    
    tic;
    trws_surface = tomo.trws(double(data), ...
      double(twtt_bin), double(Bottom_bin), double(gt), double(ice_mask), ...
      double(mu), double(sigma), double(smooth_weight), double(smooth_var), ...
      double(smooth_slope), double([]), double(max_loops), int64(bounds), ...
      double(mask_dist), double(DIM_costmatrix), ...
      double(transition_mu), double(transition_sigma));
    toc;
    
    trws_surface = reshape(trws_surface,size(mdata.Tomo.img,2), ...
      size(mdata.Tomo.img,3));
    
    for surf_name_idx = 1:length(surf_names)
      surf_name = surf_names{surf_name_idx};
      try
        surf = sd.get_surf(surf_name);
        if ~strcmpi(param.tomo_collate.surfData_mode,'fillgaps')
          surf.y = trws_surface;
          surf.plot_name_values = plot_name_values;
          surf.visible = visible;
          sd.set_surf(surf);
        end
      catch ME
        surf = tomo.surfdata.empty_surf();
        surf.x = repmat((1:Nsv).',[1 size(mdata.twtt,2)]);
        surf.y = trws_surface;
        surf.name = surf_name;
        surf.plot_name_values = plot_name_values;
        surf.visible = visible;
        sd.insert_surf(surf);
      end
      sd.set(surf_name,'top','top','active','bottom','mask','ice mask', ...
        'gt','bottom gt','quality','bottom quality');
    end
    
  elseif strcmpi(cmd,'c3d_rnn')
    c3d_rnn.dwnsammat_dir = fullfile(ct_filename_out(param, 'C3D_RNN_temporary_resources'), '');
    c3d_rnn.dwnsamnpy_dir = fullfile(ct_filename_out(param, 'C3D_RNN_temporary_resources'), '');
    temp_str              = strfind(c3d_rnn.dwnsammat_dir, filesep);
    c3d_rnn.dwnsammat_dir = c3d_rnn.dwnsammat_dir(1 : temp_str(end));
    c3d_rnn.dwnsammat_dir = fullfile(c3d_rnn.dwnsammat_dir, 'slices_mat_64x64', ct_filename_out(param, filesep));
    c3d_rnn.dwnsamnpy_dir = c3d_rnn.dwnsamnpy_dir(1 : temp_str(end));
    c3d_rnn.dwnsamnpy_dir = fullfile(c3d_rnn.dwnsamnpy_dir, 'slices_npy_64x64', ct_filename_out(param, filesep));
    
    % Down-sample data and save file for each and every slice
    for rline = 1 : size(data, 3)
      fusion = db(mdata.Tomo.img(:, :, rline));
      fusion(fusion>27) = 27;
      fusion = imresize(fusion, [64, 64]);
      fusion = mat2gray(fusion);
      
      out_dir = char(strcat(c3d_rnn.dwnsammat_dir, '/', sprintf('%.3d', param.proc.frm), '/'));
      outfile = strcat(out_dir, num2str(rline,'%05.f'), '.mat');
      
      try
        save(outfile, 'fusion');
      catch ME
        try
          mkdir(out_dir);
          save(outfile, 'fusion');
        catch ME
          fprintf('\nProblem saving temporary MAT file, verify.\n');
          keyboard
  end
end
    end
    fprintf('\nFinished down-sampling and saving MAT files for %s_%03.0f.\nPath: %s\n\n',param.day_seg,param.proc.frm, out_dir);

    %% Search for pre-trained model files (c3d.pth and rnn.pth)
    c3d_rnn.pth_path     = fullfile(param.path, '+tomo', 'c3d_rnn_models');
    c3d_rnn.c3d_pth_path = fullfile(c3d_rnn.pth_path, 'c3d.pth');
    c3d_rnn.rnn_pth_path = fullfile(c3d_rnn.pth_path, 'rnn.pth');
    
    if ~exist(c3d_rnn.c3d_pth_path, 'file') || ~exist(c3d_rnn.c3d_pth_path, 'file')
      fprintf('\nProblem locating model files (c3d.pth and rnn.pth). Directories being searched:\n%s\n%s\n', ...
        c3d_rnn.c3d_pth_path, c3d_rnn.rnn_pth_path);
      keyboard
    end
    
    %% Convert from MAT to NPY and run C3D_RNN
    %   Calls shell script
    fprintf('Executing shell script to run Python scripts...\n\n');
    try
      temp_str              = strfind(c3d_rnn.dwnsammat_dir, filesep);
      c3d_rnn.dwnsammat_dir = c3d_rnn.dwnsammat_dir(1 : temp_str(end));
      c3d_rnn.dwnsamnpy_dir = c3d_rnn.dwnsamnpy_dir(1 : temp_str(end));
      temp_str              = strfind(c3d_rnn.dwnsammat_dir, filesep);
      c3d_rnn.data_dir      = c3d_rnn.dwnsammat_dir(1 : temp_str(end - 1));
      c3d_rnn.outtext_dir   = fullfile(c3d_rnn.data_dir, sprintf('C3D_RNN_Out_%s_%03.0f.txt', ...
        param.day_seg,param.proc.frm));
      cd(fullfile(param.path, '+tomo'));
      sh_cmd = ['chmod +x run_C3D_RNN_Python.sh; ./run_C3D_RNN_Python.sh ', ...
        c3d_rnn.dwnsammat_dir, ' ', ...
        c3d_rnn.dwnsamnpy_dir, ' ', ...
        c3d_rnn.data_dir,      ' ', ...
        c3d_rnn.c3d_pth_path,  ' ', ...
        c3d_rnn.rnn_pth_path,  ' ', ...
        c3d_rnn.outtext_dir,   ' ', ...
        sprintf('Data_%s_%03.0f',param.day_seg,param.proc.frm)];
      tic;
      system(sh_cmd);
      toc;      
    catch ME
      fprintf('\nProblem during execution of Python scripts, verify.\n');
      keyboard
    end
    fprintf('\nFinished executing Python scripts for %s_%03.0f.\n\n',param.day_seg,param.proc.frm);
    
    c3d_rnn.result_surface = ones(size(mdata.Tomo.img,2), size(mdata.Tomo.img,3));
    c3d_rnn.result_bottom  = ones(size(mdata.Tomo.img,2), size(mdata.Tomo.img,3));
    
    sl_idx = 1;
    %% Get surface and bottom vectors from generated text file
    fid = fopen(c3d_rnn.outtext_dir);
    tline = '';
    
    while ischar(tline)
      tline = fgetl(fid);
      if (isscalar(tline) && tline == -1) || isempty(tline)
        continue;
      end
      tline = fgetl(fid);
      if (isscalar(tline) && tline == -1) || isempty(tline)
        continue;
      end
      c3d_rnn.result_surface(:, sl_idx) = str2num(tline)';
      tline = fgetl(fid);
      if (isscalar(tline) && tline == -1) || isempty(tline)
        continue;
      end
      c3d_rnn.result_bottom(:, sl_idx) = str2num(tline)';
      sl_idx = sl_idx + 1;
    end
    
    % Threshold bottom layer to location of surface layer (avoids negative
    % ice thickness)
    if param.tomo_collate.surfdata_cmds(cmd_idx).surface_threshold
      c3d_rnn.result_bottom(c3d_rnn.result_bottom < c3d_rnn.result_surface) = ...
        c3d_rnn.result_surface(c3d_rnn.result_bottom < c3d_rnn.result_surface);
    end
    
    c3d_rnn.result_matrix(:, :, 1) = c3d_rnn.result_surface;
    c3d_rnn.result_matrix(:, :, 2) = c3d_rnn.result_bottom;
    
    for surf_name_idx = 1:length(surf_names)
      surf_name = surf_names{surf_name_idx};
      try
        surf = sd.get_surf(surf_name);
        if ~strcmpi(param.tomo_collate.surfData_mode,'fillgaps')
          surf.y = c3d_rnn.result_matrix(:, :, surf_name_idx);
          surf.plot_name_values = plot_name_values;
          surf.visible = visible;
          sd.set_surf(surf);
        end
      catch ME
        surf = tomo.surfdata.empty_surf();
        surf.x = repmat((1:Nsv).',[1 size(mdata.twtt,2)]);
        surf.y = c3d_rnn.result_matrix(:, :, surf_name_idx);
        surf.name = surf_name;
        surf.plot_name_values = plot_name_values;
        surf.visible = visible;
        sd.insert_surf(surf);
      end
      sd.set(surf_name,'top','top','active','bottom','mask','ice mask', ...
        'gt','bottom gt','quality','bottom quality');
    end
  end
end

fprintf('Done (%s)\n', datestr(now));

sd.save_surfdata(out_fn);
