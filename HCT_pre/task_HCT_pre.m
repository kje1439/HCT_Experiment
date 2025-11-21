clear all
close all
clc

% taskdir = 'C:\Users\bspl\Downloads\task_files\task_files\HCT_pre';
% cd(taskdir);

HBC_dur = [40, 45, 25, 30, 50, 35];
% HBC_dur = [1 3 2 3 2 3]; % for test
% rand_idx=randperm(6);
% HBC_dur = HBC_dur(rand_idx);

%% sbjInfo
timestamp = clock;
timestamp = strcat(num2str(timestamp(4 )), '_', sprintf('%02d',timestamp(5)));
timestamp = timestamp(~isspace(timestamp));
datDir=fullfile('..','Data');
tmpDir = fullfile('..','Data_tmp');
sbjInfo.ID=input('Subject ID ? ');
sbjInfo.Name=input('Subject Name ? ','s');

fileName = strcat('sbj_', sprintf('%02d_%s',sbjInfo.ID,sbjInfo.Name));
prac=input('practice ? (1 yes) ');
% realecg =input('ecg connected ? (1 yes) ');

saveFileName=fullfile(datDir, strcat(fileName,'_hct.mat'));
errFilename=fullfile(tmpDir, strcat(fileName,'_hct_', timestamp, '.mat'));

% %% ecg get
% if realecg ==1
%     try
%     addpath('C:\Users\user\Desktop\LSD_EEG\BIOPAC Hardware API 2.2.3 Education')
%     addpath('C:\Users\user\Desktop\LSD_EEG\cuspis-main')
%     
%     Bhapi = setApi('C:\Users\user\Desktop\LSD_EEG\BIOPAC Hardware API 2.2.3 Education');
%     MpSys = setDaq(9, 1e4, 101, 11);
%     openApi(Bhapi, MpSys);
%     hz =10000;
%     ecg = recSignal(Bhapi, MpSys, 1, 'seconds', 0.5);
%     catch
%         error('no ecg detected');
%     end
% end
%% Experimental parameter
PsychJavaTrouble();
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebugLevel', 0);
Screen('Preference', 'ConserveVRAM', 64);
Screen('Preference', 'TextRenderer', 0);


% Keyboard inputs
KbName('UnifyKeyNames');
[KeyIsDown, secs, KeyCode] = KbCheck; % dummy check
quitKey = KbName('q');
% nextKey = KbName('space');
nextKey = KbName('4$');
syncKey = KbName('s');
% respLKey = [KbName('0)') KbName('1!') KbName('2@') KbName('3#') KbName('4$') KbName('5%') KbName('6^') KbName('7&') KbName('8*') KbName('9(')];
respLKey = [KbName('2@') KbName('3#')];
% respLKey = [KbName('0') KbName('1') KbName('2') KbName('3') KbName('4') KbName('5') KbName('6') KbName('7') KbName('8') KbName('9')];
% respnums = {'0','1','2','3','4','5','6','7','8','9'};
KeyCode_active = [syncKey nextKey quitKey respLKey]';  % activate only the keys that need to be used
KeyCode_inactive = setdiff(1:length(KeyCode), KeyCode_active);  % inactivate other keys


% Color
white = [255 255 255];
gray = [127 127 127];
black = [0 0 0];
red = [255 0 0];
bgcolor = black;
textSi = 28;

conf_txt = '방금 응답한 심박수에 대해 얼마나 확신하십니까?';
scale = '0 - 1 - 2 - 3 - 4 - 5 - 6 - 7 - 8 - 9 - 10';
prend_txt = '연습 시행이 완료되었습니다.';
mnend_txt = '본 시행이 모두 완료되었습니다. \n\n자리에 앉아 다음 안내를 기다려주세요.';

%% Screen parameters
Screens = Screen('Screens');
ScreenNumber = max(Screens);
%ScreenNumber = 2;
[mainwin, screenrect] = Screen('OpenWindow', ScreenNumber, [100 100 100]);
%screenrect = [0 0 1980 1080];
center = [screenrect(3)/2, screenrect(4)/2];  % center coordinate of the monitor screen

instSi = [0 0 screenrect(3) screenrect(4)];

% % Set priority for script execution to realtime priority:
% priorityLevel=MaxPriority(mainwin);
% Priority(priorityLevel);

%inst
list_inst = dir(fullfile('img','*.jpg'));
nINST = length(list_inst);
im_INST = NaN(nINST,1);
for i = 1:nINST
    im1 = imread(fullfile(list_inst(i).folder, list_inst(i).name));
    im_INST(i,:) = Screen('MakeTexture', mainwin, im1);
end

HideCursor;
Screen('TextSize', mainwin, textSi);
%% log file
logFilename=fullfile(tmpDir, strcat(fileName,'_','log_', timestamp, '.txt'));
tlog=cell(0);

%% fMRI sync waiting
Screen('FillRect', mainwin, bgcolor);
DrawFormattedText(mainwin, double('Sync waiting'), 'center', 'center', white);
Screen('Flip', mainwin);
% syncf=1;
keyIsDown=0;
KbQueueCreate;
KbQueueStart;
disp('sync waiting')
while 1
%     [keyIsDown, endrt, keyCode] = KbCheck;
    [keyIsDown,firstPress]=KbQueueCheck;
%     keyCode(KeyCode_inactive) = 0;
%     if keyIsDown
%         if keyIsDown && keyCode(KbName('s'))
        if keyIsDown && firstPress(KbName('s'))
            disp('sync on')
%             KbReleaseWait;
            break;
        end
%     end
    WaitSecs(0.01);
end
KbQueueRelease;
stime=datetime;
tlog{1,1}='Sync';
tlog{1,2}=datetime(stime,'format','uuuu-MM-dd HH:mm:ss.SSSSSSS');
% WaitSecs(0.1);
%%
try
    %% instruction
    for inst = 1:4
        Screen('DrawTexture', mainwin, im_INST(inst), [], instSi, 0, [], [], [], [], [], []);  % instruction page
        [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
        
%         keycheck = 0;
%         while keycheck == 0
%             [keyisdown,secs,keycode] = KbCheck;
%             if keycode(KbName('space')) == 1;
%                 keycheck =1;
%                 tt = target_onset;
%                 ss = secs;
%             elseif keycode(quitKey) == 1
%                 save(errFilename);
%                 ShowCursor; Screen('CloseAll'); return
%             end
%         end
        WaitSecs(5);
        tlog{end+1,1}=sprintf('Instruction%02d',inst);
        tlog{end,2}=seconds(datetime-stime);
    end
    
    if prac ==1
        %% prac_start
        Screen('DrawTexture', mainwin, im_INST(5), [], instSi, 0, [], [], [], [], [], []);  % instruction page
        [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
%         keycheck = 0;
%         while keycheck == 0
%             [keyisdown,secs,keycode] = KbCheck;
%             if keycode(KbName('space')) == 1;
%                 keycheck =1;
%                 tt = target_onset;
%                 ss = secs;
%             end
%         end
        WaitSecs(5);
        tlog{end+1,1}='Practice_Instruction';
        tlog{end,2}=seconds(datetime-stime);
        
        for pi =1:2
            % Cross fixation 10sec
            Screen('DrawTexture', mainwin, im_INST(6), [], instSi, 0, [], [], [], [], [], []);  % cross fixation page
            Screen('Flip', mainwin);
            
            WaitSecs(10);
            tlog{end+1,1}='Cross';
            tlog{end,2}=seconds(datetime-stime);
            for ss = 3:-1:1
%                 Screen('FillRect', mainwin, bgcolor);
                DrawFormattedText(mainwin, double(num2str(ss)), 'center', 'center', white);
                Screen('Flip', mainwin);
                WaitSecs(1);
            end
            tlog{end+1,1}='Countdown';
            tlog{end,2}=seconds(datetime-stime);
            
            % count start
            Screen('DrawTexture', mainwin, im_INST(7), [], instSi, 0, [], [], [], [], [], []);  % Green circle page
            Screen('Flip', mainwin);
            WaitSecs(10);
            tlog{end+1,1}=sprintf('Practice_Green%02d',pi);
            tlog{end,2}=seconds(datetime-stime);
%             WaitSecs(1);
            
            %count end
            Screen('DrawTexture', mainwin, im_INST(8), [], instSi, 0, [], [], [], [], [], []);  % Red circle page
            [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
            ansenter = 0;
            tansw=0;
            answ = '';
            while ~ansenter
                keyIsDown = 0;
                while 1
%                     onset = GetSecs;
                    [keyIsDown, endrt, keyCode] = KbCheck;
                    keyCode(KeyCode_inactive) = 0;
                    if keyIsDown
%                         find(keyCode(respLKey))
%                         if length(find(keyCode(respLKey) == 1)) ~=0
                        if keyCode(KbName('4$'))
                            tansw=tansw+1;
%                             disp(respnums{tmp_ans(1)})
%                             answ = strcat(answ, respnums{tmp_ans(1)});
                            answ = num2str(tansw);
                            break;
                        elseif keyCode(KbName('3#')) && tansw>0
                            tansw=tansw-1;
                            answ = num2str(tansw);
                            break;
                        elseif keyCode(KbName('2@')) == 1
                            if str2double(answ) > 0
                                ansenter = 1;break;
                            else
                                break;
                            end
                        elseif keyCode(quitKey) == 1
                            save(errFilename);
                            ShowCursor; Screen('CloseAll'); return
                        else
                            break;
                        end
                    end
                end
                if ansenter ==1
                    break;
                end
                Screen('DrawTexture', mainwin, im_INST(8), [], instSi, 0, [], [], [], [], [], []);  % red circle page
                DrawFormattedText(mainwin, double(answ), 'center', center(2)+250, red);
                
                [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
                
                WaitSecs(0.15);
            end
            tlog{end+1,1}=sprintf('Practice_red_resp%02d',pi);
            tlog{end,2}=seconds(datetime-stime);

            tmp_resp(pi,1) = str2num(answ);
            WaitSecs(0.1);
            %% confidence
%             Screen('FillRect', mainwin, bgcolor);
            DrawFormattedText(mainwin, double(conf_txt), 'center', 'center', white);
            DrawFormattedText(mainwin, double(scale), 'center', center(2)+250, white);
            [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
            
            confresp = 0;
            tconf = randi(10)-1;
            inif=0;
            while ~confresp
                keyIsDown = 0;
                while 1
                    onset = GetSecs;
                    [keyIsDown, endrt, keyCode] = KbCheck;
                    keyCode(KeyCode_inactive) = 0;
                    if keyIsDown
                        if keyCode(KbName('4$')) && tconf<10
                            tconf = tconf+1;
                            tmp_resp(pi,2) = tconf;
                            inif=1;
                            break;
                        elseif keyCode(KbName('3#')) && tconf>0
                            tconf = tconf-1;
                            tmp_resp(pi,2) = tconf;
                            inif=1;
                            break;
                        elseif keyCode(KbName('2@')) && inif
                            confresp=1;break;
                        elseif keyCode(quitKey) == 1
                            save(errFilename);
                            ShowCursor; Screen('CloseAll'); return
                        else
                            break;
                        end
                    end
                end
%             WaitSecs(0.2);
            if confresp
                break;
            end
%             Screen('FillRect', mainwin, bgcolor);
            DrawFormattedText(mainwin, double(conf_txt), 'center', 'center', white);
            DrawFormattedText(mainwin, num2str(tconf), 'center', center(2)+250, red);
            Screen('Flip', mainwin);
            WaitSecs(0.15);
            end
            
            tlog{end+1,1}=sprintf('Practice_conf%02d',pi);
            tlog{end,2}=seconds(datetime-stime);
             
            
        end
        
        % Cross fixation 10sec
            Screen('DrawTexture', mainwin, im_INST(6), [], instSi, 0, [], [], [], [], [], []);  % cross fixation page
            Screen('Flip', mainwin);
            
            WaitSecs(10);
            tlog{end+1,1}='Cross';
            tlog{end,2}=seconds(datetime-stime);

%         Screen('FillRect', mainwin, bgcolor);
        DrawFormattedText(mainwin, double(prend_txt), 'center', 'center', white);
        Screen('Flip', mainwin);
        
%         keycheck = 0;
%         while keycheck == 0
%             [keyisdown,secs,keycode] = KbCheck;
%             if keycode(KbName('space')) == 1;
%                 keycheck =1;
%                 tt = target_onset;
%                 ss = secs;
%             end
%         end
        WaitSecs(5);
        tlog{end+1,1}='Practice_end';
        tlog{end,2}=seconds(datetime-stime);
    end
    
    %% main task start
    
    Screen('DrawTexture', mainwin, im_INST(9), [], instSi, 0, [], [], [], [], [], []);  % instruction page
    [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
    
    WaitSecs(5);
    tlog{end+1,1}='Main_instruction';
    tlog{end,2}=seconds(datetime-stime);
    for mi =1:length(HBC_dur)
        % cross fixation 10sec
        Screen('DrawTexture', mainwin, im_INST(6), [], instSi, 0, [], [], [], [], [], []);  % cross fixation page
        Screen('Flip', mainwin);
        
        WaitSecs(10);
        tlog{end+1,1}='Cross';
        tlog{end,2}=seconds(datetime-stime);
        for ss = 3:-1:1
%             Screen('FillRect', mainwin, bgcolor);
            DrawFormattedText(mainwin, double(num2str(ss)), 'center', 'center', white);
            Screen('Flip', mainwin);
            WaitSecs(1);
        end
        tlog{end+1,1}='Countdown';
        tlog{end,2}=seconds(datetime-stime);
        % count start
        Screen('DrawTexture', mainwin, im_INST(7), [], instSi, 0, [], [], [], [], [], []);  % instruction page
        Screen('Flip', mainwin);
        
        WaitSecs(HBC_dur(mi));
        tlog{end+1,1}=sprintf('Main_green%02d',mi);
        tlog{end,2}=seconds(datetime-stime);
        %count end
        Screen('DrawTexture', mainwin, im_INST(8), [], instSi, 0, [], [], [], [], [], []);  % instruction page
        [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
%         ecg_data{mi} = ecg;
        ansenter = 0;
        tansw=0;
        answ = '';
        while ~ansenter
            keyIsDown = 0;
            while 1
                onset = GetSecs;
                [keyIsDown, endrt, keyCode] = KbCheck;
                keyCode(KeyCode_inactive) = 0;
                if keyIsDown
                    if keyCode(KbName('4$'))
                        tansw=tansw+1;
                        answ = num2str(tansw);
                        break;
                    elseif keyCode(KbName('3#')) && tansw>0
                            tansw=tansw-1;
                            answ = num2str(tansw);
                            break;
                    elseif keyCode(KbName('2@')) == 1
                        if str2double(answ) > 0
                            ansenter = 1;break;
                        else
                            break;
                        end
                    elseif keyCode(quitKey) == 1
                        save(errFilename);
                        ShowCursor; Screen('CloseAll'); return
                    else
                        break;
                    end
                end
            end
            if ansenter ==1
                break;
            end
            Screen('DrawTexture', mainwin, im_INST(8), [], instSi, 0, [], [], [], [], [], []);  % instruction page
            DrawFormattedText(mainwin, double(answ), 'center', center(2)+250, red);
            
            [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
            
            WaitSecs(0.15);
        end
        tlog{end+1,1}=sprintf('Main_red_resp%02d',mi);
        tlog{end,2}=seconds(datetime-stime);

        resp(mi,1) = str2num(answ);
        WaitSecs(0.1);
        
%         Screen('FillRect', mainwin, bgcolor);
        DrawFormattedText(mainwin, double(conf_txt), 'center', 'center', white);
        DrawFormattedText(mainwin, double(scale), 'center', center(2)+250, white);
        [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
        confresp = 0;
        tconf = randi(10)-1;
        inif=0;
        while ~confresp
            keyIsDown = 0;
            while 1
                onset = GetSecs;
                [keyIsDown, endrt, keyCode] = KbCheck;
                keyCode(KeyCode_inactive) = 0;
                if keyIsDown
                    if keyCode(KbName('4$')) && tconf<10
                        tconf = tconf+1;
                        resp(mi,2) = tconf;
                        inif=1;
                        break;
                    elseif keyCode(KbName('3#')) && tconf>0
                        tconf = tconf-1;
                        resp(mi,2) = tconf;
                        inif=1;
                        break;
                    elseif keyCode(KbName('2@')) && inif
                        confresp=1;break;
                    elseif keyCode(quitKey) == 1
                        save(errFilename);
                        ShowCursor; Screen('CloseAll'); return
                    else
                        break;
                    end
                end
            end
%             WaitSecs(0.2);
            if confresp
                break;
            end
%             Screen('FillRect', mainwin, bgcolor);
            DrawFormattedText(mainwin, double(conf_txt), 'center', 'center', white);
            DrawFormattedText(mainwin, double(num2str(tconf)), 'center', center(2)+250, red);
            Screen('Flip', mainwin);
            WaitSecs(0.15);
        end
        tlog{end+1,1}=sprintf('Main_conf%02d',mi);
        tlog{end,2}=seconds(datetime-stime);
         % Cross fixation 10sec
            Screen('DrawTexture', mainwin, im_INST(6), [], instSi, 0, [], [], [], [], [], []);  % cross fixation page
            Screen('Flip', mainwin);
            
            WaitSecs(10);
        tlog{end+1,1}='Cross';
        tlog{end,2}=seconds(datetime-stime);
    end
    
%     Screen('FillRect', mainwin, bgcolor);
    DrawFormattedText(mainwin, double(mnend_txt), 'center', 'center', white);
    Screen('Flip', mainwin);
    
    keycheck = 0;
    while keycheck == 0
        [keyisdown,secs,keycode] = KbCheck;
        if keycode(KbName('space')) == 1;
            keycheck =1;
            tt = target_onset;
            ss = secs;
        end
    end
    
    WaitSecs(0.1);
    
    %% calculate IACC, IS, time estimation
    minIBI = 0.3;
    hbc_data =[];
%     for ht = 1:length(HBC_dur)
%         hbc_data(ht,1) = HBC_dur(ht);
%         [pks, locs] = findpeaks(ecg_data{ht},'minPeakHeight',mean(ecg_data{ht})+std(ecg_data{ht})*2, 'MinPeakDistance',minIBI*hz);
%         hbc_data(ht,2) = length(pks); %actual hb
%         hbc_data(ht,3) = resp(ht,1); %reported hb
%         hbc_data(ht,4) = resp(ht,2); %confidence
%         hbc_data(ht,5) = 1 - (abs(hbc_data(ht,2)-hbc_data(ht,3))/((hbc_data(ht,2)+hbc_data(ht,3))/2)); %IACC
%         hbc_data(ht,6) = 1 - (abs(hbc_data(ht,1)-hbc_data(ht,3))/((hbc_data(ht,1)+hbc_data(ht,3))/2)); %time estimation
%     end
    
%     save(saveFileName,'resp','ecg_data','hbc_data','sbjInfo');
    save(saveFileName,'tmp_resp','resp','HBC_dur','sbjInfo','tlog');
    Screen('CloseAll');
    tlog{end+1,1}='End';
    tlog{end,2}=seconds(datetime-stime);
    % fprintf('meanIACC: %.2f, mean IS: %.1f\n',mean(hbc_data(:,5)), mean(hbc_data(:,4)))
    lgf=fopen(logFilename,'w+');
    fprintf(lgf,'%s\t%s\n',tlog{1,1},sprintf('%s',tlog{1,2}));
    for a=2:length(tlog)
        fprintf(lgf,'%s\t%s\n',tlog{a,1},num2str(tlog{a,2}));
    end
    fclose(lgf);
catch
    save(errFilename);
    Screen('CloseAll');
end
