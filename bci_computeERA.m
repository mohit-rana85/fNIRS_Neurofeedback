function bci=bci_computeERA(bci)
%BCI_COMPUTEERA Display one data window of fMRI choi data output of TBV


%initialization/configuration
mean_baseline_choi = 0;
mean_baseline_choi_oxy=0;
mean_baseline_choi_deo=0;

baserows=0;
basecols=0;
regulrows=0;
regucols=0;

% %open .ert file and wait for data
% bci_ui_wait(bci.highWavFile);        % wait until regular file is there
% bci_ui_wait(bci.loweWavFile);        % wait until regular file is there
% fidh=fopen(bci.highWavFile, 'rt');   % text mode (matlab does the '\r\n' stuff)
% fidl=fopen(bci.loweWavFile, 'rt');
% fpositionh = -1;
% fpositionl = -1;
bci_ui_wait(bci.oxyFile)       % wait until regular file is there
%averages
bci.era.baseOxyData=[]; %event related conc values for each time point in baseline condition
bci.era.reguOxyData=[]; %event related conc values for each time point in the regulation condition
bci.era.baseDeoData=[];
bci.era.reguDeoData=[];


%note the first and the last volume numbers
firstVolNum=1;
lastVolNum=bci.prt.seqview.block{bci.prt.seq_length}(1,2);
X=[firstVolNum:lastVolNum];


%for each condition in the protocol
for current_cond = 1:bci.prt.seq_length
    if sum(bci.prt.seqview.cond(current_cond) == bci.target_label)>0
        cumBold(current_cond)=0; %init
        posBold(current_cond)=0; %init
        current_block = bci.prt.seqview.block{current_cond};
        current_color = bci.prt.seqview.color{current_cond};
        % current_image = bci.prt.seqview.cond_image{current_cond};
        %current_imginfo = bci.prt.seqview.cond_imginfo{current_cond};
        current_view_score = 0;
        
        %for each time point within the current block, get the effective choi
        volume_start = current_block(1);
        volume_end = current_block(2);
        blockData = zeros(volume_end-volume_start+1, 1); %initilize first to zeros
        baseline_choi=[];
        volume_index = 0;
        
        %initialize for each block
        oxyData=[];
        deoData=[];
        baseOxyData=[];
        baseDeoData=[];
        reguOxyData=[];
        reguDeoData=[];
        if   bci.perf.criteria(current_cond)~=0
            for volume = volume_start:volume_end
                volume_index = volume_index + 1;
                %             if (bci.debug == 1)
                %                 fprintf('\nTimepoint: %d\n', volume);
                %                 fprintf('\nVolume index: %d\n', volume_index);
                %             end
                load([bci.path, filesep, 'oxy_', num2str(volume),  '.mat']);
                %         [hwData,fpositionh] = bci_readplot(fidh,fpositionh,ceil(bci.samplingrate));
                %         [lwData,fpositionl] = bci_readplot(fidl,fpositionl,ceil(bci.samplingrate));
                %
                %         %compute the oxy and deo concentration changes for the time
                %         %point
                %         [cc_oxy cc_deo]=calcHbconc(hwData,lwData,bci.optodeDist);
                %
                %Event Related
                oxyData=[oxyData; cc_oxy'];
                deoData=[deoData; cc_deo'];
                
                %if it is the last volume of the baseline block compute the
                %mean baseline_choi else if it is is the first active block compute
                %the multfactor for the thermometer feedback to be valid
                if (mod(current_cond, 2)==1) & (volume == volume_end)
                    
                    %accumulating the signals for each time point for computing ERA
                    %             baseOxyData=[baseOxyData; oxyData];
                    %             baseDeoData=[baseDeoData; deoData];
                    
                    %reshape the matrices into vectors for averaging across
                    %multiple
                    bci.era.baseOxyData(:,:,round(current_cond/2))= oxyData ;
                    bci.era.baseDeoData(:,:,round(current_cond/2))= deoData ;
                    
                    %initialize for each block
                    oxyData=[];
                    deoData=[];
                    %             baseOxyData=[];
                    %             baseDeoData=[];
                elseif(mod(current_cond, 2)==0) & (volume == volume_end)
                    %computation of event related average for baseline condition
                    %reshape the matrices into vectors for averaging across
                    %multiple
                    bci.era.reguOxyData(:,:,round(current_cond/2))=oxyData;
                    bci.era.reguDeoData(:,:,round(current_cond/2))=deoData;
                    
                    %initialize for each block
                    oxyData=[];
                    deoData=[];
                    %             reguOxyData=[];
                    %             reguDeoData=[];
                end
            end
        end
    end
end


%Event related average across column vectors
mbaseOxyData=mean(bci.era.baseOxyData,3);
mbaseDeoData=mean(bci.era.baseDeoData,3);
mreguOxyData=mean(bci.era.reguOxyData,3);
mreguDeoData=mean(bci.era.reguDeoData,3);

% %re-reshaping to bring it back to timeXchannels format
% rmbaseOxyData=reshape(mbaseOxyData,baserows,basecols);
% rmbaseDeoData=reshape(mbaseDeoData,baserows,basecols);
% rmreguOxyData=reshape(mreguOxyData,regurows,regucols);
% rmreguDeoData=reshape(mreguDeoData,regurows,regucols);
%
% %clear memory
% mbaseOxyData=[];
% mbaseDeoData=[];
% mreguOxyData=[];
% mreguDeoData=[];
bci.era.baseOxyData=[];
bci.era.baseDeoData=[];
bci.era.reguOxyData=[];
bci.era.reguDeoData=[];

%combine baseline and regulation eras
bci.era.oxyData=[mbaseOxyData ; mreguOxyData ];
bci.era.deoData=[mbaseDeoData ; mreguDeoData ];

bci.era.timepoints=1:(size(mbaseOxyData,1))*2;

return


