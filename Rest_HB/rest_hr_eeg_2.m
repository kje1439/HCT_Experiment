 clear all
close all
clc

taskdir = 'C:\Users\bspl\Downloads\task_files\task_files\Rest_HB';
cd(taskdir);

%%
RST_dur = 600;
HBC_dur = [65, 50, 60, 30, 40, 55];

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
trigger.rststart = 11;
trigger.rstend = 12;
trigger.taskstart = 20;
trigger.hrstart = 21;
trigger.hrend = 22;
trigger.hrresp = 23;
trigger.hrconfans = 24;
trigger.taskend = 29;
%%%%%%%%%%%%%%%%%%%%%% Expt information %%%%%%%%%%%%%%%%%%%%%%%%%
%% sbjinfo
timestamp = clock;
timestamp = strcat(num2str(timestamp(4)), '_', sprintf('%02d',timestamp(5)));
timestamp = timestamp(~isspace(timestamp));
datDir='Data';
tmpDir = 'Data_tmp';
sbjInfo.ID=input('Subject ID ? ');
sbjInfo.Name=input('Subject Name ? ','s');

fileName = strcat('sbj_', sprintf('%02d_%s',sbjInfo.ID,sbjInfo.Name));
saveFileName=fullfile(datDir, strcat(fileName,'.mat'));
errFilename=fullfile(tmpDir, strcat(fileName,'_', timestamp, '.mat'));
%% Random shuffle seed
% rng('shuffle');
%stream = RandStream('mt19937ar', 'seed', sum(100*clock));
%RandStream.setDefaultStream(stream);


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
nextKey = KbName('space');
% respLKey = [KbName('0)') KbName('1!') KbName('2@') KbName('3#') KbName('4$') KbName('5%') KbName('6^') KbName('7&') KbName('8*') KbName('9(')];
respLKey = [KbName('0') KbName('1') KbName('2') KbName('3') KbName('4') KbName('5') KbName('6') KbName('7') KbName('8') KbName('9')];
respnums = {'0','1','2','3','4','5','6','7','8','9'};
KeyCode_active = [nextKey quitKey respLKey]';  % activate only the keys that need to be used
KeyCode_inactive = setdiff(1:length(KeyCode), KeyCode_active);  % inactivate other keys


% Color
white = [255 255 255];
gray = [127 127 127];
black = [0 0 0];
red = [255 0 0];
bgcolor = black;

conf_txt = '방금 응답한 심박수에 대해 얼마나 확신하십니까?';
scale = '0 - 1 - 2 - 3 - 4 - 5 - 6 - 7 - 8 - 9';
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

% Set priority for script execution to realtime priority:
priorityLevel=MaxPriority(mainwin);
Priority(priorityLevel);

%inst
list_inst = dir(fullfile('inst','*.jpg'));
nINST = length(list_inst);
im_INST = NaN(nINST,1);
for i = 1:nINST
    im1 = imread(fullfile(list_inst(i).folder, list_inst(i).name));
    im_INST(i,:) = Screen('MakeTexture', mainwin, im1);
end

%% Resting

HideCursor;
Screen('DrawTexture', mainwin, im_INST(1), [], instSi, 0, [], [], [], [], [], []);  % instruction page
[VBLTimestamp, target_onset] = Screen('Flip', mainwin);

keycheck = 0;
while keycheck == 0
    [keyisdown,secs,keycode] = KbCheck;
    if keycode(KbName('space')) == 1;
        keycheck =1;
        tt = target_onset;
        ss = secs;
    elseif keycode(quitKey) == 1
        save(errFilename);
        ShowCursor; Screen('CloseAll'); return
    end
end
WaitSecs(0.3);

Screen('DrawTexture', mainwin, im_INST(2), [], instSi, 0, [], [], [], [], [], []);  % instruction page

[VBLTimestamp, target_onset] = Screen('Flip', mainwin);
% trigger %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
outp(address,trigger.rststart); % Execution to triggers EEG
WaitSecs(0.002); % give enough time to be recoreded EEG
outp(address,0); % reset the states EEG


WaitSecs(RST_dur);

Screen('DrawTexture', mainwin, im_INST(3), [], instSi, 0, [], [], [], [], [], []);  % instruction page
[VBLTimestamp, target_onset] = Screen('Flip', mainwin);
% trigger %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
outp(address,trigger.rstend); % Execution to triggers EEG
WaitSecs(0.002); % give enough time to be recoreded EEG
outp(address,0); % reset the states EEG
keycheck = 0;
while keycheck == 0
    [keyisdown,secs,keycode] = KbCheck;
    if keycode(KbName('space')) == 1;
        keycheck =1;
        tt = target_onset;
        ss = secs;
    elseif keycode(quitKey) == 1
        save(errFilename);
        ShowCursor; Screen('CloseAll'); return
    end
end
WaitSecs(0.3);

%% HR
try
    for ii = 4:8
        Screen('DrawTexture', mainwin, im_INST(ii), [], instSi, 0, [], [], [], [], [], []);  % instruction page
        [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
        keycheck = 0;
        while keycheck == 0
            [keyisdown,secs,keycode] = KbCheck;
            if keycode(KbName('space')) == 1
                keycheck =1;
                tt = target_onset;
                ss = secs;
            elseif keycode(quitKey) == 1
                save(errFilename);
                ShowCursor; Screen('CloseAll'); return
            end
        end
        WaitSecs(0.3);
    end
    
    next_txt= '스페이스 바를 눌러 과제를 시작하세요.';
    Screen('FillRect', mainwin, bgcolor);
    DrawFormattedText(mainwin, double(next_txt), 'center', 'center', white);
    [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
    
    keycheck = 0;
    while keycheck == 0
        [keyisdown,secs,keycode] = KbCheck;
        if keycode(KbName('space')) == 1;
            keycheck =1;
        end
    end
    WaitSecs(0.3);
    % trigger %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    outp(address,trigger.taskstart); % Execution to triggers EEG
    WaitSecs(0.002); % give enough time to be recoreded EEG
    outp(address,0); % reset the states EEG
    for mi =1:length(HBC_dur)
        
        Screen('DrawTexture', mainwin, im_INST(2), [], instSi, 0, [], [], [], [], [], []);  % instruction page
        Screen('Flip', mainwin);
        
        WaitSecs(2);
        for ss = 3:-1:1
            Screen('FillRect', mainwin, bgcolor);
            DrawFormattedText(mainwin, double(num2str(ss)), 'center', 'center', white);
            Screen('Flip', mainwin);
            WaitSecs(1);
        end
        
        % count start
        Screen('DrawTexture', mainwin, im_INST(10), [], instSi, 0, [], [], [], [], [], []);  % instruction page
        Screen('Flip', mainwin);
        % trigger %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        outp(address,trigger.hrstart); % Execution to triggers EEG
        WaitSecs(0.002); % give enough time to be recoreded EEG
        outp(address,0); % reset the states EEG
        
        WaitSecs(HBC_dur(mi));
        
        %count end
        Screen('DrawTexture', mainwin, im_INST(9), [], instSi, 0, [], [], [], [], [], []);  % instruction page
        [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
        % trigger %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        outp(address,trigger.hrend); % Execution to triggers EEG
        WaitSecs(0.002); % give enough time to be recoreded EEG
        outp(address,0); % reset the states EEG
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
                    elseif keyCode(quitKey) == 1
                        save(errFilename);
                        ShowCursor; Screen('CloseAll'); return
                    end
                end
            end
            if ansenter ==1
                break;
            end
            Screen('DrawTexture', mainwin, im_INST(9), [], instSi, 0, [], [], [], [], [], []);  % instruction page
            DrawFormattedText(mainwin, double(answ), 'center', center(2)+300, red);
            
            [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
            
            WaitSecs(0.3);
        end
        % trigger %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        outp(address,trigger.hrresp); % Execution to triggers EEG
        WaitSecs(0.002); % give enough time to be recoreded EEG
        outp(address,0); % reset the states EEG
        resp(mi,1) = str2num(answ);
        WaitSecs(0.3);
        
        Screen('FillRect', mainwin, bgcolor);
        DrawFormattedText(mainwin, double(conf_txt), 'center', 'center', white);
        DrawFormattedText(mainwin, double(scale), 'center', center(2)+300, white);
        [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
        keyIsDown = 0;
        while 1
            onset = GetSecs;
            [keyIsDown, endrt, keyCode] = KbCheck;
            keyCode(KeyCode_inactive) = 0;
            if sum(keyCode) > 0
                if length(find(keyCode(respLKey) == 1)) ~=0
                    resp(mi,2) = find(keyCode) -96 ;
                    break;
                elseif keyCode(quitKey) == 1
                    save(errFilename);
                    ShowCursor; Screen('CloseAll'); return
                end
            end
        end
        WaitSecs(0.2);
        Screen('FillRect', mainwin, bgcolor);
        DrawFormattedText(mainwin, double(conf_txt), 'center', 'center', white);
        DrawFormattedText(mainwin, double(num2str(resp(mi,2))), 'center', center(2)+300, red);
        Screen('Flip', mainwin);
        % trigger %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        outp(address,trigger.hrconfans); % Execution to triggers EEG
        WaitSecs(0.002); % give enough time to be recoreded EEG
        outp(address,0); % reset the states EEG
        WaitSecs(1);
        
        
    end
    
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
        elseif keycode(quitKey) == 1
            save(errFilename);
            ShowCursor; Screen('CloseAll'); return
        end
    end
    WaitSecs(0.3);
    
    % trigger %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    outp(address,trigger.taskend); % Execution to triggers EEG
    WaitSecs(0.002); % give enough time to be recoreded EEG
    outp(address,0); % reset the states EEG
    
    save(saveFileName,'resp','sbjInfo');
    Screen('CloseAll');
    
    %
    % Screen('DrawTexture', mainwin, im_INST(2), [], instSi, 0, [], [], [], [], [], []);  % instruction page
    % [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
    %
    % keycheck = 0;
    % while keycheck == 0
    % [keyisdown,secs,keycode] = KbCheck;
    %     if keycode(KbName('space')) == 1;
    %        keycheck =1;
    %        tt = target_onset;
    %        ss = secs;
    %     end
    % end
    % WaitSecs(0.3);
    %
    %  Screen('DrawTexture', mainwin, im_INST(4), [], instSi, 0, [], [], [], [], [], []);  % instruction page
    %
    %  [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
    %  % trigger %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  outp(address,trigger.hrastart); % Execution to triggers EEG
    %  WaitSecs(0.002); % give enough time to be recoreded EEG
    %  outp(address,0); % reset the states EEG
    % WaitSecs(duration);
    %
    % Screen('DrawTexture', mainwin, im_INST(6), [], instSi, 0, [], [], [], [], [], []);  % instruction page
    % [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
    % % trigger %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  outp(address,trigger.hraend); % Execution to triggers EEG
    %  WaitSecs(0.002); % give enough time to be recoreded EEG
    %  outp(address,0); % reset the states EEG
    % keycheck = 0;
    % while keycheck == 0
    % [keyisdown,secs,keycode] = KbCheck;
    %     if keycode(KbName('space')) == 1
    %        keycheck =1;
    %        tt = target_onset;
    %        ss = secs;
    %     end
    % end
    % WaitSecs(0.3);
    %%
    ShowCursor;
    Priority(0);
catch
    save(errFilename);
    Screen('CloseAll');
    ShowCursor;
    Priority(0);
end
