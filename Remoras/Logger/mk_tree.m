function [tree, container] = mk_tree(node)

try
   % In MATLAB R2022a+, the 'v0' wrapper was deliberately removed.
    % Instantiate the peer directly and embed its Swing component.
   tree = javaObjectEDT('com.mathworks.hg.peer.UITreePeer');
    [~, container] = javacomponent(tree.getScrollPane(), [0 0 1 1], node);
catch ME
   try
       % Fallback for older MATLAB versions
       [tree, container] = uitree('v0', node);
   catch
       tree = uitree('v0', node);
       container = tree;
   end
end