







serialt=serial('COM5','Baudrate',115200, 'terminator',60);% initial code while connecting device: 1111
fopen(serialt);
%triger start ans stop
trigger='>T<';

for ii=50:20:400
     numpulse='>SN;xxx<';
        var2=dec2bin(30);%(round((1/ii)*2500));
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
         fwrite(serialt, uint8(numpulse),'async')
        
        pause(0.05)
    
pulsewidth= '>SW;xx<';
var=dec2bin(ii);

if bin2dec(var)>255
pulsewidth(5)=uint8(bin2dec(var(1:end-8)));
pulsewidth(6)=uint8(bin2dec(var(end-7:end)));
else
    pulsewidth(5)=0;
  pulsewidth(6)=uint8(bin2dec(var));  
end
fwrite(serialt, uint8(pulsewidth),'async')
pause(0.1)
disp(ii)
 fwrite(serialt, uint8('>T<'),'async'); disp('sent1')
pause(2);
disp('sent2')
%fwrite(serialt, uint8('>T<'),'async');
tt=input('Wanna continue!!','s');
if ~isempty(tt)
    break
end
    
end
fclose(serialt);