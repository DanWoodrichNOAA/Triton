function log_open(MetadataNames, MetadataValues)
% log_open(MetadataNames, MetadataValues)
% Open spreadsheet and set specified metavalues.  
% 
% MetadataNames and MetadataValues contain an optional pair of cell arrays
% with a set of field names and their corresponding values for the Metadata
% shee in the active log file
% Valid names and values depend upon the spreadsheet template that is used
% for the logger, but the following example indicates things some of the
% fields for which this was developed:
%
% log_start({'User ID', 'Project', 'Site'}, {'ritter', 'SOCAL', 'A'});
% If this is a continued log sheeet, use
% log_start(); 

global handles HANDLES

ShowSpreadsheet = false;  % set to true for debugging

% Enable going off-effort (ad-hoc)
%set(handles.adhoc, 'Visible', 'on');

% Set up handles for files
handles.Meta.File = fullfile(handles.logdir, sprintf('%s_MetaData.csv', handles.logbase));
handles.OnEffort.File = fullfile(handles.logdir, sprintf('%s_Detections.csv', handles.logbase));
handles.OffEffort.File = fullfile(handles.logdir, sprintf('%s_AdhocDetections.csv', handles.logbase));

% Check writability
[fid, ~] = fopen(handles.Meta.File, 'a');
if fid < 0
    errordlg(sprintf('Log files in %s are not writable', handles.logdir));
    delete(handles.logcallgui);  % Remove logger gui
    clear GLOBAL handles;  % No longer valid
    return;
end
if fid > 0, fclose(fid); end

try
    handles.Meta.Sheet = readtable(handles.Meta.File, 'TextType', 'string', 'PreserveVariableNames', true);
catch
    errordlg('No MetaData file in log directory');
    delete(handles.logcallgui);
    clear GLOBAL handles; % No longer valid
    return
end

set(handles.logcallgui, 'CloseRequestFcn', @log_closewindow)

for f = {'main', 'ctrl', 'msg'}
    field = f{1};
    if isfield(HANDLES.fig, field) && isvalid(HANDLES.fig.(field))
        handles.log.oldclosefn.(field) = get(HANDLES.fig.(field), 'CloseRequestFcn');
        set(HANDLES.fig.(field), 'CloseRequestFcn', @log_closewindow);
    end
end

handles.Meta.Headers = handles.Meta.Sheet.Properties.VariableNames;

if nargin == 2
    if length(MetadataNames) ~= length(MetadataValues)
        error('Mismatched name/value pairs');
    end

    for idx=1:length(MetadataNames)
        col = find(strcmp(handles.Meta.Headers, MetadataNames{idx}));
        if isempty(col)
            errordlg(sprintf('Missing column %s from MetaData sheet', ...
                MetadataNames{idx}));
        else
            val = MetadataValues{idx};
            if ischar(val) && size(val,1) > 1
                val = val(1,:);
            end
            if iscell(val)
                val = val{1};
            end
            columnName = handles.Meta.Headers{col};
            handles.Meta.Sheet.(columnName) = ...
                string(handles.Meta.Sheet.(columnName));
            handles.Meta.Sheet(1, col) = {string(val)};
        end
    end
    writetable(handles.Meta.Sheet, handles.Meta.File);
end

% Save and store log and ad-hoc column labels
try
    handles.OnEffort.Sheet = readtable(handles.OnEffort.File, 'TextType', 'string', 'PreserveVariableNames', true);
    handles.OnEffort.Headers = handles.OnEffort.Sheet.Properties.VariableNames;
    handles.OnEffort.Sheet = normalize_detection_columns( ...
        handles.OnEffort.Sheet, handles.OnEffort.Headers);
    handles.OnEffort.ParamCols = parameter_columns(handles.OnEffort.Headers);
catch
    errordlg('No Detections sheet in log folder');
end

try
    handles.OffEffort.Sheet = readtable(handles.OffEffort.File, 'TextType', 'string', 'PreserveVariableNames', true);
    handles.OffEffort.Headers = handles.OffEffort.Sheet.Properties.VariableNames;
    handles.OffEffort.Sheet = normalize_detection_columns( ...
        handles.OffEffort.Sheet, handles.OffEffort.Headers);
    handles.OffEffort.ParamCols = parameter_columns(handles.OffEffort.Headers);
catch
    warndlg('The AdhocDetections sheet is missing.  No adhoc detections will be permitted');
    set(handles.adhoc, 'Visible', 'off');    % Disable off-effort button
end


% Create directories for images and audio if they do not already exist
for fname = {'imagedir', 'audiodir'}
    field = fname{1};
    if ~exist(handles.log.(field), 'dir')
        [retval, msg] = mkdir(handles.log.(field));
        if ~ retval
            errordlg('Unable to create %s\n%s', handles.log.(field), msg);
        end
    end
end

% fetch metadata that we expect to be static
fields = {'User ID',  'DeploymentId'};
for fidx = 1:length(fields);
    tmp = strrep(fields{fidx}, ' ', '_');  % no spaces
    col = find(strcmp(handles.Meta.Headers, fields{fidx}));
    if ~ isempty(col)
        handles.Meta.(tmp) = handles.Meta.Sheet{1, col};
    end
end

% This name is used as part of the image and audio filenames 
% when the user takes a snapshot.
handles.Meta.file_tag = handles.Meta.DeploymentId;

% Disable crosshair pointers when window loses focus
% This relies on undocumented Matlab functionality.
%
% Creates more problems than its worth due to the fulllcrosshair pointer
% bug workaround in set_pointer shifting focus to the window.  
% jframe = get(HANDLES.fig.main, 'JavaFrame');
% jaxis = jframe.getAxisComponent();
% set(jaxis, 'FocusGainedCallback', {@pickxyz, true});
% set(jaxis, 'FocusLostCallback', {@set_pointer, HANDLES.fig.main, 'arrow'});

function cols = parameter_columns(headers)
% cols = parameter_columns(headers)
% Parse headers for parameters and return a cell array such that
% cols{N} contains the column index for the Nth parameter.

params = regexp(headers, 'Parameter\s(?<n>\d+)', ...
    'ignorecase', 'names');
paramI = ~cellfun(@isempty, params);
if any(paramI)
    cols = cell(1, max(str2double(cellfun(@(x) x.n, params(paramI), 'UniformOutput', false))));
    for idx=find(paramI)
        cols{str2double(params{idx}.n)} = idx;
    end
else
    cols = {};
end

function sheet = normalize_detection_columns(sheet, headers)
for idx = 1:length(headers)
    if ~contains(headers{idx}, 'Parameter', 'IgnoreCase', true)
        sheet.(headers{idx}) = string(sheet.(headers{idx}));
    end
end
