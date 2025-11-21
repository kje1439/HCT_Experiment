clear all
close all
clc
try
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
    gray_fix = [155 155 155];
    white    = [255 255 255];
    black = [0 0 0];
    red = [255 0 0];
    bgcolor = black;
    rect = [0 0 1920 1080];
    xc = rect(3)/2;
    yc = rect(4)/2;
    [img_full_cx, img_full_cy] = RectCenter([0 0 rect(3) rect(4)]); %full screen
    [img_full_loc] = CenterRectOnPoint([0 0 1024 576], img_full_cx, img_full_cy);
    
    key_space = KbName('space');
    key_quit = KbName('q');
    ScreenDis = (2.54/96)*1920; %cm
    ScreenHeight = (2.54/96)*1080; %cm
    ppd=pi/180 * ScreenDis/ScreenHeight * rect(4);
    
    
    %% Gabor patch
    % % ST_med = 37;
    % % CP_med = 97;
    
    stim.diameter = 3.5*ppd;          %% the same with the size of grating image matrix
    % stim.diameter = 5*ppd;          %% 5 degree visaul angle/ = 3 degree of only gabor
    stim.eccentricity = 1*ppd;    %% 3 degree fix to center of the stim
    
    LT_xc = xc - stim.eccentricity;
    RT_xc = xc + stim.eccentricity;
    t1 = 0;
    stimRect = [0 0 stim.diameter stim.diameter];
    beep=sin(2*pi*0.02*[0:800]);
    
    Stim_duration = 0.5;
    
    %% Stimulus parameter
    % imgSize = [5 5]; % in visual degree, [width height]
    % imgSz = round(imgSize*ppd);
    x = rect(3)*1/2 ;
    y = rect(4)*1/2 ;
    
    
    %% Gabor_achromatic
    % contrast range in logspace
    cond_level = 30;
    
    contRange = [0.2 0.7];   % the lowest and highest contrast
    contLevel= logspace(log10(contRange(1)), ...
        log10(contRange(2)), cond_level-1);
    contLevel(1,cond_level) = 0.7;
    
    for i = 1 : cond_level
        c = contLevel(i) ;     % contrast of the Gabor
        f = 1/29;            % spatial frequency in 1/pixels (= 1 cpd)
        t = pi/180;          % tilt of 0 degrees into radians (=vertical)
        s = 20; %24;              % standard deviation of the spatial
        % window of the Gabor
        g_size = 112;        % calculated to be 3 degrees  % It used to be 256.
        [x,  y] = meshgrid(-(g_size*1/2):(g_size*1/2-1), (g_size*1/2):-1:-(g_size*1/2-1));
        M2 = uint8(127*(1+ c*sin(2.0*pi*f*(y*sin(t) + x*cos(t))) ...
            .*exp(-(x.^2 + y.^2)/2/s^2)));
        
        after_Img{i,1} = M2;
    end
    seq = [1:30 29:-1:1 2:30];
    
    buttonpress = [];
    
    for i = 1:length(seq)
        Screen('FillRect', mainwin, gray_fix);
        
        tex1 = Screen('MakeTexture', mainwin, after_Img{seq(i),1});               % left side
        Screen('DrawTexture', mainwin, tex1, [], CenterRectOnPoint(stimRect, LT_xc, yc),t1);
        [VBLTimestamp, target_onset] = Screen('Flip', mainwin);
        startTime = GetSecs;
        stopTime = startTime + 1;
        keyIsDown = 0;
        while GetSecs < stopTime
            [keyIsDown, endrt, keyCode] = KbCheck;
%             keyCode(KeyCode_inactive) = 0;
            if sum(keyCode) > 0
                if length(find(keyCode(key_space) == 1)) ~=0
                    rt = 1000.*(endrt-target_onset);
                    buttonpress(i,1) = 1;
                    WaitSecs(1-rt);
                    break;
                elseif keyCode(key_quit) == 1
                    ShowCursor; Screen('CloseAll'); return
                end
            end
        end
    end
    Screen('CloseAll');
catch
    Screen('CloseAll');
    error('something is wrong');
end
