function search_callback(obj,src,event)
% mapwin.search_callback(obj,src,event)

% return focus to figure
try
  warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
  javaFrame = get(obj.h_fig,'JavaFrame');
  javaFrame.getAxisComponent.requestFocus;
catch
  fprintf('JavaFrame figure property not available, click inside echogram window after pressing a listbox button before using key shortcuts\n');
end

if strcmpi(get(obj.map_panel.h_axes,'Visible'),'off')
  % No map selected, so just return
  return;
end

% Update map selection plot
if obj.map.fline_source==1
  % Find the first frame that matches the search string
  frm_id = get(obj.top_panel.searchTB,'String');
  frm_id(regexp(frm_id,'_')) = [];
  frm_id = str2num(frm_id);
  
  % Get a logical mask indicating all indices that match the frame
  frm_mask = obj.layerdata.frms == frm_id;
  idx = find(frm_mask,1);
  if isempty(idx)
    % No frames match, so just return
    return;
  end
  season_idx = obj.layerdata.season_idx(idx);
  frm_id = obj.layerdata.frms(idx);

  % Generate search string
  frm_id = num2str(frm_id);
  day = frm_id(1:8);
  seg = frm_id(9:10);
  frame = frm_id(11:13);
  frm_str = strcat(day,'_',seg,'_',frame);

  if strcmpi(obj.cur_map_pref_settings.layer_source,'layerdata')
    status = [];
    
    % Set data properties
    data = struct('properties',[]);
    data.properties.frame = frm_str;
    data.properties.season = obj.cur_map_pref_settings.seasons{season_idx};
    data.properties.segment_id = str2num(frm_id(1:10));
    data.properties.X = obj.layerdata.x(frm_mask);
    data.properties.Y = obj.layerdata.y(frm_mask);
    
  else
    % Get segment id from opsGetFrameSearch
    frame_search_param = struct('properties',[]);
    frame_search_param.properties.frm_str = frm_str;
    frame_search_param.properties.location = param.properties.location;
    [frm_status,frm_data] = opsGetFrameSearch(sys,frame_search_param);
    
    % Set data properties
    data = struct('properties',[]);
    data.properties.frame = frm_str;
    data.properties.season = frm_data.properties.season;
    data.properties.segment_id = frm_data.properties.segment_id;
    data.properties.X = obj.layerdata.x(frm_mask);
    data.properties.Y = obj.layerdata.y(frm_mask);
    status = frm_status;
  end
  
  obj.map.sel.frame_name = data.properties.frame;
  obj.map.sel.season_name = data.properties.season;
  obj.map.sel.segment_id = data.properties.segment_id;
  
  set(obj.map_panel.h_cur_sel,{'XData','YData'},{data.properties.X/obj.map.scale,data.properties.Y/obj.map.scale});
  new_xdata = data.properties.X/obj.map.scale;
  new_ydata = data.properties.Y/obj.map.scale;

  % Update map limits if necessary
  [changed,pos] = obj.compute_new_map_limits(new_xdata,new_ydata);
  if changed
      obj.query_redraw_map(pos(1),pos(2),pos(3),pos(4));
  end

else
  ops_param.properties.search_str = get(obj.top_panel.searchTB,'String');
  ops_param.properties.season = obj.map_pref.settings.seasons;
  ops_param.properties.location = obj.cur_map_pref_settings.map_zone;
  
  [status,data] = opsGetFrameSearch(obj.cur_map_pref_settings.system,ops_param);
  if status==2
    % result not found; warning already printed to console, so just exit
    return;
  end
  
  % Record current frame selection
  obj.map.sel.frame_name = data.properties.frame;
  obj.map.sel.season_name = data.properties.season;
  obj.map.sel.segment_id = data.properties.segment_id;
  
  if obj.map.source == 1
    [lat,lon] = projinv(obj.map.proj,data.properties.X,data.properties.Y);
    [data.properties.X,data.properties.Y] = google_map.latlon_to_world(lat,lon);
    data.properties.Y = 256-data.properties.Y;
  end
  
  set(obj.map_panel.h_cur_sel,{'XData','YData'},{data.properties.X/obj.map.scale,data.properties.Y/obj.map.scale});
  new_xdata = data.properties.X/obj.map.scale;
  new_ydata = data.properties.Y/obj.map.scale;

  % Update map limits if necessary
  [changed,pos] = obj.compute_new_map_limits(new_xdata,new_ydata);
  if changed
      obj.query_redraw_map(pos(1),pos(2),pos(3),pos(4));
  end
end
% Change map title to the currently selected frame
set(obj.top_panel.flightLabel,'String',obj.map.sel.frame_name);
