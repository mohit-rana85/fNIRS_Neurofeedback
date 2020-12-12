function x = bci_str2int( s )
%BCI_STR2INT Convert string to positive integer value.
%  terminates with error if conversion does not yield positive integer

% for config file value reading
%   // could use bci_str2uint( varargin ) to be able to specify suggested
%   // range for value, e.g. bci_str2uint( s, 10, 500 ) ...
% 
% v0.1  2003-02-27  Simon Bock <sbock@uni-tuebingen.de>

x = fix(str2double( s ));
if ~isfinite(x) | (x<0)             % isnan(), 'Inf', <0 out
    error(['BCI/TBV configuration file error: value "' s ...
           '" is not a positive integer']);
end
