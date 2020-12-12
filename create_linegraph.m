function [lg_fig lg_handles]=create_linegraph(data,proto,chs_display)

base=1; %starting of the baseline block
numchs=size(chs_display,2);
if numchs<=0
    return
end;
m=fix(numchs/2);
n=ceil(numchs/m);
lg_fig = figure('Name', 'Real-time display of channel data');
%cmap=colormap( flipud(rot90(reshape( [proto.cond.color], 3, ...
        %length([proto.cond.color]) / 3 ))) );

for i=1:numchs
    lg_handles(i)=subplot(m,n,i);
    grid(lg_handles(i),'on'); 
    title(lg_handles(i),['Channel: ' num2str(chs_display(i))]); 
    set(lg_handles(i),'XTick',proto.ticks); %to show the protocol
    set(lg_handles(i),'XTickLabel',[]); %to show the protocol
    %set(lg_handles(i),'XTickLabel',proto.ticklabels); %does not work!

    %         set( gcf, 'BackingStore', 'off'); %faster
    %         set( gcf, 'RendererMode', 'manual');    % für 'DoubleBuffer'
    %         set( gcf, 'Renderer', 'painters');      % für 'DoubleBuffer'
    set(gcf,'DoubleBuffer', 'on');        %  sonst flackert es !!
    %         set( gcf, 'ShareColors', 'off');            % genau meine Farben
    %         axis xy;

end
%ask the user to get ready
uiwait(msgbox('Please arrange the windows as needed. Please press OK to proceed for beginning BCI feedback task'));
end









