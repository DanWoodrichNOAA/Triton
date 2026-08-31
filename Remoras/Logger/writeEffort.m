function writeEffort(rootNode, spreadsheet)
% writeEffort(rootNode, spreadsheet)
% Based on the current effort tree rooted at rootNode,
% write the Effort table to a CSV file.


global TREE
if strcmp(TREE.gran, 'binned')
    granOffset = 2;
    granCell = cell(1,2);%creat a  cell array, will only have two values and set
    granCell{1} = TREE.gran;%to appropiate values. 
    granCell{2} = TREE.binTime;
    binnedTime = true;
else
    granOffset = 1;
    granCell = cell(1,1);
    granCell{1} = TREE.gran;
    binnedTime = false;
end
list = selectedEffortLeaves(rootNode);

if ischar(spreadsheet)
    EffortFile = spreadsheet;
else
    error('Logger:InvalidEffortFile', 'Effort output must be a filename.');
end

try
    EffortSheet = readEffortTable(EffortFile);
catch
    errordlg('Master template missing Effort file');
    return;
end

headerRangeCell = EffortSheet.Properties.VariableNames;

% Traverse rows, removing unselected ones and setting the granularity
% where needed.  We move in reverse order as rows are deleted and this
% prevents problems with rows shifting.  Our list variable must be
% in the same order as the effort sheet or things will break.  As the
% list was generated from the effort sheet, this should not be problematic.

speciesCol= find(strcmp(headerRangeCell, 'Species Code') | strcmp(headerRangeCell, 'Species_Code'));
callCol = find(strcmp(headerRangeCell, 'Call'));
granCol = find(strcmp(headerRangeCell, 'Granularity'));
groupCol = find(strcmp(headerRangeCell, 'Group'));
listGroupCol = 1;
listSpeciesCol = 3;
listCallCol = 4;

requiredColumns = {speciesCol, callCol, granCol, groupCol};
if any(cellfun(@(column) ~isscalar(column), requiredColumns))
    error('Logger:InvalidEffortTemplate', ...
        ['Effort template must contain exactly one each of Group, ', ...
        'Species Code, Call, and Granularity.']);
end

EffortSheet.(headerRangeCell{granCol}) = ...
    string(EffortSheet.(headerRangeCell{granCol}));
EffortSheet.(headerRangeCell{groupCol}) = ...
    string(EffortSheet.(headerRangeCell{groupCol}));

if length(granCell) > 1
    % BinSize required
    granLastCol = find(strcmp(headerRangeCell, 'BinSize_m'));
else
    granLastCol = granCol;
end

selectedidx = size(list, 1);

RowsN = height(EffortSheet);  % #rows in sheet
effortidx = RowsN;

whitespace = false;  % for retaining spacing between entries 
while effortidx > 0 && selectedidx >= 1
    % Is the current row equivalent to the last row in list?
    values = EffortSheet(effortidx, :);
    
    callVal = values{1, callCol};
    if iscell(callVal), callVal = callVal{1}; end
    speciesVal = values{1, speciesCol};
    if iscell(speciesVal), speciesVal = speciesVal{1}; end
    
    callPresent = ~all(ismissing(string(callVal)));
    speciesPresent = ~all(ismissing(string(speciesVal)));
    if callPresent && speciesPresent
        callMatches = strcmp(string(callVal), string(list(:, listCallCol)));
        speciesMatches = strcmp(string(speciesVal), ...
            string(list(:, listSpeciesCol)));
        matchIdx = find(callMatches & speciesMatches, 1, 'last');
    else
        matchIdx = [];
    end

    if ~isempty(matchIdx)
        % Matches, add granularity
        EffortSheet{effortidx, granCol} = string(granCell{1});
        if length(granCell) > 1
            EffortSheet{effortidx, granLastCol} = granCell{2};
        end

        if ~isempty(list{matchIdx, listGroupCol})
            % first item in group, set group name
            EffortSheet{effortidx, groupCol} = ...
                string(list{matchIdx, listGroupCol});
        end
        list(matchIdx, :) = [];
        selectedidx = size(list, 1);
        whitespace = false;
    else
        % The first empty row after retaining an entry is retained.
        % All others are removed.
        has_data = any(~ismissing(values{1, :}) & strlength(string(values{1, :})) > 0);        
        if has_data || whitespace
            EffortSheet(effortidx, :) = [];
        end
        if ~ has_data
            whitespace = true;
        end
    end
    effortidx = effortidx - 1;
end

% Remove any remaining rows
while effortidx > 0
    EffortSheet(effortidx, :) = [];
    effortidx = effortidx - 1;
end

writetable(EffortSheet, EffortFile);

function list = selectedEffortLeaves(rootNode)
list = cell(0, 4);
node = rootNode.getNextNode();
while ~isempty(node)
    nodeValue = node.getValue();
    if ~node.getAllowsChildren() && strcmp(char(nodeValue(1)), 'selected')
        speciesNode = node.getParent();
        groupNode = speciesNode.getParent();
        speciesValue = speciesNode.getValue();
        list(end+1, :) = {char(groupNode.getName()), ...
            char(speciesNode.getName()), char(speciesValue(2)), ...
            char(nodeValue(2))};
    end
    node = node.getNextNode();
end
