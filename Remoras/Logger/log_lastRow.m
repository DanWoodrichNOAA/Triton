function last = log_lastRow(sheetH)
% last = log_lastRow(sheetH)
% Return the last used row for a table or Excel worksheet.

if istable(sheetH)
	last = height(sheetH);
else
	last = sheetH.UsedRange.Rows.Count;
end