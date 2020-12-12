function [ data, proto, perf ] = bci_protocol( proto,directory)
%BCI_PROTOCOL Read stimulation protocol & display it to subject

% feedback array 'data' will be set up with stimulation protocol conditions
%   column1: condition nr. // column2: block nr. within condition
%   - read from 'filename'.
% new fields of proto are
%   .count      - number of conditions
%   .cond( count ).???  - .color, .blocks
%               // should all be read from *.prt file, not hardcoded //


%bci_ui_wait( proto.file );        % wait until regular file is there
fid = fopen( proto.file, 'r');   % text mode (matlab does the '\r\n' stuff)

% I could read the 'NrOfConditions' with bci_read(), but I have no way of
%   knowing where my condition data (unfortunately all in free form) starts.
proto.count = bci_str2int( bci_read_matchline( fid, 'NrOfConditions' ));
% So I assume it starts just after the 'NrOfConditions' entry ;-) // danger //
 proto.cond=[];proto.seqview=[];proto.seq_length=[];
for c = 1:proto.count
    proto.cond(c).name = read_no_empty(fid);                % just to check //
    proto.cond(c).blocks = bci_str2int( read_no_empty(fid));% blocks/condition
    for b = 1:proto.cond(c).blocks
        proto.cond(c).block{b} = str2num( read_no_empty(fid) ); % volume range
        % set up the feedback array 'data': data( 1:4, 1:volumes )
        % row 1 - condition number // 1 == pause
        data( 1, proto.cond(c).block{b}(1):proto.cond(c).block{b}(2) ) = c;
        % row 2 - block condition within condition
        data( 2, proto.cond(c).block{b}(1):proto.cond(c).block{b}(2) ) = b;
    end
    proto.cond(c).color= str2num( bci_read_matchline( fid, 'Color' ));
%     try                         % do we have an override entry for this color ?
%         proto.cond(c).color = proto.colors( c, : );       % then use it...
%     catch
%     end
    proto.cond(c).color = proto.cond(c).color / 255;  % matlabs [0 1] ranges...
    
    %read the protocol image, example: up-arrow, down-arrow, cross-hari etc
    %proto.cond(c).cond_image = bci_read_matchline(fid, 'Image');
end
% with this freeform data, I cannot know if I read the right thing.
if feof(fid)    %   but assume that if we hit feof(fid) it's bad...
    fclose(fid);
    errordlg([ 'Reached EOF while reading "' proto.file '". ' ...
            'Your protocol file is broken.' ]);
end
proto.seqview.cond = str2num( bci_read_matchline( fid, 'ConditionSequence' ));
proto.seq_length = size(proto.seqview.cond, 2); %number of columns
cur_block(1:proto.count) = 0; %initialize the cursor for the condition block as each condition has multiple blocks
for s = 1:proto.seq_length
    cur_cond = proto.seqview.cond(s);
    cur_block(cur_cond) = cur_block(cur_cond) + 1; % increment the cursor
    proto.seqview.block{s} = proto.cond(cur_cond).block{cur_block(cur_cond)}; 
    proto.seqview.color{s} = proto.cond(cur_cond).color;
   % proto.seqview.cond_image{s} = proto.cond(cur_cond).cond_image;
    
end
% proto.seqview.cond_image{s} = proto.cond(cur_cond).cond_image;
% proto.seqview.cond_image{s} = proto.cond(cur_cond).cond_image;
% %
%read in the performance criteria
perf.criteria =[];perf.regulation=[];perf.thermo_image=[];proto.initial_rest=[];
perf.criteria = str2num( bci_read_matchline( fid, 'PerformanceCriteria' ));
perf.regulation=str2num(bci_read_matchline( fid, 'Down_UP_Regulation' ));
perf.thermo_image=str2num(bci_read_matchline( fid, 'Thermo_image_seq' ));
proto.initial_rest=str2num(bci_read_matchline( fid, 'Initial_Rest' ));
aa=bci_read_matchline( fid, 'BCI_file' );
if ~isempty(aa)
    proto.bci_file= [directory, filesep,aa];
else
    if isfield(proto,'bci_file')
       proto = rmfield(proto,'bci_file');
    end
end
proto.trigger_cond = str2num(bci_read_matchline( fid, 'Trigger_cond' ));
%
%condition images information Initial_Rest:10

% [p mio]= fileparts(which('pradeep'));
% folder= [p filesep 'Protocol'];
% %folder = bci_read_matchline(fid, 'ConditionImageFolder');
% str = bci_read_matchline(fid, 'ConditionImageFiles'); %read the whole line containing all the filenames
% substr = dlmstr(str, '\s'); %split the line read by space delimiter to get individual image file names
% for i = 1:length(substr)
%     cond_imagefile = [folder filesep char(substr(i))];
%     proto.cond(i).cond_image = imread(cond_imagefile);
%     proto.cond(i).cond_imginfo = imfinfo(cond_imagefile);
% end

% 
%protocol sequence view information to be extracted here
%Ranga, 21-03-2005

%needed when plotting real-time graphs of nirs signals
% proto.ticks=[];
% for i=1:size(proto.seqview.block,2)
%     proto.ticks=[proto.ticks proto.seqview.block{i}(1)];
% end

% %space the ticklabels so that the texts do not run into each other
% proto.ticklabels=[];
% for t=1:size(proto.ticks,2)
%     if(t==1)
%         proto.ticklabels=[proto.ticklabels int2str(proto.ticks(t))];
%     elseif (mod(t,4)==0)
%         proto.ticklabels=[proto.ticklabels int2str(proto.ticks(t))];
%     elseif(t==size(proto.ticks,2))
%         proto.ticklabels=[proto.ticklabels int2str(proto.ticks(t))];
%     else
%         proto.ticklabels=[proto.ticklabels '.'];
%     end
% end
fclose(fid);

%_______________________________________________________________________
function value = read_no_empty( fid )
while ~feof(fid)
    value = deblank( fgetl(fid));
    if ~isempty(value)
        return
    end
end
%_______________________________________________________________________

