function bci=bci_goFeedback(bci)
%Start the reading data files and feedback
fprintf('\nFeedback protocol started.\n');
bci.prt.b.mydate = datestr(now);
bci.fig=figure('NumberTitle', 'off');
bci.fbwindow_size = [400 100 400 300];
set(bci.fig,'Position', bci.fbwindow_size);
set(bci.fig, 'MenuBar', 'none');
bci.prt.b.ui.thermo_ax = bci_init_thermo( 'k',  [232  240  500  420] );
bci.prt.b.ui.thermo_color=  [0.5 0.5 0.6]; %color for the thermometer
bci.prt.b.ui.backcolor = [0 0 0]; %initialize
% %Figure for image display

if isfield(bci.prt,'bci_file')
   % image_fig = figure;
    [bci.prt.b.images, bci.prt.b.ui, bci.prt.b.ui.images ] = bci_images( bci.prt.bci_file,bci.prt.b.ui,bci,'bci' ); % read optional image files to display on top of feedback window
else
    bci.prt.b.images.count =1;
    [bci.prt.b.images, bci.prt.b.ui, bci.prt.b.ui.images ] = bci_images([bci.prt_path,filesep,'fixation.jpg'],bci.prt.b.ui,bci,'fixation' );
end
 bci = draw_thermo(bci.fig,bci.thermo_bars,bci.prt.b.ui.thermo_color,bci.prt.b.ui.backcolor,bci);
 bci.b.ui = bci_image_display(bci.fig, 1 , bci.prt.b.ui, bci.prt.b.images, 'first' );

%channel of interest (choi) and the contrast
if isempty( str2num(bci.run_number))
    bci.ch_weights(1:bci.totNumChs)=1;
else    
    bci.ch_weights(1:bci.totNumChs)=0;
end
for i=1:size(bci.chContrast,2)
    bci.ch_weights(abs(bci.chContrast(i)))=bci.chWeight(i); %set positive weight to 1 and neg weights to -1
end
%now run the thermo feedback
bci=bci_view(bci);