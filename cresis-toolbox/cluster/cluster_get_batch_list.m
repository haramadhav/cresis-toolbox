function ctrls = cluster_get_batch_list(param)
% ctrls = cluster_get_batch_list(param)
%
% Gets a list of batches using the specified data location.
%
% Inputs:
% param = optional input (just needs to contain param.cluster.data_location)
%   default value is to use global gRadar
%
% Outputs:
% ctrls = cell vector of batch jobs (can be used with the other cluster_*
%   functions). Job information is not retrieved, just the basics.
%   Use cluster_job_list to get job information.
%  .cluster = cluster parameter structure
%   .data_location
%  .batch_dir = path to directory containing batch information
%  .job_id_fn = path to file containing torque job ids
%  .in_fn_dir = input arguments directory
%  .out_fn_dir = output arguments directory
%  .stdout_fn_dir = stdout directory
%  .error_fn_dir = error directory
%  .user_file = path of file containing the username who owns batch
%  .user = string containing username who owns batch
%
% Author: John Paden
%
% See also: cluster_chain_stage, cluster_cleanup, cluster_compile
%   cluster_exec_job, cluster_get_batch, cluster_get_batch_list, 
%   cluster_hold, cluster_job, cluster_new_batch, cluster_new_task,
%   cluster_print, cluster_run, cluster_submit_batch, cluster_submit_task,
%   cluster_update_batch, cluster_update_task

if ~exist('param','var')
  global gRadar;
  param = gRadar;
end

batch_dirs = get_filenames(param.cluster.data_location,'batch_','','',struct('type','d'));

ctrls = [];
if nargout == 0
  fprintf('Batch Username    Directory\n');
end
for batch_idx = 1:length(batch_dirs)
  ctrls{batch_idx}.batch_dir = batch_dirs{batch_idx};
  
  [tmp batch_dir_name] = fileparts(ctrls{batch_idx}.batch_dir);
  ctrls{batch_idx}.batch_id = strtok(batch_dir_name(7:end),'_');
  ctrls{batch_idx}.batch_id = str2double(ctrls{batch_idx}.batch_id);
  
  if nargout == 0
    fprintf('%6d %s\n', ctrls{batch_idx}.batch_id, ctrls{batch_idx}.batch_dir);
  else
    ctrls{batch_idx}.job_id_fn = fullfile(ctrls{batch_idx}.batch_dir,'job_id_file');
    ctrls{batch_idx}.in_fn_dir = fullfile(ctrls{batch_idx}.batch_dir,'in');
    ctrls{batch_idx}.out_fn_dir = fullfile(ctrls{batch_idx}.batch_dir,'out');
    ctrls{batch_idx}.stdout_fn_dir = fullfile(ctrls{batch_idx}.batch_dir,'stdout');
    ctrls{batch_idx}.error_fn_dir = fullfile(ctrls{batch_idx}.batch_dir,'error');
    ctrls{batch_idx}.hold_fn = fullfile(ctrls{batch_idx}.batch_dir,'hold');
    
    ctrls{batch_idx} = cluster_new_batch(param,ctrls{batch_idx});
  end
  
end

end
