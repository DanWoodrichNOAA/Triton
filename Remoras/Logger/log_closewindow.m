function log_closewindow(src,evnt)
% src is the figure number
global handles PARAMS

if (src >= 1 && src <= 3) || src == 7 || src == 9 %from 5 (old logger) to 7 (remora version)
    % sf added in 9 because bug wasn't able to close at all 2022 Aug 2
    % User attempted to close one of Triton's main windows
    % or the logger window
    
    % Kludge - to prevent user from closing the window
    % while setting effort.
    if strcmp(get(handles.effortPane(1), 'Visible'), 'on')
        r = questdlg(...
            ['Closing the log at this point will result in an ', ...
            'inconsistent log.  We strongly recommend setting Effort, ', ...
            'then closing.'], 'Really close?', ...
            'Do not close', 'Close anyway', 'Do not close');
        
        switch r
            case 'Close anyway'
                log_close([]);
            case 'Do not close'
                % do nothing.
        end
        return
    end
    options = {};
    
    %  Find last detection
    colStart = find(~cellfun(@isempty, ...
        strfind(handles.OnEffort.Headers, 'Start time')));
    colEnd =  find(~cellfun(@isempty, ...
        strfind(handles.OnEffort.Headers, 'End time')));
    lastRow = height(handles.OnEffort.Sheet);
    if lastRow < 1
        handles.log.lastDate = [];  % no detections recorded
        lastDateStr = 'none';
        last = [];
    else
        startDates = datetime(handles.OnEffort.Sheet{:, colStart}, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSSZ', 'TimeZone', 'UTC');
        if ~isempty(colEnd) && any(~ismissing(handles.OnEffort.Sheet{:, colEnd}))
            validEnd = handles.OnEffort.Sheet{:, colEnd};
            validEnd = validEnd(~ismissing(validEnd) & strlength(string(validEnd)) > 0);
            if ~isempty(validEnd)
                endDates = datetime(validEnd, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSSZ', 'TimeZone', 'UTC');
                handles.log.lastDate = max([max(startDates), max(endDates)]);
            else
                handles.log.lastDate = max(startDates);
            end
        else
            handles.log.lastDate = max(startDates);
        end
        
        lastDateStr = string(handles.log.lastDate, 'yyyy-MM-dd''T''HH:mm:ss.SSSZ');
        set(handles.end_pick.disp, 'String', lastDateStr);
        last = sprintf('Latest pick: %s', lastDateStr);
        options{end+1} = last;
    end

    % Is there a current end date from a previous session?
    previousEnd = [];  % Assume not until we learn otherwise
    endCol = find(strcmp(handles.Meta.Headers, 'Effort End'), 1, 'first');
    if ~isempty(endCol)
        endDateVal = handles.Meta.Sheet{1, endCol};
        if ~ismissing(endDateVal) && strlength(string(endDateVal)) > 0
            endDate = datetime(endDateVal, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSSZ', 'TimeZone', 'UTC');
        
            % Make the last recorded end of effort be an option if we have not
            % detected anything past the end.
            if isempty(last) || endDate >= handles.log.lastDate
                endDateStr = string(endDate, 'yyyy-MM-dd''T''HH:mm:ss.SSSZ');
                set(handles.end_previous.disp, 'String', endDateStr);
                previousEnd = sprintf('Existing:  %s', endDateStr);
                handles.log.endDate = endDate;
                options{end+1} = previousEnd;
            end
        end
    end
    
    terminate = questdlg(...
        'End logging session.  Close to cancel or denote end of effort by:', ...
        'End logging session', ...
        options{:}, 'Let me specify', 'Let me specify');

    
    switch terminate
        case ''  % User closed the dialog box
            return
        
        case last
            log_close(handles.log.lastDate);
            return
            
        case previousEnd
            log_close(handles.log.endDate)
            return
            
        case 'Let me specify'
            set(handles.log.control, 'Visible', 'off');
            set(handles.log.close, 'Visible', 'on');
            PARAMS.log.pick = 'effort_end';
            set(handles.done, 'String', 'Close log', ...
                'Callback', {@control_log, 'set_meta_end'});
            return
    end
end
