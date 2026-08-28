function log_close(end_effort_date)
% log_close(end_effort_date)
% Close off the log with an end effort date.
% In case of catastrophic failure/user abort, may be called without an
% end date in which case none is written.

global handles HANDLES PARAMS

% Locate the end of effort
effortEnd = 'Effort End';
col = find(strcmp(handles.Meta.Headers, effortEnd), 1, 'first');
if ~ isempty(end_effort_date)
    if isempty(col)
        errordlg(sprintf('Column %s missing from MetaData sheet', effortEnd));
        return
    else
        columnName = handles.Meta.Headers{col};
        handles.Meta.Sheet.(columnName) = string(handles.Meta.Sheet.(columnName));
        handles.Meta.Sheet{1, col} = string(end_effort_date, ...
            'yyyy-MM-dd''T''HH:mm:ss.SSSZ');
    end
end

PARAMS.log.pick = [];  % Turn off time X freq callback
pickxyz(true);  % reset cursor

% Save and close up
writetable(handles.Meta.Sheet, handles.Meta.File);
if isfield(handles, 'OnEffort') && isfield(handles.OnEffort, 'Sheet')
    writetable(handles.OnEffort.Sheet, handles.OnEffort.File);
end
if isfield(handles, 'OffEffort') && isfield(handles.OffEffort, 'Sheet')
    writetable(handles.OffEffort.Sheet, handles.OffEffort.File);
end

% Restore original closing function
for f = {'main', 'ctrl', 'msg'}
    field = f{1};
    if isfield(HANDLES.fig, field) && isfield(handles.log.oldclosefn, field) ...
            && isvalid(HANDLES.fig.(field))
        set(HANDLES.fig.(field), ...
            'CloseRequestFcn', handles.log.oldclosefn.(field));
    end
end

delete(handles.logcallgui);  % Remove logger gui
clear global handles;  % No longer valid
