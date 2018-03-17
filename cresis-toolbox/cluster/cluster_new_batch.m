function ctrl = cluster_new_batch(param,ctrl)
% ctrl = cluster_new_batch(param,ctrl)
%
% Creates a new batch
% 1. Creates a temporary batch directory in param.data_location
% 2. Creates stdout, error, in, and out directories
% 3. Initializes the ctrl structure
%
% Input:
%  param: structure with cluster information
%   .cluster: structure (default is gRadar.cluster)
%    .data_location: location to store temporary job files
%
% Output:
% ctrl = batch control structure
%  .cluster = set equal to param.cluster structure
%  .batch_dir = path to directory containing batch information
%  .job_id_fn = path to file containing cluster job ids associated with
%    each task
%  .in_fn_dir = input arguments directory
%  .out_fn_dir = output arguments directory
%  .stdout_fn_dir = stdout directory
%  .error_fn_dir = error directory
%  .user_file = path of file containing the username who owns batch
%  .user = string containing username who owns batch
%  .task_id = number of tasks created, N (which is zero since we just created
%    this batch)
%  .job_id_list = Nx1 vector of cluster job IDs associated with each task
%    (this should match the contents of the job_id_fn)
%  .job_status = Nx1 vector of job status
%  .error_mask = Nx1 vector of error status
%
% Example:
%  cluster_new_batch; % Usually called with no arguments
%
% Author: John Paden
%
% See also: cluster_chain_stage, cluster_cleanup, cluster_compile
%   cluster_exec_job, cluster_get_batch, cluster_get_batch_list, 
%   cluster_hold, cluster_job, cluster_new_batch, cluster_new_task,
%   cluster_print, cluster_run, cluster_submit_batch, cluster_submit_task,
%   cluster_update_batch, cluster_update_task

%% Input arguments check
global gRadar;

if ~exist('param','var') || isempty(param)
  param = gRadar;
end

ctrl.cluster = param.cluster;

if ~isfield(ctrl.cluster,'type') || isempty(ctrl.cluster.type)
  ctrl.cluster.type = 'debug';
end

if ~isfield(ctrl.cluster,'cluster_job_fn') || isempty(ctrl.cluster.cluster_job_fn)
  ctrl.cluster.cluster_job_fn = fullfile(gRadar.path,'cluster','cluster_job.sh');
end

if any(strcmpi(ctrl.cluster.type,{'slurm','torque'}))
  [status,msg] = fileattrib(ctrl.cluster.cluster_job_fn,'rwx','a');
end

if ~isfield(ctrl.cluster,'mcr_cache_root') || isempty(ctrl.cluster.mcr_cache_root)
  ctrl.cluster.mcr_cache_root = '/tmp/';
end

if ~isfield(ctrl.cluster,'matlab_mcr_path') || isempty(ctrl.cluster.matlab_mcr_path)
  ctrl.cluster.matlab_mcr_path = matlabroot;
end

if ~isfield(ctrl.cluster,'max_jobs_active') || isempty(ctrl.cluster.max_jobs_active)
  ctrl.cluster.max_jobs_active = 1;
end

if ~isfield(ctrl.cluster,'max_time_per_job') || isempty(ctrl.cluster.max_time_per_job)
  ctrl.cluster.max_time_per_job = 86400;
end

if ~isfield(ctrl.cluster,'desired_time_per_job') || isempty(ctrl.cluster.desired_time_per_job)
  ctrl.cluster.max_time_per_job = 0;
end

if ~isfield(ctrl.cluster,'max_retries') || isempty(ctrl.cluster.max_retries)
  ctrl.cluster.max_retries = 1;
end

if ~isfield(ctrl.cluster,'submit_pause') || isempty(ctrl.cluster.submit_pause)
  ctrl.cluster.submit_pause = 0;
end

if ~isfield(ctrl.cluster,'stat_pause') || isempty(ctrl.cluster.stat_pause)
  ctrl.cluster.stat_pause = 1;
end

if ~isfield(ctrl.cluster,'file_check_pause') || isempty(ctrl.cluster.file_check_pause)
  ctrl.cluster.file_check_pause = 4;
end

if ~isfield(ctrl.cluster,'rerun_only') || isempty(ctrl.cluster.rerun_only)
  ctrl.cluster.rerun_only = false;
end

if ~isfield(ctrl.cluster,'hidden_depend_funs') || isempty(ctrl.cluster.hidden_depend_funs)
  ctrl.cluster.hidden_depend_funs = [];
end

if ~isfield(ctrl.cluster,'force_compile') || isempty(ctrl.cluster.force_compile)
  ctrl.cluster.force_compile = 0;
end

if ~isfield(ctrl.cluster,'cpu_time_mult') || isempty(ctrl.cluster.cpu_time_mult)
  ctrl.cluster.cpu_time_mult = 1;
end

if ~isfield(ctrl.cluster,'mem_mult') || isempty(ctrl.cluster.mem_mult)
  ctrl.cluster.mem_mult = 1;
end

if ~isfield(ctrl.cluster,'mcc') || isempty(ctrl.cluster.mcc)
  ctrl.cluster.mcc = 'system';
end

if ~isfield(ctrl.cluster,'file_version') || isempty(ctrl.cluster.file_version)
  ctrl.cluster.file_version = '-v6';
end

if ~isfield(ctrl.cluster,'dbstop_if_error') || isempty(ctrl.cluster.dbstop_if_error)
  ctrl.cluster.dbstop_if_error = true;
end

if ~isfield(ctrl.cluster,'qsub_submit_arguments') || isempty(ctrl.cluster.qsub_submit_arguments)
  % -m n: no mail
  % -l nodes=1:ppn=1: one compute node and one core/processor on the node
  ctrl.cluster.qsub_submit_arguments = '-m n -l nodes=1:ppn=1,pmem=%dmb,walltime=%d:00';
end

if ~isfield(ctrl.cluster,'slurm_submit_arguments') || isempty(ctrl.cluster.slurm_submit_arguments)
  ctrl.cluster.slurm_submit_arguments = '-N 1 -n 1 --mem=%d --time=%d';
end

%% Get the job manager for the matlab cluster interface
if strcmpi(ctrl.cluster.type,'matlab')
  ctrl.cluster.jm = parcluster();
end

%% Return if this ctrl already existed
if nargin >= 2
  return
end

%% Create directory to store temporary files
% Find the first unique and unused batch_id
% Assign batch_id, batch_dir
ctrls = cluster_get_batch_list(param);

ctrl.batch_id = 1;
done = 0;
while ~done
  done = 1;
  for batch_idx = 1:length(ctrls)
    if ctrls{batch_idx}.batch_id == ctrl.batch_id
      done = 0;
      ctrl.batch_id = ctrl.batch_id + 1;
      break;
    end
  end
end

% Each batch of jobs creates a unique directory
[tmp tmp_name] = fileparts(tempname);
ctrl.batch_dir = fullfile(param.cluster.data_location,sprintf('batch_%i_%s', ctrl.batch_id, tmp_name));

%% Initialize ctrl structure and create batch directory and 4 subdirectories
ctrl.task_id = 0;
ctrl.job_id_list = [];
ctrl.job_status = '';
ctrl.error_mask = [];
ctrl.submission_queue = [];
ctrl.active_jobs = 0;
ctrl.retries = [];

ctrl.notes = {};
ctrl.cpu_time = [];
ctrl.mem = [];
ctrl.success = {};
ctrl.cpu_time_actual = [];

ctrl.in_fn_dir = fullfile(ctrl.batch_dir,'in');
mkdir(ctrl.in_fn_dir)
ctrl.out_fn_dir = fullfile(ctrl.batch_dir,'out');
mkdir(ctrl.out_fn_dir)
ctrl.stdout_fn_dir = fullfile(ctrl.batch_dir,'stdout');
mkdir(ctrl.stdout_fn_dir)
ctrl.error_fn_dir = fullfile(ctrl.batch_dir,'error');
mkdir(ctrl.error_fn_dir)
ctrl.hold_fn = fullfile(ctrl.batch_dir,'hold');

%% Create empty job id list file (one 20 character line per task)
ctrl.job_id_fn = fullfile(ctrl.batch_dir,'job_id_file');
fid = fopen(ctrl.job_id_fn,'w');
fclose(fid);

return;
