clear all
close all
clc

taskdir = 'C:\Users\user\Desktop\LSD_EEG\LCD';
cd(taskdir);

%%
% LCD_dur = [65, 50, 60, 30, 40, 55];
LCD_dur = [40, 45, 25, 30, 50, 35];
% LCD_dur = [10, 10, 10, 10, 10, 10];

%% set up for the EEG expeirments
% initialize access to the inpoutx32 low-level I/O driver
config_io;
% optional step: verify that the inpoutx32 driver was successfully initialized
global cogent;
if( cogent.io.status ~= 0 )
    error('inp/outp installation failed');
end
address = hex2dec('3FF8');% write a value to the LPT1 port EEG
% trigger coding
trigger.taskstart = 90;
trigger.lcstart = 91;
trigger.lcend = 92;
trigger.lcresp = 93;
trigger.lcconfans = 94;
trigger.taskend = 99;
%%%%%%%%%%%%%%%%%%%%%% Expt information %%%%%%%%%%%%%%%%%%%%%%%%%
%% sbjinfo
timestamp = clock;
timestamp = strcat(num2str(timestamp(4)), '_', sprintf('%02d',timestamp(5)));
timestamp = timestamp(~isspace(timestamp));
datDir='Data';
tmpDir = 'Data_tmp';
sbjInfo.ID=input('Subject ID ? ');
prac=input('practice ? (1 yes) ');

fileName = strcat('sbj_', sprintf('%02d',sbjInfo.ID));
saveFileName=fullfile(datDir, strcat(fileName,'.mat'));
errFilename=fullfile(tmpDir, strcat(fileName,'_', timestamp, '.mat'));
%% Random shuffle seed
% rng('shuffle');
%stream = RandStream('mt19937ar', 'seed', sum(100*clock));
%RandStream.setDefaultStream(stream);





PsychJavaTrouble();
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebugLevel', 0);
Screen('Preference', 'ConserveVRAM', 64);
Screen('Preference', 'TextRenderer', 0);
rand('state',sum(clock));
Screens = Screen('Screens');
ScreenNumber = max(Screens);
%     ScreenNumber = 1;
[mainwin, screenrect] = Screen('OpenWindow', ScreenNumber, [100 100 100]);
gray_fix = [127 127 127];
white    = [255 255 255];
black = [0 0 0];
red = [255 0 0];
bgcolor = black;
rect = [0 0 1920 1080];
xc = rect(3)/2;
yc = rect(4)/2;
[img_full_cx, img_full_cy] = RectCenter([0 0 rect(3) rect(4)]); %full screen
[img_full_loc] = CenterRectOnPoint([0 0 1024 576], img_full_cx, img_full_cy);
KbName('UnifyKeyNames');
[KeyIsDown, secs, KeyCode] = KbCheck; % dummy check
key_space = KbName('space');
key_quit = KbName('q');
respLKey = [KbName('0') KbName('1') KbName('2') KbName('3') KbName('4') KbName('5') KbName('6') KbName('7') KbName('8') KbName('9')];
respnums = {'0','1','2','3','4','5','6','7','8','9'};
KeyCode_active = [key_space key_quit respLKey]';  % activate only the keys that need to be used
KeyCode_inactive = setdiff(1:length(KeyCode), KeyCode_active);  % inactivate other keys
resp_txt = '몇 번의 변화가 있었습니까?';
conf_txt = '방금 응답에 대해 얼마나 확신하십니까?';
scale = '0 - 1 - 2 - 3 - 4 - 5 - 6 - 7 - 8 - 9';

ScreenDis = (2.54/96)*1920; %cm
ScreenHeight = (2.54/96)*1080; %cm
ppd=pi/180 * ScreenDis/ScreenHeight * rect(4);
%% Gabor patch
% % ST_med = 37;
% % CP_med = 97;

stim.diameter = 3.5*ppd;          %% the same with the size of grating image matrix
% stim.diameter = 5*ppd;          %% 5 degree visaul angle/ = 3 degree of only gabor
%stim.eccentricity = 3*ppd;    %% 3 degree fix to center of the stim

LT_xc = xc; % - stim.eccentricity;
RT_xc = xc; % + stim.eccentricity;
t1 = 0;
stimRect = [0 0 stim.diameter stim.diameter];
beep=sin(2*pi*0.02*[0:800]);

Stim_duration = 0.5;
changeHz = 10;
%% Stimulus parameter
% imgSize = [5 5]; % in visual degree, [width height]
% imgSz = round(imgSize*ppd);
x = rect(3)*1/2 ;
y = rect(4)*1/2 ;

%% trial info
contRanges = [0.2 0.35 0.15 0.4 0.25 0.3]; contRanges = contRanges*2;
contChange = [9 6 10 5 8 7]; %contChange = contChange*2;
contMin = 0.5 - contRanges/2;


%inst
list_inst = dir(fullfile('img','*.JPG'));
nINST = length(list_inst);
im_INST = NaN(nINST,1);
for i = 1:nINST
    im1 = imread(fullfile(list_inst(i).folder, list_inst(i).name));
    im_INST(i,:) = Screen('MakeTexture', mainwin, im1);
end
instSi = [0 0 rect(3) rect(4)];
HideCursor;
try
    %% instruction
    for inst = 1:6
        Screen('DrawTexture', mainwin, im_INST(inst), [], instSi, 0, [], [], [], [], [], []);  % instruction page
        [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
        
        keycheck = 0;
        while keycheck == 0
            [keyisdown,secs,keycode] = KbCheck;
            if keycode(KbName('space')) == 1;
                keycheck =1;
                tt = target_onset;
                ss = secs;
            elseif keycode(key_quit) == 1
                save(errFilename);
                ShowCursor; Screen('CloseAll'); return
            end
        end
        WaitSecs(0.3);
    end
    
    if prac == 1
        prac_cond_level = changeHz*15/5;
        prac_contRange = [0.1 0.9];   % the lowest and highest contrast
        prac_contChange = 4;
        [after_Img, seq] = make_gabor_img(prac_cond_level, prac_contRange, prac_contChange, 1);
        
        Screen('DrawTexture', mainwin, im_INST(7), [], instSi, 0, [], [], [], [], [], []);  % instruction page
        [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
        
        keycheck = 0;
        while keycheck == 0
            [keyisdown,secs,keycode] = KbCheck;
            if keycode(KbName('space')) == 1;
                keycheck =1;
            end
        end
        WaitSecs(0.3);
        for ss = 3:-1:1
            Screen('FillRect', mainwin, bgcolor);
            DrawFormattedText(mainwin, double(num2str(ss)), 'center', 'center', white);
            Screen('Flip', mainwin);
            WaitSecs(1);
        end
        
        
        for ii = 1:length(seq)
            Screen('FillRect', mainwin, gray_fix);
            tex1 = Screen('MakeTexture', mainwin, after_Img{seq(ii),1});               % left side
            Screen('DrawTexture', mainwin, tex1, [], CenterRectOnPoint(stimRect, LT_xc, yc),t1);
            [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
            startTime = GetSecs;
            stopTime = startTime + 1/changeHz;
            keyIsDown = 0;
            while GetSecs < stopTime
                [keyIsDown, endrt, keyCode] = KbCheck;
                %             keyCode(KeyCode_inactive) = 0;
                if sum(keyCode) > 0
                    if keyCode(key_quit) == 1
                        ShowCursor; Screen('CloseAll'); return
                    end
                end
            end
        end
        Screen('FillRect', mainwin, bgcolor);
        DrawFormattedText(mainwin, double(resp_txt), 'center', 'center', white);
        Screen('Flip', mainwin);
        ansenter = 0;
        answ = '';
        while ~ansenter
            keyIsDown = 0;
            while 1
                onset = GetSecs;
                [keyIsDown, endrt, keyCode] = KbCheck;
                keyCode(KeyCode_inactive) = 0;
                if sum(keyCode) > 0
                    if length(find(keyCode(respLKey) == 1)) ~=0
                        tmp_ans = find(respLKey == find(keyCode));
                        answ = strcat(answ, respnums{tmp_ans(1)});
                        break;
                    elseif keyCode(KbName('space')) == 1
                        if length(answ) > 0
                            ansenter = 1;break;
                        else
                            break;
                        end
                    elseif keyCode(key_quit) == 1
                        save(errFilename);
                        ShowCursor; Screen('CloseAll'); return
                    end
                end
            end
            if ansenter ==1
                break;
            end
            %             Screen('DrawTexture', mainwin, im_INST(8), [], instSi, 0, [], [], [], [], [], []);  % instruction page
            DrawFormattedText(mainwin, double(resp_txt), 'center', 'center', white);
            DrawFormattedText(mainwin, double(answ), 'center', yc+300, red);
            
            [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
            
            WaitSecs(0.3);
        end
        WaitSecs(0.3);
        
        % confidence
        Screen('FillRect', mainwin, bgcolor);
        DrawFormattedText(mainwin, double(conf_txt), 'center', 'center', white);
        DrawFormattedText(mainwin, double(scale), 'center', yc+300, white);
        [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
        keyIsDown = 0;
        while 1
            onset = GetSecs;
            [keyIsDown, endrt, keyCode] = KbCheck;
            keyCode(KeyCode_inactive) = 0;
            if sum(keyCode) > 0
                if length(find(keyCode(respLKey) == 1)) ~=0
                    prac_conf = num2str(find(respLKey == find(keyCode))-1);
                    break;
                elseif keyCode(key_quit) == 1
                    save(errFilename);
                    ShowCursor; Screen('CloseAll'); return
                end
            end
        end
        WaitSecs(0.2);
        Screen('FillRect', mainwin, bgcolor);
        DrawFormattedText(mainwin, double(conf_txt), 'center', 'center', white);
        DrawFormattedText(mainwin, double(prac_conf), 'center', yc+300, red);
        Screen('Flip', mainwin);
        WaitSecs(1);
    end
    
    
    % trigger %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    outp(address,trigger.taskstart); % Execution to triggers EEG
    WaitSecs(0.002); % give enough time to be recoreded EEG
    outp(address,0); % reset the states EEG
    
    for tt = 1:length(LCD_dur)
        Screen('FillRect', mainwin, bgcolor);
        fixationtxt = '스페이스바를 눌러 시작하세요.';
        DrawFormattedText(mainwin, fixationtxt, 'center', 'center', white);
        [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
        
        keycheck = 0;
        while keycheck == 0
            [keyisdown,secs,keycode] = KbCheck;
            if keycode(KbName('space')) == 1;
                keycheck =1;
            end
        end
        WaitSecs(0.3);
        
        Screen('FillRect', mainwin, bgcolor);
        fixationtxt = '+';
        DrawFormattedText(mainwin, fixationtxt, 'center', 'center', white);
        Screen('Flip', mainwin);
        WaitSecs(2);
        for ss = 3:-1:1
            Screen('FillRect', mainwin, bgcolor);
            DrawFormattedText(mainwin, double(num2str(ss)), 'center', 'center', white);
            Screen('Flip', mainwin);
            WaitSecs(1);
        end
        
        %% Gabor_achromatic
        % contrast range in logspace
        cond_level = changeHz*round(LCD_dur(tt)/contChange(tt));
        contRange = [contMin(tt) contMin(tt)+contRanges(tt)];   % the lowest and highest contrast
        [after_Img, seq] = make_gabor_img(cond_level, contRange, contChange, 1);
        
        %%% trigger - lc start
        outp(address,trigger.lcstart); % Execution to triggers EEG
        WaitSecs(0.002); % give enough time to be recoreded EEG
        outp(address,0); % reset the states EEG
        for ii = 1:length(seq)
            Screen('FillRect', mainwin, gray_fix);
            tex1 = Screen('MakeTexture', mainwin, after_Img{seq(ii),1});               % left side
            Screen('DrawTexture', mainwin, tex1, [], CenterRectOnPoint(stimRect, LT_xc, yc),t1);
            [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
            startTime = GetSecs;
            stopTime = startTime + 1/changeHz;
            keyIsDown = 0;
            while GetSecs < stopTime
                [keyIsDown, endrt, keyCode] = KbCheck;
                %             keyCode(KeyCode_inactive) = 0;
                if sum(keyCode) > 0
                    if keyCode(key_quit) == 1
                        ShowCursor; Screen('CloseAll'); return
                    end
                end
            end
        end
        %         fprintf(num2str(tt));
        %%% trigger - lc end
        outp(address,trigger.lcend); % Execution to triggers EEG
        WaitSecs(0.002); % give enough time to be recoreded EEG
        outp(address,0); % reset the states EEG
        %%% resp
        Screen('FillRect', mainwin, bgcolor);
        DrawFormattedText(mainwin, double(resp_txt), 'center', 'center', white);
        Screen('Flip', mainwin);
        ansenter = 0;
        answ = '';
        while ~ansenter
            keyIsDown = 0;
            while 1
                onset = GetSecs;
                [keyIsDown, endrt, keyCode] = KbCheck;
                keyCode(KeyCode_inactive) = 0;
                if sum(keyCode) > 0
                    if length(find(keyCode(respLKey) == 1)) ~=0
                        tmp_ans = find(respLKey == find(keyCode));
                        answ = strcat(answ, respnums{tmp_ans(1)});
                        break;
                    elseif keyCode(KbName('space')) == 1
                        if length(answ) > 0
                            ansenter = 1;break;
                        else
                            break;
                        end
                    elseif keyCode(key_quit) == 1
                        save(errFilename);
                        ShowCursor; Screen('CloseAll'); return
                    end
                end
            end
            if ansenter ==1
                break;
            end
            %             Screen('DrawTexture', mainwin, im_INST(8), [], instSi, 0, [], [], [], [], [], []);  % instruction page
            DrawFormattedText(mainwin, double(resp_txt), 'center', 'center', white);
            DrawFormattedText(mainwin, double(answ), 'center', yc+300, red);
            
            [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
            
            WaitSecs(0.3);
        end
        %         %%% trigger - lc resp
        %         outp(address,trigger.lcresp); % Execution to triggers EEG
        %         WaitSecs(0.002); % give enough time to be recoreded EEG
        %         outp(address,0); % reset the states EEG
        resp(tt,1) = str2num(answ);
        WaitSecs(0.3);
        
        % confidence
        Screen('FillRect', mainwin, bgcolor);
        DrawFormattedText(mainwin, double(conf_txt), 'center', 'center', white);
        DrawFormattedText(mainwin, double(scale), 'center', yc+300, white);
        [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
        keyIsDown = 0;
        while 1
            onset = GetSecs;
            [keyIsDown, endrt, keyCode] = KbCheck;
            keyCode(KeyCode_inactive) = 0;
            if sum(keyCode) > 0
                if length(find(keyCode(respLKey) == 1)) ~=0
                    resp(tt,2) = find(respLKey == find(keyCode))-1;
                    break;
                elseif keyCode(key_quit) == 1
                    save(errFilename);
                    ShowCursor; Screen('CloseAll'); return
                end
            end
        end
        WaitSecs(0.2);
        %%% trigger - lc cond
        outp(address,trigger.lcconfans); % Execution to triggers EEG
        WaitSecs(0.002); % give enough time to be recoreded EEG
        outp(address,0); % reset the states EEG
        Screen('FillRect', mainwin, bgcolor);
        DrawFormattedText(mainwin, double(conf_txt), 'center', 'center', white);
        DrawFormattedText(mainwin, double(num2str(resp(tt,2))), 'center', yc+300, red);
        Screen('Flip', mainwin);
        WaitSecs(1);
    end
    
    save(saveFileName,'resp', 'sbjInfo');
    
    mnend_txt = '과제가 종료되었습니다.\n\n\n자리에 앉아 대기해주세요.';
    Screen('FillRect', mainwin, bgcolor);
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
    WaitSecs(0.3);
    % trigger %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    outp(address,trigger.taskend); % Execution to triggers EEG
    WaitSecs(0.002); % give enough time to be recoreded EEG
    outp(address,0); % reset the states EEG
    
    Screen('CloseAll');
catch
    save(errFilename);
    Screen('CloseAll');
    error('something is wrong');
end
