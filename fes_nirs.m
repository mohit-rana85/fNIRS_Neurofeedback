function fes_nirs(predict,volume,bci,grads)
global fes_trigger
if strcmp(bci.FES_System, 'MEDEL')
    if predict==1
        for ii=1:length(bci.fes_amplitude)
            fwrite(bci.port.s, handles.bci.fes_amplitude_cmd(ii,:), 'async');
            pause(handles.bci.time_fes(:,ii));
            fwrite(bci.port.s, handles.bci.fes_off_apm_cmd(ii,:), 'async');
            pause(0.1);
        end
        
    elseif predict==-1
        for ii=1:length(bci.fes_amplitude)
            fwrite(bci.port.s, handles.bci.fes_off_apm_cmd(ii,:), 'async');
            pause(0.1);
        end
        
    end
elseif strcmp(bci.FES_System, 'INTFES')
    if predict==1
        numpulse='>SN;xxx<';
        %var2=dec2bin(round((1/bci.current_pulse_width)*1000000));
        var2=dec2bin(30);
        if bin2dec(var2)>65536 && bin2dec(var2)<999999
             numpulse(5)=uint8(var2(1:end-14));
             numpulse(6)=uint8(bin2dec(var2(end-15:end-8)));
             numpulse(7)=uint8(bin2dec(var2(end-7:end)));
        elseif bin2dec(var2)>255 && bin2dec(var2)<=65536
            numpulse(5)=0;
            numpulse(6)=uint8(bin2dec(var2(1:end-8)));
            numpulse(7)=uint8(bin2dec(var2(end-7:end)));
            
        else
            numpulse(5)=0;
            numpulse(6)=0;
            numpulse(7)=uint8(bin2dec(var2));
            
        end
         fwrite(bci.port.s, uint8(numpulse),'async')
        
        pause(0.05)
        
        pulsewidth= '>SW;xx<';
        var=dec2bin(bci.current_pulse_width);
        
        if bin2dec(var)>255
            pulsewidth(5)=uint8(bin2dec(var(1:end-8)));
            pulsewidth(6)=uint8(bin2dec(var(end-7:end)));
        else
            pulsewidth(5)=0;
            pulsewidth(6)=uint8(bin2dec(var));
        end
        fwrite(bci.port.s, uint8(pulsewidth),'async')
        pause(0.05)
        
        fwrite(bci.port.s, bci.trigger,'async')
        fes_trigger=1;
    end
    
end