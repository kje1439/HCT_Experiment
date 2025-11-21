%% Dilemma Task, PTB, EEG
% 2024-08-01 KJY

close all
clear all
clc

taskdir = 'C:\Users\user\Desktop\LSD_EEG\dilemma_EEG';
cd(taskdir);

debugging = 0; % change to 0 for real experiment
eeg = input('eeg connected? '); % change to 1 for eeg recording experiment

%% %%%%%%%%%%%%%%%%%%%% Directory %%%%%%%%%%%%%%%%%%%%
% tmpWd = 'C:\Users\KJY\Dropbox\tmpwd\dilemma_ptb';
% cd(tmpWd) 

%% %%%%%%%%%%%%%%%%%%%% EEG set up %%%%%%%%%%%%%%%%%%%%
if eeg ==1
    % initialize access to the inpoutx32 low-level I/O driver
    config_io;
    % optional step: verify that the inpoutx32 driver was successfully initialized
    global cogent;
    if( cogent.io.status ~= 0 )
       error('inp/outp installation failed');
    end
    
    % trigger coding
    trigger.taskstart = 30;
    trigger.fixation = 31;
    trigger.scenario_onset = 32;
    trigger.question_onset = 33;
    trigger.response_y = 34;
    trigger.response_n = 35;
    trigger.response_1 = 36;
    trigger.response_2 = 37;
    trigger.response_3 = 38;
    trigger.response_4 = 39;
    trigger.taskend = 59;
    
end

%% %%%%%%%%%%%%%%%%%%%% Stimuli file %%%%%%%%%%%%%%%%%%%%
scenario_fn = fullfile(pwd,'stim_scenarios_trim.xlsx');
scenario_tb = readtable(scenario_fn);

%% %%%%%%%%%%%%%%%%%%%% Collect subject data %%%%%%%%%%%%%%%%%%%%
if debugging ==0
    sbjInfo.ID = input('Subject Num: ');
    sbjInfo.name = input('Subject Name: ','s');
    sbjInfo.gender = input('Subject Gender: ','s');
    sbjInfo.age = input('Subject Age: ');
    sbjInfo.handedness = input('Handedness: ','s');
else
    sbjInfo.ID = 999;
end

%% %%%%%%%%%%%%%%%%%%%% Experiment info %%%%%%%%%%%%%%%%%%%%
exp_title = 'MD_intero';
dir_save = fullfile(pwd,exp_title,'rawdata');
if ~exist(dir_save,"dir")
    mkdir(dir_save)
end

dir_backup = fullfile(pwd, exp_title, 'backup');
if ~exist(dir_backup,"dir")
    mkdir(dir_backup)
end

if debugging == 0
    fileName = fullfile(dir_save, strcat(exp_title,sprintf('_%03d_%s',sbjInfo.ID, sbjInfo.name),'.mat'));
    fileBackup = fullfile(dir_backup, strcat(exp_title,sprintf('_%03d_%s_BU',sbjInfo.ID,sbjInfo.name),'.mat'));
end
%% %%%%%%%%%%%%%%%%%%%% Setup Psychtoolbox %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call default setup
% PTB-INFO: Multi-display setup in explicit multi-display mode detected.
% Using the following mapping: 
% PTB-INFO: Screen 0 corresponds to the full Windows desktop area. Useful for stereo presentations in stereomode=4 ...
% PTB-INFO: Screen 1 corresponds to the display area of the monitor with the Windows-internal name \\.\DISPLAY1 ...
% PTB-INFO: Screen 2 corresponds to the display area of the monitor with the Windows-internal name \\.\DISPLAY2 ...
% PTB-INFO: Screen 3 corresponds to the display area of the monitor with the Windows-internal name \\.\DISPLAY3 ...

PsychDefaultSetup(2);

%% %%%%%%%%%%%%%%%%%%%% Screen parameters %%%%%%%%%%%%%%%%%%%%

% set global parameters for sub-functions
global center black white windowRect maxWidth show_param

Screen('Preference', 'SkipSyncTests', 1); % Setting this preference to 1 suppresses the printout of warnings.
Screen('Preference', 'TextRenderer', 0) 


% set the primary screen as stimulus presenting screen
% for more info, read help RetinaDisplay
if debugging==1
    screenNum = 2;
else
    screens = Screen('Screens');
    screenNum = max(screens);
end


% define colors to use
white = WhiteIndex(screenNum);
black = BlackIndex(screenNum);


% open initial screen
if debugging == 1 % partial window for debugging
    screenW = 1200;
    screenH = 750;
    [window, windowRect] = PsychImaging('OpenWindow', screenNum, black,...
    [0 0 screenW screenH], [], [], [], [], [], kPsychGUIWindow);

    % calculate text bounds first
    txtBounds_y = TextBounds(window, double('매우 그렇다'));
    % screen offsets
    show_param.y_scenario = .25;
    show_param.w_scenario = 35;
    show_param.scale_txt = (txtBounds_y(3)-txtBounds_y(1))/2;

elseif debugging == 0 % full screen mode
    [window, windowRect] = PsychImaging('OpenWindow', screenNum, black);
    % Set priority for script execution to realtime priority:
    priorityLevel=MaxPriority(window);
    Priority(priorityLevel);

    % calculate text bounds first
    txtBounds_y = TextBounds(window, double('매우 그렇다'));

    % stimuli screen settings
    show_param.y_scenario = .2;
    show_param.w_scenario = 50;
    show_param.scale_txt = (txtBounds_y(3)-txtBounds_y(1))/2;
end

maxWidth = windowRect(3)*.9;

% calculate coordinates for necessary text segments
% center coords
center = [windowRect(3)/2, windowRect(4)/2];


% check for possible fonts
Screen( 'Textfont', window, '-:lang=kr')

%% %%%%%%%%%%%%%%%%%%%% Response keys %%%%%%%%%%%%%%%%%%%%
% Keyboard inputs
KbName('UnifyKeyNames');
[KeyIsDown, secs, KeyCode] = KbCheck; % dummy check
quitKey = KbName('q');
spaceKey = KbName('space');
respKey = [KbName('f') KbName('j')]; 
% respLKey = [KbName('1!') KbName('2@') KbName('3#') KbName('4$') KbName('5%') KbName('6^') KbName('7&') KbName('8*') KbName('9(')]; 
respLKey = [KbName('0') KbName('1') KbName('2') KbName('3') KbName('4') KbName('5') KbName('6') KbName('7') KbName('8') KbName('9')];

KeyCode_active = [respKey respLKey quitKey]';  % activate only the keys that need to be used
KeyCode_inactive = setdiff(1:length(KeyCode), KeyCode_active);  % inactivate other keys

%% %%%%%%%%%%%%%%%%%%%% Experiment %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if eeg ==1
    address = hex2dec('3FF8');% write a value to the LPT1 port EEG
end
%% Check time
currentTime = datetime('now');
txtTime = datestr(currentTime, 'yyyy-mm-dd-HHMM');

if eeg ==1
    %  EEG trigger - TTL Triggers out
    outp(address,trigger.taskstart); % Execution to triggers EEG
    WaitSecs(0.002); % give enough time to be recoreded EEG
    outp(address,0); % reset the states EEG
end

WaitSecs(2);

%% Instruction
inst_txt1 = '본 과제는 제시되는 시나리오를 읽고, 주인공의 입장이 되어 의사결정을 하는 과제입니다. \n최대한 시나리오의 내용에 집중해서 읽고, 제시되는 상황에 몰입해 질문에 응답해주세요. \n\n 시나리오가 제시되고 아래 안내문이 나오면 스페이스바를 눌러 시나리오에 대한 질문을 확인할 수 있습니다. \n \n 질문에 대해 4점 척도로 응답해주세요.';
inst_txt2 = '스페이스바를 눌러 진행해주세요.';

Screen('FillRect',window, black)
Screen('TextSize',window, 30)
DrawFormattedText(window, double(char(inst_txt1)), 'center',center(2)-200,white, show_param.w_scenario, 0, 0, 1.2);
Screen('TextSize',window, 25)
DrawFormattedText(window, double(char(inst_txt2)), 'center',center(2)+200,white, [], 0, 0, 1.2);

time.instTimeStamp = Screen('Flip', window);
time.instructionTime = datestr(datetime("now"),'yyyy-mm-dd-HHMMSS');

% Wait for space key press
keyCheck = 0;
while keyCheck ==0
    [KeyIsDown, xx, KeyCode_inst]=KbCheck;
    if KeyCode_inst(KbName('space'))==1;
        keyCheck=1;
    elseif KeyCode_inst(KbName('q'))==1;
        Screen('CloseAll');
    end
end;


%% Trials
% randomize trials
rdmOrder = randperm(height(scenario_tb));

if debugging ==1
    nTrials = 3;
else
    nTrials = height(scenario_tb);
    %nTrials = 2;
end

% initialize timeStamp
timeStamp = zeros(4,1);
respData = {};

time.trialStartTime = datestr(datetime('now'),'yyyy-mm-dd-HHMMSS');

HideCursor;

for tN = 1: nTrials
    tScenario = scenario_tb(rdmOrder(tN),:);  
    txtScenario = tScenario.scenario{:};
    txtQuestion = tScenario.question{:};

    %% Fixation
    Screen('FillRect',window, black);
    Screen('DrawText', window, '+', center(1), center(2), white);
    timeStamp(tN, 1) = Screen('Flip', window);

    if eeg ==1
        %  EEG trigger - TTL Triggers out
        outp(address,trigger.fixation); % Execution to triggers EEG
        WaitSecs(0.002); % give enough time to be recoreded EEG
        outp(address,0); % reset the states EEG
    end 
    WaitSecs(2); 

 
    %% Show cenario
    Screen('FillRect',window,black);
    Screen('TextSize',window, 30);
    DrawFormattedText(window, double(txtScenario), 'center',...
        center(2)-show_param.y_scenario*windowRect(3),white, show_param.w_scenario, 0, 0, 1.4);
    if eeg ==1
        % EEG trigger - TTL Triggers out
        outp(address,trigger.scenario_onset); % Execution to triggers EEG
        WaitSecs(0.002); % give enough time to be recoreded EEG
        outp(address,0); % reset the states EEG
    end
    timeStamp(tN, 2) = Screen('Flip',window);

    WaitSecs(5);

    Screen('FillRect',window,black);
    Screen('TextSize',window, 30);
    DrawFormattedText(window, double(txtScenario), 'center',...
        center(2)-show_param.y_scenario*windowRect(3),white, show_param.w_scenario, 0, 0, 1.4);
    Screen('TextSize',window, 25)
    DrawFormattedText(window, double(char(inst_txt2)), 'center',center(2)+300,white, [], 0, 0, 1.2);
    Screen('Flip',window)
    
    keyCheck =0;
    while keyCheck==0
        [KeyIsDown_q, xx, KeyCode_qst]=KbCheck;
        if KeyCode_qst(KbName('space'))==1;
            keyCheck=1;
        elseif KeyCode_qst(KbName('q'))==1;
            Screen('CloseAll');
        end
    end
    WaitSecs(1);

    %% Questions 

    drawQuestionScreen(window, txtScenario, txtQuestion, 0);

    if eeg ==1
        % EEG trigger - TTL Triggers out
        outp(address,trigger.question_onset); % Execution to triggers EEG
        WaitSecs(0.002); % give enough time to be recoreded EEG
        outp(address,0); % reset the states EEG
    end
    timeStamp(tN, 4) = Screen('Flip',window);

    %%

    % Get response
    while 1
        [KeyIsDown_r, secs, keyCode_resp] = KbCheck;
        keyCode_resp(KeyCode_inactive) = 0;

        if sum(keyCode_resp) > 0
            if keyCode_resp(respLKey(1))==1
                % record trigger
                if eeg ==1
                    outp(address,trigger.response_1)
                    WaitSecs(.002);
                    outp(address,0)
                end

                drawQuestionScreen(window, txtScenario, txtQuestion, 1);
                timeStamp(tN, 5) = Screen('Flip',window);
                WaitSecs(1);

            elseif keyCode_resp(respLKey(2))==1
                % record trigger
                if eeg==1
                    outp(address,trigger.response_2)
                    WaitSecs(.002);
                    outp(address,0)
                end

                drawQuestionScreen(window, txtScenario, txtQuestion, 2);
                timeStamp(tN, 5) = Screen('Flip',window);
                WaitSecs(1);

            elseif keyCode_resp(respLKey(3))==1

                % record trigger
                if eeg==1
                    outp(address,trigger.response_3)
                    WaitSecs(.002);
                    outp(address,0)
                end
                drawQuestionScreen(window, txtScenario, txtQuestion, 3);
                timeStamp(tN, 5) = Screen('Flip',window);
                WaitSecs(1);

            elseif keyCode_resp(respLKey(4))==1

                % record trigger
                if eeg==1
                    outp(address,trigger.response_4)
                    WaitSecs(.002);
                    outp(address,0)
                end
                drawQuestionScreen(window, txtScenario, txtQuestion, 4);
                timeStamp(tN, 5) = Screen('Flip',window);
                WaitSecs(1);

            end

            break;
        elseif keyCode_resp(KbName('q')) == 1
            save(fileBackup);
            Screen('CloseAll');
        end

    end
    WaitSecs(.3)
         
    respData{tN,1} = KbName(find(keyCode_resp));

end
%%
time.expEndTime = datestr(datetime('now'),'yyyy-mm-dd-HHMMSS');
%% %%%%%%%%%%%%%%%%%%%% Save data %%%%%%%%%%%%%%%%%%%%
if (debugging == 0 & eeg == 1)
    save(fileName, "time","respData",'sbjInfo','rdmOrder','timeStamp','trigger');
    save(fileBackup);
elseif debugging == 0 & eeg == 0
    save(fileName, "time","respData",'sbjInfo','rdmOrder','timeStamp');
    save(fileBackup);
end
%% %%%%%%%%%%%%%%%%%%%% Thanks & Bye %%%%%%%%%%%%%%%%%%%%
Screen('FillRect',window, black)
Screen('TextSize',window, 30)
txt = '과제가 모두 끝났습니다. \n\n자리에 앉아 기다려주세요. \n\n\n감사합니다.';
DrawFormattedText(window, double(txt), 'center', 'center', white);
Screen('Flip', window)

% Wait for key press
[KeyIsDown, xx, KeyCode_bye]=KbCheck;
while KeyCode_bye(spaceKey) ~= 1
    [KeyIsDown, xx, KeyCode_bye]=KbCheck;
end

if eeg ==1
    %  EEG trigger - TTL Triggers out
    outp(address,trigger.taskend); % Execution to triggers EEG
    WaitSecs(0.002); % give enough time to be recoreded EEG
    outp(address,0); % reset the states EEG
end


% Cleanup at end of experiment - Close window, show mouse cursor, close
% result file, switch Matlab/Octave back to priority 0 -- normal
% priority:
Screen('CloseAll');
ShowCursor;
Priority(0);

%% sub functions

function window = drawQuestionScreen(window, txtScenario, txtQuestion, response)
    
    global windowRect center black white maxWidth show_param 
    
    % do not color the response key! to prevent observation effect
    response = 0;

    % keep the scenario
    Screen('FillRect',window, black)
    Screen('TextSize',window, 30);
    DrawFormattedText(window, double(txtScenario), 'center',...
        center(2)-show_param.y_scenario*windowRect(3),white, show_param.w_scenario, 0, 0, 1.4);

    % add question
    DrawFormattedText(window, double(txtQuestion), 'center',...
        center(2)+0.2*windowRect(4), white, [], 0, 0, 1.2);

    % choose font color based on response for numbers
    switch response
        case 0
            crtColor = {[1 1 1 ]; [1 1 1]; [1 1 1]; [1 1 1]};
        case 1
            crtColor = {[1 0 0 ]; [1 1 1]; [1 1 1]; [1 1 1]};
        case 2
            crtColor = {[1 1 1 ]; [1 0 0]; [1 1 1]; [1 1 1]};
        case 3
            crtColor = {[1 1 1 ]; [1 1 1]; [1 0 0]; [1 1 1]};
        case 4
            crtColor = {[1 1 1 ]; [1 1 1]; [1 1 1]; [1 0 0]};
    end

    % draw scale bar
    
    Screen('TextSize',window, 35)
    Screen('DrawText', window, double('매우 아니다'), center(1)-maxWidth/2+show_param.scale_txt, ...
        center(2)+.3*windowRect(4), white);
    Screen('DrawText', window, double('매우 그렇다'), center(1)+maxWidth/2-show_param.scale_txt*3, ...
        center(2)+.3*windowRect(4), white);

    Screen('DrawText', window, double('1'), center(1)-maxWidth/2, ...
        center(2)+.4*windowRect(4), [crtColor{1}]);
    Screen('DrawText', window, double('2'), center(1)-maxWidth/6, ...
        center(2)+.4*windowRect(4), [crtColor{2}]);
    Screen('DrawText', window, double('3'), center(1)+maxWidth/6, ...
        center(2)+.4*windowRect(4), [crtColor{3}]);
    Screen('DrawText', window, double('4'), center(1)+maxWidth/2, ...
        center(2)+.4*windowRect(4), [crtColor{4}]);


end
