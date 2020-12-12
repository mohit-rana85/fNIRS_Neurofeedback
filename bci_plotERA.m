function bci=bci_plotERA(chs,bci)
%plot the event related averages for all channels for both oxy and deoxy
%data

figure('Name','Event related averages');

%subplot size
numchs=size(chs,2);

m=fix(numchs/2);
n=ceil(numchs/m);

starttime=bci.era.timepoints(1);
endtime=bci.era.timepoints(end);
xlabelstr=['baseline&regulation:' num2str(starttime) '--' num2str(endtime) 'sec'];

for i=1:numchs %for each channel to be displayed
    subplot(m,n,i)
    plot(bci.era.timepoints,bci.era.oxyData(:,chs(i))','r-',bci.era.timepoints,bci.era.deoData(:,chs(i)),'b-');
    xlabel(xlabelstr);ylabel('Oxy & deoxy conc.');
    hx = graph2d.constantline(endtime/2, 'LineStyle',':','LineWidth',3, 'Color',[0 0 0]);
    changedependvar(hx,'x');
    %legend('Oxy','Deoxy');
    xlim([starttime endtime]);
    title(['Channel: ' num2str(chs(i))]);
    xlim('auto');
    ylim('auto');
    grid('on');
end