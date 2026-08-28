function entries = log_entries(effort, rows, format)
% log_entries(effort, rows, format)
% Given a structure containing information about on/off effort,
% return detections for the specified table rows. The function log_lastRow
% can be used to find the last row used.
% If variable format is true, entry is formatted as a string and 
% entries will contain an array of strings.  When format is false, 
% a matrix of values are returned.
%
% example:  sprintf('%s\n', log_entries(handles.OnEffort, 2:5, true)

global TREE;


commonnames = true;

if isempty(rows)
    entries = {};
end

lastRow = log_lastRow(effort.Sheet);
if rows(end) > lastRow 
    error('Detection table only has %s rows', lastRow);
end

% Values returned
entries = table2cell(effort.Sheet(rows, :));

if commonnames && size(TREE.textW, 2) >= 2 && size(TREE.textR, 2) >= 2
    namecol = find(strcmpi(effort.Headers, 'Species Code'), 1);
    for idx=1:size(entries, 1)
        if isempty(namecol)
            break
        end
        speciesCode = string(entries{idx, namecol});
        codeidx = find(strcmp(string(TREE.textW(:, 2)), speciesCode), ...
            1, 'first');
        if ~isempty(codeidx)
            entries{idx, namecol} = TREE.textR{codeidx, 2};
        end
    end
end

1;

           
if format
    if ismac
        UseCols = {
            'SpeciesCode', '%s'
            'Call', '%s'
            'StartTime', 'date'
            'EndTime', 'date'
            };
    else
        UseCols = {
            'Species Code', '%s'
            'Call', '%s'
            'Start time', 'date'
            'End time', 'date'
            };
    end
    formatted = cell(size(entries, 1), 1);
    for lidx=1:size(entries, 1)
        str = '';
        for fidx = 1:size(UseCols, 1)
            cidx = findHeader(UseCols{fidx, 1}, effort);
            switch UseCols{fidx, 2}
                case 'date'
                    if ischar(entries{lidx, cidx}) || isstring(entries{lidx, cidx})
                        value = string(entries{lidx, cidx});
                        if ~ismissing(value) && strlength(value) > 0
                            str = sprintf('%s%s ', str, char(value));
                        end
                    elseif ~isempty(entries{lidx, cidx}) ...
                            && ~isnan(entries{lidx, cidx})
                        str = sprintf('%s%s ', str, ...
                            datestr(entries{lidx, cidx} + ...
                            date_epoch('excel'),'YYYY-mm-DD HH:MM:SS'));
                    end
                case '%s'
                    value = string(entries{lidx, cidx});
                    if ~ismissing(value) && strlength(value) > 0
                        str = sprintf('%s%s ', str, char(value));
                    end
            end
        end
        formatted{lidx} = str;
    end
    entries = formatted;
end

function colI = findHeader(field, effort)
% Return logical array indicating the column the specified header is in
colI = ~cellfun(@isempty, strfind(effort.Headers, field));
