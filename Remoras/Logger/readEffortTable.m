function effortTable = readEffortTable(filename, sheetName)
% Read a Logger template sheet or CSV while preserving its header row.

if nargin < 2
    sheetName = 'Effort';
end

filename = templateSheetFile(filename, sheetName);
cells = readcell(filename);
headers = string(cells(1, :));
unnamed = ismissing(headers) | strlength(strtrim(headers)) == 0;
headers(unnamed) = "Var" + find(unnamed);
headers = matlab.lang.makeUniqueStrings(cellstr(headers));
effortTable = cell2table(cells(2:end, :), 'VariableNames', headers);

function filename = templateSheetFile(filename, sheetName)
if strcmp(sheetName, 'Effort')
    return
end

[folder, base, extension] = fileparts(filename);
sheetSuffixes = {'_Effort', '_MetaData', '_Detections', '_AdhocDetections'};
for idx = 1:length(sheetSuffixes)
    suffix = sheetSuffixes{idx};
    if length(base) >= length(suffix) ...
            && strcmp(base(end-length(suffix)+1:end), suffix)
        base = base(1:end-length(suffix));
        break
    end
end

candidate = fullfile(folder, [base, '_', sheetName, extension]);
if exist(candidate, 'file')
    filename = candidate;
end