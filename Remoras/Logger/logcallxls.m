function logcallxls(action)
% logcallxls(action)
% Store an action to the log file

global handles PARAMS TREE


badhandles = [];
entry.src_file = [];

% Verify dates and try to obtain source audio
for f = {'pickstartdisplay', 'pickenddisplay'}
    f = f{1};
    value = get(handles.(f), 'String');
    try
        if ~ handles.log.pickend_mandatory  && strcmp(f, 'pickenddisplay')
            % Allowed to skip end dates?
            if isempty(value)
                continue;
            end
        end
        entry.(f) = datetime(value, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSSZ', 'TimeZone', 'UTC');
        if isempty(entry.(f)) || any(isnat(entry.(f)))
            badhandles(end+1) = handles.(f);
        end
    catch
        badhandles(end+1) = handles.(f);
    end
   
    if isempty(entry.src_file)
        % time, freq, and filename are stored when a user picks a time x freq node.
        % However, they could have entered the start date by hand (or modified it
        % after a pick) in which case we won't know what file they took it from.
        % If its present, use it from either the start or end pick
        tf = get(handles.(f), 'UserData');
        if ~isempty(tf)
            entry.src_file = tf.src_file;
        end
    end

end


if isfield(entry, 'pickenddisplay') && (entry.pickenddisplay < entry.pickstartdisplay)
    badfield(handles.pickenddisplay, 'Before start', .5);
    return
end
Svalue = get(handles.species.pulldown, 'Value');
entry.species = TREE.speciesW{Svalue};

% Retrieve attributes of calls (if any)
entry.callAttrib = get(handles.species.pulldown, 'UserData');

% Retrieve active call types
% Not necessarily in same order as call attributes
callH = get(handles.speciesbuttons, 'children');
callV = get(callH, 'Value');
if iscell(callV)  % when multiple calls are active, callV is a cell array
    callV = logical(cell2mat(callV));
else
    callV = logical(callV);
end
if sum(callV) == 0
    % Must have at least one call type selected
    badhandles(end+1:end+length(callH)) = callH;
else
    entry.calls = get(callH(callV), 'String');
    if ischar(entry.calls)
        entry.calls = {entry.calls};  %ensure cell array
    end
end

if ~isempty(badhandles)
    badfield(badhandles, [], .6);
    return;
end

% Generate event id
time = datetime('now', 'TimeZone', 'UTC');
entry.event = string(time, 'yyyy-MM-dd''T''HH:mm:ss.SSSZ');

deploymentTag = string(handles.Meta.file_tag);
if ismissing(deploymentTag) || strlength(strtrim(deploymentTag)) == 0
    errordlg(['DeploymentId is missing from the log metadata. ' ...
        'Set DeploymentId in the MetaData CSV before logging.'], ...
        'Missing deployment metadata');
    return
end

speciesTag = string(TREE.speciesR{Svalue});
if ismissing(speciesTag) || strlength(strtrim(speciesTag)) == 0
    errordlg('Select a species with a valid species code before logging.', ...
        'Missing species code');
    return
end

% Generate the basename for image and audio files
entry.fname_time = sprintf('%s-%s-%s', ...
    char(speciesTag), char(deploymentTag), ...
    char(string(entry.pickstartdisplay, 'yyyyMMdd''T''HHmmss')));

entry.comment = get(handles.comments, 'String');

% find out if audio or image files were created 
set(handles.savexwavbutton, 'String', 'Save Audio')
if ~ isempty(handles.log.audio);
    [dir, fname, ext] = fileparts(handles.log.audio);
    if regexp(handles.log.audio, '.*\.x\.wav$')
        ext = '.x.wav';
    end
    entry.audio = [entry.fname_time, ext];
    success = movefile(handles.log.audio, fullfile(dir, entry.audio));
    if ~ success
        errordlg(sprintf('Unable to rename %s to %s.  Permission problem?', ...
            handles.log.audio, fullfile(dir, entry.audio)));
        handles.log.audio = [];
        return
    end
else
    entry.audio = [];
end
handles.log.audio = [];

set(handles.savejpegbutton, 'String', 'Save Image')
if ~ isempty(handles.log.image)
    [dir, fname, ext] = fileparts(handles.log.image);
    entry.image = [entry.fname_time, ext];
    success = movefile(handles.log.image, fullfile(dir, entry.image));
    if ~ success
        handles.log.image = [];
        errordlg(sprintf('Unable to rename %s to %s.  Permission problem?', ...
            handles.log.image, fullfile(dir, entry.image)));
        return
    end
else
    entry.image = [];
end
handles.log.image = [];

% Data for detection entry has been gathered, determine where it
% will be stored.
detection = handles.(PARAMS.log.mode);

% Add one row for each call that is being logged
for callIdx = 1:length(entry.calls)
    
    % adjust event number to make unique
    if callIdx > 1
        entry.event = string(datetime('now', 'TimeZone', 'UTC'), 'yyyy-MM-dd''T''HH:mm:ss.SSSZ');
    end
    
    newRow = cell(1, length(detection.Headers));
    
    for hidx = 1:length(detection.Headers)
        if contains(detection.Headers{hidx}, 'Parameter', 'IgnoreCase', true)
            continue  % parameters are a special case
        end
        
        % Some fields are only populated for the first call
        firstonly = false; 
        
        switch lower(detection.Headers{hidx})
            case 'input file'
                newRow{hidx} = entry.src_file;
            case 'start time'
                newRow{hidx} = string(entry.pickstartdisplay, 'yyyy-MM-dd''T''HH:mm:ss.SSSZ');
            case 'end time'
                if isfield(entry, 'pickenddisplay')
                    newRow{hidx} = string(entry.pickenddisplay, 'yyyy-MM-dd''T''HH:mm:ss.SSSZ');
                end
            case 'event number'
                newRow{hidx} = entry.event;
            case 'species code'
                newRow{hidx} = entry.species;
            case 'call'
                newRow{hidx} = entry.calls{callIdx};
            otherwise 
                firstonly = true;
        end
        
        if callIdx == 1 && firstonly
            switch lower(detection.Headers{hidx})
                case 'audio'
                    if ~ isempty(entry.audio)
                        newRow{hidx} = entry.audio;
                    end
                case 'image'
                    if ~ isempty(entry.image)
                        newRow{hidx} = entry.image;
                    end
                case 'comments'
                    if ~ isempty(entry.comment)
                        newRow{hidx} = entry.comment;
                    end
            end
        end
    end
    
    % Handle parameters associated with the call
    % Find the parameters associated with the call:
    attrIdx = find(strcmp({entry.callAttrib.call}, entry.calls{callIdx}) == 1);
    % Set parameters
    for pidx = 1:length(entry.callAttrib(attrIdx).values)
        if ~ isnan(entry.callAttrib(attrIdx).values(pidx))
            % Populate cell associated with parameter pidx
            colIdx = detection.ParamCols{pidx};
            newRow{colIdx} = entry.callAttrib(attrIdx).values(pidx);
        end
    end
    
    currentRow = height(detection.Sheet) + 1;
    for hidx = 1:length(detection.Headers)
        if ~isempty(newRow{hidx})
            columnName = detection.Headers{hidx};
            if contains(columnName, 'Parameter', 'IgnoreCase', true)
                detection.Sheet.(columnName)(currentRow, 1) = newRow{hidx};
            else
                value = string(newRow{hidx});
                detection.Sheet.(columnName)(currentRow, 1) = join(value, newline);
            end
        end
    end
end

handles.(PARAMS.log.mode) = detection;
writetable(detection.Sheet, detection.File);
control_log('display_lastentry');  % Update last logged entry

% Reset parameters while preserving the selected species and call types.
checked = get(handles.calltype, 'Value');
if iscell(checked)
    checked = cell2mat(checked);
end
callAttr = get(handles.species.pulldown, 'UserData');
for idx = 1:length(callAttr)
    callAttr(idx).values(:) = NaN;
    callAttr(idx).timefreq(:) = NaN;
end
set(handles.species.pulldown, 'UserData', callAttr);

% Find last checked box and invoke the callback
if sum(checked) > 0
    % At leat one call type was checked, call the selection callback
    % for any one of them to update the parameters
    paramfn = get(handles.calltype(1), 'Callback');
    paramfn{1}([], [], []);
end

for f = {'pickstartdisplay', 'pickenddisplay', 'comments'}
    f = f{1};
    set(handles.(f), 'String', '');
end

1;
