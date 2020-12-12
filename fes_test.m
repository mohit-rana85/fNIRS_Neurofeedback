function fes_test(bci)
if isempty(instrfind)
      bci.port.s = serial(bci.fes_port{1},'Baudrate',19200);% Make sure this is the right port!
else
      bci.port.s = instrfind('port', bci.fes_port{1});
end
if isempty(instrfind('Status','open'))
    fopen(bci.port.s);
end

for ii=1:length(bci.fes_amplitude)
    fwrite(bci.port.s, bci.fes_amplitude_cmd(ii,:), 'async');
    pause( bci.time_fes(:,ii));
    fwrite(bci.port.s, bci.fes_off_apm_cmd(ii,:), 'async');   
    pause(0.1);
end
disp('done!');
fclose (bci.port.s);