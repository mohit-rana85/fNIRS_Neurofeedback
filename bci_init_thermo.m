function varargout = bci_init_thermo( background, master_bci)
%BCI_INIT_THERMO - initialize figure window for data display
%   use existing active figure window, so user can rely on window position
%   calculate dimensions of common protocol & data axes, return if needed

 

%Axes dimensions; note these values are changed again in draw_thermo()
ax.l = 0.4;
ax.b = 0.05; 
ax.w = 0.2;
ax.h = 0.4;

magic.window_size = [ 232 300 560 350 ];% my default "Figure Win Position"

%_______________________________________________________________________
% read optional Window Position data, use default if not in 'master.bci'
if nargout
    window_size = master_bci;%str2num( bci_read( master_bci, 'Window_size', 2 ) );
    if isempty( window_size )
        window_size = magic.window_size;
    end
    h = gcf;
    window_oldUnits = get( h,'Units');      % remember this...
    set( h,'Units','Pixels');
    set( h,'Position', window_size);
    set( h, 'Units', window_oldUnits);      % restore window properties
end
%_______________________________________________________________________
delete( get(gcf, 'Children') );         % clear all existing contents

set( gcf, 'MenuBar', 'none');           % unneeded; unwanted brightness

set( gcf, 'BackingStore', 'off');           % schneller
set( gcf, 'Color', background );
%set( gcf, 'Colormap', '');
set( gcf, 'RendererMode', 'manual');    % für 'DoubleBuffer'
set( gcf, 'Renderer', 'painters');      % für 'DoubleBuffer'
set( gcf, 'DoubleBuffer', 'on');        %  sonst flackert es !!
% set( gcf, 'ShareColors', 'off');            % genau meine Farben
set( gcf, 'MinColormap', length(get(gcf,'ColorMap')) ); % nett zum System

%_______________________________________________________________________

if nargout == 1
    varargout(1) = {ax};
end
