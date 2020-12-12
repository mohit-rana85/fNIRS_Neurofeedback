function [wavData,fposition,error] = bci_readplot(fid,fposition,numlines,type)
%Reads the next numoflines from the data file indicated by fid and convert it to a
%matrix of data values
global fposition_last_oxy fposition_last_deoxy
fprintf('File position: %d\n', fposition);

if fposition==-1 &&strcmp(type,'oxy')
fposition_last_oxy=-1;
elseif fposition==-1 && strcmp(type,'deoxy')
fposition_last_deoxy=-1;

end
fseek(fid,fposition, 'bof'); %go to the last file position
%read next lines and convert them to float
for i=1:numlines
%      while 1
%            p=mean(fgetl(fid)~=-1);
%         if p== -1
%             p=0;
%         end
if strcmp(type,'oxy')
   [value, n] = read_waitnoui( fid,fposition_last_oxy) ;   
elseif strcmp(type,'deoxy')
   [value, n] = read_waitnoui( fid,fposition_last_deoxy) ;   
end
    if  value %mean(fgetl(fid)~=-1) && ischar(fgetl(fid))
        try
        wavData(i,:)=str2num(n);
        pause(.02);
%         break
        catch
       %pause(.1)
        end
       % i
%     elseif ii==100
%        error=1; 
%        msgbox('measurement is stopped');
%         
%         break
%    
%     elseif ~ischar(fgetl(fid))
%         pause(.2)
%          ii=ii+1 
%     end
   end
      
%    if ii==10
%        
%       wavData=[];
%        return
%    end
%    
end
wavData=mean(wavData);error=0;%numlines
%remember and return the file position
fposition=ftell(fid);
if strcmp(type,'oxy')
fposition_last_oxy=ftell(fid);
elseif  strcmp(type,'deoxy')
    fposition_last_deoxy=ftell(fid);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [value,n] = read_waitnoui( fid,fposition_last)  % wait if value not there yet

while(1)
    n=fgetl(fid);
	position = ftell(fid);  % remember position to resume to on EOF
  
    % 	value = str2double( bci_read_matchline( fid, field) );
	  if position==fposition_last           % better re-read if it was the last line
        %fprintf('\nPROBLEM: End of file encountered!\n\n');
        fseek( fid, position, 'bof');  % 'bof': relative to start
          t=tic;              % how much time has elapsed ?
        if t < 0.1          %   0.1 == WAITTIME Schleifenmindestdauer
            pause(0.1-t)    %   0.1 == WAITTIME Schleifenmindestdauer
        end
          toc(t);   % get a new time indicator...
          
	else
      value=1; 
      return;             % everything in order...
    end
end

