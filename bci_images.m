function [ images, ui, RAM ] = bci_images( filename,ui,bci,info )
%BCI_IMAGES Read optional image files to display on top of feedback window

% images: Informationen zu den files // nur für Debugging //
% RAM: Daten aller angegeben Bilder in .data, .map, .volume
% ui.ax will be adapted to new size with image axis (in ui.image)
%
% v0.3  2003-05-03  Simon Bock <sbock@uni-tuebingen.de>

% wir brauchen die Anzahl - default '0', aber '' würde str2int verwirren ;) //
if strcmp(info,'bci')
    images.count = bci_str2int( bci_read( filename, 'NrOfImages', 0 ));
    if images.count > 0
        try
            images.folder = bci_read( filename, 'ImageFolder', 1 );
        catch
            images.folder=[bci.root_path,filesep ,'Protocol'];
        end
        if ~isdir(images.folder)
            images.folder=[bci.root_path,filesep ,'Protocol'];
        end
        for i = 1:images.count  % images.file{} will be cell array of names
            try
                name = bci_read( filename, [ 'Image' int2str(i) ], 1 );
            catch
                
            end
            %images.file{i} = fullfile( images.folder, value );     % the whole thing...
            [ name, rest ] = strtok( name, ';');    % my 'Filename; Volumes' delimeter
            [s, e] = strtok(rest, ','); %num of volumes to show the picture
            start_vol = str2num( s );
            end_vol = str2num( e );
            images.volume{i} = start_vol:end_vol; %set all volumes in between for displaying this image
             start_vol=[];end_vol=[];
            [ t, rest ] = strtok( name, [ filesep '\/:'] ); % already contains path ?
            if isempty(rest)
                name = fullfile( images.folder, name );   % add path
            end
            try
                [ RAM.data{i}, RAM.map{i} ] = imread( name );
            catch
                [pa f]=fileparts(name);
                name =  [bci.root_path,filesep ,'Protocol',filesep, pa]   ;
                [ RAM.data{i}, RAM.map{i} ] = imread( name );
            end
            images.file{i} = name;
        end
        RAM.file = images.file;
        RAM.volume = images.volume;     % // somehow duplicate entry //
        RAM.count = images.count;     % // somehow duplicate entry //
        %RAM.duration = images.duration;
        %ui.ax.h = ui.ax.h/4; % nw
        % ui.ax.h = ui.ax.h / 2;      % fit two
        % ax.h = ui.ax.h;             % the second one
        % % do a little for the aspect ratio...
        % ax.window = get( gcf, 'Position');% all Units are screen-relative ?'normalized'
        % ax.r = ax.window(4) / ax.window(3);     % height / with
        % ax.w = ax.h * ax.r;                     % shrink width by ratio (4:3 fullscreen)
        
        
        %image axes dimensions
        % ui.image_ax.l = 1/3;
        % ui.image_ax.b = 0.5+0.05;
        % ui.image_ax.w = 1/3;
        % ui.image_ax.h = 0.4;
        
        % ui.image_ax.w = .5
        % ui.image_ax.h = .5;
        % ui.image_ax.l = (1 - ui.image_ax.w) / 2;  % left      // in the middle of figure
        % ui.image_ax.b = (1 - ui.image_ax.h) / 2;  % bottom
        
        %Image axes set to full screen for insula localization (Ranga)
        ui.image_ax.w = 1.0;
        ui.image_ax.h = 1.0;
        ui.image_ax.l = 0.0;  % left
        ui.image_ax.b = 0.0;  % bottom
        
         ui.del_image = axes( 'Position', [ ui.image_ax.l ui.image_ax.b ui.image_ax.w ui.image_ax.h ], 'Color', 'k');
        
        set( ui.del_image, 'DataAspectRatio', [ 1 1 1] )
        
        set(  ui.del_image, 'Visible','off' ); % hat ohne s.o. keinen Effekt
   end
elseif strcmp(info,'fixation')
        start_vol = 1;
        end_vol = bci.prt.initial_rest;
        images.volume{1} = start_vol:end_vol; images.count=1;
        images.file{1} = [bci.prt_path,'fixation.jpg'];
        [ RAM.data{1}, RAM.map{1} ] = imread( images.file{1} );
        RAM.file = images.file;
        RAM.volume = images.volume;     % // somehow duplicate entry //
        RAM.count = images.count; 
        ui.del_image_ax.w = 1.0;
        ui.del_image_ax.h = 1.0;
        ui.del_image_ax.l = 0.0;  % left
        ui.del_image_ax.b = 0.0;  % bottom
        
        ui.del_image = axes( 'Position', [ ui.del_image_ax.l ui.del_image_ax.b ui.del_image_ax.w ui.del_image_ax.h ], 'Color', 'k');
        
        set( ui.del_image, 'DataAspectRatio', [ 1 1 1] )
        
        set( ui.del_image, 'Visible','off' );  % hat ohne s.o. keinen Effekt
        
              % no image data
end
