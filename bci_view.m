function bci=bci_view(bci)
try
    %     bci.isudp=1;
    trigger_cond= bci.prt.trigger_cond; % or -1 for all blocks trigger
    bci.auto_sel=0;
    error_catched=0;
    bci.grad_value=[];
    bci.label=[];
    bci.target_cond=[];
    bci.correl_per_volume=[];
    bci.total_reward_final=0;
    bci.cur_choi=[];
    bci.eff_choi_value=[];
    if ~bci.basic_info.isUDP
        fid_feedback=fopen([bci.output_dir,filesep,'feedback.txt'],'wt');
        fid_money=fopen([bci.output_dir,filesep,'money.txt'],'wt');
    end
    if bci.istesting_SVM
        if ~isfield(bci.SVM.model,'W') 
           [file, pathfile]= uigetfile('*.mat', 'Please select the save session containing SVM model');
           previousData = load(fullfile(pathfile,file));
           bci.SVM.model.W = previousData.bci.SVM.model.W;
           bci.SVM.model.rho = previousData.bci.SVM.model.rho;
           clear previousData
        end
    end
    
    if  isempty(instrfind('port','COM3','Status','open'))
        bci.port.trigger = serial(bci.trigger_port,'Baudrate',9600); fopen(bci.port.trigger);
    else
        bci.port.trigger = instrfind('port','COM3','Status','open'); %serial(  bci.trigger_port,'Baudrate',9600);
        
        % fopen(bci.port.trigger)
    end
    %BCI_VIEW Display one data window of fMRI choi data output of TBV
    xn=0;
    % ver 0.1 Ranga, 15-12-2009
    % based on thepradeep previous bci_data() function
    if strcmp(bci.system,'Hitachi')
        marker{1}=sprintf('A \r\n');
        marker{2}=sprintf('B \r\n');
        marker{3}=sprintf('C \r\n');
        marker{4}=sprintf('D \r\n');
        marker{5}=sprintf('E \r\n');
        marker{6}=sprintf('F \r\n');
        marker{7}=sprintf('G \r\n');
        marker{8}=sprintf('H \r\n');
    elseif strcmp(bci.system,'NIRx')
        marker{1}=1;
        marker{2}=2;
        marker{3}=4;
        marker{4}=8;
        marker{5}=5;
        marker{6}=6;
        marker{7}=7;
        marker{8}=8;
    end
    
    
    % channel selecttion if no localizer is there
    if ~isfield(bci,'med_sel_ch') && ~isempty(str2num(bci.run_number))  %#ok<ST2NM>
        
        
        bci.range=2;
        
        
        if ~bci.isnone
            chn_str = input_channel('correlation',bci);
            if ~isempty(chn_str{1})
                t=evalc(['bci.roi{1}=[' ,chn_str{1},']']);
                t=evalc(['bci.roi{2}=[',chn_str{2},']']);
            end
            if ~isempty(bci.roi{1})
                if sum((bci.roi {1}>bci.totNumChs))+sum((bci.roi {2}>bci.totNumChs))>0
                    chn_str = input_channel('correlation',bci);
                    t=evalc(' bci.roi{1}=[' ,chn_str{1},']');
                    t=evalc(' bci.roi{2}=[',chn_str{2},']');
                    
                elseif length(unique( [bci.roi{1},bci.roi{2}])) <(length(bci.roi{1})+length(bci.roi{1}))>0
                    dlg_title=['Same ch', num2str(bci.totNumChs)];
                    chn_str = inputdlg(prompt,dlg_title,num_lines,chn_str);
                    t=evalc(' bci.roi{1}=[' ,chn_str{1},']');
                    t=evalc(' bci.roi{2}=[',chn_str{2},']');
                    
                end
            else
                if ~isdeployed
                    warning ('Channels for the ROIs not selected');
                    return
                else
                    logMessage(bci.log.jEditbox, ' Channels for the ROIs not selected !!', 'warn');
                    return
                end
            end
            bci.chContrast=[bci.roi{1},bci.roi{2}];
            bci.med_sel_ch=bci.chContrast;
            for ii=1:(length(bci.roi{1})+length(bci.roi{2}))
                bci.std_sel_ch(ii)= 0.3 ;
            end
            bci.ch_weights(1:bci.totNumChs)=0;
            
            for i=1:size(bci.chContrast,2)
                bci.ch_weights(abs(bci.chContrast(i)))=1; %set positive weight to 1 and neg weights to -1
            end
        else
            bci.med_sel_ch=bci.chContrast;
            for ii=1:length(bci.chContrast)
                bci.std_sel_ch(ii)= 0.3 ;
            end
        end
    end
    [bci.prt.b.ui]= bci_image_display(bci.fig, 1 , bci.prt.b.ui, bci.prt.b.images,'No' );
    % select Labels to be classified
    if ~isfield(bci, 'input_labels')|| isempty(bci.input_labels)||  isempty(bci.target_label)
        bci.input_labels = inputdlg(['Please enter the target condition(s)(', num2str(1:bci.prt.count) ,'):']);
        
        if isempty(bci.input_labels)
            close(bci.fig)
            return
        end
        t=evalc([ 'bci.target_label=[', bci.input_labels{1,1}, ']']);
    end
    
    
    
    bci.x1=0;
    %initialization/configuration
    mean_baseline_choi = 0;
    global displayingImage; %this value is set inside bci_display_image()
    global preImageFile;
    global preImageHandle;
    
    %global key_pressed
    key_pressed = 0; %initialization
    preImageFile = 0, preImageHandle = 0, displayingImage = 0; %initialize %Modification_RANGA_Mar17_2006
    % online plotting of the thermometer and correlation values
    if ~isempty(str2num(bci.run_number))
        if bci.isref_zero
            nn=1;
        else
            nn=2;
        end
        if bci.thermometer==1 ||bci.fes==1 || ( bci.ispositive||bci.isnegative)
            screensize = get( 0, 'Screensize' );
            fHand = figure('Menubar','none','position',[screensize(3)/2,screensize(4)/3,800,600] ,'Name','Real-time feedback' ,'NumberTitle','off');
            aHand = axes('parent', fHand);
            set(aHand, 'position', [0.05 0.1 0.9 .85])
            hold(aHand, 'on')
            if ( bci.ispositive||bci.isnegative)
                ind=ones(1,bci.prt.seqview.block{1,end}(2));
            elseif bci.thermometer
                ind=ones(1,bci.prt.seqview.block{1,length(bci.prt.seqview.block)}(2))*bci.thermo_bars;
            end
            bar((1: bci.prt.initial_rest), ind(1: bci.prt.initial_rest), 1,'parent', aHand,'grouped', 'facecolor',[0 0 0],'edgecolor', [0 0 0]);
            bar((1: bci.prt.initial_rest), -1*ind(1: bci.prt.initial_rest), 1,'parent', aHand,'grouped', 'facecolor',[0 0 0],'edgecolor', [0 0 0]);
            
            for i = 1: length(bci.prt.seqview.cond)
                % for ii=b.proto.seqview.block{i}(1):  b.proto.seqview.block{i}(2)
                bar(bci.prt.initial_rest+(bci.prt.seqview.block{i}(1): (bci.prt.seqview.block{i}(2))), ind(bci.prt.seqview.block{i}(1):bci.prt.seqview.block{i}(2)), 1,'parent', aHand,'grouped', 'facecolor',bci.prt.seqview.color{1,i}(1:3),'edgecolor',bci.prt.seqview.color{1,i}(1:3));
                bar(bci.prt.initial_rest+(bci.prt.seqview.block{i}(1): (bci.prt.seqview.block{i}(2))), -1*ind(bci.prt.seqview.block{i}(1):bci.prt.seqview.block{i}(2)), 1,'parent', aHand,'grouped', 'facecolor',bci.prt.seqview.color{1,i}(1:3),'edgecolor',bci.prt.seqview.color{1,i}(1:3));
                % end
            end
            
            if ( bci.ispositive||bci.isnegative)
                set(aHand,'XLim',[0 bci.prt.seqview.block{1,end}(2)]);
                set(aHand,'YLim',[-1 1]);
            elseif bci.thermometer==1
                set(aHand,'YLim',[-1*round(bci.thermo_bars/nn), round(bci.thermo_bars/nn)]);
                set(aHand,'XLim',[0 (bci.prt.seqview.block{1,end}(2)+bci.prt.initial_rest)]);
            end
            
        end
    end
    %starting the COM ports
    
    if ~bci.debug
        if isempty(instrfind)
            if bci.fes
                if strcmp(bci.FES_System, 'MEDEL')
                    bci.port.s = serial(bci.fes_port,'Baudrate',19200);% Make sure this is the right port!
                elseif strcmp(bci.FES_System, 'INTFES')
                    % bci.port.s=serial(bci.fes_port,'Baudrate',115200, 'terminator',60);
                    bci.port.s=serial(bci.fes_port,'Baudrate',115200, 'terminator',60);
                end
            end
            
        else
            if bci.fes
                bci.port.s = instrfind('port', bci.fes_port);
            end
            if strcmp(bci.system,'Hitachi')
                bci.port.nn=instrfind('port', bci.trigger_port);
            end
        end
        if ~strcmp( bci.trigger_port,'0')
            if strcmp(bci.system,'Hitachi')
                bci.port.nn=serial( bci.trigger_port,'Baudrate',9600);
            elseif strcmp(bci.system,'NIRx')
                config_io;
            end
        end
        if isempty(instrfind('Status','open'))
            if bci.fes
                fopen(bci.port.s);
            end
            if strcmp(bci.system,'Hitachi')
                fopen(bci.port.nn);
            end
            
        end
        
        if bci.fes && strcmp(bci.FES_System, 'MEDEL')
            try
                fwrite(bci.port.s, [255 255 1 2 40 43], 'async');
            catch
                pause(0.1);
                fwrite(bci.port.s, [255 255 1 2 40 43], 'async');
            end
        end
    end
    
    
    %ask the user to get ready
    uiwait(msgbox('Please arrange the figure window as needed. Please press OK to proceed for beginning BCI feedback task'));
    pause(1)
    %open tcpip socket
    % tt = instrfind('tcpip', '192.168.1.2','Status','open') 
    if bci.basic_info.isUDP
        u1 = tcpip('192.168.1.2', 30000, 'NetworkRole','Server'); fopen(u1);
    end
    if ~isdir(bci.path)
        mkdir(bci.path);
    end
    %  [path fnamedeoxy]=fileparts(bci.deoxyFile);
    %   if ~isdir(path)
    %  mkdir(path);
    %   end
    % if  bci.prt.b.images.count>0
    %     [bci.b.ui]= bci_image_display(bci.fig, 1 , bci.prt.b.ui, bci.prt.b.images, 'first' );
    % elseif ( bci.thermometer || bci.fes)
    %    bci = draw_thermo(bci.fig,bci.thermo_bars,bci.thermo_color,bci.backcolor,bci);
    % end
    
    % bci.oxyFile=[bci.data_dir  filesep bci.data_filename '_' fnameoxy '.txt'];
    % bci.deoxyFile=[bci.data_dir  filesep bci.data_filename '_' fnamedeoxy '.txt'];
    bci_ui_wait([bci.path filesep 'oxy_1.mat']);
    fwrite(bci.port.trigger,2); 
    bci.whole_data=[];
    bci.total_reward=0;
    bci_ui_wait(bci.oxyFile)
    %for each condition in the protocol
    for current_cond = 1:bci.prt.seq_length
        current_block = bci.prt.seqview.block{current_cond};
        current_color = bci.prt.seqview.color{current_cond};
        current_condition =  bci.prt.seqview.cond(current_cond);
        current_perf=bci.perf.criteria(current_cond);
        current_thermo_image=bci.perf.thermo_image(current_cond);
        current_regulation=bci.perf.regulation(current_cond);
        bci.success(current_cond)=0;
        sucess_send = 0;
        if current_cond>1 && bci.prt.b.ui.SHOW_REWARD
            if ( bci.perf.criteria(current_cond-1)==2||bci.perf.criteria(current_cond-1)==1) &&  ~bci.perf.thermo_image(current_cond)==3
                bci.total_reward_final=bci.total_reward_final+bci.total_reward;
                bci.total_reward=0;
            end
        elseif current_cond == 1 && bci.prt.b.ui.SHOW_REWARD
            bci.total_reward_final=bci.prt.b.ui.Min_EUROS_per_run;
        end
        grads = 0; %current graduations
        % last_grads = 0; %to compute score for current timepoint
        if  ~isempty(bci.output_dir) || ~strcmp(num2str(bci.output_dir),'0')
            if trigger_cond == -1
                fwrite(bci.port.trigger,2);
            elseif trigger_cond == current_condition
                fwrite(bci.port.trigger,2);
            end
            bci.trigger=0;
        else
            bci.trigger=1;
        end
        if strcmp(bci.system,'Hitachi')
            if current_cond==1
                bci.prt.b.ui.backcolor = current_color;
                if ~bci.debug
                    if bci.trigger
                        fprintf(bci.port.nn,marker{bci.prt.seqview.cond(current_cond)});
                    end
                end
            else
                bci.prt.b.ui.backcolor = current_color;
                if ~bci.debug
                    if bci.trigger
                        fprintf(bci.port.nn,marker{bci.prt.seqview.cond(current_cond-1)});
                        pause(0.5);
                        fprintf(bci.port.nn,marker{bci.prt.seqview.cond(current_cond)});
                    end
                end
            end
        elseif strcmp(bci.system,'NIRx')
            filename=NIRStar_control(1);
            if current_cond==1
                bci.prt.b.ui.backcolor = current_color;
                if ~bci.debug
                    if bci.trigger
                        outp( bci.trigger_port,marker{bci.prt.seqview.cond(current_cond)});
                    end
                end
            else
                bci.prt.b.ui.backcolor = current_color;
                if ~bci.debug
                    if bci.trigger
                        outp( bci.trigger_port,marker{bci.prt.seqview.cond(current_cond-1)});
                        pause(0.1);
                        outp( bci.trigger_port,marker{bci.prt.seqview.cond(current_cond)});
                    end
                end
            end
        end
        volume_start = current_block(1)+bci.prt.initial_rest;
        volume_end = current_block(2)+bci.prt.initial_rest;
        if bci.prt.b.images.count==1 && current_cond==1
            if strcmp(bci.prt.b.ui.feedbacktype,'THERMOMETER')&& bci.isDelayed
                [bci.prt.b.ui]= bci_image_display(bci.fig, 1 , bci.prt.b.ui, bci.prt.b.images,'update_back' );
                update_thermo(bci.fig,  bci.grad_value_del(current_cond-1), [1 0 0], bci.prt.b.ui.backcolor,bci);
                
            end
            if ( bci.prt.b.ui.SHOW_REWARD && bci.iscontinuous)
                if bci.prt.b.ui.show_bar_reward
                    set( bci.high_limit, 'visible','on');
                    set( bci.low_limit, 'visible','on');
                end
                set( bci.cum_feed, 'visible','on');
                
            end
            [bci.prt.b.ui]= bci_image_display(bci.fig, 1 , bci.prt.b.ui, bci.prt.b.images,'update_back' );
            update_thermo(bci.fig, 0, [1 0 0], bci.prt.b.ui.backcolor,bci);
            
        elseif bci.prt.b.images.count>1
            [bci.prt.b.ui]= bci_image_display(bci.fig, volume_start , bci.prt.b.ui, bci.prt.b.images,'No' );
        elseif  current_cond == bci.prt.seq_length && bci.prt.b.ui.SHOW_REWARD && bci.iscontinuous
            
            set( bci.high_limit, 'visible','off');
            set( bci.low_limit, 'visible','off');
            set( bci.cum_feed, 'visible','off');
            feed_axes=axes('parent',bci.fig);
            set( feed_axes,'position',[0 0 1 1],'units','normalized','Color',[0 0 0]);
            uistack(feed_axes,'top')
            handles.b.figures.feed_text= text(0.3,0.5,['Total: ',num2str(bci.total_reward_final),'CLP'],'FontSize',32,'Color',[1 1 1]);
        elseif bci.isCon_Del || (strcmp(bci.prt.b.ui.feedbacktype,'THERMOMETER') && bci.prt.b.ui.SHOW_REWARD )
            [bci.prt.b.ui]= bci_image_display(bci.fig, volume_start , bci.prt.b.ui, bci.prt.b.images,'update_back' );
            if   bci.perf.thermo_image(current_cond)==1
                update_thermo(bci.fig, 0, [1 0 0],bci.prt.b.ui.backcolor,bci);
            elseif  bci.perf.thermo_image(current_cond)==2  || bci.perf.thermo_image(current_cond)==3
                feed_axes=axes('parent',bci.fig);
                set( feed_axes,'position',[0 0 1 1],'units','normalized','Color',[0 0 0]);
                uistack(feed_axes,'top')
                handles.b.figures.feed_text= text(0.3,0.5,['Total: ',num2str(bci.total_reward_final),'CLP'],'FontSize',32,'Color',[1 1 1]);
            end
        else
            [bci.prt.b.ui]= bci_image_display(bci.fig, 1 , bci.prt.b.ui, bci.prt.b.images,'update_back' );
            if   bci.perf.thermo_image(current_cond)==1
                update_thermo(bci.fig, 0, [1 0 0],bci.prt.b.ui.backcolor,bci);
            end
        end
        %for each time point within the current block, get the effective choice
        if  current_perf~=0
            if sum(bci.prt.seqview.cond(current_cond)==bci.target_label)>0
                bci.label((volume_start-bci.prt.initial_rest):(volume_end-bci.prt.initial_rest))=bci.prt.seqview.cond(current_cond);
                bci.target_cond((volume_start-bci.prt.initial_rest):(volume_end-bci.prt.initial_rest))=current_perf;
            else
                bci.label((volume_start-bci.prt.initial_rest):(volume_end-bci.prt.initial_rest))=0;
                bci.target_cond((volume_start-bci.prt.initial_rest):(volume_end-bci.prt.initial_rest))=0;
            end
        end
        
        % blockData = zeros(volume_end-volume_start+1, 1); %initilize first to zeros
        for volume = volume_start:volume_end
            
            %tic
            if ~isdeployed
                fprintf( '\nTimepoint: %d\n', volume);
            else
                logMessage(bci.log.jEditbox, ['Timepoint:' num2str(volume)], 'info');
            end
            %if it is automatic simulation
            if (bci.debug == 1)
                %pause(0.1);
            end
            %waiting for the new data
            bci_ui_wait([bci.path filesep 'oxy_' num2str(volume)  '.mat']);
            try
                load([bci.path filesep 'oxy_' num2str(volume)  '.mat']);
            catch
                pause(0.1)
                load([bci.path filesep 'oxy_' num2str(volume)  '.mat']);
            end
            %Type of Input data for Feedback calculation
            %cc_oxy=cc_oxy'; cc_deo=cc_deo';
            if(bci.feedbacktype==1)
                if sum( isnan(cc_oxy))>0
                    cc_oxy(isnan(cc_oxy))=0;
                end
                feedbackVector=cc_oxy;
            elseif(bci.feedbacktype==2)
                feedbackVector=cc_deo;
            elseif(bci.feedbacktype==3)
                feedbackVector=cc_oxy+cc_deo;
            elseif(bci.feedbacktype==4)
                feedbackVector=[cc_oxy,cc_deo];
            end
            %compute eff_choi based on the ch_weight (based on the contrast
            %chosen by the user)
            if  current_perf~=0
                
                if volume==volume_start && ~isfield(bci,'ori_whole_data')
                    bci.ori_whole_data(1:size(feedbackVector,2),:)=feedbackVector';
                    bci.whole_data(1:size(feedbackVector,2),volume-bci.prt.initial_rest)= mean(feedbackVector) ;
                    bci.start_volume=volume;
                else
                    bci.ori_whole_data(1:size(feedbackVector,2),size(bci.ori_whole_data,2)+1:size(bci.ori_whole_data,2)+size(feedbackVector,1))=feedbackVector';
                    bci.whole_data(1:size(feedbackVector,2),volume-bci.prt.initial_rest)=mean(feedbackVector);
                end
            end
            if ~bci.issham
                if ~bci.istesting_SVM && ~isempty(str2num(bci.run_number))
                    if isfield(bci,'start_volume')
                        if ~bci.isnone && volume>6+bci.start_volume
                            correl=corrcoef(nanmean(bci.ori_whole_data(bci.roi{1},end- 6*bci.samplingrate+1:end), 1),nanmean(bci.ori_whole_data(bci.roi{2},end- 6*bci.samplingrate+1:end),1));
                            bci.correl_per_volume(volume)=correl(1,2);
                            plot(aHand,bci.correl_per_volume,'color',[1,1,1],'LineWidth',3);
                            if ~isdeployed
                                fprintf('\nCorrelation Coefficient: %3.1f\n', correl(1,2));
                            else
                                logMessage(bci.log.jEditbox, ['Correlation Coefficient:' num2str(correl(1,2))], 'info');
                            end
                        end
                    end
                    bci.grad_value(volume)=0;
                    if nanmean(abs(nanmean( feedbackVector(:,bci.ch_weights~=0)))>bci.range*bci.std_sel_ch)>0
                        beep
                    end
                    
                    eff_choi=nanmean(nanmean(feedbackVector(:,bci.ch_weights~=0)));
                    bci.cur_choi(volume)=eff_choi;
                end
            else
                pause(0.7)
            end
            %if it is the last volume of the baseline block compute the
            %mean baseline_choi else if it is is the first active block compute
            %the multfactor for the thermometer feedback to be valid
            if ~isempty(str2num(bci.run_number)) %#ok<ST2NM>
                if ~bci.issham
                    if (current_perf==9) && (volume == volume_end)
                        if ~bci.isnone &&  bci.iscorr_coef
                            if current_cond==1
                                mean_correl_baseline=bci.correl_per_volume(volume_start+7:volume_end);
                            else
                                mean_correl_baseline=bci.correl_per_volume(volume_start:volume_end);
                            end
                        elseif (current_perf==9) && (volume == volume_start)
                            mean_baseline_choi=shaping(bci);
                        else
                            mean_baseline_choi = nanmean(bci.cur_choi(volume_start:volume_end));
                            mean_baseline_choi_std = nanstd(bci.cur_choi(volume_start:volume_end));
                        end
                    elseif (current_perf==1 && (bci.isDelayed || bci.isCon_Del)&& (volume == volume_end)) ||(current_perf==2 && (bci.isDelayed || bci.isCon_Del) && (volume == volume_end))
                        mean_reg_eff_choi = nanmean(bci.cur_choi(volume_start:volume_end));
                    end
                    
                    if (bci.debug == 1)
                        if ~isdeployed
                            fprintf('Raw Effective choi: %3.6f\n', eff_choi); %for debug
                        else
                            logMessage(bci.log.jEditbox, ['Raw Effective choi:' num2str(eff_choi)], 'info');
                        end
                        
                    end
                    if   bci.fes && current_cond>1
                        if bci.success(current_cond-1)==1 &&  volume == volume_start
                            tt=toc;
                            pause(1-tt);
                            try
                                fes_nirs(-1,volume,bci,grads)
                            catch
                                pause(0.1);
                                fes_nirs(-1,volume,bci,grads)
                            end
                        end
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%
                    %compute effective choi
                    if (current_perf==1)||(current_perf==2)
                        if ~bci.istesting_SVM && (bci.iscontinuous || bci.isEvent|| bci.isCon_Del)
                            if bci.isupregulation
                                if ~bci.isnone
                                    if  bci.ispositive
                                        eff_choi = ((eff_choi - mean_baseline_choi)/ mean_baseline_choi_std )*(1+bci.correl_per_volume(volume));  %calculate feedback with positive correlation
                                    elseif  bci.isnegative
                                        eff_choi =((eff_choi - mean_baseline_choi)/ mean_baseline_choi_std )*(1-bci.correl_per_volume(volume));  %calculate feedback with positive correlation
                                    elseif bci.iscorr_coef
                                        eff_choi = (bci.correl_per_volume(volume) - mean_correl_baseline);
                                    end
                                else
                                    eff_choi = ((eff_choi - mean_baseline_choi)/ mean_baseline_choi_std ); %calculate feedback
                                end
                            elseif bci.isdownregulation
                                if ~bci.isnone
                                    if  bci.ispositive
                                        eff_choi = ((mean_baseline_choi-eff_choi )/ mean_baseline_choi_std )*(1+bci.correl_per_volume(volume));  %calculate feedback with positive correlation
                                    elseif  bci.isnegative
                                        eff_choi = ((mean_baseline_choi-eff_choi )/ mean_baseline_choi_std )*(1-bci.correl_per_volume(volume));  %calculate feedback with positive correlation
                                    elseif bci.iscorr_coef
                                        eff_choi = (mean_correl_baseline-bci.correl_per_volume(volume));
                                    end
                                else
                                    eff_choi =   ((mean_baseline_choi-eff_choi )/ mean_baseline_choi_std );
                                end
                                
                            end
                            
                            
                            bci.eff_choi_value(volume) =eff_choi;
                            %compute effective choi again as the moving average of given
                            %window size
                            if((volume-volume_start)+1)>=bci.numavgs
                                eff_choi = nanmean(bci.eff_choi_value(volume-bci.numavgs+1:volume)); %avg of last few volumes
                                bci.avg_eff_choi_value(volume) =eff_choi;
                            else
                                eff_choi = nanmean(bci.eff_choi_value(volume_start:volume));
                                bci.avg_eff_choi_value(volume) =eff_choi;
                            end
                            
                            if (bci.debug == 1)
                                if ~isdeployed
                                    fprintf('Moving Average: %3.6f\n', eff_choi);%for debug
                                else
                                    logMessage(bci.log.jEditbox, ['Moving Average: ' num2str(eff_choi)], 'info');
                                end
                            end
                            grads = round(eff_choi);%Ceil will up-roundoff to the nearest digit
                            bci.grad_value(volume)=grads;
                        elseif bci.istesting_SVM && (bci.iscontinuous || bci.isEvent)
                            bci.SVM.result(volume)=bci.SVM.model.W*(feedbackVector)'-bci.SVM.model.rho;
                            if bci.SVM.result(volume)>0
                                grads=grads+1;
                            else
                                grads=grads-1;
                            end
                            bci.grad_value(volume)=grads;
                        end
                        if ~bci.istesting_SVM && ( bci.isDelayed || bci.isCon_Del)
                            if volume==volume_end
                                if bci.isupregulation
                                    if ~bci.isnone
                                        if  bci.ispositive
                                            eff_choi_del =( (mean_reg_eff_choi - mean_baseline_choi)/ mean_baseline_choi_std )*(1+bci.correl_per_volume(volume));  %calculate feedback with positive correlation
                                        elseif  bci.isnegative
                                            eff_choi_del = ((mean_reg_eff_choi - mean_baseline_choi)/ mean_baseline_choi_std )*(1-bci.correl_per_volume(volume));  %calculate feedback with positive correlation
                                        elseif bci.iscorr_coef
                                            eff_choi_del = (nanmean(bci.correl_per_volume(volume_start:volume_end))- mean_correl_baseline);
                                        end
                                    else
                                        eff_choi_del = ( nanmean(bci.eff_choi_value(volume_start:volume_end)) - mean_baseline_choi)/ mean_baseline_choi_std ; %calculate feedback
                                    end
                                elseif bci.isdownregulation
                                    if ~bci.isnone
                                        if  bci.ispositive
                                            eff_choi_del = ((mean_baseline_choi-mean_reg_eff_choi )/ mean_baseline_choi_std )*(1+bci.correl_per_volume(volume));  %calculate feedback with positive correlation
                                        elseif  bci.isnegative
                                            eff_choi_del = ((mean_baseline_choi-mean_reg_eff_choi )/ mean_baseline_choi_std )*(1-bci.correl_per_volume(volume));  %calculate feedback with positive correlation
                                        elseif bci.iscorr_coef
                                            eff_choi_del = (mean_correl_baseline-nanmean(bci.correl_per_volume(start_volume:volume_end)));
                                        end
                                    else
                                        eff_choi_del =  ( mean_baseline_choi-mean_reg_eff_choi)/ mean_baseline_choi_std ;
                                    end
                                end
                                bci.eff_choi_del(current_cond)= eff_choi_del;
                                grads = round(eff_choi_del);%Ceil will up-roundoff to the nearest digit
                                bci.grad_value_del(current_cond)=grads;
                            end
                            
                        end
                    end
                    
                    if (bci.debug == 1)
                        if ~isdeployed
                            fprintf('Mean Baseline choi: %3.6f\n', mean_baseline_choi); %for debug
                            fprintf('Graduations : %d\n', grads); %for debug
                        else
                            logMessage(bci.log.jEditbox, ['Mean Baseline choi: ' num2str(mean_baseline_choi)], 'info');
                        end
                    elseif isdeployed
                        logMessage(bci.log.jEditbox, ['Graduations: ' num2str( grads)], 'info');
                    else
                        fprintf('Graduations : %d\n', grads);
                    end
                end
                %Show activation in the feedback at all conditions! So comment out the
                %first part of code below
                if bci.isnone
                    figure(fHand)
                    plot(aHand, bci.grad_value(1: volume),'color',[1,1,1],'LineWidth',3);
                end
                if(strcmp(bci.isTransfer, 'NO')) %feeback only when it is not a transfer mode
                    figure(bci.fig);
                    if  current_perf == 9&& volume==volume_start %baseline
                        if bci.thermometer
                            update_thermo(bci.fig, 0, [1 0 0], bci.prt.b.ui.backcolor,bci);% no feedback if baseline
                        elseif bci.fes
                            if volume==volume_start
                                try
                                    fes_nirs(-1,volume,bci,grads)
                                catch
                                    pause(0.1);
                                    fes_nirs(-1,volume,bci,grads)
                                end
                            end
                        end
                    elseif ( current_perf == 1 || current_perf == 2)
                        if bci.prt.b.ui.SHOW_REWARD &&  bci.isCon_Del && bci.thermometer
                            bci.current_reward(volume)=bci.grad_value(volume)*bci.prt.b.ui.step_euros;
                            if bci.current_reward(volume)>0
                                bci.total_reward=bci.total_reward+bci.current_reward(volume);
                            end
                            
                            if bci.perf.thermo_image(current_cond)==1
                                if ~strcmp(bci.output_dir,'0')
                                    if bci.inter_feed
                                        if  bci.grad_value(volume)>0
                                            bci.success(current_cond)= bci.success(current_cond)+1;
                                        end
                                        if bci.success(current_cond)> bci.inter_feed_val(2) && ~sucess_send
                                            fwrite(u1, [num2str(volume_start+bci.inter_feed_val(1)-1), ':',num2str(mean(bci.grad_value(volume_start:volume))),';']);
                                            sucess_send = 1;
                                        end
                                    else
                                        % save([bci.output_dir,filesep,'feedback.mat'],'grads');
                                        grads1=bci.grad_value(volume)+11;
                                        if grads1>21
                                            grads1=21;
                                        elseif grads1<1
                                            grads1=1;
                                        end
                                        if ~bci.basic_info.isUDP
                                            fprintf(fid_feedback,'%s\n',num2str(grads1));
                                        else
                                            fwrite(u1, [num2str(volume), ':',num2str(grads1),';']);
                                        end
                                    end
                                end
                                update_thermo(bci.fig, bci.grad_value(volume), [1 0 0], bci.prt.b.ui.backcolor,bci);
                            end
                            if (bci.perf.thermo_image(current_cond+1)==2 || bci.perf.thermo_image(current_cond+2)==2) && volume==volume_end
                                block_reward_mean= mean(bci.current_reward(volume_start: volume_end));
                                if ~bci.basic_info.isUDP
                                    fprintf(fid_money,'%s\n',num2str(block_reward_mean));
                                else
                                    fwrite(u1, [num2str(volume), ':',num2str(block_reward_mean),';']);
                                end
                            elseif (bci.perf.thermo_image(current_cond+1)==3 || bci.perf.thermo_image(current_cond+2)==3) && volume==volume_end
                                bci.total_reward_final=bci.total_reward_final+bci.total_reward;
                                if  bci.total_reward_final < bci.prt.b.ui.MAX_EUROS_per_run
                                    if ~bci.basic_info.isUDP
                                        fprintf(fid_money,'%s\n',num2str(bci.total_reward_final));
                                    else
                                        %fwrite(u1,[num2str(bci.total_reward_final),';']);
                                        fwrite(u1,[num2str(volume),':', num2str(bci.total_reward_final),';']);%
                                    end
                                elseif  bci.total_reward_final>bci.prt.b.ui.Max_EUROS_per_run
                                    if ~bci.basic_info.isUDP
                                        fprintf(fid_money,'%s\n',num2str(bci.prt.b.ui.Max_EUROS_per_run ));
                                    else
                                        fwrite(u1,[num2str(bci.prt.b.ui.Max_EUROS_per_run),';']);%
                                    end
                                    %                                 elseif  bci.total_reward_final<1500
                                    %                                         fprintf(fid_money,'%s\n',num2str(1500));
                                end
                            end
                            if  bci.perf.thermo_image(current_cond)==2
                                [bci.prt.b.ui]= bci_image_display(bci.fig,volume , bci.prt.b.ui, bci.prt.b.images,block_reward_mean );
                            elseif  bci.perf.thermo_image(current_cond)==3
                                [bci.prt.b.ui]= bci_image_display(bci.fig,volume , bci.prt.b.ui, bci.prt.b.images,bci.total_reward_final);
                            end
                        elseif bci.thermometer && ( bci.iscontinuous || bci.isEvent)
                            if ~strcmp(bci.output_dir,'0')
                                % save([bci.output_dir,filesep,'feedback.mat'],'grads');
                                grads1=bci.grad_value(volume)+11;
                                if grads1>21
                                    grads1=21;
                                elseif grads1<1
                                    grads1=1;
                                end
                                if ~bci.basic_info.isUDP
                                    fprintf(fid_feedback,'%s\n',num2str(grads1));
                                else
                                    fwrite(u1, [num2str(volume),':', num2str(grads1),';']);
                                end
                            end
                            update_thermo(bci.fig, bci.grad_value(volume), [1 0 0], bci.prt.b.ui.backcolor,bci);
                            
                            if bci.isEvent
                                if grads > bci.threshold
                                    xn=xn+1;
                                else
                                    xn=0;
                                end
                                if  xn>= bci.time2stimulus
                                    bci.success(current_cond)=1;
                                    fwrite(u1,[ volume+10,';']);%
                                end
                            end
                        elseif  bci.prt.b.ui.SHOW_REWARD && bci.isDelayed
                            bci.cuurent_reward(volume)=eff_choi_del*bci.bci.prt.b.ui.step_euros;
                            bci.total_reward=bci.total_reward+ bci.cuurent_reward(volume);
                            [bci.prt.b.ui]= bci_image_display(bci.fig,volume , bci.prt.b.ui, bci.prt.b.images,bci.cuurent_reward(current_cond) );
                            
                        elseif bci.fes && bci.isEvent
                            
                            update_thermo(bci.fig, grads, [1 0 0], bci.prt.b.ui.backcolor,bci);
                            if bci.isEvent
                                if grads > bci.threshold
                                    xn=xn+1;
                                    if xn>= bci.time2stimulus
                                        bci.success(current_cond)=1;
                                    end
                                elseif grads<=bci.threshold
                                    xn=0;
                                    try
                                        fes_nirs(-1,volume,bci,grads)
                                    catch
                                        pause(0.1);
                                        fes_nirs(-1,volume,bci,grads)
                                    end
                                end
                                if  bci.success(current_cond)==1  && volume== volume_end
                                    if ~bci.debug
                                        if strcmp(bci.system,'Hitachi')
                                            fprintf(bci.port.nn,marker{bci.prt.seqview.cond(current_cond )});
                                        elseif strcmp(bci.system,'NIRx')
                                            outp( bci.trigger_port,marker{bci.prt.seqview.cond(current_cond )});
                                        end
                                        tic,
                                        try
                                            bci.current_pulse_width=fix(bci.pulse_width_range(2)+bci.pulse_width_range(3));
                                            fes_nirs(1,volume,bci,grads)
                                        catch
                                            pause(0.1);
                                            fes_nirs(1,volume,bci,grads)
                                        end
                                        
                                        if strcmp(bci.system,'Hitachi')
                                            pause(0.5);  fprintf(bci.port.nn,marker{bci.prt.seqview.cond(current_cond+1)});
                                        elseif strcmp(bci.system,'NIRx')
                                            pause(0.1);    outp( bci.trigger_port,marker{bci.prt.seqview.cond(current_cond+1)});
                                        end
                                        
                                    end
                                    update_thermo(bci.fig, 0, [1 0 0], bci.prt.b.ui.backcolor,bci);
                                    xn=0;
                                end
                            end
                        elseif bci.fes && bci.iscontinuous
                            update_thermo(bci.fig, grads, [1 0 0], bci.prt.b.ui.backcolor,bci);
                            tic
                            if grads<5
                                bci.current_pulse_width=bci.pulse_width_range(1)+abs(grads)*bci.pulse_width_step(1);
                            elseif grads>5
                                bci.current_pulse_width=bci.pulse_width_range(2)+grads*bci.pulse_width_step(2);
                            elseif grads==10
                                bci.current_pulse_width=bci.pulse_width_range(2);
                            elseif grads<=0
                                bci.current_pulse_width=0;
                                try
                                    fes_nirs(-1,volume,bci,grads)
                                catch
                                    pause(0.1);
                                    fes_nirs(-1,volume,bci,grads)
                                end
                            end
                            if  bci.current_pulse_width>bci.pulse_width_range(3) && grads>5
                                bci.current_pulse_width=bci.pulse_width_range(3);
                            elseif (grads>0 && grads<=5) && bci.current_pulse_width>bci.pulse_width_range(2)
                                bci.current_pulse_width=bci.pulse_width_range(2);
                            end
                            if  bci.current_pulse_width~=0 && grads>0
                                try
                                    t=toc;
                                    pause(1-t);
                                    fes_nirs(1,volume,bci,grads)
                                catch
                                    pause(0.1);
                                    fes_nirs(1,volume,bci,grads)
                                end
                            end
                        end
                    end
                    
                end
                if volume==volume_end
                    bci.average_HB_cond(volume_start:volume_end)= nanmean( bci.cur_choi(volume_start:volume_end));
                end
            end
        end
        
    end
catch Me
    close(bci.fig);
    disp(Me.stack)
    if ~isempty (str2num(bci.run_number))
        close(fHand);
        fclose(bci.port.trigger);
        if bci.basic_info.isUDP
            fclose(u1);
        else
            fclose(fid_feedback);
            fclose(fid_money);
        end
    end
    error_catched=1;
end
try
    delete_thermo;
    close(fHand);
    close(bci.fig);
    fclose(bci.port.trigger);
    if bci.basic_info.isUDP
        fclose(u1);
    else
        fclose(fid_feedback);
        fclose(fid_money);
    end
catch
end
% save([bci.output_dir, filesep, bci.experiment, filesep, bci.Subject, filesep,bci.run_number, filesep, bci.experiment,'_',bci.Subject,'_',bci.run_number,'_', 'feedback.mat'],'bci');
if ~error_catched
    if ~bci.debug && strcmp(bci.system, 'Hitachi')
        fprintf(bci.port.nn,'ED  ');
    end
    [ c]= find( bci.whole_data(:,1)~=0);
    bci.whole_data((max(c)+1):size(  bci.whole_data,1),:)=[];
    bci.data1=[  bci.whole_data', bci.label'];
    
    if  ~bci.istraining_SVM
        [bci.fsel, bci.MI]=fsmibifpw(bci.data1,20,bci.target_label);
        disp('Selected Channels:')
        disp(bci.fsel)
    else
        [bci.fsel, bci.MI]=fsmibifpw(bci.data1,30,bci.SVM_label);
        disp('Selected Channels:')
        disp( bci.fsel)
    end
    if  bci.istraining_SVM
        r = find(bci.data1(:,size(bci.data1,2))==bci.SVM_label(1));
        r1 = find(bci.data1(:,size(bci.data1,2))==bci.SVM_label(2));
        for i11=1:bci.SVM.cross_valid
            multi=floor((size(r1,1)+size(r,1))/(bci.SVM.cross_valid*2));
            if i11==1
                b=r(1:multi*i11);
                rec=r;
                rec(1:multi*i11)=[];
                a=rec;
                b((multi*i11+1):(multi*i11+multi))=r1(1:multi*i11);
                rec1=r1;
                rec1(1:multi*i11)=[];
                
                a(size(rec,1)+1:size(rec,1)+size(rec1,1))=rec1;
                
            else
                b=r((multi*(i11-1)+1):(multi*(i11)));
                rec=r;
                rec((multi*(i11-1)+1):(multi*(i11)))=[];
                a=rec;
                b((multi+1):(multi+multi))=r1((multi*(i11-1)+1):(multi*(i11)));
                rec1=r1;
                rec1((multi*(i11-1)+1):(multi*(i11)))=[];
                
                a(size(rec,1)+1:size(rec,1)+size(rec1,1))=rec1;
                
            end
            train_feature=double(bci.data1(a,bci.fsel));
            test_feature=double(bci.data1(b,bci.fsel));
            test_Label=double(bci.data1(b,size(bci.data1,2)));
            train_label=double(bci.data1(a,size(bci.data1,2)));
            for iCost = 1 : numel( bci.SVM.SVM_para_C)
                bci.SVM.SVM_para = strcat('-t 0 -c ', num2str(bci.SVM.SVM_para_C(iCost)));
                SVM.model = svmtrain(train_label ,train_feature, bci.SVM.SVM_para );
                [pre, acc, dec] = svmpredict(test_Label,test_feature,bci.SVM.model);
                SVM.err(bci.SVM.cross_valid)=100-acc(1);
                accuracy(bci.SVM.cross_valid, iCost) = acc(1);
                SVM.model.pre=pre;
                SVM.model.acc=acc;
                SVM.model.dec=dec;
                SVM.model.W=SVM.model.sv_coef'*SVM.model.SVs;
                SVM.model.pred_tr=bci.SVM.model.W*train_feature'-SVM.model.rho;
                SVM.model.multi = SVM.model.multi;
                bci.SVM.model_cv{bci.SVM.cross_valid, iCost}= SVM.model;
               
            end
           
        end
        % finding model with maximum accuracy
        [y,~] = max(accuracy);
        [value,column] = max(y);
        [~,row]= max(accuracy(:, column));
        fprintf('Selected SVM linear model with cost function: %d with percentage accuracy: %d',...
            bci.SVM.SVM_para_C(column), value);
        % average weights and bais for all cvs
        for ii = 1: bci.SVM.cross_valid
            weights(:, ii) =  bci.SVM.model_cv{ii, column}.W; 
            rho(ii) = bci.SVM.model_cv{ii, column}.rho;
        end
        bci.SVM.model.W = median(weights,2);
        bci.SVM.model.rho = median(rho); 
        model = bci.SVM.model_cv{row,column};
        plotLabel(bci.label==bci.SVM_label(1))=-1;plotLabel(bci.label==bci.SVM_label(2))=1;
        plotPredLabel( model.pre==1)=-1;plotPredLabel( model.pre==0)=1;
        figure,stem( model.dec,'*'),hold on, stem(plotPredLabel,'.r','LineStyle','none'), stem(plotLabel,'.g','LineStyle','none'),hold off;
        
        
        
    elseif ~ bci.istraining_SVM ||  bci.istraining_SVM
        if isempty(str2num(bci.run_number)) %#ok<ST2NM>
            if ~bci.auto_sel
                if bci.isnone
                    
                    try
                        plot_MI(bci);
                        bci.sel_ch_str= input_channel('normal',bci);
                        co=strfind(bci.sel_ch_str,';');
                        t =evalc([' bci.sel_ch=[',   bci.sel_ch_str(1:co-1), ']']);
                        t =evalc([' bci.ref_ch=[',   bci.sel_ch_str(co+1:end), ']']);
                    catch
                        warning('Please enter the channels correctly!!');
                        bci.sel_ch_str= input_channel('normal',bci);
                        t=evalc(['bci.sel_ch=[',   bci.sel_ch_str, ']']);
                        
                    end
                else
                    try
                        bci.roi1_str= input_channel('correlation',bci);
                        t=evalc(['bci.roi{1}=[',   bci.roi1_str{1,1}, ']']);
                        t=evalc(['bci.roi{2}=[',   bci.roi1_str{1,2}, ']']);
                    catch
                        if ~isdeployed
                            warning('Please enter the channels correctly!!');
                        else
                            logMessage(bci.log.jEditbox, 'Please enter the channels correctly !!', 'warn');
                        end
                        bci.roi1_str= input_channel('correlation',bci);
                        t=evalc(['bci.roi{1}=[',   bci.roi1_str{1,1}, ']']);
                        t=evalc(['bci.roi{2}=[',   bci.roi1_str{1,2}, ']']);
                    end
                    bci.sel_ch_str=[bci.roi1_str{1,1},bci.roi1_str{1,2}];
                    bci.sel_ch=[bci.roi{1},bci.roi{2}];
                    
                end
            else
                
                if sum(bci.fsel(1:5)==1)>0 || sum(bci.fsel(1:5)==3)>0
                    aa=bci.fsel;
                    aa(aa==1)=[]; aa(aa==3)=[];
                    bci.sel_ch=aa(1:5);
                    bci.sel_ch_str=num2str(aa(1:5));
                else
                    bci.sel_ch=bci.fsel(1:5);
                    bci.sel_ch_str=num2str(bci.fsel(1:5));
                end
                plot_MI(bci);
            end
            bci.chContrast=  bci.sel_ch;
            if bci.thermo_bars <2
                ed= errordlg('The number of bars specified wrongly','Thermometer Bars');
                waitfor(ed);
                the=inputdlg('Please specify number of bars:','Number of Bars');
                bci.thermo_bars=str2num(the{1,1}); %#ok<ST2NM>
                
            end
            %             bci=bci_computeERA(bci);
            %             bci=bci_plotERA( bci.sel_ch,bci);
            if  sum(bci.target_cond==9)>0
                aa=bci.prt.seqview.cond( find( bci.perf.criteria==9, 1, 'first' ));
                if aa==bci.target_label(1)
                    bb=bci.perf.criteria(find(bci.prt.seqview.cond==bci.target_label(2), 1, 'first'));
                    bci.med_sel_ch=median(abs(nanmean(bci.data1((bci.target_cond==bb),  abs(bci.sel_ch)))- nanmean(bci.data1((bci.target_cond==9),  abs(bci.sel_ch)))));
                    bci.std_sel_ch=median(std(bci.data1((bci.target_cond==bb), abs( bci.sel_ch))));
                elseif aa==bci.target_label(2)
                    bb=bci.perf.criteria(find(bci.prt.seqview.cond==bci.target_label(1), 1, 'first'));
                    bci.med_sel_ch=median(abs(nanmean(bci.data1((bci.target_cond==bb), abs(bci.sel_ch)))- nanmean(bci.data1((bci.target_cond==9), abs( bci.sel_ch)))));
                    bci.std_sel_ch=median(std(bci.data1((bci.target_cond==bb),  abs(bci.sel_ch))));
                end
            else
                bci.med_sel_ch=median(abs([nanmean(bci.data1((bci.target_cond==bci.target_label(2)), abs( bci.sel_ch))), nanmean(bci.data1((bci.target_cond==bci.target_label(1)),  abs(bci.sel_ch)))]));
                bci.std_sel_ch=median([std(bci.data1((bci.target_cond==bci.target_label(2)),  abs(bci.sel_ch))),std(bci.data1((bci.target_cond==bci.target_label(1)),  abs(bci.sel_ch)))]);
                
            end
            if ~isdeployed
                disp (['HBO value :', num2str(bci.med_sel_ch)]);
                disp ([' Standard deviation for HBO :', num2str(bci.std_sel_ch)]);
            else
                logMessage(bci.log.jEditbox, ['HBO value :', num2str(bci.med_sel_ch)], 'info');
                logMessage(bci.log.jEditbox, [' Standard deviation for HBO :', num2str(bci.std_sel_ch)], 'info');
            end
            if ~bci.auto_sel
                ttn =inputdlg('Please mention the number of standard deviation to calculate the normalizing fator [e.g. 2]:');
            else
                ttn={2};
            end
            bci.range=ttn{1,1};
            ch_HBO=((bci.med_sel_ch+(bci.range*bci.std_sel_ch))-(bci.med_sel_ch-(bci.range*bci.std_sel_ch)));
            if ((bci.med_sel_ch+(bci.range*bci.std_sel_ch))-(bci.med_sel_ch-(bci.range*bci.std_sel_ch)))<=0
                ed= errordlg('Error in calculating HBO range','Error');
                waitfor(ed);
                ch_HBO=1;
            end
            
            multi_factor=ceil(bci.thermo_bars /ch_HBO);
            if isfield(bci,'ref_ch')
                bci.sel_ch=[ bci.sel_ch,bci.ref_ch];
                bci.sel_ch_str=[num2str(bci.sel_ch)];
            end
            if multi_factor>35
                warning('Multiplying factor is very high. Please consider using smaller multiplying factor...')
                multi_factor=35;
            elseif  multi_factor < 1
                multi_factor= 1;
            end
            if isfield(bci,'ref_ch')
                bci.chWeight= [ ((ones(size(  abs(bci.sel_ch))))*multi_factor),-1*((ones(size(  abs(bci.ref_ch))))*multi_factor)];%.* bci.channel_weight_direction;
            else
                bci.chWeight= (ones(size(  abs(bci.sel_ch))))*multi_factor;%.* bci.channel_weight_direction;
            end
            save([fileparts(bci.savefile), filesep, bci.run_number '_extra.mat'],'multi_factor','bci');
            
            fprintf('IMPORTANT: Please Note the Thermometer Multiplication Factor: %d\n', multi_factor);
        elseif ~isempty (str2num(bci.run_number)) %#ok<ST2NM>
            if bci.thermo_bars < 2
                ed= errordlg('The number of bars specified wrongly','Thermometer Bars');
                waitfor(ed);
                the=inputdlg('Please specify number of bars:','Number of Bars');
                bci.thermo_bars=str2num(the{1,1}); %#ok<ST2NM>
                
            end
            if ~isfield(bci,'sel_ch' )
                bci.sel_ch=bci.chContrast;
            end
            if  sum(bci.target_cond==9)>0
                aa=bci.prt.seqview.cond( find( bci.perf.criteria==9, 1, 'first' ));
                if aa==bci.target_label(1)
                    bb=bci.perf.criteria(find(bci.prt.seqview.cond==bci.target_label(2), 1, 'first'));
                    bci.med_sel_ch=median(abs(nanmean(bci.data1((bci.target_cond==bb),  bci.sel_ch))- nanmean(bci.data1((bci.target_cond==9),  bci.sel_ch))));
                    bci.std_sel_ch=median(std(bci.data1((bci.target_cond==bb),  bci.sel_ch)));
                elseif aa==bci.target_label(2)
                    bb=bci.perf.criteria(find(bci.prt.seqview.cond==bci.target_label(1), 1, 'first'));
                    bci.med_sel_ch=median(abs(nanmean(bci.data1((bci.target_cond==bb),  bci.sel_ch))- nanmean(bci.data1((bci.target_cond==9),  bci.sel_ch))));
                    bci.std_sel_ch=median(std(bci.data1((bci.target_cond==bb),  bci.sel_ch)));
                end
            else
                bci.med_sel_ch=median(abs([nanmean(bci.data1((bci.target_cond==bci.target_label(2)),  bci.sel_ch)), nanmean(bci.data1((bci.target_cond==bci.target_label(1)),  bci.sel_ch))]));
                bci.std_sel_ch=median([std(bci.data1((bci.target_cond==bci.target_label(2)),  bci.sel_ch)),std(bci.data1((bci.target_cond==bci.target_label(1)),  bci.sel_ch))]);
                
            end
            %bci=bci_computeERA(bci);
            try
                bci=bci_plotERA( abs(bci.sel_ch),bci);
            catch
            end
            if ~isdeployed
                disp (['HBO value :', num2str(bci.med_sel_ch)]);
                disp ([' Standard deviation for HBO :', num2str(bci.std_sel_ch)]);
            else
                logMessage(bci.log.jEditbox, ['HBO value :', num2str(bci.med_sel_ch)], 'info');
                logMessage(bci.log.jEditbox, [' Standard deviation for HBO :', num2str(bci.std_sel_ch)], 'info');
            end
            ttn = inputdlg('Number of std for normalizing fator [e.g. 2]:', 'Std', [1 50]);
            bci.range= str2num(ttn{1});
            %         ch_HBO=((bci.med_sel_ch+(bci.range*bci.std_sel_ch))-(bci.med_sel_ch-(bci.range*bci.std_sel_ch)));
            %         if ((bci.med_sel_ch+(bci.range*bci.std_sel_ch))-(bci.med_sel_ch-(bci.range*bci.std_sel_ch)))<=0
            %             ed= errordlg('Error in calculating HBO range','Error');
            %             waitfor(ed);
            %             ch_HBO=1;
            %         end
            
            multi_factor= ceil(bci.thermo_bars /(bci.range*2*bci.std_sel_ch));
            disp (['Multiply factor :', num2str(multi_factor)]);
            if multi_factor>35
                multi_factor= 35;
                if ~isdeployed
                    warning('Multiplying factor is very high. Please consider using smaller multiplying factor...')
                else
                    logMessage(bci.log.jEditbox, 'Multiplying factor is very high. Please consider using smaller multiplying factor...', 'warn');
                end
           elseif  multi_factor < 1
                multi_factor= 1;
            end
            %  multi_factor= ceil(bci.thermo_bars /(bci.range*2*bci.std_sel_ch));
            % bci.chWeight= (ones(size(find(bci.ch_weights~=0))))*multi_factor;
            save([fileparts(bci.savefile), bci.run_number '_extra.mat'],'multi_factor','bci');
            
            if ~isdeployed
                fprintf('IMPORTANT: Please Note the Thermometer Multiplication Factor: %d\n', multi_factor);
            else
                logMessage(bci.log.jEditbox, ['IMPORTANT: Please Note the Thermometer Multiplication Factor:', num2str(multi_factor)], 'info');
            end
        end
    end
    save(bci.savefile,'bci');
    
    if ~isempty (str2num(bci.run_number)) %#ok<ST2NM>
        figure,plot( bci.cur_choi,'color','b','LineWidth',2); hold on
        plot(bci.grad_value, 'color','r','LineWidth',2);
        plot(bci.average_HB_cond,'color','k','LineWidth',2);
        plot(bci.eff_choi_value, 'color','g','LineWidth',2);
        legend('HB original','Grad values','Average HB','Correct HB','Location','NorthEastOutside')
    end
    
    if((current_cond > 1)) % & (image == 0))
        if ~bci.debug && bci.fes
            fclose(bci.port.s);
        end
        if ~bci.debug && strcmp(bci.system,'Hitachi')
            fclose (bci.port.nn);
        end
    end
end



%fprintf('IMPORTANT: Please Note the Thermometer Multiplication Factor: %d\n', multi_factor);
return
%------------------------------------------
function key_pressed = whichKeyPress()

key_pressed = 0;

key_pressed = get(gcf, 'CurrentCharacter');
%fprintf('\n%d\n', key_pressed);
return

