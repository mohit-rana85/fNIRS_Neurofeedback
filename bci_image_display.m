function [ui]= bci_image_display(fig, volume, ui, images,grads )
%BCI_IMAGE_DISPLAY Read stimulus image to display on top of feedback window

% // besser wäre eine Lookup-Table zur Anzeige: in b.data(1,:) = BildNr //
% structure 'images' will contain
%   .count:     Anzahl Bilder
%   .volume{}:  Zur Messung von welchem Volume anzeigen ?
%   .data{}:    Bilddaten
%   .map{}:     Colormap dazu - aber bisher war alles Truecolor...
%
% v0.1  2003-03-05  Simon Bock <sbock@uni-tuebingen.de>
global last_gobjects
global previous_grads;
global displayingImage;
global preImageFile;
global preImageHandle;
if strcmp(grads,'No')
    if find( [ images.volume{:} ] == volume )       % gibts bessere Wege dafür ?
        
        figure(fig);
        for i = 1:images.count
            if ~isempty(images.volume{1,i}) & find( images.volume{1,i} == volume )
                % a colormap would seriously impact our other image: the plot window ! //
                %            colormap( images.map{i} );
                displayingImage = 1;
                if ~strcmp(images.file{1,i},preImageFile)
                    oldAxis = gca;
                    figure(fig);
                    axes( ui.del_image );
                    preImageHandle = image( ui.images.data{1,i} );
                    axis off                            % Property ('Visible','off' );
                    axes( oldAxis );            % restore active axis
                end
                preImageFile = images.file{1,i};
                %fprintf( '\tVolume %3i, Image Nr %i\n', volume, i );
                break
            end
        end
    else %if there is no stimulus image to display delete the previous
        if (displayingImage)
            set(preImageHandle, 'Visible', 'off');
        end
        preImageFile = [];
        displayingImage = 0;
    end
elseif strcmp(grads,'update_back')
    a(:,:,1)=ones(720,540)*ui.backcolor(1);a(:,:,2)=ones(720,540)*ui.backcolor(2);a(:,:,3)=ones(720,540)*ui.backcolor(3);
    axes( ui.del_image );
    ui.del_image_handle=image(a);
    axis off;
 
       
elseif isfield(ui,'del_image')
    
    %axes(ui.thermo_ax.handle)
    if strcmp(grads,'first')
        axes( ui.del_image );
        ui.del_image_handle=image(zeros(720,540));
        %set(preImageHandle, 'Visible', 'off');
        set(ui.del_image_handle, 'Visible', 'off');
        axis off
        return
    end
    % set(ui.del_image_handle, 'Visible', 'off');
    set(ui.thermo_ax.handle,'visible','off');
    axes( ui.del_image );
    n=axis;
    text(((n(2)-n(1))/2)-50,((n(4)-n(3))/2)-20 ,[num2str(grads) ,' Euro'],'FontName','Arial', 'Color','white' ,'FontSize',44, 'FontWeight','BOLD','BackgroundColor','k')
    axis off                            % Property ('Visible','off' );
    axes( gca );
    
    
    
    
else
    set(preImageHandle, 'Visible', 'off');
    
    axes( ui.image );
    n=axis;
    text(((n(2)-n(1))/2)-50,((n(4)-n(3))/2)-20 ,['$ ',num2str(grads) ],'FontName','Arial', 'Color','white' ,'FontSize',44, 'FontWeight','BOLD','BackgroundColor','k')
    axis off                            % Property ('Visible','off' );
    axes( gca );
    
    
    
end
% h = text(.5,.5,'xxXXXxx','HorizontalAlignment','center')
