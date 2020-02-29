function varargout = build1(varargin)
% BUILD1 MATLAB code for build1.fig
%      BUILD1, by itself, creates a new BUILD1 or raises the existing
%      singleton*.
%
%      H = BUILD1 returns the handle to a new BUILD1 or the handle to
%      the existing singleton*.
%
%      BUILD1('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BUILD1.M with the given input arguments.
%
%      BUILD1('Property','Value',...) creates a new BUILD1 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before build1_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to build1_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% Edit the above text to modify the response to help build1

% Last Modified by GUIDE v2.5 24-Jul-2019 13:37:36

% Begin initialization code - DO NOT EDIT
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
    global pathname
    pathname = pwd;
    global selpath
    selpath = pwd;
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before build1 is made visible.
function build1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to build1 (see VARARGIN)

% Choose default command line output for build1
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes build1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = build1_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function setGlobalDetected(val)
global detected
detected = val; 

function r = getGlobalDetected
global detected
r = detected;

% --- Executes on button press in mistake.
function mistake_Callback(hObject, eventdata, handles)
% hObject    handle to mistake (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setGlobalDetected(0);
set(handles.status, 'String', '-');
set(handles.ongoing, 'String', '-');

% --- Executes on button press in loadbutton.
function loadbutton_Callback(hObject, eventdata, handles)
% hObject    handle to loadbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global pathname
[filename, pathname] = uigetfile('*.mp4', 'File Selector');
global selpath
set(handles.outputpath, 'String', selpath);

if ~ischar(filename)
    return;   %user canceled dialog
end
filepath = fullfile(pathname, filename);
set(handles.videopath, 'String', filepath);

addpath(genpath(pathname));

if ~exist(filepath, 'file')
    errorMessage = sprintf('Error: %s does not exist.', filepath);
    uiwait(warndlg(errorMessage));
    return
end
try
    obj = VideoReader(filename);
catch
    errorMessage = sprintf('Error: %s does not exist.', filepath);
    uiwait(warndlg(errorMessage));
    return
end
% obtain the first frame and display
orig = readFrame(obj);
image(orig, 'Parent', handles.ax1);
set(handles.ax1, 'Visible', 'off');
set(handles.ax1,'xtick',[])

% mouse callback - 1 (ROI)
message = sprintf('Draw a box for the region \n in which you would like \n to see motion changes.');
mh = msgbox(message,'Select Box 1 (ROI)','help');
th = findall(mh, 'Type', 'Text');                   %get handle to text within msgbox
th.FontSize = 12;
uiwait(mh);
k = waitforbuttonpress;
point1 = get(gca,'CurrentPoint');    % button down detected
finalRect = rbbox;                   % return figure units
point2 = get(gca,'CurrentPoint');    % button up detected
point1 = point1(1,1:2);              % extract x and y
point2 = point2(1,1:2);
p1 = min(point1,point2);             % calculate locations
offset = abs(point1-point2);         % and dimensions
x = round([p1(1), p1(1)+offset(1), p1(1)+offset(1), p1(1), p1(1)]);
y = round([p1(2), p1(2), p1(2)+offset(2), p1(2)+offset(2), p1(2)]);

% mouse callback - 2 (HR)
message = sprintf('Draw a box for the region \n in which you would like \n to read numbers.');
mh2 = msgbox(message,'Select Box 2 (Number)', 'help');
th2 = findall(mh2, 'Type', 'Text');                   %get handle to text within msgbox
th2.FontSize = 12;
uiwait(mh2);
k = waitforbuttonpress;
point1 = get(gca,'CurrentPoint');    % button down detected
finalRect = rbbox;                   % return figure units
point2 = get(gca,'CurrentPoint');    % button up detected
point1 = point1(1,1:2);              % extract x and y
point2 = point2(1,1:2);
p1 = min(point1,point2);             % calculate locations
offset_HR = abs(point1-point2);         % and dimensions
x_HR = round([p1(1), p1(1)+offset_HR(1), p1(1)+offset_HR(1), p1(1), p1(1)]);
y_HR = round([p1(2), p1(2), p1(2)+offset_HR(2), p1(2)+offset_HR(2), p1(2)]);

% Give a name to the title bar.
set(gcf, 'Name', filename, 'NumberTitle', 'Off')

if hasFrame(obj)
    global detected
    detected = 0;
    count = 1;
    status = '-';
    prev_diff = 0;
    timeStart = 0;
    timeEnd = 0;
    duration = 0;
    heartRates = [];
    min_HR = 0;
    max_HR = 0;
    mean_HR = 0;

    ITERATIONS = [];
    TIME_START = [];
    TIME_END = [];
    DURATION = [];
    MIN_HR = [];
    MAX_HR = [];
    AVG_HR = [];

    while hasFrame(obj)
        for i = 1:3
            if hasFrame(obj)
                readFrame(obj);
            else
                continue
            end
        end
        if hasFrame(obj)
            vidFrame = readFrame(obj);
        end
        image(vidFrame, 'Parent', handles.ax1);
        if ~detected
            rect = rectangle('Position',[x(1), y(1), offset(1), offset(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'r', 'LineWidth', 2, 'LineStyle','--');
            rect = rectangle('Position',[x_HR(1), y_HR(1), offset_HR(1), offset_HR(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'r', 'LineWidth', 2, 'LineStyle','--');
        else
            rect = rectangle('Position',[x(1), y(1), offset(1), offset(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'g', 'LineWidth', 3, 'LineStyle','-');
            rect = rectangle('Position',[x_HR(1), y_HR(1), offset_HR(1), offset_HR(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'g', 'LineWidth', 3, 'LineStyle','-');
        end
        origGray = rgb2gray(orig);
        vidFrameGray = rgb2gray(vidFrame);
        % crop image by selected roi
        origGray = imcrop(origGray, [x(1), y(1), offset(1), offset(2)]);
        currGray = imcrop(vidFrameGray, [x(1), y(1), offset(1), offset(2)]);
        hrGray = imcrop(vidFrameGray, [x_HR(1), y_HR(1), offset_HR(1), offset_HR(2)]);

    %     for display
        curr = imcrop(vidFrame, [x(1), y(1), offset(1), offset(2)]);
        hr = imcrop(vidFrame, [x_HR(1), y_HR(1), offset_HR(1), offset_HR(2)]);

        hrGrayCorrected =  imtophat(hrGray, strel('disk',15));
        marker = imerode(hrGrayCorrected, strel('line',10,0));
        hrGrayCorrectedClean = imreconstruct(marker, hrGrayCorrected);
        hrCrop = imbinarize(hrGrayCorrectedClean);
        readHeartRate = ocr(hrCrop, 'TextLayout','Block');
        % read only if in digit format
        regularExpr = '\d*';
        heartRate = regexp(readHeartRate.Text, regularExpr, 'match');
        % if not convertible to number, set it to 0 to be safe
        try
            heartRate = str2double(strcat(heartRate{:}));
        catch
            heartRate = 0;
        end
        if class(heartRate)=='double'
            heartRates(count,end+1) = heartRate;
        end
        % Structural similarity index    
        ssimVal = ssim(origGray, currGray);

        % get number of pixels not zero
        orig_pixels = numel(origGray);
        orig_nonzero = length(origGray(origGray~=0));
        curr_pixels = numel(currGray);
        curr_nonzero = length(currGray(currGray~=0));
        
        % get the number of different pixels in differential frame
        % and compare against the previous different pixel number,
        % as well as similiarity index
        % STARTING condition
        diff = abs(orig_nonzero - curr_nonzero);
        if (((diff-prev_diff)>10)&(ssimVal<0.7))&(detected==0)
            detected = 1;
            status = 'START';
            timeStart = obj.CurrentTime;
            TIME_START(1,count) = timeStart;
        % END condition
        elseif (((diff-prev_diff)<10)&(ssimVal>0.85))&(detected==1)
            format short;
            detected = 0;
            status = 'END';
            ITERATIONS(1,count) = count;
            set(handles.ongoing, 'String', '-');

            format short;
            timeEnd = obj.CurrentTime;
            TIME_END(1,count) = timeEnd;
            duration = timeEnd - timeStart;
            DURATION(1,count) = duration;

            heartRates = heartRates(count,:);
            hrlist = heartRates(heartRates>50);
            hrlist = hrlist(hrlist<180);
            minhr = min(hrlist);
            maxhr = max(hrlist);
            meanhr = mean(hrlist);

            MIN_HR(1,count) = minhr;
            MAX_HR(1,count) = maxhr;
            AVG_HR(1,count) = meanhr;
            result = [ITERATIONS(end,count), TIME_START(end,count), TIME_END(end,count), DURATION(end,count), MIN_HR(end,count), MAX_HR(end,count),AVG_HR(end,count)];
            set(handles.result_table, 'Data', result);
            set(handles.result_table, 'ColumnName',{'Iteration'; 'TIME_START'; 'TIME_END'; 'DURATION'; 'MIN_HR'; 'MAX_HR'; 'AVG_HR'});

            count = count + 1;
        % In Motion condition
        elseif (detected==1)
            set(handles.ongoing, 'String', '-IN MOTION-');
            set(handles.heartrate, 'String', heartRate);

            image(curr, 'Parent', handles.current_image); 
            image(hr, 'Parent', handles.heartrate_image);
            title(handles.current_image, 'Current');
            title(handles.heartrate_image, strcat('Number: ',num2str(heartRates(count,end))));
            set(handles.current_image,'xtick',[])
            set(handles.heartrate_image,'xtick',[])
        end
        set(handles.status, 'String', status);

        set(handles.count, 'String', count);
        set(handles.ax1, 'Visible', 'off');
        pause(1/obj.FrameRate);
        prev_diff = diff;
        set(handles.currenttime, 'String',obj.CurrentTime);    
    end
    if size(ITERATIONS,1)>0
        % note the average
        ITERATIONS(end, end+1) = 0;
        TIME_START(end, end+1) = 0;
        TIME_END(end, end+1) = 0;
        DURATION(end, end+1) = mean(DURATION(end, 1:end));
        MIN_HR(end, end+1) = mean(MIN_HR(end, 1:end));
        MAX_HR(end, end+1) = mean(MAX_HR(end, 1:end));
        AVG_HR(end, end+1) = mean(AVG_HR(end, 1:end));

        % round to the nearest 4 digits after decimal point
        ITERATIONS = round(ITERATIONS(end,:)',4);
        TIME_START = round(TIME_START(end,:)',4);
        TIME_END = round(TIME_END(end,:)',4);
        DURATION = round(DURATION(end,:)',4);
        MIN_NUMBER = round(MIN_HR(end,:)',4);
        MAX_NUMBER = round(MAX_HR(end,:)',4);
        AVG_NUMBER = round(AVG_HR(end,:)',4);

        T = table(ITERATIONS, TIME_START, TIME_END, DURATION, MIN_NUMBER, MAX_NUMBER, AVG_NUMBER, 'VariableNames', {'ITERATIONS', 'TIME_START', 'TIME_END', 'DURATION', 'MIN_NUMBER', 'MAX_NUMBER', 'AVG_NUMBER'})

        filename = split(obj.Name, '.');
    %     writetable(T, fullfile(pathname,strcat(string(filename(1)),'.csv')), 'Delimiter', ',');   % store to where the video is located
        writetable(T, fullfile(selpath,strcat(string(filename(1)),'.csv')), 'Delimiter', ',');      % store to where specified

        rect = rectangle('Position',[x(1), y(1), offset(1), offset(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'b', 'LineWidth', 3, 'LineStyle','-');
        rect = rectangle('Position',[x_HR(1), y_HR(1), offset_HR(1), offset_HR(2)],'Curvature',[0.1,0.1], 'EdgeColor', 'b', 'LineWidth', 3, 'LineStyle','-');
        
        message = sprintf('Video Finished.');
        mh3 = msgbox(message,'END','help');
        th3 = findall(mh3, 'Type', 'Text');                   % get handle to text within msgbox
        th3.FontSize = 12;
        uiwait(mh3);
    else
        message = sprintf('No complete rep found.');
        mh3 = msgbox(message,'END','error');
        th3 = findall(mh3, 'Type', 'Text');                   % get handle to text within msgbox
        th3.FontSize = 12;
        uiwait(mh3);
    end
end
clear obj


% --- Executes on button press in outputbutton.
function outputbutton_Callback(hObject, eventdata, handles)
% hObject    handle to outputbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global pathname
global selpath
selpath = uigetdir(pathname);
set(handles.outputpath, 'String', selpath);


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

function ax1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to ax1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function ax1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ax1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function ax1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to ax1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
