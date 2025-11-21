function task_HCT_2
% Heartbeat Counting Task (R2018b) — ECG는 별도 Python이 연속 기록, 이벤트는 CSV에 함께 기록
clc; close all;

%% ---- 설정 ----
taskdir = 'C:\Users\bspl\Downloads\task_files\task_files\HCT_pre';
cd(taskdir);

HBC_dur     = [40, 45, 25, 30, 50, 35];
% HBC_dur = [1, 2];
HBC_dur = HBC_dur(randperm(length(HBC_dur)));
practiceDur = 10;

forceCircles         = true;   % 이미지 대신 원 사용
showFeedbackPerTrial = false;  % 실시간 계산/피드백 OFF0111

conf_txt = '이번 박동 수 추정에 대한 확신 정도는 어느 정도인가요?';
scale_txt = '0 1 2 3 4 5 6 7 8 9';
prend_txt = '연습이 끝났습니다.';
mnend_txt = sprintf('모든 과제가 끝났습니다.\n\n담당자에게 알려주세요.');

datDir = 'Data';      if ~exist(datDir,'dir'), mkdir(datDir); end
tmpDir = 'Data_tmp';  if ~exist(tmpDir,'dir'), mkdir(tmpDir); end

sbjInfo.ID   = input('Subject ID ? ');
sbjInfo.Name = input('Subject Name ? ','s');
fileName     = sprintf('sbj_%02d_%s', sbjInfo.ID, sbjInfo.Name);
saveFileName = fullfile(datDir, [fileName '.mat']);
csvECG       = fullfile(datDir, [fileName '_ecgstream.csv']);

prac    = input('practice ? (1 yes) ');
realecg = input('ecg connected ? (1 yes) ');

%% ---- Movesense / Python ----
useMovesense = (realecg==1);
pythonExe    = 'python';     % Windows면 'py -3' 권장
ms_py        = fullfile(taskdir,'movesense_ecg_capture.py');
ms_fs        = 200;
ms_nameFilter= 'Movesense';
ms_adapter   = '';           % Linux면 'hci0' 권장
ms_mac       = '';
udp_port     = 8765;

%% ---- UI ----
bg=[0 0 0]; fg=[1 1 1]; red=[1 0 0];
fig = figure('Name','HCT','NumberTitle','off','Color',bg,'MenuBar','none','ToolBar','none',...
             'Units','normalized','OuterPosition',[0 0 1 1],'Resize','off');
ax = axes('Parent',fig,'Position',[0 0 1 1]); axis(ax,'off');
set(fig,'KeyPressFcn',[]);
fontName = 'Malgun Gothic';

% (선택) 안내 이미지
list_inst = dir(fullfile('img','*.jpg'));
nINST = numel(list_inst);
im_INST = cell(nINST,1);
for i=1:nINST, im_INST{i}=imread(fullfile(list_inst(i).folder, list_inst(i).name)); end

%% ---- Movesense 스캔 / 선택 / 캡처 시작 ----
udpObj = [];
if useMovesense
    try
        devs = scanMovesense(ms_py, pythonExe, 8, ms_nameFilter, ms_adapter);
        if isempty(devs)
            choice = questdlg('Movesense를 찾지 못했습니다.','스캔','다시 스캔','MAC 직접입력','ECG없이 진행','다시 스캔');
            switch choice
                case '다시 스캔'
                    devs = scanMovesense(ms_py, pythonExe, 8, ms_nameFilter, ms_adapter);
                case 'MAC 직접입력'
                    s = inputdlg('MAC/UUID를 입력하세요:','Movesense 주소',[1 52]);
                    if isempty(s), useMovesense=false; else, ms_mac = s{1}; end
                otherwise
                    useMovesense=false;
                    close all force;
                    sca;
                    error('Movesense를 찾지 못했거나 선택하지 않았습니다. 실험을 중단합니다.');
            end
        end
        if isempty(devs) && isempty(ms_mac)
            close all force;
            sca;
            error('Movesense 장치가 감지되지 않았습니다. 실험을 중단합니다.');
        end
        if useMovesense && isempty(ms_mac)
            listStr = arrayfun(@(d) sprintf('%s   (%s)   RSSI %d',d.name,d.address,d.rssi), devs,'UniformOutput',false);
            [idx, ok] = listdlg('PromptString','연결할 Movesense를 선택하세요:', ...
                                'SelectionMode','single','ListString',listStr,'ListSize',[520 340]);
            refocusFig();
            if ~ok, useMovesense=false; else, ms_mac = devs(idx).address; end
        end
    catch ME
        close all force;
        sca;
        error('스캔 실패: %s', ME.message);
        useMovesense=false;
    end

    if useMovesense
        startMovesenseCapture(ms_py, pythonExe, ms_mac, ms_fs, csvECG, ms_adapter, udp_port);
        udpObj = makeUDPSender('127.0.0.1', udp_port); % R2018b 호환(udp or Java)
        sendEvent(udpObj, 'SESSION_START');
        refocusFig();
    end
end

%% ---- 실험 진행 (ECG와 독립) ----
try
    % 안내
    for inst=1:min(4, nINST)
        showImage(im_INST{inst}); waitSpaceOrQuit(); pause(0.3);
    end

    % 연습
    if prac==1
        if nINST>=5 && ~forceCircles, showImage(im_INST{5}); else, showTextCentered('연습을 시작합니다. (Space)', fg, 0, 36); end
        waitSpaceOrQuit(); pause(0.3);

        tmp_resp = nan(2,2);
        for pi=1:2
            if nINST>=6 && ~forceCircles, showImage(im_INST{6}); else, showTextCentered('준비', fg, 0, 40); end
            pause(2); countdown(3);

            if nINST>=7 && ~forceCircles, showImage(im_INST{7}); else, showCircle('green'); end
            if useMovesense, sendEvent(udpObj, sprintf('COUNT_START|trial=P%d',pi)); end
            pause(practiceDur);
            if useMovesense, sendEvent(udpObj, sprintf('COUNT_END|trial=P%d',pi)); end

            baseImg=[]; useRedCircle=true;
            if nINST>=8 && ~forceCircles, baseImg=im_INST{8}; useRedCircle=false; end
            answ = numericEntryOverlay(baseImg, useRedCircle);
            tmp_resp(pi,1) = str2double(answ);
            if useMovesense, sendEvent(udpObj, sprintf('REPORTED_HB|trial=P%d|value=%s',pi,answ)); end

            c = digit0to9Prompt(conf_txt, scale_txt);
            tmp_resp(pi,2) = c;
            if useMovesense, sendEvent(udpObj, sprintf('CONFIDENCE|trial=P%d|value=%d',pi,c)); end
        end
        showTextCentered(prend_txt, fg, 0, 30); waitSpaceOrQuit(); pause(0.3);
    end

    % 메인
    if nINST>=9 && ~forceCircles, showImage(im_INST{9}); else, showTextCentered('메인 과제를 시작합니다. (Space)', fg, 0, 36); end
    waitSpaceOrQuit(); pause(0.3);

    N = numel(HBC_dur);
    resp = nan(N,2);
    for mi=1:N
        if nINST>=6 && ~forceCircles, showImage(im_INST{6}); else, showTextCentered('준비', fg, 0, 40); end
        pause(2); countdown(3);

        if nINST>=7 && ~forceCircles, showImage(im_INST{7}); else, showCircle('green'); end
        if useMovesense, sendEvent(udpObj, sprintf('COUNT_START|trial=%d',mi)); end
        pause(HBC_dur(mi));
        if useMovesense, sendEvent(udpObj, sprintf('COUNT_END|trial=%d',mi)); end

        baseImg=[]; useRedCircle=true;
        if nINST>=8 && ~forceCircles, baseImg=im_INST{8}; useRedCircle=false; end
        answ = numericEntryOverlay(baseImg, useRedCircle);
        resp(mi,1) = str2double(answ);
        if useMovesense, sendEvent(udpObj, sprintf('REPORTED_HB|trial=%d|value=%s',mi,answ)); end

        c = digit0to9Prompt(conf_txt, scale_txt);
        resp(mi,2) = c;
        if useMovesense, sendEvent(udpObj, sprintf('CONFIDENCE|trial=%d|value=%d',mi,c)); end
    end

    showTextCentered(mnend_txt, fg, 0, 30); waitSpaceOrQuit(); pause(0.3);

    save(saveFileName,'resp','sbjInfo');

    if useMovesense
        sendEvent(udpObj, 'SESSION_END');
        pause(0.2);
        sendEvent(udpObj, 'STOP');   % 파이썬 종료
        pause(0.5);
        udpObj.close();
    end

    if isvalid(fig), close(fig); end

catch ME
    if useMovesense && ~isempty(udpObj)
        try, sendEvent(udpObj, 'STOP'); udpObj.close(); catch, end
    end
    try, save(fullfile(tmpDir,[fileName '_err.mat']),'ME'); catch, end
    if exist('fig','var') && isvalid(fig), close(fig); end
    rethrow(ME);
end

%% ----------------- 헬퍼 (R2018b 호환) -----------------
    function setupAxes(doClear)
        if nargin<1, doClear=true; end              % 기본은 clear
        if ~ishandle(fig), error('메인 창이 닫혔습니다.'); end
        if ~ishandle(ax) || ~strcmp(get(ax,'Type'),'axes')
            ax = axes('Parent',fig);
        end
        set(ax,'Units','normalized','Position',[0.06 0.06 0.88 0.88]); % 여백
        set(ax,'XLim',[0 1],'YLim',[0 1],'XTick',[],'YTick',[],'Visible','off');
        set(ax,'DataAspectRatio',[1 1 1],'PlotBoxAspectRatio',[1 1 1],'Clipping','off');
        if doClear, cla(ax); end
    end

    function showImage(img)
        setupAxes();
        axes(ax); cla(ax); image(ax,img); axis(ax,'image'); axis(ax,'off'); drawnow;
    end
    function showTextCentered(txt,color,~,fs)
        if nargin<2, color=fg; end
        if nargin<4, fs=28; end
        setupAxes();
        axes(ax); cla(ax); xlim([0 1]); ylim([0 1]); axis(ax,'off'); axis(ax,'equal');
        text(0.5,0.5,txt,'Units','normalized','HorizontalAlignment','center','VerticalAlignment','middle',...
            'Color',color,'FontSize',fs,'FontName',fontName); drawnow;
    end
    function showCircle(which)
        % which: 'green' | 'red' | 'gray'
        setupAxes();
        axes(ax); cla(ax);
        xlim([0 1]); ylim([0 1]); axis(ax,'off');
        r = 0.22; % radius (normalized)
        pos = [0.5-r 0.5-r 2*r 2*r];
        switch lower(which)
            case 'green', fc = [0 0.8 0];
            case 'red',   fc = [0.9 0 0];
            otherwise,    fc = [0.5 0.5 0.5];
        end
        rectangle('Position',pos, 'Curvature',[1 1], 'FaceColor',fc, 'EdgeColor','none');
        drawnow;
    end
    function waitSpaceOrQuit()
        while true
            waitforbuttonpress; ch=get(fig,'CurrentCharacter');
            if isempty(ch), continue; end
            if ch=='q', error('User quit'); end
            if ch==' ', break; end
        end
    end
    function countdown(n)
        for k=n:-1:1, showTextCentered(num2str(k), fg, 0, 80); pause(1); end
    end
    function s = numericEntryOverlay(baseImg, useRedCircle)
    % 빨강 원/이미지 위에 숫자 입력. Space로 확정, Backspace로 지움, q로 중단.
    setupAxes();
    if useRedCircle, showCircle('red');
    elseif ~isempty(baseImg), showImage(baseImg);
    else, showTextCentered('',[1 1 1]);
    end
    hold(ax,'on');
    tEcho = text(ax,0.5,0.18,'','Units','normalized','HorizontalAlignment','center',...
        'VerticalAlignment','middle','Color',[1 0 0],'FontSize',32,'FontName',fontName);
    hold(ax,'off'); drawnow;

    s = ''; done=false;
    refocusFig();
    set(fig,'WindowKeyPressFcn',@onKey);  % ★ 콜백 설치
    uiwait(fig);                          % 키 입력으로 uiresume 될 때까지 대기
    set(fig,'WindowKeyPressFcn',[]);      % 콜백 해제

    if getappdata(fig,'aborted'), error('사용자 중단'); end

    function onKey(~,evt)
        ch  = evt.Character;
        key = evt.Key;             % ← 추가: 키 이름 (e.g., '1','numpad1','space')

        % 종료
        if strcmp(key,'escape') || isequal(ch,'q')
            setappdata(fig,'aborted',true); uiresume(fig); return;
        end

        % 확정
        if strcmp(key,'space') || isequal(ch,' ')
            if ~isempty(s)  % numericEntryOverlay
                uiresume(fig); 
            end
            return;
        end

        % 백스페이스
        if strcmp(key,'backspace') || isequal(ch,char(8))
            if ~isempty(s)         % numericEntryOverlay
                s(end) = []; set(tEcho,'String',s); drawnow;
            end
            return;
        end

        % 숫자 처리 (IME/숫자패드 포함)
        isDigitChar = ~isempty(ch) && ch>='0' && ch<='9';
        numpadMap = {'numpad0','0';'numpad1','1';'numpad2','2';'numpad3','3';'numpad4','4'; ...
                     'numpad5','5';'numpad6','6';'numpad7','7';'numpad8','8';'numpad9','9'};
        isDigitKey  = any(strcmp(key, numpadMap(:,1))) || any(strcmp(key, numpadMap(:,2)));

        if isDigitChar || isDigitKey
            if isDigitChar
                dchar = ch;
            else
                % key가 'numpadX'거나 'X'일 수 있음
                idx = find(strcmp(key, numpadMap(:,1)));
                if ~isempty(idx), dchar = numpadMap{idx,2}; else, dchar = key; end
            end
            % numericEntryOverlay:
            if exist('s','var')
                s = [s dchar]; set(tEcho,'String',s); drawnow;
            else
            % digit0to9Prompt:
                d = str2double(dchar);
                set(tEcho,'String',dchar); drawnow; pause(0.2); uiresume(fig);
            end
        end
    end
    end

    function d = digit0to9Prompt(question, scaleLine)
        % 0~9 중 하나 입력하면 즉시 확정
        setupAxes();
        text(0.5,0.55,question,'Units','normalized','HorizontalAlignment','center','VerticalAlignment','middle',...
             'Color',[1 1 1],'FontSize',28,'FontName',fontName);
        text(0.5,0.25,scaleLine,'Units','normalized','HorizontalAlignment','center','VerticalAlignment','middle',...
             'Color',[1 1 1],'FontSize',24,'FontName',fontName);
        tEcho = text(ax,0.5,0.18,'','Units','normalized','HorizontalAlignment','center','VerticalAlignment','middle',...
             'Color',[1 0 0],'FontSize',32,'FontName',fontName);
        drawnow;

        d = NaN;
        refocusFig();
        set(fig,'WindowKeyPressFcn',@onKey);  % ★
        uiwait(fig);
        set(fig,'WindowKeyPressFcn',[]);

        if getappdata(fig,'aborted'), error('사용자 중단'); end

        function onKey(~,evt)
            ch = evt.Character;
            if isempty(ch), return; end
            if ch=='q'
                setappdata(fig,'aborted',true); uiresume(fig);
            elseif ch>='0' && ch<='9'
                d = double(ch)-double('0');
                set(tEcho,'String',num2str(d)); drawnow;
                pause(0.2);
                uiresume(fig);
            end
        end
    end


    % ---- Python 연동 ----
    function devs = scanMovesense(ms_py, pythonExe, timeoutSec, nameFilter, adapter)
        if nargin<3||isempty(timeoutSec), timeoutSec=6; end
        if nargin<4, nameFilter=''; end
        if nargin<5, adapter=''; end
        nameArg=''; if ~isempty(nameFilter), nameArg=sprintf(' --name "%s"',nameFilter); end
        adArg='';   if ~isempty(adapter),   adArg=sprintf(' --adapter %s',adapter); end
        % PowerShell로 실행 (Windows)
        if ispc
            cmd = sprintf('powershell -Command "%s \\"%s\\" --scan --timeout %d%s%s 2>&1"', ...
                pythonExe, ms_py, timeoutSec, nameArg, adArg);
        else
            cmd = sprintf('"%s" "%s" --scan --timeout %d%s%s 2>&1', ...
                pythonExe, ms_py, timeoutSec, nameArg, adArg);
        end
        disp(cmd)
        cmd = sprintf('"%s" "%s" --scan --timeout %d%s%s 2>&1', pythonExe, ms_py, timeoutSec, nameArg, adArg);
        [status,out] = system(cmd);
        if status~=0, disp("❌ Movesense 연결 실패:"); disp(out); error('스캔 실패(status=%d)\n%s',status,out); end
        s = strfind(out,'['); e = strfind(out,']'); if isempty(s)||isempty(e), error('스캔 JSON 파싱 실패:\n%s',out); end
        devs = jsondecode(out(s(1):e(end)));
    end

    function startMovesenseCapture(ms_py, pythonExe, mac, fs, csvPath, adapter, udpPort)
        mvFlag = '--mv';
        adArg = ''; if ~isempty(adapter), adArg = sprintf('--adapter %s', adapter); end

        % CSV 폴더 존재 확인
        [csvDir,~,~] = fileparts(csvPath);
        if ~isempty(csvDir) && ~exist(csvDir, 'dir')
            mkdir(csvDir);
            fprintf('폴더 생성: %s\n', csvDir);
        end

        % 인자 문자열 조합
        argsCell = {ms_py};
        if ~isempty(mac)
            argsCell{end+1} = '--address';
            argsCell{end+1} = mac;
        end
        argsCell{end+1} = '--samplerate';
        argsCell{end+1} = num2str(fs);
        if ~isempty(mvFlag)
            argsCell{end+1} = mvFlag;
        end
        argsCell{end+1} = '--csv';
        argsCell{end+1} = csvPath;
        argsCell{end+1} = '--udp';
        argsCell{end+1} = num2str(udpPort);
        if ~isempty(adArg)
            argsCell{end+1} = adArg;
        end

        % 인자를 공백으로 이어 붙임
        pyCmd = strjoin(argsCell, ' ');

        % Windows / Linux 구분 없이 system으로 실행
%         if ispc
%             cmd = sprintf('"%s" %s', pythonExe, pyCmd);
%         else
%             cmd = sprintf('%s %s', pythonExe, pyCmd);
%         end
        if ispc
            cmd = sprintf('start "" python "%s" --address %s --samplerate %d --mv --csv "%s" --udp %d', ...
                ms_py, ms_mac, ms_fs, csvECG, udp_port);
%             cmd = sprintf('"%s" "%s" --address %s --samplerate %d --mv --csv "%s" --udp %d', ...
%                 'C:\Path\To\pythonw.exe', ms_py, ms_mac, ms_fs, csvECG, udp_port);
        else
            cmd = sprintf('nohup python3 "%s" --address %s --samplerate %d --mv --csv "%s" --udp %d &', ...
                ms_py, ms_mac, ms_fs, csvECG, udp_port);
        end
%         system(cmd);

        disp(['실행 명령: ', cmd]);  % 디버깅용

        % system 호출
        [status, out] = system(cmd);
        if status ~= 0
            error('Movesense 캡처 시작 실패(status=%d)\n%s', status, out);
        end
    end




    % ---- R2018b 호환 UDP 송신 (udp 함수 또는 Java) ----
    function h = makeUDPSender(host, port)
        % Instrument Control Toolbox가 있으면 udp(), 없으면 Java DatagramSocket 사용
        if exist('udp','file')==2
            u = udp(host, port); %#ok<UDP>
            fopen(u);
            h.send  = @(txt) fwrite(u, uint8(txt));
            h.close = @() closeUdp(u);
        else
            if ~usejava('jvm'), error('UDP 전송 불가: JVM/Toolbox 없음'); end
            import java.net.DatagramSocket
            import java.net.DatagramPacket
            import java.net.InetAddress
            ds = DatagramSocket();
            ia = InetAddress.getByName(host);
            h.send  = @(txt) localJavaSend(ds, ia, port, uint8(txt));
            h.close = @() ds.close();
        end
    end
    function localJavaSend(ds, ia, port, bytes)
        pkt = java.net.DatagramPacket(bytes, numel(bytes), ia, port);
        ds.send(pkt);
    end
    function sendEvent(udpObj, text)
        if isempty(udpObj), return; end
        udpObj.send(text);
    end
    function closeUdp(u)
        try
            if strcmp(get(u,'Status'),'open'), fclose(u); end
            delete(u);
        catch
            % 무시
        end
    end
    function refocusFig()
        if ~ishandle(fig), return; end
        figure(fig);        % MATLAB 현재 Figure로 올리기
        drawnow; pause(0.02);
        % R2018b에서는 JavaFrame 사용 가능(비공식)
        try
            jf = get(handle(fig),'JavaFrame');
            jf.fHG1Client.requestFocus();
        catch
            % macOS/Linux 등에서 JavaFrame 접근이 막혀도 무시
        end
    end
end
