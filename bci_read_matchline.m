function value = bci_read_matchline( fid, field )
%BCI_READ_MATCHLINE return text after ['field',':'] OR '' if not found

% FORMAT: ASCII text lines in 'file' starting with ['field',':'], e.g.
% "NameTag:   value"
% reads until first matching line or EOF


value = '';             % in case of EOF or not-found
while ~feof(fid)
    line = fgetl(fid);
    if strncmp( line, [field ':'], length(field) +1 )   % if found NameTag:
        value = line( length(field)+2:end );            % return rest of line
        % as in the deblank() function, but remove leading + trailing spaces:
        [ row, col ] = find( ~isspace(value) );         % find nonspace chars
        value = value( min(row), min(col):max(col) );   % first to last
        break
    end
end
