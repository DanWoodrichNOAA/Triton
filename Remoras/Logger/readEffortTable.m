function effortTable = readEffortTable(filename)
% Read an Effort workbook or CSV while preserving its header row.

[~, ~, extension] = fileparts(filename);
if any(strcmpi(extension, {'.xls', '.xlsx'}))
    cells = readcell(filename, 'Sheet', 'Effort');
    headers = string(cells(1, :));
    unnamed = ismissing(headers) | strlength(strtrim(headers)) == 0;
    headers(unnamed) = "Var" + find(unnamed);
    headers = matlab.lang.makeUniqueStrings(cellstr(headers));
    effortTable = cell2table(cells(2:end, :), ...
        'VariableNames', headers);
else
    effortTable = readtable(filename, 'TextType', 'string', ...
        'PreserveVariableNames', true);
end