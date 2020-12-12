function bci_ui_wait( filename )
%BCI_UI_WAIT - show window until regular file 'filename' is there
%  returns only if file exists or appears, else terminates program.

% if file exists, returns immediately.
% if filename is not a regular file, exit with error()
% else  - if file appears, return.
%       - if cancel is pressed, exit with error()


switch exist(filename)
  case 2
    return;             % our file is already there
  case 0
    window_title = 'Looking for file...';
    window_text = strrep( filename, '\', '\\');     % else '\' denotes ESCAPE
    window_text = strrep( window_text, '_', '\_');  % else '_' = subscript
    window_text = strvcat( ' ', ['File "' window_text '" not found.'],...
        ' ', 'Waiting for it to appear...' );
    screen_oldUnits = get( 0,'Units');      % remember this...
    set( 0,'Units','normalized');           % normalized is [0 1]
% unfortunately, release 5.3 (11) on the test comp has only 2 arguments...
if ~isempty( findstr( version, 'R11') )
    h = waitbar(0, window_text );
else
    h = waitbar(0, window_text, 'Name',window_title, 'Pointer','watch',...
        'CreateCancelBtn','delete(gcf)' );
end
    window.oldUnits = get( h,'Units');      % remember this...
    set( h,'Units','normalized');           % normalized is [0 1]
    window.size = get( h,'Position');
    window.size(1) = 0 + window.size(1)/100;    % left + "a little"
    % titlebar should be visible - 17*height/100 is approx. height
if ~isempty( findstr( version, 'R11') )
    window.size(2) = 1 - window.size(4) - 25*window.size(4)/100;    % a little 
else
    window.size(2) = 1 - window.size(4) - 17*window.size(4)/100;    % top
end
    set( h,'Position', window.size);        % move it
    set( 0, 'Units', screen_oldUnits);      % restore screen
    set( h, 'Units', window.oldUnits);      % restore window
    while ishandle(h)                   % while window is open
        switch exist(filename)
          case 2
            close(h);       % close window, go back to caller
            return
          case 0            % continue while loop...
          otherwise
            break           % exit loop, throw error
        end
        pause(0.5)          % is 1/10 second a good time to wait ? //
    end
    if ~ishandle(h)
        errordlg(['File "' filename '" not found.']);
    end
    close(h);
end
errordlg(['"' filename '" is not a regular file.']);
