function bci =create_grads(current_fig, grads, force_creation,bci)

global thermo;
global thermo_ax;
global previous_grads;
global MAX_GRADUATIONS;
global last_gobjects;
if bci.isref_zero
    aa=1;
else
    aa=2;
    INCREMENT_GRADS = 10;
end


if ( abs(grads)*aa > 0.5*MAX_GRADUATIONS) & ( abs(grads)*aa < MAX_GRADUATIONS) %grads can be negative also, so absolute is taken
    return; %don't have to create
    
elseif (force_creation ~= 1) & ( abs(grads)*aa == MAX_GRADUATIONS)
    return;
    
else  %create new grads if grads > MAX_GRADUATIONS
    
    if (force_creation ~= 1)
        %if the current number of grads is greater than MAX_GRADUATIONS,
        %increase
        delete_grads; %first delete the previous grads
        MAX_GRADUATIONS = abs(grads)*aa + INCREMENT_GRADS;
        
        if (MAX_GRADUATIONS <= 0)
            MAX_GRADUATIONS = INCREMENT_GRADS; %to make sure value does not go below zero
        end
        
    end
    
    %fprintf('\nNew MAX_GRADUATIONS = %d\n', MAX_GRADUATIONS);
end

%compute the co-ordinates of all the graduations and store it for later
%use in update_thermo
grad.w = thermo.wi;
grad.gap = 0.0; %some problem here! does not work if the grad.gap is more than 1.0!!!!
grad.h = (thermo.hi / MAX_GRADUATIONS) - grad.gap*aa;

bottom_xleft = thermo.Xi(1,1);
bottom_xright = thermo.Xi(1,2);
bottom_yleft = thermo.Yi(1,1) + grad.gap; %start after the gape
bottom_yright = thermo.Yi(1,2) + grad.gap;

for i=1:MAX_GRADUATIONS
    add_y = (grad.gap + grad.h)*(i-1);
    grad.coords(i).X = [bottom_xleft bottom_xright bottom_xright bottom_xleft]; %5 points to close the polygon
    grad.coords(i).Y = [(bottom_yleft+add_y) (bottom_yright+add_y) (bottom_yright+grad.h+add_y) (bottom_yleft+grad.h+add_y)];
    
    %baseline
    if bci.isref_zero
        grad.color(i).value = [1 0 0]; %red
    else
        if (i > fix(MAX_GRADUATIONS/aa))
            grad.color(i).value = [1 0 0]; %red
        else
            grad.color(i).value = [0 0 1]; %blue
        end
    end
    
    %draw the object but set its visibility to off now
    %set the figure and the axes
    figure(current_fig); %set the current fig
    axes(thermo_ax.handle); %background of the axes
    last_gobjects.update(i) = patch(grad.coords(i).X, grad.coords(i).Y, grad.color(i).value);
    set(last_gobjects.update(i), 'Visible', 'off');
end

if  bci.prt.b.ui.SHOW_REWARD  && bci.iscontinuous && strcmp(bci.prt.b.ui.feedbacktype , 'THERMOMETER')
    nn=figure(current_fig);
    % set(nn,'Units','normalized');
    bci.high_limit=uicontrol('Parent',nn,'Style','text',...
        'Units','Normalized',...
        'FontUnits','normalized',...
        'FontSize',0.7,...
        'HorizontalAlignment','left',...
        'BackgroundColor',[0.46 0.46 0.46],...
        'visible','off',...
        'Position',[0.601   0.65    0.07   0.05]);
    bci.low_limit=uicontrol(nn,'Style','text',...
        'Units','Normalized',...
        'FontUnits','normalized',...
        'FontSize',0.7,...
        'HorizontalAlignment','center',...
        'BackgroundColor',[0.46 0.46 0.46],...
        'visible','off',...
        'Position',[0.601   0.22    0.07   0.05]);
    bci.cum_feed=uicontrol(nn,'Style','text',...
        'Units','Normalized',...
        'FontUnits','normalized',...
        'FontSize',0.75,...
        'HorizontalAlignment','center',...
        'BackgroundColor',[0.46 0.46 0.46],...
        'visible','off',...
        'Position',[0.38 0.75 0.25 0.1]);
    set(bci.low_limit,'string','$0');
set(bci.high_limit,'string',['$',num2str(bci.prt.b.ui.MAX_EUROS)]);

end

previous_grads = last_gobjects.update;
