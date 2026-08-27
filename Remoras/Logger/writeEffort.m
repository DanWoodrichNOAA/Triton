function writeEffort(rootNode, spreadsheet)
% writeEffort(rootNode, spreadsheet)
% Based on the current effort tree rooted at rootNode,
% write the Effort to a spreadhseet.  Spreadsheet may be
% either a string indicating a filename to be used or 
% a handle to an active X (OLE) spreadsheet.


global TREE
currNode = rootNode.getFirstChild();
tLength = rootNode.getDepth();
if nargout > rootNode.getDepth()
    tLength = nargout-1;
end
struct = cell(1,tLength);
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
list = cell(0,tLength);
flag1 = 0;
level = currNode.getLevel();
first = true;

% params will be built into a matrix with default
% parameters, one row for each species.  We double
% the number of columns to accomadate users that
% need to store time with selections.
params = cell(0, 2*size(TREE.frequency,2));

while ~isempty(currNode) || level > 1
    
    previous = currNode;
    level = currNode.getLevel();
    gpValue = currNode.getValue();
    %disp(char(gpValue(2)));
    selected = strcmp(gpValue(1), 'selected');
    if selected
        level = currNode.getLevel();
        % We need to store two values for the second level of the tree
        % Common name and abbreviation
        offset = level >= 2;
        if level == 2
            values{level} = char(currNode.getName());
        end
        values{currNode.getLevel()+offset} = char(gpValue(2));
        traverseChildren = currNode.getAllowsChildren();
        
        if traverseChildren
            % Traverse children
            currNode = currNode.getFirstChild();
        else
            % At a leaf node.  values{1:level} contain the tree info
            list(end+1,1:level+offset) = values(1:level+offset);
            if first
                values{1} = '';  % effort template does not repeat group
            end
        end
    else
        traverseChildren = false;
    end
    
    %disp([num2str(isempty(currNode.getNextSibling())), ' ', num2str(~isempty(currNode.getParent()))]);
    if ~ traverseChildren
        % Don't go further down the chain
        % We are either at a leaf or we are not interested in this chain
        
        if ~isempty(currNode.getNextSibling())
            % process siblings of the current node
            currNode = currNode.getNextSibling();
        elseif ~isempty(currNode.getParent().getNextSibling())
            % no more siblings, process parent's siblings
            currNode = currNode.getParent().getNextSibling();
        elseif level ~= 1
            % process grandparent's sibling
            % Todo:  Make the whole process more general, perhaps
            %        use a stack and push/pop
            level = currNode.getParent().getParent().getLevel();
            currNode = currNode.getParent().getParent().getNextSibling();
        end
    end
    
    if previous == currNode
        break
    end
end

if ischar(spreadsheet)
    EffortFile = spreadsheet;
else
    EffortFile = spreadsheet; 
end

try
    EffortSheet = readtable(EffortFile, 'TextType', 'string', 'PreserveVariableNames', true);
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
        callMatches = strcmp(string(callVal), string(list(:, callCol)));
        speciesMatches = strcmp(string(speciesVal), ...
            string(list(:, speciesCol)));
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

        if ~isempty(list{matchIdx, 1})
            % first item in group, set group name
            EffortSheet{effortidx, groupCol} = ...
                string(list{matchIdx, 1});
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
