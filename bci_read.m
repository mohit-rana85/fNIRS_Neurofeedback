function value = bci_read( file, field, behavior )
%BCI_READ_WAIT Read value for tag 'field'':' from config file 'file'
%   value can be optional or vital == (behavior = { 1, 'string' })
%       default string can be specified in 'behavior'

% ASCII text lines in 'file' starting with 'field'':', e.g.
% "NameTag:   value"
% are read. Behavior is variable and depends on the value of behavior
%   1 - argument is vital, wait for file to appear, terminate if field missing
%   2 - argument is optional, don't requite file nor field, simply return ''
%   'string' - argument is vital, write out 'behavior' (create file if...)
% actually doesn't matter if 2 or any other number used...
%
% v0.3  2003-03-18  Simon Bock <sbock@uni-tuebingen.de>

if behavior == 1
    bci_ui_wait( file);             % vital, wait until file is there
end
if ischar( behavior )               % vital, create if necessary
    fid = fopen( file, 'at+');  % text mode (matlab does the '\r\n' stuff)
    if fid == -1
        fid = fopen( file, 'rt');   % copied from CD ROM = read only
        behavior = '"';
    end
else
    fid = fopen( file, 'rt');   % text mode (matlab does the '\r\n' stuff)
end

value = bci_read_matchline( fid, field);

if isempty(value)
    if behavior == 1                % vital but field not found
        fclose(fid);
        errordlg(['File "' file '" does not specify "' field ':".']);
    elseif ischar( behavior )
        if behavior == '"'
            fclose(fid);
            errordlg(['Read Only file "' file '" does not specify "' field ':".']);
        end
        value = behavior;           % vital, use & write out default
        fprintf( fid, ['%s:\t%s\n'], field, value);
    end
end
fclose(fid);
