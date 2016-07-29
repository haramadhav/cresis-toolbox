classdef (HandleCompatible = true) slicetool_detect < imb.slicetool
  % Slice_browser tool which calls detect.cpp (HMM)
  
  properties
  end
  
  properties (SetAccess = private, GetAccess = private)
  end
  
  events
  end
  
  methods
    function obj = slicetool_detect()
      obj.create_option_ui();
      obj.tool_name = 'Detect';
      obj.tool_menu_name = '(D)etect';
      obj.tool_shortcut = 'd';
    end
    
    function cmd = apply_PB_callback(obj,sb)
      % Read and set sb.layer
      % Read sb.data
      % Read sb.slice
      % Read sb.layer_idx
      fprintf('Apply %s to layer %d slice %d\n', obj.tool_name, sb.layer_idx, sb.slice);
      
      surf_idx = 1;
      
      surf_bins = sb.layer(surf_idx).y(:,sb.slice);
      surf_bins(isnan(surf_bins)) = -1;
      
      bottom_bin = obj.custom_data.bottom(sb.slice);
      bottom_bin(isnan(bottom_bin)) = -1;
      
      labels = tomo.detect(sb.data(:,:,sb.slice), ...
        double(surf_bins), double(bottom_bin), ...
        [], double(obj.custom_data.ice_mask(:,sb.slice)), ...
        double(obj.custom_data.mu), double(obj.custom_data.sigma));
      
      % Create cmd for layer change
      cmd = [];
      cmd{1}.undo.slice = sb.slice;
      cmd{1}.redo.slice = sb.slice;
      cmd{1}.undo.layer = sb.layer_idx;
      cmd{1}.redo.layer = sb.layer_idx;
      cmd{1}.undo.x = 1:size(sb.layer(sb.layer_idx).y,1);
      cmd{1}.undo.y = sb.layer(sb.layer_idx).y(:,sb.slice);
      cmd{1}.redo.x = 1:size(sb.layer(sb.layer_idx).y,1);
      cmd{1}.redo.y = labels;
    end
    
    function set_custom_data(obj,custom_data)
      obj.custom_data.mu = mean(custom_data.mu);
      obj.custom_data.sigma = mean(custom_data.sigma);
      obj.custom_data.ice_mask = custom_data.ice_mask;
      obj.custom_data.bottom = custom_data.bottom;
    end
    
    function create_option_ui(obj)
    end

  end
  
end


