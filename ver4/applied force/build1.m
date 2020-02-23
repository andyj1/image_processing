function varargout = build1(varargin)
% heart rates:
% (1) take initial grand HR
% (2) take final grand HR
% take average --> take the trend that gives its average closer to this average

% Last Modified by GUIDE v2.5 08-Feb-2020 18:35:38
%% Initialization of GUI main function from figure
% --- Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @build1_OpeningFcn, ...
                   'gui_OutputFcn',  @build1_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% --- End initialization code - DO NOT EDIT

% --- Executes just before build1 is made visible.
function build1_OpeningFcn(hObject, eventdata, handles, varargin)
%% Setup handler and GUI Objects
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to build1 (see VARARGIN)

% set how many frames to skip every iteration to speed up
global frame_speedup
frame_speedup = 0; % change this to nonzero value; otherwise, set to 30;

global checkedROI1
global checkedROI2
global checkedROI3
checkedROI1 = 1;
checkedROI2 = 0;
checkedROI3 = 0;

% set default to 1
set(handles.rep_count, 'String', 10);

% Choose default command line output for build1
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% initial path (current working directory)
set(handles.outputpath, 'String', pwd);
set(handles.count, 'String', '-');
set(handles.status_curr1, 'String', '-');
set(handles.status_curr2, 'String', '-');
set(handles.status_curr3, 'String', '-');
set(handles.heartrate1, 'String', '-');
set(handles.heartrate2, 'String', '-');
set(handles.currenttime, 'String', '-');
set(handles.mainvideo,'xtick',[]);
set(handles.mainvideo,'ytick',[]);
% --- Outputs from this function are returned to the command line.
function varargout = build1_OutputFcn(hObject, eventdata, handles)
%% Setup output path to command line
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% for ROI 1
function setGlobalDetected1(val)
%% Setup global variable for 'detected1'
global detected1
detected1 = val; 

function r = getGlobalDetected1
%% Getter function for 'detected1'
global detected1
r = detected1;

% for ROI 2
function setGlobalDetected2(val)
%% Setup global variable for 'detected2'
global detected2
detected2 = val; 

function r = getGlobalDetected2
%% Getter function for 'detected2'
global detected2
r = detected2;

% for ROI 3
function setGlobalDetected3(val)
%% Setup global variable for 'detected3'
global detected3
detected3 = val; 

function r = getGlobalDetected3
%% Getter function for 'detected3'
global detected3
r = detected3;

% --- Executes on button press in mistake.
function mistake_Callback(hObject, eventdata, handles)
%% Button for resetting the start button
% hObject    handle to mistake (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% clear outputs
set(handles.status_curr1, 'String', '-');
set(handles.status_curr2, 'String', '-');
set(handles.status_curr3, 'String', '-');
set(handles.count, 'String', '-');
set(handles.currenttime, 'String', '-');
set(handles.heartrate1, 'String', '-');
set(handles.heartrate2, 'String', '-');
set(handles.roi1, 'Value', 0);
set(handles.roi2, 'Value', 0);
set(handles.roi3, 'Value', 0);
loadbutton_Callback(hObject, eventdata, handles);
% --- Executes on button press in outputbutton.
function outputbutton_Callback(hObject, eventdata, handles)
% hObject    handle to outputbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global pathname
pathname = pwd;
global selpath
% select output path
selpath = uigetdir(pathname);
% update output path
set(handles.outputpath, 'String', selpath);

% --- Executes on button press in loadbutton.
function loadbutton_Callback(hObject, eventdata, handles)
%% Start reading videos upon loading
format short;
% hObject    handle to loadbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% uninitialized global variables
global startTime
global initialTimeSeconds
global time_hr
global time_min
global time_sec
global rep_count
global frame_speedup
global status

global orig
orig = [];

global detected1
global detected2
global detected3

% reset the detected states
setGlobalDetected1(0);
setGlobalDetected2(0);
setGlobalDetected3(0);

% thresholds for device 1
HR1_thresh1 = 50;
HR1_thresh2 = 140;

% thresholds for device 2
HR2_thresh1 = 50;
HR2_thresh2 = 140;

% load video from a chosen directory path
global pathname     % path to the loaded video
[filename, pathname] = uigetfile({'*.mp4';'*.avi'}, 'File Selector');

% check if filename is chosen properly
% else exit
if ~ischar(filename)
    return;
end

% load file
filepath = fullfile(pathname, filename);

% check if filepath is valid
if ~exist(filepath, 'file')
    errorMessage = sprintf('Error: %s does not exist.', filepath);
    uiwait(warndlg(errorMessage));
    return
end

% set the filepath as the object's videopath
% and add the chosen path to the program path
set(handles.videopath, 'String', filepath);
addpath(genpath(pathname));

% load video object
try
    obj = VideoReader(filename);
catch
    errorMessage = sprintf('Error: %s does not exist.', filepath);
    uiwait(warndlg(errorMessage));
    return
end

h = msgbox('Please wait whlie loading...');
% obtain the first frame and display to check to use as reference
orig = readFrame(obj);
image(orig, 'Parent', handles.mainvideo);
pause(0.5);
delete(h);

% set titles for the axes
set(handles.mainvideo, 'Visible', 'off');
set(handles.mainvideo, 'xtick', [])
set(handles.mainvideo, 'ytick', [])

% Give a name to the title bar of the GUI window
set(gcf, 'Name', filename, 'NumberTitle', 'Off')

% ================BOUNDING BOXES for ROI & Digits================ START
% --------------ROI 1-----------------------------------
message = sprintf('Motion ROI 1 - Box a region');
mh = msgbox(message,'Select Box 1 (ROI)','help');
th = findall(mh, 'Type', 'Text');                   %get handle to text within msgbox
th.FontSize = 12;
uiwait(mh);
% buttonpress
k = waitforbuttonpress;
point1 = get(gca,'CurrentPoint');    % button down detected
finalRect = rbbox;                   % return figure units
point2 = get(gca,'CurrentPoint');    % button up detected
point1 = point1(1,1:2);              % extract x and y
point2 = point2(1,1:2);
p1 = min(point1,point2);             % calculate locations
% acquire {offset, x, y} for ROI 1
offset_roi1 = abs(point1-point2);         % and dimensions
x_roi1 = round(p1(1));
y_roi1 = round(p1(2));
rectangle(handles.mainvideo, 'Position',[x_roi1(1), y_roi1(1), offset_roi1(1), offset_roi1(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'y', 'LineWidth', 2, 'LineStyle','--');

% --------------HR ROI 1-----------------------------------
message = sprintf('Heart Rate Device 1 - Box a region');
mh2 = msgbox(message,'Select Box 2 (Number)', 'help');
th2 = findall(mh2, 'Type', 'Text');                   %get handle to text within msgbox
th2.FontSize = 12;
uiwait(mh2);
% buttonpress
k = waitforbuttonpress;
point1 = get(gca,'CurrentPoint');    % button down detected
finalRect = rbbox;                   % return figure units
point2 = get(gca,'CurrentPoint');    % button up detected
point1 = point1(1,1:2);              % extract x and y
point2 = point2(1,1:2);
p1 = min(point1,point2);             % calculate locations
% acquire {offset, x, y} for Digit ROI 1
offset_hr1 = abs(point1-point2);         % and dimensions
x_hr1 = round(p1(1));
y_hr1 = round(p1(2));
rectangle(handles.mainvideo, 'Position',[x_hr1(1), y_hr1(1), offset_hr1(1), offset_hr1(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'r', 'LineWidth', 2, 'LineStyle','--');

% --------------HR ROI 2-----------------------------------
message = sprintf('Heart Rate Device 2 - Box a region');
mh2 = msgbox(message,'Select Box 2 (Number)', 'help');
th2 = findall(mh2, 'Type', 'Text');                   %get handle to text within msgbox
th2.FontSize = 12;
uiwait(mh2);
% buttonpress
k = waitforbuttonpress;
point1 = get(gca,'CurrentPoint');    % button down detected
finalRect = rbbox;                   % return figure units
point2 = get(gca,'CurrentPoint');    % button up detected
point1 = point1(1,1:2);              % extract x and y
point2 = point2(1,1:2);
p1 = min(point1,point2);             % calculate locations
% acquire {offset, x, y} for Digit ROI 2
offset_hr2 = abs(point1-point2);         % and dimensions
x_hr2 = round(p1(1));
y_hr2 = round(p1(2));
rectangle(handles.mainvideo, 'Position',[x_hr2(1), y_hr2(1), offset_hr2(1), offset_hr2(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'r', 'LineWidth', 2, 'LineStyle','--');
                
% ================READ FRAMES================  START

% if the video has subsequent frames to read, then proceed reading them
% check if the object has valid frames to read
origReset = 0;
if hasFrame(obj)
    fps = obj.FrameRate % frames per second
    status = '-';
    
    timeStart = 0;
    frameCountActual = 0;
    countROI1 = 1;      % iteration
    countROI2 = 1;      % iteration
    countROI3 = 1;      % iteration
    
    % get hour, min, sec of the initial frame at opening
    startTime = obj.CurrentTime; 
    
    % acquire initially set time (hour/min/sec) to start at
    time_hr_Callback(handles.loadbutton, eventdata, handles);
    startHour = repmat(time_hr,1,1);     
    time_min_Callback(handles.loadbutton, eventdata, handles);
    startMin = repmat(time_min,1,1);
    time_sec_Callback(handles.loadbutton, eventdata, handles);
    startSec = repmat(time_sec,1,1);

    % convert the initially specified time to seconds
    startHour_sec = startHour * 60*60;
    startMin_sec = startMin * 60;
    time_seconds = startHour_sec + startMin_sec + startSec;
    initialTimeSeconds = (startHour*3600 + startMin*60 + startSec);
    % acquire the number of repetitions this will run for
    rep_count_Callback(handles.loadbutton, eventdata, handles);
    rep_count = repmat(rep_count,1,1); 
    
    % initialize cells for tabular output 
    ITERATIONS1 = {};
    TIME_START1 = {};
    TIME_END1 = {};
    DURATION1 = {};
    
    ITERATIONS2 = {};
    TIME_START2 = {};
    TIME_END2 = {};
    DURATION2 = {};
    
    ITERATIONS3 = {};
    TIME_START3 = {};
    TIME_END3 = {};
    DURATION3 = {};
    
    MIN_DEV1 = {};
    MAX_DEV1 = {};
    AVG_DEV1 = {};
    MIN_DEV2 = {};
    MAX_DEV2 = {};
    AVG_DEV2 = {};
    
    frameCount = 0;
    
    % for HR reading comparisons
    prev_diff1 = 0;
    prev_diff2 = 0;
    prev_diff3 = 0;
    
    % set image view settings
    title(handles.current_image1, 'ROI 1');               % ROI 1
    set(handles.current_image1,'xtick',[]);
    set(handles.current_image1,'ytick',[]);
    title(handles.current_image2, 'ROI 2');               % ROI 2
    set(handles.current_image2,'xtick',[]);
    set(handles.current_image2,'ytick',[]);
    title(handles.current_image3, 'ROI 3');               % ROI 3
    set(handles.current_image3,'xtick',[]);
    set(handles.current_image3,'ytick',[]);
    title(handles.heartrate_image1, strcat('HR: -'));   % HR ROI 1
    set(handles.heartrate_image1,'xtick',[]);
    set(handles.heartrate_image1,'ytick',[]);
    title(handles.heartrate_image2, strcat('HR: -'));   % HR ROI 2
    set(handles.heartrate_image2,'xtick',[]);
    set(handles.heartrate_image2,'ytick',[]);
    
    % intialize to store digit readings
    numDevice1_ROI1 = zeros(rep_count,1000);   % ocr texts per iteration
    numDevice2_ROI1 = zeros(rep_count,1000);
    
    numDevice1_ROI2 = zeros(rep_count,1000);   % ocr texts per iteration
    numDevice2_ROI2 = zeros(rep_count,1000);
    
    numDevice1_ROI3 = zeros(rep_count,1000);   % ocr texts per iteration
    numDevice2_ROI3 = zeros(rep_count,1000);
    
    % booleans to check if 2nd or 3rd ROI is requested
    setROI2 = 0;
    setROI3 = 0;
    % run through frames-----------------------------------------------
    while hasFrame(obj)
        % allow the user to select region upon checking ROI boxes
        if get(handles.roi1, 'Value') == 1.0 && ...
            get(handles.roi2, 'Value') == 1.0 && ...
            get(handles.roi3, 'Value') == 0.0 && ...
            setROI2 == 0
            % --------------ROI 2-----------------------------------
            message = sprintf('Motion ROI 2 - Box a region');
            mh = msgbox(message,'Select Box 2 (ROI)','help');
            th = findall(mh, 'Type', 'Text');                   %get handle to text within msgbox
            th.FontSize = 12;
            uiwait(mh);
            % buttonpress
            k = waitforbuttonpress;
            point1 = get(gca,'CurrentPoint');    % button down detected
            finalRect = rbbox;                   % return figure units
            point2 = get(gca,'CurrentPoint');    % button up detected
            point1 = point1(1,1:2);              % extract x and y
            point2 = point2(1,1:2);
            p1 = min(point1,point2);             % calculate locations
            % acquire {offset, x, y} for ROI 2
            offset_roi2 = abs(point1-point2);         % and dimensions
            x_roi2 = round(p1(1));
            y_roi2 = round(p1(2));
            rect2 = rectangle(handles.mainvideo, 'Position',[x_roi2(1), y_roi2(1), offset_roi2(1), offset_roi2(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'y', 'LineWidth', 2, 'LineStyle','--');
            setROI2 = 1;
            set(handles.status_curr1, 'String', 'END');
%             pause(0.5);
            set(handles.count, 'String', countROI2);
        end
        if get(handles.roi1, 'Value') == 1.0 && ...
            get(handles.roi2, 'Value') == 1.0 && ...
            get(handles.roi3, 'Value') == 1.0 && ...         
            setROI3 == 0
            % --------------ROI 3-----------------------------------
            message = sprintf('Motion ROI 3 - Box a region');
            mh = msgbox(message,'Select Box 3 (ROI)','help');
            th = findall(mh, 'Type', 'Text');                   %get handle to text within msgbox
            th.FontSize = 12;
            uiwait(mh);
            % buttonpress
            k = waitforbuttonpress;
            point1 = get(gca,'CurrentPoint');    % button down detected
            finalRect = rbbox;                   % return figure units
            point2 = get(gca,'CurrentPoint');    % button up detected
            point1 = point1(1,1:2);              % extract x and y
            point2 = point2(1,1:2);
            p1 = min(point1,point2);             % calculate locations
            % acquire {offset, x, y} for ROI 2
            offset_roi3 = abs(point1-point2);         % and dimensions
            x_roi3 = round(p1(1));
            y_roi3 = round(p1(2));
            rectangle(handles.mainvideo, 'Position',[x_roi3(1), y_roi3(1), offset_roi3(1), offset_roi3(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'y', 'LineWidth', 2, 'LineStyle','--');
            setROI3 = 1;
            setROI2 = 0;
            set(handles.status_curr1, 'String', 'END');
            set(handles.status_curr2, 'String', 'END');
%             pause(0.5);
            set(handles.count, 'String', countROI3);
        end
        
        % increment frame count (for output later)
        frameCount = frameCount + 1;
        disp(sprintf("Frame %i:",frameCount))
        % speed up running frames by specified 'frame_speedup' number
        if frame_speedup ~= 0
            offset = frame_speedup;
        else
            offset = ceil(double(obj.FrameRate));
        end
        for i = 1:offset
            if hasFrame(obj)                
                vidFrame = readFrame(obj);
                frameCountActual = frameCountActual + offset;        
            else
                continue
            end
        end
        
        global checkedROI1
        global checkedROI2
        global checkedROI3
        % read subsequent frame
        if hasFrame(obj)
            vidFrame = readFrame(obj);
            % display currently read frame to the mainvideo view------------
            image(vidFrame, 'Parent', handles.mainvideo);
        end
        
        % if ROI 2 or 3 is checked off, then reset the original frame
        % to the current one
        if origReset == 0 && setROI2 == 1
            orig = vidFrame;
            origReset = 1;
            disp('setROI2 reset')
        elseif origReset == 1 && setROI3 == 1
            orig = vidFrame;
            origReset = 2;
            disp('setROI3 reset')
        end
        

        % grayscale-----------------------------------------------------
        origGray = rgb2gray(orig);          % reference frame (very first)
        vidFrameGray = rgb2gray(vidFrame);  % current frame, grascaled
        
        % Crop grayscaled images to compare for thresholding------------
        % ROI 1
        origGray1 = imcrop(origGray, [x_roi1(1), y_roi1(1), offset_roi1(1), offset_roi1(2)]);
        currGray1 = imcrop(vidFrameGray, [x_roi1(1), y_roi1(1), offset_roi1(1), offset_roi1(2)]);
        
        % ROI 2
        if setROI2 == 1
            origGray2 = imcrop(origGray, [x_roi2(1), y_roi2(1), offset_roi2(1), offset_roi2(2)]);
            currGray2 = imcrop(vidFrameGray, [x_roi2(1), y_roi2(1), offset_roi2(1), offset_roi2(2)]);
        elseif setROI3 == 1
        % ROI 3
            origGray3 = imcrop(origGray, [x_roi3(1), y_roi3(1), offset_roi3(1), offset_roi3(2)]);
            currGray3 = imcrop(vidFrameGray, [x_roi3(1), y_roi3(1), offset_roi3(1), offset_roi3(2)]);
        end
        
        % read HR devices-----------------------------------------------
        % HR device 1
        rotation1 = 5;        
        hrGray1 = imcrop(vidFrameGray, [x_hr1(1), y_hr1(1), offset_hr1(1), offset_hr1(2)]);
        hrGray1 = imrotate(hrGray1,rotation1,'bilinear','crop');
        hrGrayCorrected1 =  imtophat(hrGray1, strel('disk',15));
        marker = imerode(hrGrayCorrected1, strel('line',10,0));
        hrGrayCorrectedClean1 = imreconstruct(marker, hrGrayCorrected1);
        hrCrop1 = imbinarize(hrGrayCorrectedClean1);
        hrCrop1 = imrotate(hrCrop1, rotation1,'bilinear','crop');
        readHeartRate = ocr(hrCrop1, 'TextLayout','Block');
        % if not convertible to number, set HR to 0 to be safe
        try
            regularExpr = '\d*';
            heartRateDevice1 = regexp(readHeartRate.Text, regularExpr, 'match');
            heartRateDevice1 = str2double(strcat(heartRateDevice1{:}));
        catch
            heartRateDevice1 = 0;
        end
        
        % read HR device 2
        rotation2 = -5;        
        hrGray2 = imcrop(vidFrameGray, [x_hr2(1), y_hr2(1), offset_hr2(1), offset_hr2(2)]);
        hrGray2 = imrotate(hrGray2,rotation2,'bilinear','crop');
        hrGrayCorrected2 =  imtophat(hrGray2, strel('disk',15));
        marker = imerode(hrGrayCorrected2, strel('line',10,0));
        hrGrayCorrectedClean2 = imreconstruct(marker, hrGrayCorrected2);
        hrCrop2 = imbinarize(hrGrayCorrectedClean2);
        hrCrop2 = imrotate(hrCrop2, rotation2,'bilinear','crop');
        readHeartRate = ocr(hrCrop2, 'TextLayout','Block');
        % if not convertible to number, set HR to 0 to be safe
        try
            regularExpr = '\d*';
            heartRateDevice2 = regexp(readHeartRate.Text, regularExpr, 'match');
            heartRateDevice2 = str2double(strcat(heartRateDevice2{:}));
        catch
            heartRateDevice2 = 0;
        end
        
        % crop original colored image views to display if motion is detected-----------------------------------------------
        % ROI 1,2,3
        curr1 = imcrop(vidFrame, [x_roi1(1), y_roi1(1), offset_roi1(1), offset_roi1(2)]); % for displaying current ROI
        if setROI2 == 1
            curr2 = imcrop(vidFrame, [x_roi2(1), y_roi2(1), offset_roi2(1), offset_roi2(2)]); % for displaying current ROI
        end
        if setROI3 == 1
            curr3 = imcrop(vidFrame, [x_roi3(1), y_roi3(1), offset_roi3(1), offset_roi3(2)]); % for displaying current ROI
        end
        % HR ROI 1,2
        hr1 = imcrop(vidFrame, [x_hr1(1), y_hr1(1), offset_hr1(1), offset_hr1(2)]); % for displaying current HR device screen
        hr2 = imcrop(vidFrame, [x_hr2(1), y_hr2(1), offset_hr2(1), offset_hr2(2)]); % for displaying current HR device screen
        
        % STRUCTURAL SIMILARITY INDEX scores for ROI's------------------
        ssimVal1 = ssim(origGray1, currGray1);
        if setROI2 == 1
            ssimVal2 = ssim(origGray2, currGray2);
        end
        if setROI3 == 1
            ssimVal3 = ssim(origGray3, currGray3);
        end

        % get number of non-zero pixels---------------------------------
        % find differences from initial frame---------------------------
        % ROI 1
        orig_nonzero1 = length(origGray1(origGray1~=0));
        curr_nonzero1 = length(currGray1(currGray1~=0));
        diff1 = abs(orig_nonzero1 - curr_nonzero1);
        
        % Detect changes between frames---------------------------------
        % >> get the number of different pixels in differential frame
        %    and compare against the previous different pixel number,
        %    as well as similiarity index
        
        % START condition - ROI 1
        if get(handles.roi1, 'Value') == 1.0 && ...
                get(handles.roi2, 'Value') == 0.0 && ...
                get(handles.roi3, 'Value') == 0.0
            % disp(sprintf('\tdiff1: %i, prev_diff1: %i, ssimVal1: %i',diff1, prev_diff1, ssimVal1))
            if ((diff1-prev_diff1)>50) && ssimVal1<0.5 && detected1==0
                % set detected state to true
                setGlobalDetected1(1);
                % update the status
                set(handles.status_curr1, 'String', 'START');
                % update and insert the starting time in hour/min/sec string
                timeStart = obj.CurrentTime;
                runtime = (timeStart - initialTimeSeconds);
                h = floor((initialTimeSeconds + runtime)/3600);
                m = floor(((initialTimeSeconds + runtime)/3600-h)*60);
                s = (((initialTimeSeconds + runtime)/3600-h)*60-m)*60;
                TIME_START1(1,countROI1) = cellstr(sprintf('%d:%d:%.1f',h,m,s));
            % END condition
            elseif (((diff1-prev_diff1)<50)&&ssimVal1>0.9) && detected1==1
                % set detected state to false 
                setGlobalDetected1(0);
                % update the status and heart rate readings
                set(handles.status_curr1, 'String', 'END');
                % update iteration vector
                ITERATIONS1(1,countROI1) = num2cell(countROI1);
                % update and insert the ending time
                timeEnd = obj.CurrentTime;
                runtime = (timeEnd - startTime);
                h = floor((initialTimeSeconds + runtime)/3600);
                m = floor(((initialTimeSeconds + runtime)/3600-h)*60);
                s = (((initialTimeSeconds + runtime)/3600-h)*60-m)*60;
                TIME_END1(1,countROI1) = cellstr(sprintf('%d:%d:%.1f',h,m,s));
                duration = timeEnd - timeStart + time_seconds;
                DURATION1(1,countROI1) = num2cell(duration);           
                % filter heart rates to specified desired range
                idx1 = find(numDevice1_ROI1(countROI1,:)>HR1_thresh1 & numDevice1_ROI1(countROI1,:)<HR1_thresh2);
                idx2 = find(numDevice2_ROI1(countROI1,:)>HR2_thresh1 & numDevice2_ROI1(countROI1,:)<HR2_thresh2);
                numDevice1_ROI1(countROI1,~idx1) = 0;
                numDevice2_ROI1(countROI1,~idx2) = 0;
                
                set(handles.count, 'String', countROI1+1);
                % eliminate left-trailing zeros and pull everything to index 1
                if numDevice1_ROI1(countROI1,1)==0
                    nonzeros = find(numDevice1_ROI1(countROI1,:)~=0);
                    if ~isempty(nonzeros)
                        firstNonzero = nonzeros(1);
                        good = numDevice1_ROI1(countROI1,firstNonzero:end);
                        lengthValid = size(good,2);
                        numDevice1_ROI1(countROI1,1:lengthValid) = good;
                    end
                end
                if numDevice2_ROI1(countROI1,1)==0
                    nonzeros = find(numDevice2_ROI1(countROI1,:)~=0);
                    if ~isempty(nonzeros)
                        firstNonzero = nonzeros(1);
                        good = numDevice2_ROI1(countROI1,firstNonzero:end);
                        lengthValid = size(good,2);
                        numDevice2_ROI1(countROI1,1:lengthValid) = good;
                    end
                end
                set(handles.count, 'String', countROI1);
                countROI1 = countROI1 + 1;
            % IN-MOTION condition
            elseif (detected1==1)
                % highlight the ROIs with rectangles
                rectangle(handles.mainvideo,'Position',[x_roi1(1), y_roi1(1), offset_roi1(1), offset_roi1(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'g', 'LineWidth', 3, 'LineStyle','-');
                rectangle(handles.mainvideo,'Position',[x_hr1(1), y_hr1(1), offset_hr1(1), offset_hr1(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'g', 'LineWidth', 3, 'LineStyle','-');
                rectangle(handles.mainvideo,'Position',[x_hr2(1), y_hr2(1), offset_hr2(1), offset_hr2(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'g', 'LineWidth', 3, 'LineStyle','-');
                % insert into cumulative vectors
                numDevice1_ROI1(countROI1, frameCount) = heartRateDevice1;
                numDevice2_ROI1(countROI1, frameCount) = heartRateDevice2;
                % update the strings on the GUI
                set(handles.heartrate1, 'String', heartRateDevice1);
                set(handles.heartrate2, 'String', heartRateDevice2);

                image(curr1, 'Parent', handles.current_image1); 
                title(handles.current_image1, 'Current');
                title(handles.current_image2, 'ROI 2');
                title(handles.current_image3, 'ROI 3');
                set(handles.current_image1,'xtick',[]);
                set(handles.current_image1,'ytick',[]);

                image(hr1, 'Parent', handles.heartrate_image1);
                title(handles.heartrate_image1, strcat('Number:  ',num2str(heartRateDevice1)));
                set(handles.heartrate_image1,'xtick',[]);
                set(handles.heartrate_image1,'ytick',[]);

                image(hr2, 'Parent', handles.heartrate_image2);
                title(handles.heartrate_image2, strcat('Number:  ',num2str(heartRateDevice2)));
                set(handles.heartrate_image2,'xtick',[]);
                set(handles.heartrate_image2,'ytick',[]);       
            elseif detected1 == 0
                rectangle(handles.mainvideo,'Position',[x_roi1(1), y_roi1(1), offset_roi1(1), offset_roi1(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle','-');
                rectangle(handles.mainvideo,'Position',[x_hr1(1), y_hr1(1), offset_hr1(1), offset_hr1(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle','-');
                rectangle(handles.mainvideo,'Position',[x_hr2(1), y_hr2(1), offset_hr2(1), offset_hr2(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle','-');
            end       
        end
        
        if setROI2 == 1
            % ROI 2
            orig_nonzero2 = length(origGray2(origGray2~=0));
            curr_nonzero2 = length(currGray2(currGray2~=0));
            diff2 = abs(orig_nonzero2 - curr_nonzero2);
            % disp(sprintf('\tdiff2: %i, prev_diff2: %i, ssimVal2: %i',diff2, prev_diff2, ssimVal2))
            % START condition - ROI 2
            if (((diff2-prev_diff2)>50)&&ssimVal2<0.5)&&(detected2==0)
                % set detected state to true
                setGlobalDetected2(1);
                % update the status
                set(handles.status_curr2, 'String', 'START');
                % update and insert the starting time in hour/min/sec string
                timeStart = obj.CurrentTime;
                runtime = (timeStart - initialTimeSeconds);
                h = floor((initialTimeSeconds + runtime)/3600);
                m = floor(((initialTimeSeconds + runtime)/3600-h)*60);
                s = (((initialTimeSeconds + runtime)/3600-h)*60-m)*60;
                TIME_START2(1,countROI2) = cellstr(sprintf('%d:%d:%.1f',h,m,s));
            % END condition
            elseif (((diff2-prev_diff2)<70) && ssimVal2>0.9) && (detected2 == 1)
                % set detected state to false 
                setGlobalDetected2(0);
                % update the status and heart rate readings
                set(handles.status_curr2, 'String', 'END');
                % update iteration vector
                ITERATIONS2(1,countROI2) = num2cell(countROI2);
                % update and insert the ending time
                timeEnd = obj.CurrentTime;
                runtime = (timeEnd - startTime);
                h = floor((initialTimeSeconds + runtime)/3600);
                m = floor(((initialTimeSeconds + runtime)/3600-h)*60);
                s = (((initialTimeSeconds + runtime)/3600-h)*60-m)*60;
                TIME_END2(1,countROI2) = cellstr(sprintf('%d:%d:%.1f',h,m,s));
                duration = timeEnd - timeStart + time_seconds;
                DURATION2(1,countROI2) = num2cell(duration);           
                % filter heart rates to specified desired range

                idx1 = find(numDevice1_ROI2(countROI2,:)>HR1_thresh1 & numDevice1_ROI2(countROI2,:)<HR1_thresh2);
                idx2 = find(numDevice2_ROI2(countROI2,:)>HR2_thresh1 & numDevice2_ROI2(countROI2,:)<HR2_thresh2);
                numDevice1_ROI2(countROI2,~idx1) = 0;
                numDevice2_ROI2(countROI2,~idx2) = 0;
                
                % eliminate left-trailing zeros and pull everything to index 1
                if numDevice1_ROI2(countROI2,1)==0
                    nonzeros = find(numDevice1_ROI2(countROI2,:)~=0);
                    if ~isempty(nonzeros)
                        firstNonzero = nonzeros(1);
                        good = numDevice1_ROI2(countROI2,firstNonzero:end);
                        numDevice1_ROI2(countROI2,1:size(good,2)) = ...
                            numDevice1_ROI2(countROI2,firstNonzero:end);
                    end
                end
                if numDevice2_ROI2(countROI2,1)==0
                    nonzeros = find(numDevice2_ROI2(countROI2,:)~=0);
                    if ~isempty(nonzeros)
                        firstNonzero = nonzeros(1);
                        good = numDevice2_ROI2(countROI2,firstNonzero:end);
                        numDevice2_ROI2(countROI2,1:size(good,2)) = ...
                            numDevice2_ROI2(countROI2,firstNonzero:end);
                    end
                end

                set(handles.count, 'String', countROI2);
                countROI2 = countROI2 + 1;
            % IN-MOTION condition
            elseif (detected2 == 1)
                % highlight the ROIs with green rectangles
                rectangle(handles.mainvideo,'Position',[x_roi2(1), y_roi2(1), offset_roi2(1), offset_roi2(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'g', 'LineWidth', 3, 'LineStyle','-');
                rectangle(handles.mainvideo,'Position',[x_hr1(1), y_hr1(1), offset_hr1(1), offset_hr1(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'g', 'LineWidth', 3, 'LineStyle','-');
                rectangle(handles.mainvideo,'Position',[x_hr2(1), y_hr2(1), offset_hr2(1), offset_hr2(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'g', 'LineWidth', 3, 'LineStyle','-');
                % insert into cumulative vectors
                numDevice1_ROI2(countROI2, frameCount) = heartRateDevice1;
                numDevice2_ROI2(countROI2, frameCount) = heartRateDevice2;
                % update the strings on the GUI
                set(handles.heartrate1, 'String', heartRateDevice1);
                set(handles.heartrate2, 'String', heartRateDevice2);

                image(curr2, 'Parent', handles.current_image2); 
                title(handles.current_image1, 'ROI 1');
                title(handles.current_image2, 'Current');
                title(handles.current_image3, 'ROI 3');
                set(handles.current_image2,'xtick',[]);
                set(handles.current_image2,'ytick',[]);

                image(hr1, 'Parent', handles.heartrate_image1);
                title(handles.heartrate_image1, strcat('Number:  ',num2str(heartRateDevice1)));
                set(handles.heartrate_image1,'xtick',[]);
                set(handles.heartrate_image1,'ytick',[]);

                image(hr2, 'Parent', handles.heartrate_image2);
                title(handles.heartrate_image2, strcat('Number:  ',num2str(heartRateDevice2)));
                set(handles.heartrate_image2,'xtick',[]);
                set(handles.heartrate_image2,'ytick',[]);       
            elseif detected2 == 0
                rectangle(handles.mainvideo,'Position',[x_roi2(1), y_roi2(1), offset_roi2(1), offset_roi2(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle','-');
                rectangle(handles.mainvideo,'Position',[x_hr1(1), y_hr1(1), offset_hr1(1), offset_hr1(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle','-');
                rectangle(handles.mainvideo,'Position',[x_hr2(1), y_hr2(1), offset_hr2(1), offset_hr2(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle','-');
            end
        end
        
        % START condition - ROI 3
        if setROI3 == 1
            % ROI 3
            orig_nonzero3 = length(origGray3(origGray3~=0));
            curr_nonzero3 = length(currGray3(currGray3~=0));
            diff3 = abs(orig_nonzero3 - curr_nonzero3);
            % disp(sprintf('\tdiff3: %i, prev_diff3: %i, ssimVal3: %i',diff3, prev_diff3, ssimVal3))
            setROI2 = 0;         
            if ((abs(diff3-prev_diff3)>50)&&ssimVal3<0.55)&&(detected3==0)
                % set detected state to true
                setGlobalDetected3(1);
                % update the status
                set(handles.status_curr3, 'String', 'START');
                % update and insert the starting time in hour/min/sec string
                timeStart = obj.CurrentTime;
                runtime = (timeStart - initialTimeSeconds);
                h = floor((initialTimeSeconds + runtime)/3600);
                m = floor(((initialTimeSeconds + runtime)/3600-h)*60);
                s = (((initialTimeSeconds + runtime)/3600-h)*60-m)*60;
                TIME_START3(1,countROI3) = cellstr(sprintf('%d:%d:%.1f',h,m,s));
            % END condition
            elseif ((abs(diff3-prev_diff3)>50)&&ssimVal3>0.7)&&(detected3==1)
                % set detected state to false 
                setGlobalDetected3(0);
                % update the status and heart rate readings
                set(handles.status_curr3, 'String', 'END');
                % update iteration vector
                ITERATIONS3(1,countROI3) = num2cell(countROI3);
                % update and insert the ending time
                timeEnd = obj.CurrentTime;
                runtime = (timeEnd - startTime);
                h = floor((initialTimeSeconds + runtime)/3600);
                m = floor(((initialTimeSeconds + runtime)/3600-h)*60);
                s = (((initialTimeSeconds + runtime)/3600-h)*60-m)*60;
                TIME_END3(1,countROI3) = cellstr(sprintf('%d:%d:%.1f',h,m,s));
                duration = timeEnd - timeStart + time_seconds;
                DURATION3(1,countROI3) = num2cell(duration);           
                % filter heart rates to specified desired range
                idx1 = find(numDevice1_ROI3(countROI3,:)>HR1_thresh1 & numDevice1_ROI3(countROI3,:)<HR1_thresh2);
                idx2 = find(numDevice2_ROI3(countROI3,:)>HR2_thresh2 & numDevice2_ROI3(countROI3,:)<HR2_thresh2);
                numDevice1_ROI3(countROI3,~idx1) = 0;
                numDevice2_ROI3(countROI3,~idx2) = 0;
                
                % eliminate left-trailing zeros and pull everything to index 1
                if numDevice1_ROI3(countROI3,1)==0
                    nonzeros = find(numDevice1_ROI3(countROI3,:)~=0);
                    if ~isempty(nonzeros)
                        firstNonzero = nonzeros(1);
                        good = numDevice1_ROI3(countROI3,firstNonzero:end);
                        lengthValid = size(good,2);
                        numDevice1_ROI3(countROI3,1:lengthValid) = good;
                    end
                end
                if numDevice2_ROI3(countROI3,1)==0
                    nonzeros = find(numDevice2_ROI3(countROI3,:)~=0);
                    if ~isempty(nonzeros)
                        firstNonzero = nonzeros(1);
                        good = numDevice2_ROI3(countROI3,firstNonzero:end);
                        lengthValid = size(good,2);
                        numDevice2_ROI3(countROI3,1:lengthValid) = good;
                    end
                end
                
                set(handles.count, 'String', countROI3);
                countROI3 = countROI3 + 1;
            % IN-MOTION condition
            elseif (detected3==1)
                % highlight the ROIs with green rectangles
                rectangle(handles.mainvideo,'Position',[x_roi3(1), y_roi3(1), offset_roi3(1), offset_roi3(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'g', 'LineWidth', 3, 'LineStyle','-');
                rectangle(handles.mainvideo,'Position',[x_hr1(1), y_hr1(1), offset_hr1(1), offset_hr1(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'g', 'LineWidth', 3, 'LineStyle','-');
                rectangle(handles.mainvideo,'Position',[x_hr2(1), y_hr2(1), offset_hr2(1), offset_hr2(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'g', 'LineWidth', 3, 'LineStyle','-');
                % insert into cumulative vectors
                numDevice1_ROI3(countROI3, frameCount) = heartRateDevice1;
                numDevice2_ROI3(countROI3, frameCount) = heartRateDevice2;
                % update the strings on the GUI
                set(handles.heartrate1, 'String', heartRateDevice1);
                set(handles.heartrate2, 'String', heartRateDevice2);

                image(curr3, 'Parent', handles.current_image3); 
                title(handles.current_image1, 'ROI 1');
                title(handles.current_image2, 'ROI 2');
                title(handles.current_image3, 'Current');
                set(handles.current_image3,'xtick',[]);
                set(handles.current_image3,'ytick',[]);

                image(hr1, 'Parent', handles.heartrate_image1);
                title(handles.heartrate_image1, strcat('Number:  ',num2str(heartRateDevice1)));
                set(handles.heartrate_image1,'xtick',[]);
                set(handles.heartrate_image1,'ytick',[]);

                image(hr2, 'Parent', handles.heartrate_image2);
                title(handles.heartrate_image2, strcat('Number:  ',num2str(heartRateDevice2)));
                set(handles.heartrate_image2,'xtick',[]);
                set(handles.heartrate_image2,'ytick',[]);       
            elseif detected3 == 0
                rectangle(handles.mainvideo,'Position',[x_roi3(1), y_roi3(1), offset_roi3(1), offset_roi3(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle','-');
                rectangle(handles.mainvideo,'Position',[x_hr1(1), y_hr1(1), offset_hr1(1), offset_hr1(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle','-');
                rectangle(handles.mainvideo,'Position',[x_hr2(1), y_hr2(1), offset_hr2(1), offset_hr2(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle','-');
            end
        end
        
        % update running video information
        set(handles.mainvideo, 'Visible', 'off');
%         pause(1/obj.FrameRate);
        prev_diff1 = diff1;
        if setROI2 == 1
            prev_diff2 = diff2;
        end
        if setROI3 == 1
            prev_diff3 = diff3;
        end
        set(handles.currenttime, 'String',obj.CurrentTime); % running time
    end % end while (hasFrame(obj))
    
    disp('Completed scanning. \nSaving to file...')
    
    % clean up data-----------------------------------------------------
    global selpath
    % ROI 1
    if size(ITERATIONS1,1) > 0
        countROI1 = countROI1 - 1;
        % filter if all durations are less than 5 seconds
        if double(cell2mat(DURATION1(:,size(ITERATIONS1,1)))) < 5
            numIter = size(ITERATIONS1,1);
            ITERATIONS1(:,numIter) = {};
            TIME_START1(:,numIter) = {};
            TIME_END1(:,numIter) = {};
            DURATION1(:,numIter) = {};
            MIN_DEV1(:,numIter) = {};
            MAX_DEV1(:,numIter) = {};
            AVG_DEV1(:,numIter) = {};
            MIN_DEV2(:,numIter) = {};
            MAX_DEV2(:,numIter) = {};
            AVG_DEV2(:,numIter) = {};
        end
        
        % filter zeros for each countROI index (iteration)
        filteredHR1ROI1 = [];
        filteredHR2ROI1 = [];
        for i = 1:countROI1
            for j = 1:size(numDevice1_ROI1,2)
               if numDevice1_ROI1(i,j) > HR1_thresh1 && numDevice1_ROI1(i,j) < HR1_thresh2
                   if numDevice1_ROI1(i,j) ~= 0
                        filteredHR1ROI1(i,end+1) = numDevice1_ROI1(i,j);
                   end
               end
            end
            for j = 1:size(numDevice2_ROI1,2)
               if numDevice2_ROI1(i,j) > HR2_thresh1 && numDevice2_ROI1(i,j) < HR2_thresh2
                   if numDevice2_ROI1(i,j) ~= 0
                        filteredHR2ROI1(i,end+1) = numDevice2_ROI1(i,j);
                   end
               end
            end
        end
        % output all read HRs to confirm
        filteredHR1ROI1
        filteredHR2ROI1
        save(strcat(fullfile(selpath,string(filename(1))), 'HR1_ROI1.mat'), 'filteredHR1ROI1')
        save(strcat(fullfile(selpath,string(filename(1))), 'HR2_ROI1.mat'), 'filteredHR2ROI1')
        
        % make table of equal-si zed rows
        ITERATIONS1 = ITERATIONS1(:,1:countROI1);
        TIME_START1 = TIME_START1(:,1:countROI1);
        TIME_END1 = TIME_END1(:,1:countROI1);
        DURATION1 = DURATION1(:,1:countROI1);

        mins = [];
        maxes = [];
        for r = 1:size(filteredHR1ROI1,1)
            rowVec = filteredHR1ROI1(r,:);
            if isempty(rowVec(rowVec~=0))
                continue;
            end
            minRow = min(rowVec(rowVec~=0));
            maxRow = max(rowVec(rowVec~=0));
            mins(r,1) = minRow;
            maxes(r,1) = maxRow;
        end
        MIN_DEV1 = num2cell(mins)';
        MAX_DEV1 = num2cell(maxes)';
            
        mins = [];
        maxes = [];
        for r = 1:size(filteredHR2ROI1,1)
            rowVec = filteredHR2ROI1(r,:);
            if isempty(rowVec(rowVec~=0))
                continue;
            end
            minRow = min(rowVec(rowVec~=0));
            maxRow = max(rowVec(rowVec~=0));
            mins(r,1) = minRow;
            maxes(r,1) = maxRow;
        end
        MIN_DEV2 = num2cell(mins)';
        MAX_DEV2 = num2cell(maxes)';
            
        AVG_DEV1 = num2cell( round( sum(filteredHR1ROI1,2)./sum(filteredHR1ROI1~=0,2) ,4) )';
        AVG_DEV2 = num2cell( round( sum(filteredHR2ROI1,2)./sum(filteredHR2ROI1~=0,2) ,4) )';
        
        if size(filteredHR1ROI1, 1) > 0 && size(filteredHR2ROI1, 1) > 0
            % append the macro average in the last row
            ITERATIONS1(end, end+1) = num2cell(0);
            TIME_START1(end, end+1) = TIME_START1(1,1);
            TIME_END1(end, end+1) = TIME_END1(end,end);
            DURATION1(end, end+1) = num2cell(round(mean(double(cell2mat(DURATION1(end, 1:end)))),4));

            MIN_DEV1(end, end+1) = num2cell(round(mean(double(cell2mat(MIN_DEV1(end, 1:end)))),4));
            MAX_DEV1(end, end+1) = num2cell(round(mean(double(cell2mat(MAX_DEV1(end, 1:end)))),4));
            AVG_DEV1(end, end+1) = num2cell(round(mean(double(cell2mat(AVG_DEV1(end, 1:end)))),4));
            MIN_DEV2(end, end+1) = num2cell(round(mean(double(cell2mat(MIN_DEV2(end, 1:end)))),4));
            MAX_DEV2(end, end+1) = num2cell(round(mean(double(cell2mat(MAX_DEV2(end, 1:end)))),4));
            AVG_DEV2(end, end+1) = num2cell(round(mean(double(cell2mat(AVG_DEV2(end, 1:end)))),4));
        end
        
        ITERATIONS1 = string(cell2mat(ITERATIONS1)');
        TIME_START1 = string(TIME_START1(:));
        TIME_END1 = string(TIME_END1(:));  
        DURATION1 = string(cell2mat(DURATION1)');
        MIN_DEV1 = string(cell2mat(MIN_DEV1)');
        MAX_DEV1 = string(cell2mat(MAX_DEV1)');
        AVG_DEV1 = string(cell2mat(AVG_DEV1)');
        MIN_DEV2 = string(cell2mat(MIN_DEV2)');
        MAX_DEV2 = string(cell2mat(MAX_DEV2)');
        AVG_DEV2 = string(cell2mat(AVG_DEV2)');
        % make output only if valid digits are found
        if size(MIN_DEV1,1)> 0 && size(MIN_DEV2,1) > 0
            
            T = table(ITERATIONS1, TIME_START1, TIME_END1, DURATION1, MIN_DEV1, MAX_DEV1, AVG_DEV1, MIN_DEV2, MAX_DEV2, AVG_DEV2, ...
                'VariableNames', {'ITERATIONS', 'TIME_START', 'TIME_END', 'DURATION', 'MIN_HR1', 'MAX_HR1', 'AVG_HR1', 'MIN_HR2','MAX_HR2','AVG_HR2'})
            T.Properties.VariableUnits = {'' 'sec' 'sec' 'sec' 'bpm' 'bpm' 'bpm' 'bpm' 'bpm', 'bpm'};
            filename = split(obj.Name, '.');

            % writetable(T, fullfile(pathname,strcat(string(filename(1)),'.csv')), 'Delimiter', ',');   % store to where the video is located
            writetable(T, strcat(fullfile(selpath,string(filename(1))), 'ROI-1', '.csv'), ...
                            'Delimiter',',');      % store to where specified
        else
            if size(MIN_DEV1,1) == 0
                error('[Error in HR device 1 for ROI 1] No valid digits within HR range [%i, %i] found',HR1_thresh1, HR1_thresh2)
            end
            if size(MIN_DEV2,1) == 0
                error('[Error in HR device 2 for ROI 1] No valid digits within HR range [%i, %i] found',HR2_thresh1, HR2_thresh2)
            end
            return
        end
    end
    
    % ROI 2
    if size(ITERATIONS2,1) > 0
        countROI2 = countROI2 - 1;
        % filter if all durations are less than 5 seconds
        if double(cell2mat(DURATION2(:,size(ITERATIONS2,1)))) < 5
            numIter = size(ITERATIONS2,1);
            ITERATIONS2(:,numIter) = {};
            TIME_START2(:,numIter) = {};
            TIME_END2(:,numIter) = {};
            DURATION2(:,numIter) = {};
            MIN_DEV1(:,numIter) = {};
            MAX_DEV1(:,numIter) = {};
            AVG_DEV1(:,numIter) = {};
            MIN_DEV2(:,numIter) = {};
            MAX_DEV2(:,numIter) = {};
            AVG_DEV2(:,numIter) = {};
        end
        
        % make tab% filter zeros for each countROI index (iteration)
        filteredHR1ROI2 = [];
        filteredHR2ROI2 = [];
        for i = 1:countROI2
            for j = 1:size(numDevice1_ROI2,2)
               if numDevice1_ROI2(i,j) > HR1_thresh1 && numDevice1_ROI2(i,j) < HR1_thresh2
                   if numDevice1_ROI2(i,j) ~= 0
                        filteredHR1ROI2(i,end+1) = numDevice1_ROI2(i,j);
                   end
               end
            end
            for j = 1:size(numDevice2_ROI2,2)
               if numDevice2_ROI2(i,j) > HR2_thresh1 && numDevice2_ROI2(i,j) < HR2_thresh2
                   if numDevice2_ROI2(i,j) ~= 0
                        filteredHR2ROI2(i,end+1) = numDevice2_ROI2(i,j);
                   end
               end
            end
        end        
        % output all read HRs to confirm
        filteredHR1ROI2
        filteredHR2ROI2
        save(strcat(fullfile(selpath,string(filename(1))), 'HR1_ROI2.mat'), 'filteredHR1ROI2')
        save(strcat(fullfile(selpath,string(filename(1))), 'HR2_ROI2.mat'), 'filteredHR2ROI2')
        
        % make table of equal-sized rows
        ITERATIONS2 = ITERATIONS2(:,1:countROI2);
        TIME_START2 = TIME_START2(:,1:countROI2);
        TIME_END2 = TIME_END2(:,1:countROI2);
        DURATION2 = DURATION2(:,1:countROI2);
        
        mins = [];
        maxes = [];
        for r = 1:size(filteredHR1ROI2,1)
            rowVec = filteredHR1ROI2(r,:);
            if isempty(rowVec(rowVec~=0))
                continue;
            end
            minRow = min(rowVec(rowVec~=0));
            maxRow = max(rowVec(rowVec~=0));
            mins(r,1) = minRow;
            maxes(r,1) = maxRow;
        end
        MIN_DEV1 = num2cell(mins)';
        MAX_DEV1 = num2cell(maxes)';
        
        mins = [];
        maxes = [];
        for r = 1:size(filteredHR2ROI2,1)
            rowVec = filteredHR2ROI2(r,:);
            if isempty(rowVec(rowVec~=0))
                continue;
            end
            minRow = min(rowVec(rowVec~=0));
            maxRow = max(rowVec(rowVec~=0));
            mins(r,1) = minRow;
            maxes(r,1) = maxRow;
        end
        MIN_DEV2 = num2cell(mins)';
        MAX_DEV2 = num2cell(maxes)';
           
        AVG_DEV1 = num2cell( round( sum(filteredHR1ROI2,2)./sum(filteredHR1ROI2~=0,2) ,4) )';
        AVG_DEV2 = num2cell( round( sum(filteredHR1ROI2,2)./sum(filteredHR1ROI2~=0,2) ,4) )';
        
        if size(filteredHR1ROI2, 1) > 0 && size(filteredHR2ROI2, 1) > 0
            % append the macro average in the last row
            ITERATIONS2(end, end+1) = num2cell(0);
            TIME_START2(end, end+1) = TIME_START2(1,1);
            TIME_END2(end, end+1) = TIME_END2(end,end);
            DURATION2(end, end+1) = num2cell(round(mean(double(cell2mat(DURATION2(end, 1:end)))),4));
            MIN_DEV1(end, end+1) = num2cell(round(mean(double(cell2mat(MIN_DEV1(end, 1:end)))),4));
            MAX_DEV1(end, end+1) = num2cell(round(mean(double(cell2mat(MAX_DEV1(end, 1:end)))),4));
            AVG_DEV1(end, end+1) = num2cell(round(mean(double(cell2mat(AVG_DEV1(end, 1:end)))),4));
            MIN_DEV2(end, end+1) = num2cell(round(mean(double(cell2mat(MIN_DEV2(end, 1:end)))),4));
            MAX_DEV2(end, end+1) = num2cell(round(mean(double(cell2mat(MAX_DEV2(end, 1:end)))),4));
            AVG_DEV2(end, end+1) = num2cell(round(mean(double(cell2mat(AVG_DEV2(end, 1:end)))),4));
        end
        
        ITERATIONS2 = string(cell2mat(ITERATIONS2)');
        TIME_START2 = string(TIME_START2(:));
        TIME_END2 = string(TIME_END2(:));  
        DURATION2 = string(cell2mat(DURATION2)');
        MIN_DEV1 = string(cell2mat(MIN_DEV1)');
        MAX_DEV1 = string(cell2mat(MAX_DEV1)');
        AVG_DEV1 = string(cell2mat(AVG_DEV1)');
        MIN_DEV2 = string(cell2mat(MIN_DEV2)');
        MAX_DEV2 = string(cell2mat(MAX_DEV2)');
        AVG_DEV2 = string(cell2mat(AVG_DEV2)');
        
        % make output only if valid digits are found
        if size(MIN_DEV1,1)> 0 && size(MIN_DEV2,1) > 0
            
            T = table(ITERATIONS2, TIME_START2, TIME_END2, DURATION2, MIN_DEV1, MAX_DEV1, AVG_DEV1, MIN_DEV2, MAX_DEV2, AVG_DEV2, ...
                'VariableNames', {'ITERATIONS', 'TIME_START', 'TIME_END', 'DURATION', 'MIN_HR1', 'MAX_HR1', 'AVG_HR1', 'MIN_HR2','MAX_HR2','AVG_HR2'})
            T.Properties.VariableUnits = {'' 'sec' 'sec' 'sec' 'bpm' 'bpm' 'bpm' 'bpm' 'bpm', 'bpm'};
            filename = split(obj.Name, '.');

            % writetable(T, fullfile(pathname,strcat(string(filename(1)),'.csv')), 'Delimiter', ',');   % store to where the video is located
            writetable(T, strcat(fullfile(selpath,string(filename(1))), 'ROI-2', '.csv'), ...
                            'Delimiter',',');      % store to where specified
        else
            if size(MIN_DEV1,1) == 0
                error('[Error in HR device 1 for ROI 2] No valid digits within HR range [%i, %i] found',HR1_thresh1, HR1_thresh2)
            end
            if size(MIN_DEV2,1) == 0
                error('[Error in HR device 2 for ROI 2] No valid digits within HR range [%i, %i] found',HR2_thresh1, HR2_thresh2)
            end
        end
    end
    
    % ROI 3
    if size(ITERATIONS3,1) > 0
        countROI3 = countROI3 - 1;
        % filter if all durations are less than 5 seconds
        if double(cell2mat(DURATION3(:,size(ITERATIONS3,1)))) < 5
            numIter = size(ITERATIONS3,1);
            ITERATIONS3(:,numIter) = {};
            TIME_START3(:,numIter) = {};
            TIME_END3(:,numIter) = {};
            DURATION3(:,numIter) = {};
            MIN_DEV1(:,numIter) = {};
            MAX_DEV1(:,numIter) = {};
            AVG_DEV1(:,numIter) = {};
            MIN_DEV2(:,numIter) = {};
            MAX_DEV2(:,numIter) = {};
            AVG_DEV2(:,numIter) = {};
        end
        
        % make tab% filter zeros for each countROI index (iteration)
        filteredHR1ROI3 = [];
        filteredHR2ROI3 = [];
        for i = 1:countROI3
            for j = 1:size(numDevice1_ROI3,2)
               if numDevice1_ROI3(i,j) > HR1_thresh1 && numDevice1_ROI3(i,j) < HR1_thresh2
                   if numDevice1_ROI3(i,j) ~= 0
                        filteredHR1ROI3(i,end+1) = numDevice1_ROI3(i,j);
                   end
               end
            end
            for j = 1:size(numDevice2_ROI3,2)
               if numDevice2_ROI3(i,j) > HR2_thresh1 && numDevice2_ROI3(i,j) < HR2_thresh2
                   if numDevice2_ROI3(i,j) ~= 0
                        filteredHR2ROI3(i,end+1) = numDevice2_ROI3(i,j);
                   end
               end
            end
        end             
        
        % output all read HRs to confirm
        filteredHR1ROI3
        filteredHR2ROI3
        save(strcat(fullfile(selpath,string(filename(1))), 'HR1_ROI3.mat'), 'filteredHR1ROI3')
        save(strcat(fullfile(selpath,string(filename(1))), 'HR2_ROI3.mat'), 'filteredHR2ROI3')
        
        % make table of equal-sized rows        
        ITERATIONS3 = ITERATIONS3(:,1:countROI3);
        TIME_START3 = TIME_START3(:,1:countROI3);
        TIME_END3 = TIME_END3(:,1:countROI3);
        DURATION3 = DURATION3(:,1:countROI3);
        
        mins = [];
        maxes = [];
        for r = 1:size(filteredHR1ROI3,1)
            rowVec = filteredHR1ROI3(r,:);
            if isempty(rowVec(rowVec~=0))
                continue;
            end
            minRow = min(rowVec(rowVec~=0));
            maxRow = max(rowVec(rowVec~=0));
            mins(r,1) = minRow;
            maxes(r,1) = maxRow;
        end
        MIN_DEV1 = num2cell(mins)';
        MAX_DEV1 = num2cell(maxes)';
            
        mins = [];
        maxes = [];
        for r = 1:size(filteredHR2ROI3,1)
            rowVec = filteredHR2ROI3(r,:);
            if isempty(rowVec(rowVec~=0))
                continue;
            end
            minRow = min(rowVec(rowVec~=0));
            maxRow = max(rowVec(rowVec~=0));
            mins(r,1) = minRow;
            maxes(r,1) = maxRow;
        end
        MIN_DEV2 = num2cell(mins)';
        MAX_DEV2 = num2cell(maxes)';
        AVG_DEV1 = num2cell( round( sum(filteredHR1ROI3,2)./sum(filteredHR1ROI3~=0,2) ,4) )';
        AVG_DEV2 = num2cell( round( sum(filteredHR1ROI3,2)./sum(filteredHR1ROI3~=0,2) ,4) )';
        
        if size(filteredHR1ROI3, 1) > 0 && size(filteredHR2ROI3, 1) > 0
            % append the macro average in the last row
            ITERATIONS3(end, end+1) = num2cell(0);
            TIME_START3(end, end+1) = TIME_START3(1,1);
            TIME_END3(end, end+1) = TIME_END3(end,end);
            DURATION3(end, end+1) = num2cell(round(mean(double(cell2mat(DURATION3(end, 1:end)))),4));
            MIN_DEV1(end, end+1) = num2cell(round(mean(double(cell2mat(MIN_DEV1(end, 1:end)))),4));
            MAX_DEV1(end, end+1) = num2cell(round(mean(double(cell2mat(MAX_DEV1(end, 1:end)))),4));
            AVG_DEV1(end, end+1) = num2cell(round(mean(double(cell2mat(AVG_DEV1(end, 1:end)))),4));
            MIN_DEV2(end, end+1) = num2cell(round(mean(double(cell2mat(MIN_DEV2(end, 1:end)))),4));
            MAX_DEV2(end, end+1) = num2cell(round(mean(double(cell2mat(MAX_DEV2(end, 1:end)))),4));
            AVG_DEV2(end, end+1) = num2cell(round(mean(double(cell2mat(AVG_DEV2(end, 1:end)))),4));
        end
        
        ITERATIONS3 = string(cell2mat(ITERATIONS3)');
        TIME_START3 = string(TIME_START3(:));
        TIME_END3 = string(TIME_END3(:));
        DURATION3 = string(cell2mat(DURATION3)');
        MIN_DEV1 = string(cell2mat(MIN_DEV1)');
        MAX_DEV1 = string(cell2mat(MAX_DEV1)');
        AVG_DEV1 = string(cell2mat(AVG_DEV1)');
        MIN_DEV2 = string(cell2mat(MIN_DEV2)');
        MAX_DEV2 = string(cell2mat(MAX_DEV2)');
        AVG_DEV2 = string(cell2mat(AVG_DEV2)');
        
        % make output only if valid digits are found
        if size(MIN_DEV1,1)> 0 && size(MIN_DEV2,1) > 0
            
            T = table(ITERATIONS3, TIME_START3, TIME_END3, DURATION3, MIN_DEV1, MAX_DEV1, AVG_DEV1, MIN_DEV2, MAX_DEV2, AVG_DEV2, ...
                'VariableNames', {'ITERATIONS', 'TIME_START', 'TIME_END', 'DURATION', 'MIN_HR1', 'MAX_HR1', 'AVG_HR1', 'MIN_HR2','MAX_HR2','AVG_HR2'})
            T.Properties.VariableUnits = {'' 'sec' 'sec' 'sec' 'bpm' 'bpm' 'bpm' 'bpm' 'bpm', 'bpm'};
            filename = split(obj.Name, '.');

            % writetable(T, fullfile(pathname,strcat(string(filename(1)),'.csv')), 'Delimiter', ',');   % store to where the video is located
            writetable(T, strcat(fullfile(selpath,string(filename(1))), 'ROI-3', '.csv'), ...
                            'Delimiter',',');      % store to where specified
        else
            if size(MIN_DEV1,1) == 0
                error('[Error in HR device 1 for ROI 3] No valid digits within HR range [%i, %i] found',HR1_thresh1, HR1_thresh2)
            end
            if size(MIN_DEV2,1) == 0
                error('[Error in HR device 2 for ROI 3] No valid digits within HR range [%i, %i] found',HR2_thresh1, HR2_thresh2)
            end
        end
    end
    
    % update GUI display
    rectangle('Position',[x_roi1(1), y_roi1(1), offset_roi1(1), offset_roi1(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'b', 'LineWidth', 3, 'LineStyle','-');
    if setROI2 == 1
        rectangle('Position',[x_roi2(1), y_roi2(1), offset_roi2(1), offset_roi2(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'b', 'LineWidth', 3, 'LineStyle','-');
    end
    if setROI3 == 1
        rectangle('Position',[x_roi3(1), y_roi3(1), offset_roi3(1), offset_roi3(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'b', 'LineWidth', 3, 'LineStyle','-');
    end
        rectangle('Position',[x_hr1(1), y_hr1(1), offset_hr1(1), offset_hr1(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'b', 'LineWidth', 3, 'LineStyle','-');
    rectangle('Position',[x_hr2(1), y_hr2(1), offset_hr2(1), offset_hr2(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'b', 'LineWidth', 3, 'LineStyle','-');

    message = sprintf('Saved to file: %s.xlsx', fullfile(selpath,strcat(string(filename(1)))));
    mh3 = msgbox(message,'END','help');
    th3 = findall(mh3, 'Type', 'Text');                   % get handle to text within msgbox
    th3.FontSize = 12;
    uiwait(mh3);
else
    return;
end
clear obj

function outputpath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to outputpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function outputpath_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to outputpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function outputpath_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to outputpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function outputpath_Callback(hObject, eventdata, handles)
% hObject    handle to outputpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function mainvideo_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to mainvideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function mainvideo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mainvideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function mainvideo_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to mainvideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function time_min_Callback(hObject, eventdata, handles)
% hObject    handle to time_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global time_min
time_min = str2double(get(handles.time_min, 'String'));
% Hints: get(hObject,'String') returns contents of time_min as text
%        str2double(get(hObject,'String')) returns contents of time_min as a double

% --- Executes during object creation, after setting all properties.
function time_min_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');

end

function time_sec_Callback(hObject, eventdata, handles)
% hObject    handle to time_sec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global time_sec
time_sec = str2double(get(handles.time_sec, 'String'));

% Hints: get(hObject,'String') returns contents of time_sec as text
%        str2double(get(hObject,'String')) returns contents of time_sec as a double

% --- Executes during object creation, after setting all properties.
function time_sec_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time_sec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function time_hr_Callback(hObject, eventdata, handles)
% hObject    handle to time_hr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of time_hr as text
%        str2double(get(hObject,'String')) returns contents of time_hr as a double
global time_hr
time_hr = str2double(get(handles.time_hr, 'String'));


% --- Executes during object creation, after setting all properties.
function time_hr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time_hr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function rep_count_Callback(hObject, eventdata, handles)
% hObject    handle to rep_count (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rep_count as text
%        str2double(get(hObject,'String')) returns contents of rep_count as a double
global rep_count
rep_count = str2double(get(handles.rep_count, 'String'));

% --- Executes during object creation, after setting all properties.
function rep_count_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rep_count (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in roi1.
function roi1_Callback(hObject, eventdata, handles)
% toggles global variable initialSensorBar

% hObject    handle to roi1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of roi1

% global initialSensorBar
% initialSensorBar = double(get(handles.roi1,'value'));
% if initialSensorBar == 0
%     set(handles.roi1, 'value', double(get(handles.roi1,'value')) + 1);
% end

global checkedROI1
if double(get(handles.roi3, 'Value')) == 1
   checkedROI1 = 1;
end

% --- Executes on button press in roi2.
function roi2_Callback(hObject, eventdata, handles)
% hObject    handle to roi2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of roi2
global checkedROI2
if double(get(handles.roi2, 'Value')) == 1
   checkedROI2 = 1;
end

% --- Executes on button press in roi3.
function roi3_Callback(hObject, eventdata, handles)
% hObject    handle to roi3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of roi3
global checkedROI3
if double(get(handles.roi3, 'Value')) == 1
   checkedROI3 = 1;
end
