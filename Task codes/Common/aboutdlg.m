function varargout = aboutdlg(varargin)
% ABOUTDLG Application M-file for untitled.fig
%   ABOUTDLG, by itself, creates a new ABOUTDLG or raises the existing
%   singleton*.
%
%   H = ABOUTDLG returns the handle to a new ABOUTDLG or the handle to
%   the existing singleton*.
%
%   ABOUTDLG('CALLBACK',hObject,eventData,handles,...) calls the local
%   function named CALLBACK in ABOUTDLG.M with the given input arguments.
%
%   ABOUTDLG('Property','Value',...) creates a new ABOUTDLG or raises the
%   existing singleton*.  Starting from the left, property value pairs are
%   applied to the GUI before aboutdlg_OpeningFunction gets called.  An
%   unrecognized property name or invalid value makes property application
%   stop.  All inputs are passed to aboutdlg_OpeningFcn via varargin.
%
%   *See GUI Options - GUI allows only one instance to run (singleton).
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help untitled

% Last Modified by GUIDE v2.5 04-Oct-2005 11:20:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',          mfilename, ...
                   'gui_Singleton',     gui_Singleton, ...
                   'gui_OpeningFcn',    @aboutdlg_OpeningFcn, ...
                   'gui_OutputFcn',     @aboutdlg_OutputFcn, ...
                   'gui_LayoutFcn',     [], ...
                   'gui_Callback',      []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    varargout{1:nargout} = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before aboutdlg is made visible.
function aboutdlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to aboutdlg (see VARARGIN)

% Choose default command line output for aboutdlg
handles.output = '';

% Update handles structure
guidata(hObject, handles);

img = zeros(100, 100);
% Insert custom Title and Text if specified by the user
if(nargin > 3)
    for index = 1:2:(nargin-3),
        switch lower(varargin{index})
            case 'title'
                set(hObject, 'Name', varargin{index+1});
            case 'string'
                set(handles.string, 'String', varargin{index+1});
            case 'image'
                img = varargin{index+1};
            otherwise
                error('Invalid input arguments');
        end
    end
end

% Determine the position of the dialog - centered on the callback figure
% if available, else, centered on the screen
FigPos=get(0,'DefaultFigurePosition');
tmp = get(hObject, 'Position');
FigWidth=tmp(3);
FigHeight=tmp(4);
if isempty(gcbf)
    ScreenUnits=get(0,'Units');
    set(0,'Units','points');
    ScreenSize=get(0,'ScreenSize');
    set(0,'Units',ScreenUnits);

    FigPos(1)=1/2*(ScreenSize(3)-FigWidth);
    FigPos(2)=2/3*(ScreenSize(4)-FigHeight);
else
    GCBFOldUnits = get(gcbf,'Units');
    set(gcbf,'Units','points');
    GCBFPos = get(gcbf,'Position');
    set(gcbf,'Units',GCBFOldUnits);
    FigPos(1:2) = [(GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2, ...
                   (GCBFPos(2) + GCBFPos(4) / 2) - FigHeight / 2];
end
FigPos(3:4)=[FigWidth FigHeight];
set(hObject, 'position', FigPos);

% Display figure
axes(handles.axes1);
ah=image(img);
set(gca, ...
    'Visible', 'off', ...
    'YDir'   ,'reverse'       , ...
    'XLim'   ,get(ah,'XData'), ...
    'YLim'   ,get(ah,'YData')  ...
    );

% UIWAIT makes aboutdlg wait for user response (see UIRESUME)
uiwait(handles.aboutdlg);

% --- Outputs from this function are returned to the command line.
function varargout = aboutdlg_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.aboutdlg);

% --- Executes on button press in ok_button.
function ok_button_Callback(hObject, eventdata, handles)
% hObject    handle to ok_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output = get(hObject,'String');

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.aboutdlg);


% --- Executes when user attempts to close aboutdlg.
function aboutdlg_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to aboutdlg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(handles.aboutdlg, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(handles.aboutdlg);
else
    % The GUI is no longer waiting, just close it
    delete(handles.aboutdlg);
end


% --- Executes on key press over aboutdlg with no controls selected.
function aboutdlg_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to aboutdlg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check for "enter" - do uiresume if we get it
if isequal(get(hObject,'CurrentKey'),'return')
    uiresume(handles.aboutdlg);
end    


