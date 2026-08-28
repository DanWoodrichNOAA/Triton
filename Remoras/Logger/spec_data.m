function [chartR, chartW, orderR, project, headers, parameters] = spec_data(filename)
% [chartR, chartW, orderR, project, headers, frequency] = spec_data(filename)
% Read specifications for allowable detections

effortTable = readEffortTable(filename, 'Effort');
raw = [effortTable.Properties.VariableNames; table2cell(effortTable)];
txt = cell(size(raw));
for idx = 1:numel(raw)
    txt{idx} = cellText(raw{idx});
end

headers = txt(1,:);
r = 1;
w = 1;
p = 1;
f = 1;

% Locate the headers that we need.
% Note that while we can have additional items, they must appear in order
% relative to one another.
HumanReadable = ~cellfun(@isempty, regexp(headers, 'Group|Common Name|Call'));
MachineReadable = ~cellfun(@isempty, regexp(headers, 'Group|Species Code|Call'));
Parameters = ~cellfun(@isempty, regexp(headers, 'Parameter.*'));

% make charts for the reading and writing inputs
chartR = txt(2:end, HumanReadable);
chartW = txt(2:end, MachineReadable);
parameters = txt(2:end, Parameters);

treeR = zeros(1,size(chartR, 2));
treeW = zeros(1,size(chartW, 2));

[ly,lx] = size(chartR);
orderR = zeros(ly,lx);

% [ly,lx] = size(chartW);
% orderW = zeros(ly,lx);
% disp(length(chart))
% disp(length(chart(1)))

prev = [];
for x = 1:size(chartR, 2)
    for y = 1:length(chartR)
        % Look for new name that we have not seen before
        if ~strcmp(chartR(y,x),'') && ~strcmp(chartR(y,x),prev)
            treeR(x) = treeR(x) + 1;
        end
        orderR(y,x) = treeR(x);
        prev = chartR(y,x);
    end
end

metadataTable = readEffortTable(filename, 'MetaData');
rawp = [metadataTable.Properties.VariableNames; table2cell(metadataTable)];
txtp = cell(size(rawp));
for idx = 1:numel(rawp)
    txtp{idx} = cellText(rawp{idx});
end
project = {};
projdata(:,1)= txtp(2:length(txtp));

for y = 1:length(projdata)
    if ~strcmp(projdata(y,1), '')
    project{length(project) + 1} = projdata{y};
    end
end
1;

function text = cellText(value)
if ischar(value)
    text = value;
elseif isstring(value)
    if ismissing(value) || strlength(value) == 0
        text = '';
    else
        text = char(value);
    end
elseif isnumeric(value)
    if isempty(value) || isnan(value)
        text = '';
    else
        text = num2str(value);
    end
else
    try
        value = string(value);
        if ismissing(value) || strlength(value) == 0
            text = '';
        else
            text = char(value);
        end
    catch
        text = '';
    end
end



