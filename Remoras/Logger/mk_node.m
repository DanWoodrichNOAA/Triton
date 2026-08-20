function node = mk_node(value, string, icon, isleaf)

try
   % In MATLAB R2022a+, the 'v0' wrapper was deliberately removed.
   % We bypass the wrapper and directly instantiate the underlying Java class.
   node = javaObjectEDT('com.mathworks.hg.peer.UITreeNode', value, string, icon, isleaf);
catch ME
   try
       % Fallback for older MATLAB versions
       node = uitreenode('v0', value, string, icon, isleaf);
   catch
       rethrow(ME);
   end
end