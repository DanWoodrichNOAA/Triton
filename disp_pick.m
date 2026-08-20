function disp_pick(pick)
%
% display pickxyz value from pickxyz.m in Message Window
%
global HANDLES

x = get(HANDLES.pick.disp,'String');
lx = length(x);
x(lx+1) = {pick};
set(HANDLES.pick.disp,'String',x,'Value',lx+1)

%places the cursor to the bottom, need to use eval because it only works on
%terminal
try
	jDEdit = findjobj(HANDLES.pick.disp);
	if ~isempty(jDEdit)
		jDisp = javaMethod('getComponent', ...
			javaMethod('getComponent', jDEdit, 0), 0);
		jDocument = javaMethod('getDocument', jDisp);
		javaMethod('setCaretPosition', jDisp, ...
			javaMethod('getLength', jDocument));
	end
catch
	% Scrolling is optional and relies on undocumented Java internals.
end
