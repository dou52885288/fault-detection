function AlarmConfig(varargin)
%% Help
% AlarmConfig(in_data, n_normal)

%% Get Started
switch length(varargin)
    case 0
       in_data = [random('normal', 0, 1, 1000, 1); random('normal', 2, 2, 1000, 1)];
%        load('Weifang_data_in_Paper.mat')
        n_normal = 1000;
    otherwise
        in_data = varargin{1};
        n_normal = varargin{2};
        n_data = length(in_data);
end
if n_normal < n_data
    is_faulty = 1;
else
    is_faulty = 0;
end
%% Initialize Parameters

design_data = in_data;

HAL_raise = {inf;inf}; HAL_DB = {0;0};
HAL_clear = {inf;inf}; is_deadband_HAL = {0;0};

LAL_raise = {-inf;-inf}; LAL_DB = {0;0};
LAL_clear = {-inf;-inf}; is_deadband_LAL = {0;0};

alpha = 0.05;
delay_on = {1;1}; delay_off = {1;1};
alarm_report = {zeros(20,1);zeros(20,1)};

alarm_time_hi = {[];[]}; alarm_time_lo = {[];[]}; 
RTN_time_hi = {[];[]};  RTN_time_lo = {[];[]}; 
p1_HAL = {[];[]}; p2_HAL = {[];[]};
q1_HAL = {[];[]}; q2_HAL = {[];[]};
p1_LAL = {[];[]}; p2_LAL = {[];[]};
q1_LAL = {[];[]}; q2_LAL = {[];[]};
FAR_HAL = {[];[]}; MAR_HAL = {[];[]}; ADD_HAL = {[];[]};
FAR_LAL = {[];[]}; MAR_LAL = {[];[]}; ADD_LAL = {[];[]};
FAR = []; MAR = []; ADD = [];

h_data_normal = {[];[]}; h_data_faulty = {[];[]};
h_bins_normal = {[];[]}; h_bins_faulty = {[];[]};
h_pdf_normal = {[];[]}; h_pdf_faulty = {[];[]};
h_line_HAL_raise = {[];[]}; h_line_HAL_clear = {[];[]};
h_line_LAL_raise = {[];[]}; h_line_LAL_clear = {[];[]};   
h_hist_HAL_raise = {[];[]}; h_hist_HAL_clear = {[];[]};
h_hist_LAL_raise = {[];[]}; h_hist_LAL_clear = {[];[]};   
h_alarms = {[];[]}; 
h_compare = []; h_cmp_axes = {[];[];[];[]};
h_cmp_table = []; cmp_id = 0; cmp_data = nan*ones(4,13);

alpha_HAL = 0.05; alpha_LAL = 0.05;
user_HAL = inf; user_LAL = -inf;
deadband_percent_HAL = 0.05; deadband_percent_LAL = 0.05;
deadband_user_HAL = 0.0; deadband_user_LAL = 0.0;

HALcmp_raise={[];[];[]}; LALcmp_raise={[];[];[]};
delaycmp_on={[];[];[]};delaycmp_off={[];[];[]};
alm_db={[];[];[]};
data_desn ={[];[];[]};

filter_type ='None';
filter_MA_par = 10;
filter_MV_par = 15;
filter_MN_par = 20;
filter_EWMA_order = 1;
filter_EWMA_const = 0.1;
filter_USER_par = 'mean(x(i-9:i))';
filter_LP_timeconst = 10;
filter_LP_samplingtime = 1;
filter_Ranksize_par = 5;
filter_Rankorder_par = 1;

color_normal = 'b';
color_faulty = 'c';
color_alarm = 'r';

%% Construct the GUI
defaultBackground = get(0, 'defaultUicontrolBackgroundColor');
%width = 1050; height = 650;
width_data = 450; height_data = 180;
width_hist = 220; height_hist = 180;
left_margin = 20; bottom_margin = 20; right_margin = 30; top_margin = 20; 
gap_hmargin = 40; gap_vmargin = 10;
width_panel = 235; height_alarm = 60;
height_panel1 = 180; height_panel2 = 420;
width = left_margin + width_panel+ gap_hmargin + width_data + gap_hmargin + width_hist + right_margin;
height = bottom_margin + 2*height_data + 10*gap_vmargin + 2*height_alarm+40;

pos_main = CenterFigure(width, height);
size_main = [pos_main(3:4) pos_main(3:4)];
h_main = figure('Position', pos_main, ...
            'Name', 'Alarm Configuration Analysis', 'NumberTitle', 'off', ...
            'Resize', 'on', 'MenuBar', 'none', ...
            'Color', defaultBackground, ...
            'Toolbar', 'auto', ...
            'CloseRequestFcn', @close_request, ...
            'Visible', 'on', ...
            'WindowStyle', 'normal');

set(h_main, 'Color', defaultBackground)

%% Constructign data plots and PDF plots
pos_data{1} = [left_margin+width_panel+gap_hmargin, bottom_margin+height_data+8*gap_vmargin+2*height_alarm+40, width_data, height_data];
pos_hist{1} = [left_margin+width_panel+gap_hmargin+width_data+gap_hmargin, bottom_margin+height_data+8*gap_vmargin+2*height_alarm+40, width_hist, height_hist];
h_axes{1} = axes('Units', 'normalized', ...
    'NextPlot', 'add', 'Box', 'on', ...
    'XTick', [], 'YTick', [], ...
    'Position', pos_data{1}./size_main);
h_hist{1} = axes('Units', 'normalized', 'Box', 'on', ...
    'Position', pos_hist{1}./size_main, ...
    'XTick', [], 'YTick', [], ...
    'NextPlot', 'add');

pos_data{2} = [left_margin+width_panel+gap_hmargin, bottom_margin+gap_vmargin, width_data, height_data];
pos_hist{2} = [left_margin+width_panel+gap_hmargin+width_data+gap_hmargin, bottom_margin+gap_vmargin, width_hist, height_hist];
h_axes{2} = axes('Units', 'normalized', ...
    'NextPlot', 'add', 'Box', 'on', ...
    'XTick', [], 'YTick', [], ...
    'Position', pos_data{2}./size_main);
h_hist{2} = axes('Units', 'normalized', 'Box', 'on', ...
    'Position', pos_hist{2}./size_main, ...
    'XTick', [], 'YTick', [], ...
    'NextPlot', 'add');

%% Alarm plots
%pos_alm{1} = [left_margin+width_panel+gap_hmargin, bottom_margin+height_data+5*gap_vmargin+height_alarm+20, width_data, height_alarm];
%h_alm{1} = axes('Units', 'normalized', ...
%    'NextPlot', 'add', 'Box', 'on', ...
%    'XTick', [], 'YTick', [], ...
%    'Position', pos_alm{1}./size_main);
%pos_alm{2} = [left_margin+width_panel+gap_hmargin, bottom_margin+height_data+3*gap_vmargin+15, width_data, height_alarm];
%h_alm{2} = axes('Units', 'normalized', ...
%    'NextPlot', 'add', 'Box', 'on', ...
%    'XTick', [], 'YTick', [], ...
%    'Position', pos_alm{2}./size_main);

%% Alarm performance
pos_alarmshow{1} = [left_margin+width_panel+gap_hmargin, bottom_margin+height_data+8*gap_vmargin+2*height_alarm-15, width_data+10, 25];
size_alarmshow{1} = [pos_alarmshow{1}(3:4) pos_alarmshow{1}(3:4)];
h_alarmshow{1} = uipanel('Parent', h_main, ...
    'BorderType', 'none',...
    'Position', pos_alarmshow{1}./size_main);
uicontrol('Parent', h_alarmshow{1}, ...
    'Style', 'text', ...
    'String' , 'Current: ', ...
    'ForegroundColor','b',...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [5, 2, 60, 15]./size_alarmshow{1});
uicontrol('Parent', h_alarmshow{1}, ...
    'Style', 'text', ...
    'String' , 'HAL_raise:', ...
    'ForegroundColor','r',...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [60, 2, 60, 15]./size_alarmshow{1});
h_text_HAL{1} = uicontrol('Parent', h_alarmshow{1}, ...
    'Style', 'text', ...
    'String' , ' ', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [120, 2, 40, 15]./size_alarmshow{1});
uicontrol('Parent', h_alarmshow{1}, ...
    'Style', 'text', ...
    'String' , 'HAL_clear:', ...
    'ForegroundColor','r',...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [160, 2, 60, 15]./size_alarmshow{1});
h_text_HAL_DB{1} = uicontrol('Parent', h_alarmshow{1}, ...
    'Style', 'text', ...
    'String' , '', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [220, 2, 40, 15]./size_alarmshow{1});
uicontrol('Parent', h_alarmshow{1}, ...
    'Style', 'text', ...
    'String' , 'LAL_raise:', ...
    'ForegroundColor','r',...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [260, 2, 60, 15]./size_alarmshow{1});
h_text_LAL{1} = uicontrol('Parent', h_alarmshow{1}, ...
    'Style', 'text', ...
    'String' , ' ', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [320, 2, 40, 15]./size_alarmshow{1});
uicontrol('Parent', h_alarmshow{1}, ...
    'Style', 'text', ...
    'String' , 'LAL_clear:', ...
    'ForegroundColor','r',...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [360, 2, 60, 15]./size_alarmshow{1});
h_text_LAL_DB{1} = uicontrol('Parent', h_alarmshow{1}, ...
    'Style', 'text', ...
    'String' , '', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [420, 2, 40, 15]./size_alarmshow{1});

pos_alarmshow{2} = [left_margin+width_panel+gap_hmargin, bottom_margin+height_data+15, width_data+10, 25];
size_alarmshow{2} = [pos_alarmshow{2}(3:4) pos_alarmshow{2}(3:4)];
h_alarmshow{2} = uipanel('Parent', h_main, ...
    'BorderType', 'none',...
    'Position', pos_alarmshow{2}./size_main);
uicontrol('Parent', h_alarmshow{2}, ...
    'Style', 'text', ...
    'String' , 'Design: ', ...
    'ForegroundColor','b',...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [5, 2, 60, 15]./size_alarmshow{2});
uicontrol('Parent', h_alarmshow{2}, ...
    'Style', 'text', ...
    'String' , 'HAL_raise:', ...
    'ForegroundColor','r',...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [60, 2, 60, 15]./size_alarmshow{2});
h_text_HAL{2} = uicontrol('Parent', h_alarmshow{2}, ...
    'Style', 'text', ...
    'String' , ' ', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [120, 2, 40, 15]./size_alarmshow{2});
uicontrol('Parent', h_alarmshow{2}, ...
    'Style', 'text', ...
    'String' , 'HAL_clear:', ...
    'ForegroundColor','r',...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [160, 2, 60, 15]./size_alarmshow{2});
h_text_HAL_DB{2} = uicontrol('Parent', h_alarmshow{2}, ...
    'Style', 'text', ...
    'String' , '', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [220, 2, 40, 15]./size_alarmshow{2});
uicontrol('Parent', h_alarmshow{2}, ...
    'Style', 'text', ...
    'String' , 'LAL_raise:', ...
    'ForegroundColor','r',...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [260, 2, 60, 15]./size_alarmshow{2});
h_text_LAL{2} = uicontrol('Parent', h_alarmshow{2}, ...
    'Style', 'text', ...
    'String' , ' ', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [320, 2, 40, 15]./size_alarmshow{2});
uicontrol('Parent', h_alarmshow{2}, ...
    'Style', 'text', ...
    'String' , 'LAL_clear:', ...
    'ForegroundColor','r',...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [360, 2, 60, 15]./size_alarmshow{2});
h_text_LAL_DB{2} = uicontrol('Parent', h_alarmshow{2}, ...
    'Style', 'text', ...
    'String' , '', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [420, 2, 40, 15]./size_alarmshow{2});

cnames1 = {'Total Alarms','HI_ALM','LO_ALM','False Alarms','HI_False','LO_False'};
rnames = {'Current','Design'};
h_table1 = uitable('Parent', h_main, ...
    'RowName', rnames, 'ColumnName', cnames1, ...
    'FontSize',10, 'Units', 'normalized', ...
    'Position', [left_margin+width_panel+gap_hmargin 315 width_data+width_hist+gap_hmargin 62]./size_main);
cnames2 = {'Duration of Alarms','D. HI_ALM','D. LO_ALM','D. False_ALM','D. Missed_ALM','% of False_ALM','% of Missed_ALM'};
h_table2 = uitable('Parent', h_main, ...
    'FontSize',10, 'Units', 'normalized', ...
    'RowName', rnames, 'ColumnName', cnames2, ...
    'Position', [left_margin+width_panel+gap_hmargin 310-65 width_data+width_hist+gap_hmargin 62]./size_main);

%% Current alarm setting
pos_bg_method = [left_margin, bottom_margin+gap_vmargin+height_panel2, width_panel, height_panel1];
size_bg_method = [pos_bg_method(3:4) pos_bg_method(3:4)];
h_bg_method = uibuttongroup('Parent', h_main, ...
    'Position', pos_bg_method./size_main, ...
    'Title','Current Alarm Setting', ...
    'ForegroundColor', 'r', 'BorderType', 'beveledout', ...
    'Fontsize', 11, 'SelectionChangeFcn', @callback_bg_method);

uicontrol('Parent', h_bg_method, ...
    'Style', 'radiobutton', ...
    'String', 'Current alarm limits', ...
    'Units', 'normalized', ...
    'Position', [10 145 150 25]./size_bg_method);

uicontrol('Parent', h_bg_method, ...
    'Style', 'radiobutton', ...
    'String', 'Alarm rate (%):', ...
    'Units', 'normalized', ...
    'Enable', 'on', ...
    'Position', [10 115 150 25]./size_bg_method);

uicontrol('Parent', h_bg_method, ...
    'Style', 'radiobutton', ...
    'String', 'User defined:', ...
    'Units', 'normalized', ...
    'Enable', 'on', ...
    'Position', [10 85 150 25]./size_bg_method);

h_edit_alpha = uicontrol('Parent', h_bg_method, ...
    'Style', 'edit', ...
    'String', num2str(100*alpha), ...
    'Units', 'normalized', ...
    'Position', [110 118 40 18]./size_bg_method, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Enable', 'off', ...
    'Callback', @callback_edit_alpha);

uicontrol('Parent', h_bg_method, ...
    'Style', 'text', ...
    'String' , 'HAL:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [18, 62, 60, 15]./size_bg_method);

h_edit_HAL = uicontrol('Parent', h_bg_method, ...
    'Style', 'edit', ...
    'String', num2str(HAL_raise{1}), ...
    'Units', 'normalized', ...
    'Position', [70 60 40 18]./size_bg_method, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Enable', 'off', ...
    'Callback', @callback_edit_HAL);

uicontrol('Parent', h_bg_method, ...
    'Style', 'text', ...
    'String' , 'HAL-DB:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [125, 62, 70, 15]./size_bg_method);

h_edit_HAL_DB = uicontrol('Parent', h_bg_method, ...
    'Style', 'edit', ...
    'String', num2str(HAL_DB{1}), ...
    'Units', 'normalized', ...
    'Position', [185 60 40 18]./size_bg_method, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Enable', 'off', ...
    'Callback', @callback_edit_HAL_DB);

uicontrol('Parent', h_bg_method, ...
    'Style', 'text', ...
    'String' , 'LAL:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [18, 35, 60, 15]./size_bg_method);

h_edit_LAL = uicontrol('Parent', h_bg_method, ...
    'Style', 'edit', ...
    'String', num2str(LAL_raise{1}), ...
    'Units', 'normalized', ...
    'Position', [70 35 40 18]./size_bg_method, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Enable', 'off', ...
     'Callback', @callback_edit_LAL);

uicontrol('Parent', h_bg_method, ...
    'Style', 'text', ...
    'String' , 'LAL-DB:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [125, 35, 60, 15]./size_bg_method);

h_edit_LAL_DB = uicontrol('Parent', h_bg_method, ...
    'Style', 'edit', ...
    'String', num2str(LAL_DB{1}), ...
    'Units', 'normalized', ...
    'Position', [185 33 40 18]./size_bg_method, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Enable', 'off', ...
    'Callback', @callback_edit_LAL_DB);

uicontrol('Parent', h_bg_method, ...
    'Style', 'text', ...
    'String' , 'ON-delay:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [18, 10, 60, 15]./size_bg_method);

h_edit_ondelay = uicontrol('Parent', h_bg_method, ...
    'Style', 'edit', ...
    'String', num2str(delay_on{1}), ...
    'Units', 'normalized', ...
    'Position', [70 8 40 18]./size_bg_method, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Enable', 'off', ...
     'Callback', @callback_edit_ondelay);

uicontrol('Parent', h_bg_method, ...
    'Style', 'text', ...
    'String' , 'OFF-delay:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [125, 10, 60, 15]./size_bg_method);

h_edit_offdelay = uicontrol('Parent', h_bg_method, ...
    'Style', 'edit', ...
    'String', num2str(delay_off{1}), ...
    'Units', 'normalized', ...
    'Position', [185 8 40 18]./size_bg_method, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Enable', 'off', ...
     'Callback', @callback_edit_offdelay);

%% Alarm configuration
pos_panel_design = [left_margin, bottom_margin, width_panel, height_panel2];
size_panel_design = [pos_panel_design(3:4) pos_panel_design(3:4)];
h_panel_design = uipanel('Parent', h_main, ...
    'Position', pos_panel_design./size_main, ...
    'BorderType', 'beveledout',...
    'Title','Alarm Configuration', 'Fontsize',11, ...
    'ForegroundColor', 'r');

h_pb_plotroc = uicontrol('Parent', h_panel_design, ...
    'Style', 'pushbutton', ...
    'String', 'Plot ROC', ...
    'Units', 'normalized', ...
    'Position', [5 5 60 25]./size_panel_design, ...
    'Enable','off',...
    'Callback', @callback_plotroc);

h_pb_optimize = uicontrol('Parent', h_panel_design, ...
    'Style', 'pushbutton', ...
    'String', 'Interactive Design', ...
    'Units', 'normalized', ...
    'Position', [65 5 105 25]./size_panel_design, ...
    'Enable','off',...
    'Callback', @callback_optimize);

h_pb_compare = uicontrol('Parent', h_panel_design, ...
    'Style', 'pushbutton', ...
    'String', 'Compare', ...
    'Units', 'normalized', ...
    'Position', [170 5 60 25]./size_panel_design, ...
    'Enable','on',...
    'Callback', @callback_compare);

%% Time Delay
pos_panel_delay = [5, 120, 225, 70];
size_panel_delay = [pos_panel_delay(3:4) pos_panel_delay(3:4)];
h_panel_delay = uipanel('Parent', h_panel_design, ...
    'Position', pos_panel_delay./size_panel_design, ...
    'Title', ' Delay Timer ', ...
    'BorderType', 'etchedin', ...
    'ForegroundColor', [0 0 1]);

h_pb_delayopt = uicontrol('Parent', h_panel_delay, ...
    'Style', 'pushbutton', ...
    'String', 'Optimize Delays', ...
    'Units', 'normalized', ...
    'Enable','off',...
    'Position', [65 5 90 30]./size_panel_delay, ...
    'Callback', @ALMdelay_opt); 

uicontrol('Parent', h_panel_delay, ...
    'Style', 'text', ...
    'String' , 'ON-delay:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [10, 48, 55, 20]./size_panel_delay);
h_edit_delay_on = uicontrol('Parent', h_panel_delay, ...
    'Style', 'edit', ...
    'String', num2str(delay_on{2}), 'Units', 'normalized', ...
    'Position', [65 45 40 25]./size_panel_delay, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Enable','off',...
    'Callback', @callback_edit_delay_on);
uicontrol('Parent', h_panel_delay, ...
    'Style', 'text', ...
    'String' , 'OFF-delay:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [120, 48, 55, 20]./size_panel_delay);
h_edit_delay_off = uicontrol('Parent', h_panel_delay, ...
    'Style', 'edit', ...
    'String', num2str(delay_off{2}), 'Units', 'normalized', ...
    'Position', [180 45 40 25]./size_panel_delay, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Enable','off',...
    'Callback', @callback_edit_delay_off);

%% Deadband
pos_panel_deadband = [5, 35, 225, 80];
size_panel_deadband = [pos_panel_deadband(3:4) pos_panel_deadband(3:4)];
h_panel_deadband = uipanel('Parent', h_panel_design, ...
    'Position', pos_panel_deadband./size_panel_design, ...
    'Title', ' Deadband ', ...
    'BorderType', 'etchedin', ...
    'ForegroundColor', [0 0 1]);

% h_text_deadband_HAL =
uicontrol('Parent', h_panel_deadband, ...
    'Style', 'text', 'String' , 'HAL:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [10, 40, 30, 20]./size_panel_deadband);
h_pm_deadband_HAL = uicontrol('Parent', h_panel_deadband, ...
    'Style', 'popupmenu', 'String', 'None', ...
    'Units', 'normalized', ...
    'Enable','off',...
    'Position', [40, 46, 135, 20]./size_panel_deadband, ...
    'Callback', @callback_pm_deadband_HAL);
h_edit_deadband_percent_HAL = uicontrol('Parent', h_panel_deadband, ...
    'Style', 'edit', ...
    'String', num2str(deadband_percent_HAL), 'Units', 'normalized', ...
    'Position', [180 40 40 25]./size_panel_deadband, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_deadband_percent_HAL);
h_edit_deadband_user_HAL = uicontrol('Parent', h_panel_deadband, ...
    'Style', 'edit', ...
    'Units', 'normalized', ...
    'Position', [180 40 40 25]./size_panel_deadband, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'String', num2str(deadband_user_HAL), ...
    'Visible', 'off', ...
    'Callback', @callback_edit_deadband_user_HAL);

% h_text_method_LAL =
uicontrol('Parent', h_panel_deadband, ...
    'Style', 'text', 'String' , 'LAL:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [10, 10, 30, 20]./size_panel_deadband);
h_pm_deadband_LAL = uicontrol('Parent', h_panel_deadband, ...
    'Style', 'popupmenu', 'String', 'None', ...
    'Units', 'normalized', ...
    'Enable','off',...
    'Position', [40, 16, 135, 20]./size_panel_deadband, ...
    'Callback', @callback_pm_deadband_LAL);
h_edit_deadband_percent_LAL = uicontrol('Parent', h_panel_deadband, ...
    'Style', 'edit', ...
    'String', num2str(deadband_percent_LAL), ...
    'Units', 'normalized', ...
    'Position', [180 10 40 25]./size_panel_deadband, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_deadband_percent_LAL);
h_edit_deadband_user_LAL = uicontrol('Parent', h_panel_deadband, ...
    'Style', 'edit', ...
    'Units', 'normalized', ...
    'String', num2str(deadband_user_LAL), ...
    'Position', [180 10 40 25]./size_panel_deadband, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_deadband_user_LAL);

%% Alarm Limit
pos_panel_alarmlimit = [5, 200, 225, 100];
size_panel_alarmlimits = [pos_panel_alarmlimit(3:4) pos_panel_alarmlimit(3:4)];
h_panel_alarmlimits = uipanel('Parent', h_panel_design, ...
    'Position', pos_panel_alarmlimit./size_panel_design, ...
    'Title', 'Alarm Limits', ...
    'BorderType', 'etchedin', ...
    'ForegroundColor', [0 0 1]);

h_pb_almclear = uicontrol('Parent', h_panel_alarmlimits, ...
    'Style', 'pushbutton', ...
    'String', 'Clear', ...
    'Units', 'normalized', ...
    'Enable', 'off',...
    'Position', [150 5 70 30]./size_panel_alarmlimits, ...
    'Callback', @callback_pb_almclear); 
%% Optimize Alarm Limits
h_pb_almopt = uicontrol('Parent', h_panel_alarmlimits, ...
    'Style', 'pushbutton', ...
    'String', 'Optimize ALM Limits', ...
    'Units', 'normalized', ...
    'Enable', 'off',...
    'Position', [40 5 110 30]./size_panel_alarmlimits, ...
    'Callback', @ALMlimit_opt); 

uicontrol('Parent', h_panel_alarmlimits, ...
    'Style', 'text', 'String' , 'HAL:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [10, 70, 30, 20]./size_panel_alarmlimits);
h_pm_method_HAL = uicontrol('Parent', h_panel_alarmlimits, ...
    'Style', 'popupmenu', 'String', {'Alarm rate (%)'}, ...
    'Units', 'normalized', ...
    'Position', [40, 75, 135, 20]./size_panel_alarmlimits, ...
    'Callback', @callback_pm_method_HAL);
h_edit_alpha_HAL = uicontrol('Parent', h_panel_alarmlimits, ...
    'Style', 'edit', ...
    'String', '', 'Units', 'normalized', ...
    'Position', [180 70 40 25]./size_panel_alarmlimits, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_alpha_HAL);
h_edit_user_HAL = uicontrol('Parent', h_panel_alarmlimits, ...
    'Style', 'edit', ...
    'String', [], 'Units', 'normalized', ...
    'Position', [180 70 40 25]./size_panel_alarmlimits, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Callback', @callback_edit_HAL_user, ...
    'Visible', 'off');

% h_text_method_LAL =
uicontrol('Parent', h_panel_alarmlimits, ...
    'Style', 'text', 'String' , 'LAL:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [10, 43, 30, 20]./size_panel_alarmlimits);
h_pm_method_LAL = uicontrol('Parent', h_panel_alarmlimits, ...
    'Style', 'popupmenu', 'String', {'Alarm rate (%)'}, ...
    'Units', 'normalized', ...
    'Position', [40, 48, 135, 20]./size_panel_alarmlimits, ...
    'Callback', @callback_pm_method_LAL);
h_edit_alpha_LAL = uicontrol('Parent', h_panel_alarmlimits, ...
    'Style', 'edit', ...
    'String', '', 'Units', 'normalized', ...
    'Position', [180 40 40 25]./size_panel_alarmlimits, ...
    'Visible', 'off', ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Callback', @callback_edit_alpha_LAL);
h_edit_user_LAL = uicontrol('Parent', h_panel_alarmlimits, ...
    'Style', 'edit', ...
    'String', [], 'Units', 'normalized', ...
    'Position', [180 40 40 25]./size_panel_alarmlimits, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Callback', @callback_edit_LAL_user, ...
    'Visible', 'off');

%% Filter
pos_panel_filter = [5, 305, 225, 100];
size_panel_filter = [pos_panel_filter(3:4) pos_panel_filter(3:4)];
h_panel_filter = uipanel('Parent', h_panel_design, ...
    'Position', pos_panel_filter./size_panel_design, ...
    'Title', ' Alarm Filter', ...
    'BorderType', 'etchedin', ...
    'ForegroundColor', [0 0 1]);

uicontrol('Parent', h_panel_filter, ...
    'Style', 'text', 'String' , 'Filter:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [10, 65, 30, 20]./size_panel_filter);
h_pm_filter = uicontrol('Parent', h_panel_filter, ...
    'Style', 'popupmenu', 'String', 'None', ...
    'Units', 'normalized', ...
    'Position', [40, 71, 135, 20]./size_panel_filter, ...
    'Callback', @callback_pm_filter);
%%
h_text_filter_par = uicontrol('Parent', h_panel_filter, ...
    'Style', 'text', ...
    'String' , 'Filter parameter(s):', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Visible', 'off', ...
    'Position', [10, 35, 105, 20]./size_panel_filter);
h_text_filter_window = uicontrol('Parent', h_panel_filter, ...
    'Style', 'text', ...
    'String' , 'Window size:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Visible', 'off', ...
    'Position', [20, 10, 70, 20]./size_panel_filter);
h_edit_filter_MA = uicontrol('Parent', h_panel_filter, ...
    'Style', 'edit', ...
    'String', '', 'Units', 'normalized', ...
    'Position', [95 10 40 23]./size_panel_filter, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_filter_MA);
h_edit_filter_MV = uicontrol('Parent', h_panel_filter, ...
    'Style', 'edit', ...
    'String', '', 'Units', 'normalized', ...
    'Position', [95 10 40 23]./size_panel_filter, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_filter_MV);
h_edit_filter_MN = uicontrol('Parent', h_panel_filter, ...
    'Style', 'edit', ...
    'String', '', 'Units', 'normalized', ...
    'Position', [95 10 40 23]./size_panel_filter, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_filter_MN);

h_text_filter_EWMA_order = uicontrol('Parent', h_panel_filter, ...
    'Style', 'text', ...
    'String' , 'Order:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Visible', 'off', ...
    'Position', [20, 10, 55, 20]./size_panel_filter);
h_edit_filter_EWMA_order = uicontrol('Parent', h_panel_filter, ...
    'Style', 'edit', ...
    'String', '', 'Units', 'normalized', ...
    'Position', [55 10 40 23]./size_panel_filter, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_filter_EWMA_order);
h_text_filter_EWMA_const = uicontrol('Parent', h_panel_filter, ...
    'Style', 'text', ...
    'String' , 'Constant:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Visible', 'off', ...
    'Position', [120, 10, 65, 20]./size_panel_filter);
h_edit_filter_EWMA_const = uicontrol('Parent', h_panel_filter, ...
    'Style', 'edit', ...
    'String', '', 'Units', 'normalized', ...
    'Position', [175 10 40 23]./size_panel_filter, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_filter_EWMA_const);

h_text_filter_LP_samplingtime = uicontrol('Parent', h_panel_filter, ...
    'Style', 'text', ...
    'String' , 'Ts:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Visible', 'off', ...
    'Position', [20, 10, 55, 20]./size_panel_filter);
h_edit_filter_LP_samplingtime = uicontrol('Parent', h_panel_filter, ...
    'Style', 'edit', ...
    'String', '', 'Units', 'normalized', ...
    'Position', [55 10 40 23]./size_panel_filter, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_filter_LP_samplingtime);
h_text_filter_LP_timeconst = uicontrol('Parent', h_panel_filter, ...
    'Style', 'text', ...
    'String' , 'Time Constant:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Visible', 'off', ...
    'Position', [100, 10, 90, 20]./size_panel_filter);
h_edit_filter_LP_timeconst = uicontrol('Parent', h_panel_filter, ...
    'Style', 'edit', ...
    'String', '', 'Units', 'normalized', ...
    'Position', [175 10 40 23]./size_panel_filter, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_filter_LP_timeconst);

h_edit_filter_Ranksize = uicontrol('Parent', h_panel_filter, ...
    'Style', 'edit', ...
    'String', '', 'Units', 'normalized', ...
    'Position', [95 10 40 23]./size_panel_filter, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_filter_Ranksize);
h_text_filter_Rankorder = uicontrol('Parent', h_panel_filter, ...
    'Style', 'text', ...
    'String' , 'Order:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Visible', 'off', ...
    'Position', [140, 10, 40, 20]./size_panel_filter);
h_edit_filter_Rankorder = uicontrol('Parent', h_panel_filter, ...
    'Style', 'edit', ...
    'String', '', 'Units', 'normalized', ...
    'Position', [175 10 40 23]./size_panel_filter, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_filter_Rankorder);

h_text_filter_USER = uicontrol('Parent', h_panel_filter, ...
    'Style', 'text', ...
    'String' , 'Custom filter:', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Visible', 'off', ...
    'Position', [30, 10, 65, 20]./size_panel_filter);
h_edit_filter_USER = uicontrol('Parent', h_panel_filter, ...
    'Style', 'edit', ...
    'String', '', 'Units', 'normalized', ...
    'Position', [100 10 100 24]./size_panel_filter, ...
    'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'Visible', 'off', ...
    'Callback', @callback_edit_filter_USER);

%% Exit
%h_pb_cancel = uicontrol('Parent', h_main, ...
%    'Style', 'pushbutton', ...
%    'String', 'Exit', ...
%    'Units', 'normalized', ...
%    'Position', [105 40 65 25]./size_main, ...
%    'Callback', @close_request); 

%% Main

HAL_alarmlimit_methods = {'None','Alarm rate (%)', 'Maximum data', 'User defined'};
LAL_alarmlimit_methods = {'None','Alarm rate (%)', 'Minimum data', 'User defined'};
deadband_methods = {'None', 'Percent of alarm limit (%)', 'User defined'};
filter_methods = {'None','Moving average','Moving variance','Moving norm','Low pass','Rank order','EWMA','User defined'};

set(h_pm_deadband_HAL, 'String', deadband_methods);
set(h_pm_deadband_LAL, 'String', deadband_methods);
set(h_pm_method_HAL, 'String', HAL_alarmlimit_methods);
set(h_pm_method_LAL, 'String', LAL_alarmlimit_methods);
set(h_pm_filter, 'String', filter_methods);

if is_faulty
    set(h_pb_almopt, 'Enable', 'on');
    set(h_pb_plotroc, 'Enable', 'on');
    set(h_pb_optimize, 'Enable', 'on');
end
%set(h_alm{1}, 'XLim',[0,n_data],'XTickMode','auto','YLim',[-1.2 1.2], 'YTick', [-1 0 1], 'YTickLabel', {'LO', '0', 'HI'});
%set(h_alm{2}, 'XLim',[0,n_data],'YLim',[-1.2 1.2], 'YTick', [-1 0 1], 'YTickLabel', {'LO', '0', 'HI'});

%apply_design('original');
%apply_design('design');
plot_data('original');
plot_data('design');

%% Functions
%%
    function callback_bg_method(source, eventdata)
        switch get(get(h_bg_method, 'SelectedObject'), 'String')
            case 'Current alarm limits'
                set(h_edit_alpha, 'Enable', 'off')
                set(h_edit_HAL, 'Enable', 'off')
                set(h_edit_LAL, 'Enable', 'off')
                set(h_edit_HAL_DB, 'Enable', 'off')
                set(h_edit_LAL_DB, 'Enable', 'off')
                set(h_edit_ondelay, 'Enable', 'off')
                set(h_edit_offdelay, 'Enable', 'off')
                HAL_raise{1} = inf;
                LAL_raise{1} = -inf;
                HAL_DB{1} = 0;
                LAL_DB{1} = 0;
                is_deadband_HAL{1} = 0;
                is_deadband_LAL{1} = 0;
                delay_on{1} = 1;
                delay_off{1} = 1;
                set(h_edit_HAL, 'String', num2str(HAL_raise{1},'%4.2f'))
                set(h_edit_LAL, 'String', num2str(LAL_raise{1},'%4.2f'))
                set(h_edit_HAL_DB, 'String', num2str(HAL_DB{1}))
                set(h_edit_LAL_DB, 'String', num2str(LAL_DB{1}))
                set(h_edit_ondelay, 'String', num2str(delay_on{1}))
                set(h_edit_offdelay, 'String', num2str(delay_off{1}))
                
            case 'Alarm rate (%):'
                % if "Alarm rate (%):" is selected:
                % 1- enable and disable appropriate ui's
                % 2- calculate HAL and LAL based on aplpha
                % 3- is_deadband = 0
                % 4- plot HAL and LAL
                set(h_edit_alpha, 'Enable', 'on')
                set(h_edit_HAL, 'Enable', 'off')
                set(h_edit_LAL, 'Enable', 'off')
                set(h_edit_HAL_DB, 'Enable', 'off')
                set(h_edit_LAL_DB, 'Enable', 'off')
                set(h_edit_ondelay, 'Enable', 'off')
                set(h_edit_offdelay, 'Enable', 'off')
%                dist_p_normal{1} = mle(in_data(1:n_normal), 'dist', 'normal'); 
%                HAL_raise{1} = icdf('normal', 1-alpha, dist_p_normal{1}(1), dist_p_normal{1}(2));
%                LAL_raise{1} = icdf('normal', alpha, dist_p_normal{1}(1), dist_p_normal{1}(2));
%                [dist_type_normal{1}, dist_p_normal{1}] = find_dist(in_data(1:n_normal), 'SQRT', 'two');
%                HAL_raise{1} = dist_icdf(dist_type_normal{1}, 1-alpha, dist_p_normal{1});
%                LAL_raise{1} = dist_icdf(dist_type_normal{1}, alpha, dist_p_normal{1});
                HAL_raise{1} = ksdensity(in_data(1:n_normal),1-alpha,'function','icdf');
                LAL_raise{1} = ksdensity(in_data(1:n_normal),alpha,'function','icdf');
                HAL_DB{1} = 0;
                LAL_DB{1} = 0;
                is_deadband_HAL{1} = 0;
                is_deadband_LAL{1} = 0;
                delay_on{1} = 1;
                delay_off{1} = 1;
                set(h_edit_HAL, 'String', num2str(HAL_raise{1},'%4.2f'))
                set(h_edit_LAL, 'String', num2str(LAL_raise{1},'%4.2f'))
                set(h_edit_HAL_DB, 'String', num2str(HAL_DB{1}))
                set(h_edit_LAL_DB, 'String', num2str(LAL_DB{1}))
                set(h_edit_ondelay, 'String', num2str(delay_on{1}))
                set(h_edit_offdelay, 'String', num2str(delay_off{1}))
 
            case 'User defined:'
                % if "User defined limits" is selected:
                % 1- enable and disable appropriate ui's
                % 2- check for "Deadbands"
                % 3-1- if "Deadband" is non-zero then update HAL_raise and
                % HAL_clear. set is_deadband = 1;
                % 3-2- if "Deadband" is zero then update
                % HAL_raise. set is_deadband = 0;
                % 4- plot HAL and LAL
                set(h_edit_alpha, 'Enable', 'off')
                set(h_edit_HAL, 'Enable', 'on')
                set(h_edit_LAL, 'Enable', 'on')
                set(h_edit_HAL_DB, 'Enable', 'on')
                set(h_edit_LAL_DB, 'Enable', 'on')
                set(h_edit_ondelay, 'Enable', 'on')
                set(h_edit_offdelay, 'Enable', 'on')
                 
                % HAL
                HAL_raise{1} = str2double(get(h_edit_HAL, 'String'));
                HAL_DB{1} = str2double(get(h_edit_HAL_DB, 'String'));
                % LAL
                LAL_raise{1} = str2double(get(h_edit_LAL, 'String'));
                LAL_DB{1} = str2double(get(h_edit_LAL_DB, 'String'));
                % delay-timer
                delay_on{1} = round(str2double(get(h_edit_ondelay, 'String')));
                delay_off{1} = round(str2double(get(h_edit_offdelay, 'String')));
        end
        apply_design('original');
    end
%%
    function callback_edit_alpha(hObject, eventdata) 
        alpha_string = get(hObject, 'string');
        alpha_double = str2double(alpha_string);
        if isnan(alpha_double) || alpha_double <= 0 || alpha_double >= 100
            errordlg('Alarm rate must be strictly between 0% and 100%', ...
                'Invalid Alarm rate', 'modal')
            set(hObject, 'String', num2str(100*alpha));
            return
        end
        alpha = alpha_double/100;
%        dist_p_normal{1} = mle(in_data(1:n_normal),'dist','normal');
%        HAL_raise{1} = icdf('normal', 1-alpha, dist_p_normal{1}(1), dist_p_normal{1}(2));
%        LAL_raise{1} = icdf('normal', alpha, dist_p_normal{1}(1), dist_p_normal{1}(2));
%        [dist_type_normal{1}, dist_p_normal{1}] = find_dist(in_data(1:n_normal), 'SQRT', 'two'); 
%        HAL_raise{1} = dist_icdf(dist_type_normal{1}, 1-alpha, dist_p_normal{1});
%        LAL_raise{1} = dist_icdf(dist_type_normal{1}, alpha, dist_p_normal{1});
        HAL_raise{1} = ksdensity(in_data(1:n_normal),1-alpha,'function','icdf');
        LAL_raise{1} = ksdensity(in_data(1:n_normal),alpha,'function','icdf');
        apply_design('original');
    end
%%
    function callback_edit_HAL(hObject, eventdata) 
        alpha_string = get(hObject, 'string');
        alpha_double = str2double(alpha_string); 
        if isnan(alpha_double) || alpha_double < LAL_raise{1}
            errordlg(['High alarm limit must be greater than ' num2str(LAL_raise{1})], ...
                    'Invalid HAL', 'modal')
            set(hObject, 'String', num2str(HAL_raise{1}, '%-6.2f'))
            return
        end
        HAL_raise{1} = alpha_double;
        apply_design('original');
    end
%%
    function callback_edit_LAL(hObject, eventdata)
        alpha_string = get(hObject, 'string');
        alpha_double = str2double(alpha_string);
        if isnan(alpha_double) || alpha_double > HAL_raise{1}
            errordlg(['Low alarm limit must be smaller than  ' num2str(HAL_raise{1})], ...
                'Invalid LAL', 'modal')
            set(hObject, 'String', num2str(LAL_raise{1}, '%-6.2f'))
            return
        end
        LAL_raise{1} = alpha_double;
        apply_design('original');
  end
%%
    function callback_edit_HAL_DB(hObject, eventdata) 
        alpha_string = get(hObject, 'string');
        alpha_double = str2double(alpha_string);
        if isempty(alpha_string)
            HAL_DB{1} = 0;
            set(hObject, 'String', num2str(HAL_DB{1}))
        elseif isnan(alpha_double) || alpha_double < 0 
            errordlg('Deadband must be a positive number', ...
                'Invalid Deadband', 'modal')
            set(hObject, 'String', num2str(HAL_DB{1}))
            return
        else
            HAL_DB{1} = alpha_double;
        end
        apply_design('original');
   end
%%
    function callback_edit_LAL_DB(hObject, eventdata) 
        alpha_string = get(hObject, 'string');
        alpha_double = str2double(alpha_string);
        if isempty(alpha_string)
            LAL_DB{1} = 0;
            set(hObject, 'String', num2str(LAL_DB{1}))
        elseif isnan(alpha_double) || alpha_double < 0
            errordlg('Deadband must be a positive number', ...
                'Invalid Deadband', 'modal')
            set(hObject, 'String', num2str(LAL_DB{1}))
            return
        else
            LAL_DB{1} =alpha_double;
        end
        apply_design('original');
    end
%%
    function callback_edit_ondelay(hObject, eventdata)
        delay_on_string = get(hObject, 'string');
        delay_on_double = str2double(delay_on_string);
        if isnan(delay_on_double) || delay_on_double ~= round(delay_on_double)|| ...
                delay_on_double < 0 || delay_on_double > 1000
            errordlg('Alarm delay must be a positive integer between 1 and 1000', ...
                'Invalid Alarm Delay', 'modal')
            set(hObject, 'String', num2str(delay_on{1}))
        end
        delay_on{1} = delay_on_double;
        apply_design('original');
    end
%%
    function callback_edit_offdelay(hObject, eventdata) 
        delay_off_string = get(hObject, 'string');
        delay_off_double = str2double(delay_off_string);
        if isnan(delay_off_double) || delay_off_double ~= ...
                round(delay_off_double)|| delay_off_double < 0 || ...
                delay_off_double > 1000
            errordlg('Alarm delay must be a positive integer between 1 and 1000', ...
                'Invalid Alarm Delay', 'modal')
            set(hObject, 'String', num2str(delay_off{1}))
        end
        delay_off{1} = delay_off_double;
        apply_design('original');
    end
%%
    function callback_edit_delay_on(hObject, eventdata)
        delay_on_string = get(hObject, 'string');
        delay_on_double = str2double(delay_on_string);
        if isnan(delay_on_double) || delay_on_double ~= round(delay_on_double)|| ...
                delay_on_double < 0 || delay_on_double > 1000
            errordlg('Alarm delay must be a positive integer between 1 and 1000', ...
                'Invalid Alarm Delay', 'modal')
            set(hObject, 'String', num2str(delay_on{2}))
        end
        delay_on{2} = delay_on_double;
        apply_design('design');
    end
%%
    function callback_edit_delay_off(hObject, eventdata) 
        delay_off_string = get(hObject, 'string');
        delay_off_double = str2double(delay_off_string);
        if isnan(delay_off_double) || delay_off_double ~= ...
                round(delay_off_double)|| delay_off_double < 0 || ...
                delay_off_double > 1000
            errordlg('Alarm delay must be a positive integer between 1 and 1000', ...
                'Invalid Alarm Delay', 'modal')
            set(hObject, 'String', num2str(delay_off{2}))
        end
        delay_off{2} = delay_off_double;
        apply_design('design');
    end
%%
    function callback_pm_method_HAL(hObject, eventdata) 
        set(h_edit_alpha_HAL, 'Visible', 'off')
        set(h_edit_user_HAL, 'Visible', 'off')
        set(h_pm_deadband_HAL, 'Enable', 'on')
        set(h_edit_deadband_percent_HAL, 'Enable', 'on')
        set(h_edit_deadband_user_HAL, 'Enable', 'on')
        set(h_edit_delay_on, 'Enable','on');
        set(h_edit_delay_off, 'Enable', 'on');
        set(h_pb_delayopt, 'Enable', 'on');
        set(h_pb_almclear, 'Enable', 'on');
        str = get(hObject, 'String');
        val = get(hObject, 'Value');
        switch str{val}
            case 'Alarm rate (%)'
                set(h_edit_alpha_HAL, 'Visible', 'on')
                set(h_edit_alpha_HAL, 'String', num2str(100*alpha_HAL))
%                dist_p_normal{2} = mle(design_data(1:n_normal), 'dist', 'normal'); 
%                HAL_raise{2} = icdf('normal', 1-alpha_HAL, dist_p_normal{2}(1), dist_p_normal{2}(2));
%                [dist_type_normal{2}, dist_p_normal{2}] = find_dist(design_data(1:n_normal), 'SQRT', 'two'); 
%                HAL_raise{2} = dist_icdf(dist_type_normal{2}, 1-alpha, dist_p_normal{2});
                HAL_raise{2} = ksdensity(design_data(1:n_normal),1-alpha,'function','icdf');
            case 'User defined'
                set(h_edit_user_HAL, 'String', num2str(HAL_raise{2}, '%-6.2f'))
                set(h_edit_user_HAL, 'Visible', 'on')
            case 'None'
                set(h_edit_deadband_percent_HAL, 'Visible', 'off')
                set(h_edit_deadband_user_HAL, 'Visible', 'off')
                set(h_pm_deadband_HAL, 'Enable', 'off')
                set(h_pm_deadband_HAL, 'String',deadband_methods,'Value',1);
                HAL_raise{2} = inf; 
                if get(h_pm_method_LAL, 'Value') == 1
                    set(h_edit_delay_on, 'Enable', 'off');
                    set(h_edit_delay_off, 'Enable', 'off');
                    set(h_pb_delayopt, 'Enable', 'off');
                    set(h_pb_almclear, 'Enable', 'off');
              end
            case 'Maximum data'
                set(h_edit_user_HAL, 'Visible', 'off')
                HAL_raise{2} = max(design_data(1:n_normal));
        end
        apply_design('design');
    end
%%
    function callback_pm_method_LAL(hObject, eventdata) 
        set(h_edit_alpha_LAL, 'Visible', 'off')
        set(h_edit_user_LAL, 'Visible', 'off')
        set(h_pm_deadband_LAL, 'Enable', 'on')
        set(h_edit_deadband_percent_LAL, 'Enable', 'on')
        set(h_edit_deadband_user_LAL, 'Enable', 'on')
        set(h_edit_delay_on, 'Enable','on');
        set(h_edit_delay_off, 'Enable', 'on');
        set(h_pb_delayopt, 'Enable', 'on');
        set(h_pb_almclear, 'Enable', 'on');
        str = get(hObject, 'String');
        val = get(hObject, 'Value');
        switch str{val}
            case 'Alarm rate (%)'
                set(h_edit_alpha_LAL, 'Visible', 'on')
                set(h_edit_alpha_LAL, 'String', num2str(100*alpha_LAL))
%                dist_p_normal{2} = mle(design_data(1:n_normal), 'dist', 'normal'); 
%                LAL_raise{2} = icdf('normal', alpha_LAL, dist_p_normal{2}(1), dist_p_normal{2}(2));
%                [dist_type_normal{2}, dist_p_normal{2}] = find_dist(design_data(1:n_normal), 'SQRT', 'two'); 
%                LAL_raise{2} = dist_icdf(dist_type_normal{2}, alpha, dist_p_normal{2});
                LAL_raise{2} = ksdensity(design_data(1:n_normal),alpha,'function','icdf');
             case 'User defined'
                set(h_edit_user_LAL, 'String', num2str(LAL_raise{2}, '%-6.2f'))
                set(h_edit_user_LAL, 'Visible', 'on')
            case 'None'
                set(h_pm_deadband_LAL, 'Enable', 'off')
                set(h_edit_deadband_percent_LAL, 'Visible', 'off')
                set(h_edit_deadband_user_LAL, 'Visible', 'off')
                set(h_pm_deadband_LAL, 'String',deadband_methods,'Value',1);
                LAL_raise{2} = -inf;
                if get(h_pm_method_HAL, 'Value') == 1
                    set(h_edit_delay_on, 'Enable', 'off');
                    set(h_edit_delay_off, 'Enable', 'off');
                    set(h_pb_delayopt, 'Enable', 'off');
                    set(h_pb_almclear, 'Enable', 'off');
                end
             case 'Minimum data'
                set(h_edit_user_LAL, 'Visible', 'off')
                LAL_raise{2} = min(design_data(1:n_normal));
        end
        apply_design('design');
    end
%%
    function callback_edit_alpha_HAL(hObject, eventdata) 
        alpha_string = get(hObject, 'string');
        alpha_double = str2double(alpha_string);
        if isnan(alpha_double) || alpha_double < 0 || alpha_double > 100
            errordlg('Alarm rate must be strictly between 0% and 100%', ...
                'Invalid Alarm rate', 'modal')
            set(hObject, 'String', num2str(100*alpha_HAL{2}));
        end
        alpha_HAL = alpha_double/100;
        apply_design('design');
    end
%%
    function callback_edit_alpha_LAL(hObject, eventdata)
        alpha_string = get(hObject, 'string');
        alpha_double = str2double(alpha_string);
        if isnan(alpha_double) || alpha_double < 0 || alpha_double > 100
            errordlg('Alarm rate must be between 0% and 100%', ...
                'Invalid Alarm rate', 'modal')
            set(hObject, 'String', num2str(100*alpha_LAL{2}))
        end
        alpha_LAL = alpha_double/100;
        apply_design('design');
    end
%%
    function callback_edit_HAL_user(hObject, eventdata) 
        alpha_string = get(hObject, 'string');
        alpha_double = str2double(alpha_string);
        if isnan(alpha_double) || alpha_double < LAL_raise{2}
            errordlg(['High alarm limit must be greater than ' num2str(LAL_raise{2})], ...
                'Invalid HAL', 'modal')
            set(hObject, 'String', num2str(user_HAL, '%-6.2f'))
        end
        user_HAL = alpha_double;
        apply_design('design');
    end
%%
    function callback_edit_LAL_user(hObject, eventdata)
        alpha_string = get(hObject, 'string');
        alpha_double = str2double(alpha_string);
        if isnan(alpha_double) || alpha_double > HAL_raise{2}
            errordlg(['Low alarm limit must be smaller than  ' num2str(HAL_raise{2})], ...
                'Invalid LAL', 'modal')
            set(hObject, 'String', num2str(user_LAL, '%-6.2f'))
        end
        user_LAL = alpha_double;
        apply_design('design');
    end
%%
    function callback_pm_deadband_HAL(hObject, eventdata) 
        set(h_edit_deadband_percent_HAL, 'Visible', 'off')
        set(h_edit_deadband_user_HAL, 'Visible', 'off')
        str = get(hObject, 'String');
        val = get(hObject, 'Value');
        switch str{val}
            case 'Percent of alarm limit (%)'
                set(h_edit_deadband_percent_HAL, 'Visible', 'on')
                set(h_edit_deadband_percent_HAL, 'String', num2str(deadband_percent_HAL*100))
                HAL_DB{2} = abs(HAL_raise{2}*deadband_percent_HAL);
            case 'User defined'
                set(h_edit_deadband_user_HAL, 'Visible', 'on')
                set(h_edit_deadband_percent_HAL, 'String', num2str(deadband_user_HAL))
                HAL_DB{2} = deadband_user_HAL;
            case 'None'
                HAL_DB{2} = 0;
         end
         apply_design('design');
    end
%%
    function callback_pm_deadband_LAL(hObject, eventdata) 
        set(h_edit_deadband_percent_LAL, 'Visible', 'off')
        set(h_edit_deadband_user_LAL, 'Visible', 'off')
        str = get(hObject, 'String');
        val = get(hObject, 'Value');
        switch str{val}
            case 'Percent of alarm limit (%)'
                set(h_edit_deadband_percent_LAL, 'Visible', 'on')
                set(h_edit_deadband_percent_LAL, 'String', num2str(deadband_percent_LAL*100))
                LAL_DB{2} = abs(LAL_raise{2}*deadband_percent_LAL);
            case 'User defined'
                set(h_edit_deadband_user_LAL, 'Visible', 'on')
                set(h_edit_deadband_user_LAL, 'String', num2str(deadband_user_LAL))
                LAL_DB{2} = deadband_user_LAL;
            case 'None'
                LAL_DB{2} = 0;
        end
        apply_design('design');
    end
%%
    function callback_edit_deadband_percent_HAL(hObject, eventdata) 
        percent_string = get(hObject, 'string');
        percent_double = str2double(percent_string);
        if isnan(percent_double) || percent_double < 0 || percent_double > 100
            errordlg('Deadband percent must be between 0 and 100', ...
                'Invalid Deadband Percent', 'modal')
            set(hObject, 'String', num2str(deadband_percent_HAL))
        end
        deadband_percent_HAL = percent_double/100;
        HAL_DB{2} = abs(HAL_raise{2})*deadband_percent_HAL;
        apply_design('design');
    end
%%
    function callback_edit_deadband_percent_LAL(hObject, eventdata) 
        percent_string = get(hObject, 'string');
        percent_double = str2double(percent_string);
        if isnan(percent_double) || percent_double < 0 || percent_double > 100
            errordlg('Deadband percent must be between 0 and 100', ...
                'Invalid Deadband Percent', 'modal')
            set(hObject, 'String', num2str(deadband_percent_LAL))
        end
        deadband_percent_LAL = percent_double/100;
        LAL_DB{2} = abs(LAL_raise{2})*deadband_percent_LAL;
        apply_design('design');
    end
%%
    function callback_edit_deadband_user_HAL(hObject, eventdata) 
        alpha_string = get(hObject, 'string');
        alpha_double = str2double(alpha_string); 
        if isnan(alpha_double) || alpha_double < 0
            errordlg('Deadband must be a positive number', ...
                'Invalid Deadband', 'modal')
            set(hObject, 'String', num2str(HAL_DB{2}))
        end
        deadband_user_HAL = alpha_double;
        HAL_DB{2} = deadband_user_HAL;
        apply_design('design');
    end
%%
    function callback_edit_deadband_user_LAL(hObject, eventdata) 
        alpha_string = get(hObject, 'string');
        alpha_double = str2double(alpha_string); 
        if isnan(alpha_double) || alpha_double < 0
            errordlg('Deadband must be a positive number', 'Invalid Deadband', 'modal')
            set(hObject, 'String', num2str(LAL_DB{2}))
        end
        deadband_user_LAL = alpha_double;
        LAL_DB{2} = deadband_user_LAL;
        apply_design('design');
    end
%%
    function callback_pm_filter(hObject, eventdata)
        str = get(hObject, 'String');
        val = get(hObject, 'Value');
        switch str{val}
            case 'None'
                set(h_text_filter_par, 'Visible', 'off');
                set(h_text_filter_window, 'Visible', 'off');
                set(h_edit_filter_MA, 'Visible', 'off');
                set(h_edit_filter_MV, 'Visible', 'off');
                set(h_edit_filter_MN, 'Visible', 'off');
                set(h_text_filter_EWMA_order, 'Visible', 'off');
                set(h_edit_filter_EWMA_order, 'Visible', 'off');
                set(h_text_filter_EWMA_const, 'Visible', 'off');
                set(h_edit_filter_EWMA_const, 'Visible', 'off');
                set(h_text_filter_LP_samplingtime, 'Visible', 'off');
                set(h_edit_filter_LP_samplingtime, 'Visible', 'off');
                set(h_text_filter_LP_timeconst, 'Visible', 'off');
                set(h_edit_filter_LP_timeconst, 'Visible', 'off');
                set(h_edit_filter_Ranksize, 'Visible', 'off');
                set(h_text_filter_Rankorder, 'Visible', 'off');
                set(h_edit_filter_Rankorder, 'Visible', 'off');
                set(h_text_filter_USER, 'Visible', 'off');
                set(h_edit_filter_USER, 'Visible', 'off');
                if is_faulty
                    set(h_pb_optimize, 'Enable', 'on');
                end
                filter_type ='None';
            case 'Moving average'
                set(h_text_filter_par, 'Visible', 'on');
                set(h_text_filter_window, 'Visible', 'on');
                set(h_edit_filter_MA, 'Visible', 'on');
                set(h_edit_filter_MV, 'Visible', 'off');
                set(h_edit_filter_MN, 'Visible', 'off');
                set(h_text_filter_EWMA_order, 'Visible', 'off');
                set(h_edit_filter_EWMA_order, 'Visible', 'off');
                set(h_text_filter_EWMA_const, 'Visible', 'off');
                set(h_edit_filter_EWMA_const, 'Visible', 'off');
                set(h_text_filter_LP_samplingtime, 'Visible', 'off');
                set(h_edit_filter_LP_samplingtime, 'Visible', 'off');
                set(h_text_filter_LP_timeconst, 'Visible', 'off');
                set(h_edit_filter_LP_timeconst, 'Visible', 'off');
                set(h_text_filter_USER, 'Visible', 'off');
                set(h_edit_filter_USER, 'Visible', 'off');
                set(h_edit_filter_Ranksize, 'Visible', 'off');
                set(h_text_filter_Rankorder, 'Visible', 'off');
                set(h_edit_filter_Rankorder, 'Visible', 'off');
                set(h_edit_filter_MA, 'String', num2str(filter_MA_par));
                if is_faulty
                    set(h_pb_optimize, 'Enable', 'off');
                end
                filter_type ='Moving average';
            case 'Moving variance'
                set(h_text_filter_par, 'Visible', 'on');
                set(h_text_filter_window, 'Visible', 'on');
                set(h_edit_filter_MA, 'Visible', 'off');
                set(h_edit_filter_MV, 'Visible', 'on');
                set(h_edit_filter_MN, 'Visible', 'off');
                set(h_text_filter_EWMA_order, 'Visible', 'off');
                set(h_edit_filter_EWMA_order, 'Visible', 'off');
                set(h_text_filter_EWMA_const, 'Visible', 'off');
                set(h_edit_filter_EWMA_const, 'Visible', 'off');
                set(h_text_filter_LP_samplingtime, 'Visible', 'off');
                set(h_edit_filter_LP_samplingtime, 'Visible', 'off');
                set(h_text_filter_LP_timeconst, 'Visible', 'off');
                set(h_edit_filter_LP_timeconst, 'Visible', 'off');
                set(h_text_filter_USER, 'Visible', 'off');
                set(h_edit_filter_USER, 'Visible', 'off');
                set(h_edit_filter_Ranksize, 'Visible', 'off');
                set(h_text_filter_Rankorder, 'Visible', 'off');
                set(h_edit_filter_Rankorder, 'Visible', 'off');
                set(h_edit_filter_MV, 'String', num2str(filter_MV_par));
                if is_faulty
                    set(h_pb_optimize, 'Enable', 'off');
                end
                filter_type ='Moving variance';
            case 'Moving norm'
                set(h_text_filter_par, 'Visible', 'on');
                set(h_text_filter_window, 'Visible', 'on');
                set(h_edit_filter_MA, 'Visible', 'off');
                set(h_edit_filter_MV, 'Visible', 'off');
                set(h_edit_filter_MN, 'Visible', 'on');
                set(h_text_filter_EWMA_order, 'Visible', 'off');
                set(h_edit_filter_EWMA_order, 'Visible', 'off');
                set(h_text_filter_EWMA_const, 'Visible', 'off');
                set(h_edit_filter_EWMA_const, 'Visible', 'off');
                set(h_text_filter_LP_samplingtime, 'Visible', 'off');
                set(h_edit_filter_LP_samplingtime, 'Visible', 'off');
                set(h_text_filter_LP_timeconst, 'Visible', 'off');
                set(h_edit_filter_LP_timeconst, 'Visible', 'off');
                set(h_text_filter_USER, 'Visible', 'off');
                set(h_edit_filter_USER, 'Visible', 'off');
                set(h_edit_filter_Ranksize, 'Visible', 'off');
                set(h_text_filter_Rankorder, 'Visible', 'off');
                set(h_edit_filter_Rankorder, 'Visible', 'off');
                set(h_edit_filter_MN, 'String', num2str(filter_MN_par));
                if is_faulty
                    set(h_pb_optimize, 'Enable', 'off');
                end
                filter_type ='Moving norm';
            case 'EWMA'
                set(h_text_filter_par, 'Visible', 'on');
                set(h_text_filter_window, 'Visible', 'off');
                set(h_edit_filter_MA, 'Visible', 'off');
                set(h_edit_filter_MV, 'Visible', 'off');
                set(h_edit_filter_MN, 'Visible', 'off');
                set(h_text_filter_EWMA_order, 'Visible', 'on');
                set(h_edit_filter_EWMA_order, 'Visible', 'on');
                set(h_text_filter_EWMA_const, 'Visible', 'on');
                set(h_edit_filter_EWMA_const, 'Visible', 'on');
                set(h_text_filter_LP_samplingtime, 'Visible', 'off');
                set(h_edit_filter_LP_samplingtime, 'Visible', 'off');
                set(h_text_filter_LP_timeconst, 'Visible', 'off');
                set(h_edit_filter_LP_timeconst, 'Visible', 'off');
                set(h_text_filter_USER, 'Visible', 'off');
                set(h_edit_filter_USER, 'Visible', 'off');
                set(h_edit_filter_EWMA_order, 'String', num2str(filter_EWMA_order));
                set(h_edit_filter_EWMA_const, 'String', num2str(filter_EWMA_const));
                set(h_edit_filter_Ranksize, 'Visible', 'off');
                set(h_text_filter_Rankorder, 'Visible', 'off');
                set(h_edit_filter_Rankorder, 'Visible', 'off');
                if is_faulty
                    set(h_pb_optimize, 'Enable', 'off');
                end
                filter_type ='EWMA';
            case 'Low pass'
                set(h_text_filter_par, 'Visible', 'on');
                set(h_text_filter_window, 'Visible', 'off');
                set(h_edit_filter_MA, 'Visible', 'off');
                set(h_edit_filter_MV, 'Visible', 'off');
                set(h_edit_filter_MN, 'Visible', 'off');
                set(h_text_filter_EWMA_order, 'Visible', 'off');
                set(h_edit_filter_EWMA_order, 'Visible', 'off');
                set(h_text_filter_EWMA_const, 'Visible', 'off');
                set(h_edit_filter_EWMA_const, 'Visible', 'off');
                set(h_text_filter_LP_samplingtime, 'Visible', 'on');
                set(h_edit_filter_LP_samplingtime, 'Visible', 'on');
                set(h_text_filter_LP_timeconst, 'Visible', 'on');
                set(h_edit_filter_LP_timeconst, 'Visible', 'on');
                set(h_text_filter_USER, 'Visible', 'off');
                set(h_edit_filter_USER, 'Visible', 'off');
                set(h_edit_filter_LP_samplingtime, 'String', num2str(filter_LP_samplingtime));
                set(h_edit_filter_LP_timeconst, 'String', num2str(filter_LP_timeconst));
                set(h_edit_filter_Ranksize, 'Visible', 'off');
                set(h_text_filter_Rankorder, 'Visible', 'off');
                set(h_edit_filter_Rankorder, 'Visible', 'off');
                if is_faulty
                    set(h_pb_optimize, 'Enable', 'off');
                end
                filter_type ='Low pass';
            case 'Rank order'
                set(h_text_filter_par, 'Visible', 'on');
                set(h_text_filter_window, 'Visible', 'on');
                set(h_edit_filter_MA, 'Visible', 'off');
                set(h_edit_filter_MV, 'Visible', 'off');
                set(h_edit_filter_MN, 'Visible', 'off');
                set(h_text_filter_EWMA_order, 'Visible', 'off');
                set(h_edit_filter_EWMA_order, 'Visible', 'off');
                set(h_text_filter_EWMA_const, 'Visible', 'off');
                set(h_edit_filter_EWMA_const, 'Visible', 'off');
                set(h_text_filter_LP_samplingtime, 'Visible', 'off');
                set(h_edit_filter_LP_samplingtime, 'Visible', 'off');
                set(h_text_filter_LP_timeconst, 'Visible', 'off');
                set(h_edit_filter_LP_timeconst, 'Visible', 'off');
                set(h_text_filter_USER, 'Visible', 'off');
                set(h_edit_filter_USER, 'Visible', 'off');
                set(h_edit_filter_Ranksize, 'Visible', 'on');
                set(h_text_filter_Rankorder, 'Visible', 'on');
                set(h_edit_filter_Rankorder, 'Visible', 'on');
                set(h_edit_filter_Ranksize, 'String', num2str(filter_Ranksize_par));
                set(h_edit_filter_Rankorder, 'String', num2str(filter_Rankorder_par));
                if is_faulty
                    set(h_pb_optimize, 'Enable', 'on');
                end
                filter_type ='Rank order';
            case 'User defined'
                set(h_text_filter_par, 'Visible', 'on');
                set(h_text_filter_window, 'Visible', 'off');
                set(h_edit_filter_MA, 'Visible', 'off');
                set(h_edit_filter_MV, 'Visible', 'off');
                set(h_edit_filter_MN, 'Visible', 'off');
                set(h_text_filter_EWMA_order, 'Visible', 'off');
                set(h_edit_filter_EWMA_order, 'Visible', 'off');
                set(h_text_filter_EWMA_const, 'Visible', 'off');
                set(h_edit_filter_EWMA_const, 'Visible', 'off');
                set(h_text_filter_LP_samplingtime, 'Visible', 'off');
                set(h_edit_filter_LP_samplingtime, 'Visible', 'off');
                set(h_text_filter_LP_timeconst, 'Visible', 'off');
                set(h_edit_filter_LP_timeconst, 'Visible', 'off');
                set(h_edit_filter_Ranksize, 'Visible', 'off');
                set(h_text_filter_Rankorder, 'Visible', 'off');
                set(h_edit_filter_Rankorder, 'Visible', 'off');
                set(h_text_filter_USER, 'Visible', 'on');
                set(h_edit_filter_USER, 'Visible', 'on');
                set(h_edit_filter_USER, 'String', num2str(filter_USER_par));
                if is_faulty
                    set(h_pb_optimize, 'Enable', 'off');
                end
                filter_type ='User defined';
        end
        design_data = filter_data(filter_type);
        apply_design('design');
    end
%%
    function callback_edit_filter_MA(hObject, evendata)
        filter_par_string = get(hObject, 'string');
        filter_par_double = str2double(filter_par_string);
        if isnan(filter_par_double) || filter_par_double ~= round(filter_par_double)|| ...
                filter_par_double < 0 || filter_par_double > 1000
            errordlg('Window size must be a positive integer between 1 and 1000', ...
                'Invalid Window Size', 'modal')
            set(hObject, 'String', num2str(filter_MA_par))
        end
        filter_MA_par = filter_par_double;
        filter_type = 'Moving average';
        design_data = filter_data(filter_type);
        apply_design('design');
    end
%%
    function callback_edit_filter_MV(hObject, evendata)
        filter_par_string = get(hObject, 'string');
        filter_par_double = str2double(filter_par_string);
        if isnan(filter_par_double) || filter_par_double ~= round(filter_par_double)|| ...
                filter_par_double < 0 || filter_par_double > 1000
            errordlg('Window size must be a positive integer between 1 and 1000', ...
                'Invalid Window Size', 'modal')
            set(hObject, 'String', num2str(filter_MV_par))
        end
        filter_MV_par = filter_par_double;
        filter_type = 'Moving variance';
        design_data = filter_data(filter_type);
        apply_design('design');
    end
%%
    function callback_edit_filter_MN(hObject, evendata)
        filter_par_string = get(hObject, 'string');
        filter_par_double = str2double(filter_par_string);
        if isnan(filter_par_double) || filter_par_double ~= round(filter_par_double)|| ...
                filter_par_double < 0 || filter_par_double > 1000
            errordlg('Window size must be a positive integer between 1 and 1000', ...
                'Invalid Window Size', 'modal')
            set(hObject, 'String', num2str(filter_MN_par))
        end
        filter_MN_par = filter_par_double;
        filter_type = 'Moving norm';
        design_data = filter_data(filter_type);
        apply_design('design');
    end
%%
    function callback_edit_filter_EWMA_order(hObject, evendata)
        filter_par_string = get(hObject, 'string');
        filter_par_double = str2double(filter_par_string);
        if isnan(filter_par_double) || filter_par_double ~= round(filter_par_double)|| ...
                filter_par_double < 0 || filter_par_double > 100
            errordlg('EWMA order must be a positive integer between 1 and 100', ...
                'Invalid EWMA order', 'modal')
            set(hObject, 'String', num2str(filter_EWMA_order))
        end
        filter_EWMA_order = filter_par_double;
        filter_type = 'EWMA';
        design_data = filter_data(filter_type);
        apply_design('design');
    end
%%
    function callback_edit_filter_EWMA_const(hObject, evendata)
        filter_par_string = get(hObject, 'string');
        filter_par_double = str2double(filter_par_string);
        if isnan(filter_par_double) || filter_par_double < 0 || filter_par_double > 1
            errordlg('EWMA constant must be a number between 0 and 1', ...
                'Invalid EWMA constant', 'modal')
            set(hObject, 'String', num2str(filter_EWMA_const))
        end
        filter_EWMA_const = filter_par_double;
        filter_type = 'EWMA';
        design_data = filter_data(filter_type);
        apply_design('design');
    end
%%
    function callback_edit_filter_LP_timeconst(hObject, evendata)
        filter_par_string = get(hObject, 'string');
        filter_par_double = str2double(filter_par_string);
        if isnan(filter_par_double) || filter_par_double < 0 || filter_par_double > 1000
            errordlg('Low-pass fiter time constant must be between 0 and 1000', ...
                'Invalid low-pass filter time constant', 'modal')
            set(hObject, 'String', num2str(filter_LP_timeconst))
        end
        filter_LP_timeconst = filter_par_double;
        filter_type = 'Low pass';
        design_data = filter_data(filter_type);
        apply_design('design');
   end
%%
    function callback_edit_filter_LP_samplingtime(hObject, evendata)
        filter_par_string = get(hObject, 'string');
        filter_par_double = str2double(filter_par_string);
        if isnan(filter_par_double) || filter_par_double < 0 
            errordlg('Low-pass fiter time constant must be larger than 0', ...
                'Invalid sampling time', 'modal')
            set(hObject, 'String', num2str(filter_LP_samplingtime))
        end
        filter_LP_samplingtime = filter_par_double;
        filter_type = 'Low pass';
        design_data = filter_data(filter_type);
        apply_design('design');
    end
%%
    function callback_edit_filter_Rankorder(hObject, evendata)
        filter_par_string = get(hObject, 'string');
        filter_par_double = str2double(filter_par_string);
        if isnan(filter_par_double) || filter_par_double ~= round(filter_par_double)|| ...
                filter_par_double < 0 || filter_par_double > filter_Ranksize_par
            errordlg('Order must be a positive integer and less than Rank Windows Size', ...
                'Invalid Order', 'modal')
            set(hObject, 'String', num2str(filter_Rankorder_par))
        end
        filter_Rankorder_par = min(filter_par_double,filter_Ranksize_par);
        filter_type = 'Rank order';
        design_data = filter_data(filter_type);
        apply_design('design');
    end
%%
    function callback_edit_filter_Ranksize(hObject, evendata)
        filter_par_string = get(hObject, 'string');
        filter_par_double = str2double(filter_par_string);
        if isnan(filter_par_double) || filter_par_double ~= round(filter_par_double)|| ...
                filter_par_double < 0 || filter_par_double > 1000 || filter_par_double < filter_Rankorder_par
            errordlg('Order must be a positive integer (between 1 and 1000) greater than Rank Order', ...
                'Invalid Rank Size', 'modal')
            set(hObject, 'String', num2str(filter_Ranksize_par))
        end
        filter_Ranksize_par = max(filter_par_double,filter_Rankorder_par);
        filter_type = 'Rank order';
        design_data = filter_data(filter_type);
        apply_design('design');
    end
%%
    function callback_edit_filter_USER(hObject, eventdata) 
        custom_filter_string = get(hObject, 'string');
        if isempty(custom_filter_string)
            errordlg('The entered filter is invalid', 'Invalid Filter', 'modal');
            set(hObject, 'String', filter_USER_par)
            return
        else
            filter_USER_par = custom_filter_string;
            filter_type = 'User defined';
            design_data = filter_data(filter_type);
            apply_design('design');
        end
    end
%%
    function y = filter_data(filter_t)
        y = zeros(0, n_data);
        switch filter_t
            case 'None'
                y = in_data;
            case 'Low pass'
                A = exp(-1/filter_LP_timeconst*filter_LP_samplingtime);
                B = 1 - exp(-1/filter_LP_timeconst*filter_LP_samplingtime);
                y(1) = in_data(1);
                for i = 2:n_data
                    y(i) = A*y(i-1)+B*in_data(i-1);
                end
            case 'Moving average'
                for i = 1:n_data
                    start_point = max(1, i - filter_MA_par + 1);
                    y(i) = mean(in_data(start_point:i));
                end
            case 'Moving variance'
                for i = 1:n_data
                    start_point = max(1, i - filter_MV_par + 1);
                    y(i) = var(in_data(start_point:i));
                end
                y(1) = y(2);
            case 'Moving norm'
                for i = filter_MN_par:n_data
                    y(i) = norm(in_data(i - filter_MN_par + 1:i), 1);
                end
                y(1:filter_MN_par-1) = y(filter_MN_par);
            case 'EWMA'
                y(1:filter_EWMA_order) = 0;
                for i = filter_EWMA_order+1:n_data
                    y(i) = filter_EWMA_const * in_data(i)+(1-filter_EWMA_const)*y(i-filter_EWMA_order);
                end
                y(1:filter_EWMA_order) = y(filter_EWMA_order+1);
            case 'Rank order' % Rank order
                for i = 1:n_data
                    w_indata = []; pass_data = [];
                    if i<filter_Ranksize_par 
                        pass_data = [in_data(1)*ones(filter_Ranksize_par-i,1);in_data(1:i)]; 
                    else
                        pass_data = in_data(i-filter_Ranksize_par+1:i); 
                    end
                    w_indata = sort(pass_data);
                    y(i) = w_indata(filter_Rankorder_par);
                end
           case 'User defined'
                x = in_data;
                y = zeros(1, n_data);
                NaN_list = [];
                for i = 1:n_data
                    try
                        y(i) = eval(filter_USER_par);
                    catch ME;
                        % Get last segment of the error message identifier.
                        idSegLast = regexp(ME.identifier, '(?<=:)\w+$', ...
                            'match');
                        
                        % Did the execution failed because of index problems?
                        if strcmp(idSegLast, 'badsubscript')
                            % Yes. Mark the number then go to the next step.
                            NaN_list = [NaN_list i]; %#ok<AGROW>
                            continue
                        else
                            % The function was not ok. Issue the warning and break the
                            % loop.
                            error_box = errordlg('The entered filter is not valid.', ...
                                'Invalid Filter', 'modal');
                            uiwait(error_box)
                            break
                        end
                    end
                end
                if ~isempty(NaN_list)
                    y(NaN_list) = y(NaN_list(end)+1);
                end
        end
        % make sure the data is column vector
        y = y(:);
    end
%%
    function apply_design(data_name) 
        h_wait = dialog('pos', CenterFigure(300, 100));
        uicontrol('Parent', h_wait, 'Style', 'text', ...
            'Position', [75 40 150 20], ...
            'FontSize', 10, ...
            'String' , 'Designing. Please wait ...');
        pause(0.1)
        
        switch data_name
            case 'original'
                current_data = in_data; 
                HAL_clear{1} = HAL_raise{1} - HAL_DB{1};
                LAL_clear{1} = LAL_raise{1} + LAL_DB{1};
                if HAL_DB{1} > 0 
                    is_deadband_HAL{1} = 1; 
                else
                    is_deadband_HAL{1} = 0;
                end
                if LAL_DB{1} > 0 
                    is_deadband_LAL{1} = 1; 
                else
                    is_deadband_LAL{1} = 0;
                end

          case 'design'
                % filter 
                val = get(h_pm_filter,'Value');
                str = get(h_pm_filter,'String');
                filter_type = str{val};
                current_data = filter_data(filter_type); 
                
                % HAL
                val = get(h_pm_method_HAL,'Value');
                switch val
                    case 1  % 'None'
                        HAL_raise{2} = inf;
                    case 2  % 'Alarm rate (%)'
                        alpha_HAL = str2double(get(h_edit_alpha_HAL,'String'))/100;
%                        dist_p_normal{2} = mle(current_data(1:n_normal), 'dist', 'normal'); 
%                        HAL_raise{2} = icdf('normal', 1-alpha_HAL, dist_p_normal{2}(1), dist_p_normal{2}(2));
%                        [dist_type_normal{2}, dist_p_normal{2}] = find_dist(current_data(1:n_normal), 'SQRT', 'two'); 
%                        HAL_raise{2} = dist_icdf(dist_type_normal{2}, 1-alpha_HAL, dist_p_normal{2});
                        HAL_raise{2} = ksdensity(current_data(1:n_normal),1-alpha_HAL,'function','icdf');
                    case 3  % 'Maximum data'
                        HAL_raise{2} = max(current_data(1:n_normal));
                    case 4  % 'User defined'
                        user_HAL = str2double(get(h_edit_user_HAL,'String'));
                        HAL_raise{2} = user_HAL;
                end
                % HAL_DB
                str = get(h_pm_deadband_HAL,'String');
                val = get(h_pm_deadband_HAL,'Value');
                switch str{val}
                    case  'None'
                        HAL_DB{2} = 0;
                        is_deadband_HAL{2} = 0;
                    case  'Percent of significance (%)'
                        deadband_percent_HAL = str2double(get(h_edit_deadband_percent_HAL,'String'))/100;
                        HAL_DB{2} = abs(HAL_raise{2})*deadband_percent_HAL;
                        is_deadband_HAL{2} = 1;
                    case  'User defined'
                        deadband_user_HAL = str2double(get(h_edit_deadband_user_HAL,'String'));
                        HAL_DB{2} = deadband_user_HAL;
                        is_deadband_HAL{2} = 1;
                end
                if isinf(HAL_DB{2})
                    HAL_DB{2} = 0;
                end
                HAL_clear{2} = HAL_raise{2} - HAL_DB{2};
                if HAL_DB{2}>0
                    is_deadband_HAL{2} = 1;
                else
                    is_deadband_HAL{2} = 0;
                end
        
                % LAL
                val = get(h_pm_method_LAL,'Value');
                switch val
                    case 1  % 'None'
                        LAL_raise{2} = -inf;
                    case 2  % 'Alarm rate (%)'
                        alpha_LAL = str2double(get(h_edit_alpha_LAL,'String'))/100;
%                        dist_p_normal{2} = mle(current_data(1:n_normal), 'dist', 'normal'); 
%                        LAL_raise{2} = icdf('normal', alpha_LAL, dist_p_normal{2}(1), dist_p_normal{2}(2));
%                        [dist_type_normal{2}, dist_p_normal{2}] = find_dist(current_data(1:n_normal), 'SQRT', 'two'); 
%                        LAL_raise{2} = dist_icdf(dist_type_normal{2}, alpha_LAL, dist_p_normal{2});
                        LAL_raise{2} = ksdensity(current_data(1:n_normal),alpha_LAL,'function','icdf');
                    case 3  % 'Minimum data'
                        LAL_raise{2} = min(current_data(1:n_normal));
                    case 4  % 'User defined'
                        user_LAL = str2double(get(h_edit_user_LAL,'String'));
                        LAL_raise{2} = user_LAL;
                end
                % LAL_DB
                str = get(h_pm_deadband_LAL,'String');
                val = get(h_pm_deadband_LAL,'Value');
                switch str{val}
                    case  'None'
                        LAL_DB{2} = 0;
                        is_deadband_LAL{2} = 0;
                    case  'Alarm rate (%)'
                        deadband_percent_LAL = str2double(get(h_edit_deadband_percent_LAL,'String'))/100;
                        LAL_DB{2} = abs(LAL_raise{2})*deadband_percent_LAL;
                        is_deadband_LAL{2} = 1;
                    case  'User defined'
                        deadband_user_LAL = str2double(get(h_edit_deadband_user_LAL,'String'));
                        LAL_DB{2} = deadband_user_LAL;
                        is_deadband_LAL{2} = 1;
                end
                if isinf(LAL_DB{2})
                    LAL_DB{2} = 0;
                end
                LAL_clear{2} = LAL_raise{2} + LAL_DB{2};
                if LAL_DB{2}>0
                    is_deadband_LAL{2} = 1;
                else
                    is_deadband_LAL{2} = 0;
                end
                
                % Delay
                delay_on{2} = str2double(get(h_edit_delay_on, 'String'));
                delay_off{2} = str2double(get(h_edit_delay_off, 'String'));
        end
        
        plot_data(data_name);
        plot_trippoint(data_name);
        Get_alarms(data_name);
        plot_alarms(data_name);
        Get_alarmperf(data_name);

        delete(h_wait)

    end
%%
    function callback_pb_almclear(hObject, eventdata)
        HAL_raise{2} = inf;
        LAL_raise{2} = -inf;
        HAL_DB{2} = 0;
        LAL_DB{2} = 0;
        is_deadband_HAL{2} = 0;
        is_deadband_LAL{2} = 0;
        delay_on{2} = 1; delay_off{2} = 1;
        set(h_edit_delay_on, 'String', num2str(delay_on{2}));
        set(h_edit_delay_off, 'String', num2str(delay_on{2}));
        
        set(h_pm_method_HAL,'Value',1); 
        set(h_pm_method_LAL,'Value',1);

        set(h_edit_user_HAL, 'Visible','off');
        set(h_edit_alpha_HAL, 'Visible','off');
        set(h_edit_user_LAL, 'Visible','off');
        set(h_edit_alpha_LAL, 'Visible','off');
 
        set(h_pm_deadband_HAL, 'Enable', 'off');
        set(h_pm_deadband_HAL, 'Value', 1);
        set(h_edit_deadband_percent_HAL, 'Visible', 'off');
        set(h_edit_deadband_user_HAL, 'Visible', 'off');
        set(h_pm_deadband_LAL, 'Enable', 'off');
        set(h_pm_deadband_LAL, 'Value', 1);
        set(h_edit_deadband_percent_LAL, 'Visible', 'off');
        set(h_edit_deadband_user_LAL, 'Visible', 'off');

        set(h_edit_delay_on, 'Enable', 'off');
        set(h_edit_delay_off, 'Enable', 'off');
        set(h_pb_delayopt, 'Enable', 'off');
        set(h_pb_almclear, 'Enable', 'off');
        apply_design('design');
    end
%%
    function close_request(hObject, eventdata) 
        % Callback function run when the Close button is pressed
        selection = questdlg('Are you sure you want to close?',...
                    'Close Alarm Designer',...
                    'Yes', 'No' , 'No');
        switch selection
            case 'Yes'
                delete(hObject);
            otherwise
                return
        end
        
        home=findobj('Tag','MasterGUIfigure');

        if ~isempty(home)
            % find one.fig
            home=guihandles(home);
            aaa=guidata(home.MasterGUIfigure);
        
            set(home.WTAlarmCF, 'string', 'Start');

            if aaa.WTAlarmCF_Enable==1
                set(home.WTAlarmCF,'enable','on');
            end
        else
            %not find one.fig
            errordlg('not found Master GUI.','Error');
        end
    end
%%
    function plot_data(data_name)
        switch data_name
            case 'original'
                current_data = in_data; id = 1;
            case 'design'
                current_data = design_data; id = 2;
        end
        delete(h_data_normal{id});
        delete(h_data_faulty{id});
        n_data = length(current_data);
        white_area = (max(current_data) - min(current_data))*0.15;
        set(h_axes{id}, 'XLim',[0 n_data], 'YLim',[min(current_data)-white_area max(current_data)+white_area], 'XTickMode', 'auto', 'YTickMode', 'auto');
%        set(h_axes{id}, 'XLim',[0 n_data], 'XTickMode', 'auto', 'YTickMode', 'auto');
        h_data_normal{id} = plot(h_axes{id}, 1:n_normal, current_data(1:n_normal), 'Color', color_normal);
        if is_faulty
            h_data_faulty{id} = plot(h_axes{id}, n_normal+1:n_data, current_data(n_normal+1:n_data), 'Color', color_faulty);
        end
%        data_ylim{id} = get(h_axes{id},'YLim'); 

        % plot histogram and PDF
        if ~isempty(h_hist_HAL_raise{id}) delete(h_hist_HAL_raise{id}); h_hist_HAL_raise{id} = []; end
        if ~isempty(h_hist_HAL_clear{id}) delete(h_hist_HAL_clear{id}); h_hist_HAL_clear{id} = []; end
        if ~isempty(h_hist_LAL_raise{id}) delete(h_hist_LAL_raise{id}); h_hist_LAL_raise{id} = []; end
        if ~isempty(h_hist_LAL_clear{id}) delete(h_hist_LAL_clear{id}); h_hist_LAL_clear{id} = []; end
        delete(h_bins_normal{id});
        delete(h_pdf_normal{id});
        set(h_hist{id}, 'XLim',[min(current_data)-white_area max(current_data)+white_area], 'XTickMode', 'auto', 'YTickMode', 'auto');
%         set(h_hist{id}, 'XLim',data_ylim{id}, 'XTickMode', 'auto', 'YTickMode', 'auto');
 
        x_temp = linspace(min(current_data), max(current_data));
        [y_temp_n, count_hist_n, center_hist_n] = Get_PDF(current_data(1:n_normal), x_temp);
        % Plot distribution for normal data
        h_bins_normal{id} = bar(h_hist{id}, center_hist_n, count_hist_n, 'hist');
        view(h_hist{id},[90 270]);
        set(h_bins_normal{id}, 'FaceColor', 'none', 'EdgeColor', color_normal, 'LineStyle', '-', 'LineWidth', 1);
        % Plot probability distribution function (PDF) for normal data
        h_pdf_normal{id}= plot(h_hist{id}, x_temp, y_temp_n, 'Color', color_normal, 'LineWidth', 1.5);

        if is_faulty
            delete(h_bins_faulty{id});
            delete(h_pdf_faulty{id});
            [y_temp_f, count_hist_f, center_hist_f] = Get_PDF(current_data(1+n_normal:n_data), x_temp);
            % Plot distribution for faulty data
            h_bins_faulty{id} = bar(h_hist{id}, center_hist_f, count_hist_f, 'hist');
            view(h_hist{id},[90 270]);
            set(h_bins_faulty{id}, 'FaceColor', 'none', 'EdgeColor', color_faulty, 'LineStyle', '-', 'LineWidth', 1);
            % Plot probability distribution function (PDF) for normal data
            h_pdf_faulty{id} = plot(h_hist{id}, x_temp, y_temp_f, 'Color', color_faulty, 'LineWidth', 1.5);
        end
    end
%%
    function plot_trippoint(data_name)
        switch data_name
            case 'original'
                current_data = in_data; id =1;
            case 'design'
                current_data = design_data; id = 2;
        end
        ylim_hist = get(h_hist{id}, 'YLim');
        
        % High alarm limit
        delete(h_line_HAL_raise{id});
        delete(h_line_HAL_clear{id});
        delete(h_hist_HAL_raise{id});
        delete(h_hist_HAL_clear{id});
        if isinf(HAL_raise{id})
            h_line_HAL_raise{id} = [];
            h_line_HAL_clear{id} = [];
            h_hist_HAL_raise{id} = [];
            h_hist_HAL_clear{id} = [];
        elseif is_deadband_HAL{id}
            h_line_HAL_raise{id} = plot(h_axes{id}, [0 n_data], [HAL_raise{id} HAL_raise{id}], 'g', ...
                'LineWidth', 1.5, 'LineStyle', '-');
            h_line_HAL_clear{id} = plot(h_axes{id}, [0 n_data], [HAL_clear{id} HAL_clear{id}], 'g', ...
                'LineWidth', 1.5, 'LineStyle', '--');
            h_hist_HAL_raise{id} = plot(h_hist{id}, [HAL_raise{id} HAL_raise{id}], ylim_hist, 'g', ...
                'LineWidth', 1.5, 'LineStyle', '-');
            h_hist_HAL_clear{id} = plot(h_hist{id}, [HAL_clear{id} HAL_clear{id}], ylim_hist, 'g', ...
                'LineWidth', 1.5, 'LineStyle', '--');
        else
            h_line_HAL_raise{id} = plot(h_axes{id}, [0 n_data], [HAL_raise{id} HAL_raise{id}], 'g', ...
                'LineWidth', 1.5, 'LineStyle', '-');
            h_line_HAL_clear{id} = [];
            h_hist_HAL_raise{id} = plot(h_hist{id}, [HAL_raise{id} HAL_raise{id}], ylim_hist, 'g', ...
                'LineWidth', 1.5, 'LineStyle', '-');
            h_hist_HAL_clear{id} = [];
        end
        
        % Low alarm limt
        delete(h_line_LAL_raise{id});
        delete(h_line_LAL_clear{id});
        delete(h_hist_LAL_raise{id});
        delete(h_hist_LAL_clear{id});
        if isinf(LAL_raise{id})
            h_line_LAL_raise{id} = [];
            h_line_LAL_clear{id} = [];
            h_hist_LAL_raise{id} = [];
            h_hist_LAL_clear{id} = [];
        elseif is_deadband_LAL{id}
            h_line_LAL_raise{id} = plot(h_axes{id}, [0 n_data], [LAL_raise{id} LAL_raise{id}], 'g', ...
                'LineWidth', 1.5, 'LineStyle', '-');
            h_line_LAL_clear{id} = plot(h_axes{id}, [0 n_data], [LAL_clear{id} LAL_clear{id}], 'g', ...
                'LineWidth', 1.5, 'LineStyle', '--');
            h_hist_LAL_raise{id} = plot(h_hist{id}, [LAL_raise{id} LAL_raise{id}], ylim_hist, 'g', ...
                'LineWidth', 1.5, 'LineStyle', '-');
            h_hist_LAL_clear{id} = plot(h_hist{id}, [LAL_clear{id} LAL_clear{id}], ylim_hist, 'g', ...
                'LineWidth', 1.5, 'LineStyle', '--');
        else
            h_line_LAL_raise{id} = plot(h_axes{id}, [0 n_data], [LAL_raise{id} LAL_raise{id}], 'g', ...
                'LineWidth', 1.5, 'LineStyle', '-');
            h_line_LAL_clear{id} = [];
            h_hist_LAL_raise{id} = plot(h_hist{id}, [LAL_raise{id} LAL_raise{id}], ylim_hist, 'g', ...
                'LineWidth', 1.5, 'LineStyle', '-');
            h_hist_LAL_clear{id} = [];
        end
    end
%%
    function plot_alarms(data_name)
        switch data_name
            case 'original'
                current_data = in_data; id =1;
            case 'design'
                current_data = design_data; id = 2;
        end

        delete(h_alarms{id});
        h_alarms{id} = []; 
        %temp0 = mean(current_data(1:n_normal));
        temp0 = (min(HAL_raise{id},max(current_data(1:n_normal))) + max(LAL_raise{id},min(current_data(1:n_normal))))/2;
        for i=1:size(alarm_time_hi{id}, 2)
%            h_alarms{id}(end+1) = plot(h_alm{id},[alarm_time_hi{id}(i) alarm_time_hi{id}(i) RTN_time_hi{id}(i) RTN_time_hi{id}(i)], [0 1 1 0], color_alarm);
            h_alarms{id}(end+1) = plot(h_axes{id},[alarm_time_hi{id}(i) alarm_time_hi{id}(i) RTN_time_hi{id}(i) RTN_time_hi{id}(i)], [temp0 HAL_raise{id} HAL_raise{id} temp0], color_alarm);
        end
%        for i=1:size(alarm_time_hi{id},2)-1
%            h_alarms{id}(end+1) = plot(h_axes{id},[RTN_time_hi{id}(i) alarm_time_hi{id}(i+1)], [temp0 temp0], color_alarm);
%        end
%        h_alarms{id}(end+1) = plot(h_axes{id},[0 alarm_time_hi{id}(1)], [temp0 temp0], color_alarm);

        for i=1:size(alarm_time_lo{id}, 2)
%            h_alarms{id}(end+1) = plot(h_alm{id},[alarm_time_lo{id}(i) alarm_time_lo{id}(i) RTN_time_lo{id}(i) RTN_time_lo{id}(i)], [0 -1 -1 0], color_alarm);
            h_alarms{id}(end+1) = plot(h_axes{id},[alarm_time_lo{id}(i) alarm_time_lo{id}(i) RTN_time_lo{id}(i) RTN_time_lo{id}(i)], [temp0 LAL_raise{id} LAL_raise{id} temp0], color_alarm);
        end
%        for i=1:size(alarm_time_lo{id},2)-1
%            h_alarms{id}(end+1) = plot(h_axes{id},[RTN_time_lo{id}(i) alarm_time_lo{id}(i+1)], [temp0 temp0], color_alarm);
%        end
%        h_alarms{id}(end+1) = plot(h_axes{id},[0 n_data], [temp0 temp0], color_alarm);

        set(h_text_HAL{id},'String',num2str(HAL_raise{id},'%6.2f'));
        set(h_text_HAL_DB{id},'String',num2str(HAL_clear{id},'%6.2f'));
        set(h_text_LAL{id},'String',num2str(LAL_raise{id},'%6.2f'));
        set(h_text_LAL_DB{id},'String',num2str(LAL_clear{id},'%6.2f'));
    end
%%
    function Get_alarms(data_name)
        switch data_name
            case 'original'
                current_data = in_data; id = 1;
            case 'design'
                current_data = design_data; id = 2;
        end
        
        is_fault_lo = 0;
        is_fault_hi = 0;
        alarm_time_hi{id} = [];
        alarm_time_lo{id} = [];
        RTN_time_hi{id} = [];
        RTN_time_lo{id} = [];

        for i = delay_on{id}+1:n_data
            switch is_fault_hi
                case false
                    is_fault_hi = all(current_data(i-delay_on{id}+1:i) > HAL_raise{id});
                    if is_fault_hi
                        alarm_time_hi{id}(end+1) = i;
                    end
                case true
                    if delay_off{id} > i
                        continue
                    end
                    is_fault_hi = ~all(current_data(i-delay_off{id}+1:i) < HAL_clear{id});
                    if ~is_fault_hi
                        RTN_time_hi{id}(end+1) = i;
                    end
            end
            
            switch is_fault_lo
                case false
                    is_fault_lo = all(current_data(i-delay_on{id}+1:i) < LAL_raise{id});
                    if is_fault_lo
                        alarm_time_lo{id}(end+1) = i;
                    end
                case true
                    if delay_off{id} > i
                        continue
                    end
                    is_fault_lo = ~all(current_data(i-delay_off{id}+1:i) > LAL_clear{id});
                    if ~is_fault_lo
                        RTN_time_lo{id}(end+1) = i;
                    end
            end
        end
        
        if size(alarm_time_hi{id}, 2) ~= size(RTN_time_hi{id}, 2)
            RTN_time_hi{id}(end+1) = n_data;
        end
        
        if size(alarm_time_lo{id}, 2) ~= size(RTN_time_lo{id}, 2)
            RTN_time_lo{id}(end+1) = n_data;
        end
    end
%%
    function Get_alarmperf(data_name)
        switch data_name
            case 'original'
                current_data = in_data; id = 1;
            case 'design'
                current_data = design_data; id = 2;
        end
        
        % Calcualting number of faults and alarms
        n_faults_hi = sum(RTN_time_hi{id}-alarm_time_hi{id});
        n_faults_lo = sum(RTN_time_lo{id}-alarm_time_lo{id});
        n_faults_total = sum(n_faults_hi+n_faults_lo);
        n_alarms_hi = size(alarm_time_hi{id}, 2);
        n_alarms_lo = size(alarm_time_lo{id}, 2);
        n_alarms_total = n_alarms_hi+n_alarms_lo;
        
        alarm_report{id}(1) = n_alarms_total; % Alarm count
        alarm_report{id}(2) = n_alarms_hi; % High alarm count
        alarm_report{id}(3) = n_alarms_lo; % Low alarm count
        alarm_report{id}(4) = n_faults_total; % Alarm points
        alarm_report{id}(5) = n_faults_hi; % High alarm points
        alarm_report{id}(6) = n_faults_lo; % Low alarm points
    
        if is_faulty
            first_alarm_hi = find(alarm_time_hi{id} > n_normal, 1, 'first');
            first_RTN_hi = find(RTN_time_hi{id} > n_normal, 1, 'first');
            if isempty(first_alarm_hi)
                alarm_report{id}(8) = n_alarms_hi; % False high alarms
                if isempty(first_RTN_hi)
                    n_faults_false_hi = n_faults_hi;
                    n_faults_true_hi = 0;
                else
                    n_faults_false_hi = sum(RTN_time_hi{id}(1:end-1)-alarm_time_hi{id}(1:end-1)) + ...
                            n_normal - alarm_time_hi{id}(end);
                    n_faults_true_hi = RTN_time_hi{id}(first_RTN_hi) -n_normal;
                end
            else
                alarm_report{id}(8) = first_alarm_hi-1; % False high alarms
                if first_alarm_hi == first_RTN_hi
                    n_faults_false_hi = sum(RTN_time_hi{id}(1:first_alarm_hi-1)-alarm_time_hi{id}(1:first_alarm_hi-1));
                    n_faults_true_hi = sum(RTN_time_hi{id}(first_alarm_hi:end)-alarm_time_hi{id}(first_alarm_hi:end));
                else
                    n_faults_false_hi = sum(RTN_time_hi{id}(1:first_alarm_hi-2)-alarm_time_hi{id}(1:first_alarm_hi-2)) + ...
                        n_normal - alarm_time_hi{id}(first_alarm_hi-1);
                    n_faults_true_hi = RTN_time_hi{id}(first_RTN_hi) -n_normal + ...
                        sum(RTN_time_hi{id}(first_alarm_hi:end)-alarm_time_hi{id}(first_alarm_hi:end));
                end
            end

            first_alarm_lo = find(alarm_time_lo{id} > n_normal, 1, 'first');
            first_RTN_lo = find(RTN_time_lo{id} > n_normal, 1, 'first');
            if isempty(first_alarm_lo)
                if isempty(first_RTN_lo)
                    alarm_report{id}(9) = n_alarms_lo; % False low alarms
                    n_faults_false_lo = n_faults_lo;
                    n_faults_true_lo = 0;
                else
                    n_faults_false_lo = sum(RTN_time_lo{id}(1:end-1)-alarm_time_lo{id}(1:end-1)) + ...
                        n_normal - alarm_time_lo{id}(end);
                    n_faults_true_lo = RTN_time_lo{id}(first_RTN_lo) -n_normal;
                end
            else
                alarm_report{id}(9) = first_alarm_lo-1; % False low alarms
                if first_alarm_lo == first_RTN_lo
                    n_faults_false_lo = sum(RTN_time_lo{id}(1:first_alarm_lo-1)-alarm_time_lo{id}(1:first_alarm_lo-1));
                    n_faults_true_lo = sum(RTN_time_lo{id}(first_alarm_lo:end)-alarm_time_lo{id}(first_alarm_lo:end));
                else
                    n_faults_false_lo = sum(RTN_time_lo{id}(1:first_alarm_lo-2)-alarm_time_lo{id}(1:first_alarm_lo-2)) + ...
                        n_normal - alarm_time_lo{id}(first_alarm_lo-1);
                    n_faults_true_lo = RTN_time_lo{id}(first_RTN_lo) -n_normal + ...
                        sum(RTN_time_lo{id}(first_alarm_lo:end)-alarm_time_lo{id}(first_alarm_lo:end));
                end
            end
            alarm_report{id}(7) = alarm_report{id}(8)+alarm_report{id}(9); % False alarms
            
            n_faults_false = n_faults_false_hi + n_faults_false_lo;
            n_faults_true = n_faults_true_hi + n_faults_true_lo;
            n_faults_missed = n_data - n_normal - n_faults_true;

            alarm_report{id}(10) = n_faults_false; % False alarm points
            alarm_report{id}(11) = n_faults_false_hi; % False high alarm points
            alarm_report{id}(12) = n_faults_false_lo; % False low alarm points

            alarm_report{id}(13) = n_alarms_total-alarm_report{id}(7); % True alarms 
            alarm_report{id}(14) = n_alarms_hi-alarm_report{id}(8); % True high alarms
            alarm_report{id}(15) = n_alarms_lo-alarm_report{id}(9); % True low alarms

            alarm_report{id}(16) = n_faults_true; % True alarm points
            alarm_report{id}(17) = n_faults_true_hi; % True high alarm points
            alarm_report{id}(18) = n_faults_true_lo; % True low alarm points

            alarm_report{id}(19) = max(0,n_faults_missed); % Missed alarm points
%            switch filter_type 
%                case 'Rank order'
%                    x_temp = linspace(min(current_data), max(current_data),1000);
%                    [FAR_f,MAR_f,EDD_f]=Eval_rankfilter(current_data(1:n_normal), current_data(1+n_normal:n_data), x_temp, filter_Ranksize_par, filter_Rankorder_par, HAL_raise{id});
%                    alarm_report{id}(20) = EDD_f;
%                case 'None'
%                    [FAR_HALx,MAR_HALx,ADD_HALx,FAR_LALx,MAR_LALx,ADD_LALx] = Eval_alarm(current_data(1:n_normal), current_data(1+n_normal:n_data),[HAL_raise{id} LAL_raise{id}],delay_on{id},delay_off{id},[HAL_DB{id} LAL_DB{id}]);
%                    alarm_report{id}(20) = ADD_HALx(1);
%                otherwise
%                        alarm_report{id}(20) = 0;
%            end
        end
        set(h_table1,'Data',[alarm_report{1}(1:3)' alarm_report{1}(7:9)';alarm_report{2}(1:3)' alarm_report{2}(7:9)']); 
        set(h_table2,'Data',[alarm_report{1}(4:6)' alarm_report{1}(10) alarm_report{1}(19) alarm_report{1}(10)*100/n_normal alarm_report{1}(19)*100/(n_data-n_normal);
                             alarm_report{2}(4:6)' alarm_report{2}(10) alarm_report{2}(19) alarm_report{2}(10)*100/n_normal alarm_report{2}(19)*100/(n_data-n_normal)]); 
    end
%%
    function Eval_alarmperf(data_name)
    % compute the false alarm rate (FAR), missed alarm rate (MAR), and average detection delay (ADD)
    h_wait = dialog('pos', CenterFigure(300, 100));
    uicontrol('Parent', h_wait, 'Style', 'text', ...
            'Position', [75 40 150 20], ...
            'FontSize', 10, ...
            'String' , 'Computing. Please wait ...');
    pause(0.1)
    switch data_name
            case 'original'
                current_data = in_data; id = 1;
            case 'design'
                current_data = design_data; id = 2;
        end
        if is_faulty % only when there are faulty data
            x_tmp = [linspace(min(current_data), max(current_data), 1000)];
            x_temp = [x_tmp HAL_raise{id}];
            n = delay_on{id};
            m = delay_off{id};
            % HAL
            p1_HAL{id} = 1 - ksdensity(current_data(1:n_normal), x_temp, 'function', 'cdf');
            p2_HAL{id} =  ksdensity(current_data(1:n_normal), x_temp-HAL_DB{id}, 'function', 'cdf');
            q1_HAL{id} = ksdensity(current_data(n_normal+1:n_data), x_temp-HAL_DB{id}, 'function', 'cdf');
            q2_HAL{id} = 1 - ksdensity(current_data(1+n_normal:n_data), x_temp, 'function', 'cdf');
            
            p2_sum = zeros(size(x_temp));
            for i=1:m
                p2_sum = p2_sum + p2_HAL{id}.^(i-1);
            end
            p1_sum = zeros(size(x_temp)); 
            for i=1:n
                p1_sum = p1_sum + p1_HAL{id}.^(i-1);
            end
            FAR_HAL{id} = (p1_HAL{id}.^n).*p2_sum./((p1_HAL{id}.^n).*p2_sum + (p2_HAL{id}.^m).*p1_sum);
                
            q1_sum = zeros(size(x_temp));
            for i=1:m
                q1_sum = q1_sum + q1_HAL{id}.^(i-1);
            end
            q2_sum = zeros(size(x_temp));
            for i=1:n
                q2_sum = q2_sum + q2_HAL{id}.^(i-1);
            end
            MAR_HAL{id} = (q1_HAL{id}.^m).*q2_sum./((q1_HAL{id}.^m).*q2_sum + (q2_HAL{id}.^n).*q1_sum);
            
            pq_sum = zeros(size(x_temp));
            for j=0:n-1
                for k=0:n-j-1
                    pq_sum = pq_sum + (p1_HAL{id}.^j) .* (q2_HAL{id}.^k);
                end
            end
            ADD_HAL{id} = p2_HAL{id}.^(m-1).*(p1_HAL{id}.^n .* q1_HAL{id}.*q2_sum + p2_HAL{id}.*(pq_sum - q2_HAL{id}.^n .* p1_sum))./(q2_HAL{id}.^n .* (p2_HAL{id}.^m .* p1_sum + p1_HAL{id}.^n .* p2_sum));
%            ADD_HAL{id} = (1-q2_HAL{id}.^n .* - q1_HAL{id} .* q2_HAL{id}.^n)./(q1_HAL{id} .* q2_HAL{id}.^n);
            
            % LAL
            x_temp = [x_tmp LAL_raise{id}];
            p1_LAL{id} =  ksdensity(current_data(1:n_normal), x_temp, 'function', 'cdf');
            p2_LAL{id} = 1- ksdensity(current_data(1:n_normal), x_temp+LAL_DB{id}, 'function', 'cdf');
            q1_LAL{id} = 1-ksdensity(current_data(n_normal+1:n_data), x_temp+LAL_DB{id}, 'function', 'cdf');
            q2_LAL{id} =  ksdensity(current_data(1+n_normal:n_data), x_temp, 'function', 'cdf');
 
            p2_sum = zeros(size(x_temp));
            for i=1:m
                p2_sum = p2_sum + p2_LAL{id}.^(i-1);
            end
            p1_sum = zeros(size(x_temp)); 
            for i=1:n
                p1_sum = p1_sum + p1_LAL{id}.^(i-1);
            end
            FAR_LAL{id} = (p1_LAL{id}.^n).*p2_sum./((p1_LAL{id}.^n).*p2_sum + (p2_LAL{id}.^m).*p1_sum);
                
            q1_sum = zeros(size(x_temp));
            for i=1:m
                q1_sum = q1_sum + q1_LAL{id}.^(i-1);
            end
            q2_sum = zeros(size(x_temp));
            for i=1:n
                q2_sum = q2_sum + q2_LAL{id}.^(i-1);
            end
            MAR_LAL{id} = (q1_LAL{id}.^m).*q2_sum./((q1_LAL{id}.^m).*q2_sum + (q2_LAL{id}.^n).*q1_sum);
            
            pq_sum = zeros(size(x_temp));
            for j=0:n-1
                for k=0:n-j-1
                    pq_sum = pq_sum + (p1_LAL{id}.^j) .* (q2_LAL{id}.^k);
                end
            end
            ADD_LAL{id} = p2_LAL{id}.^(m-1).*(p1_LAL{id}.^n .* q1_LAL{id}.*q2_sum + p2_LAL{id}.*(pq_sum - q2_LAL{id}.^n .* p1_sum))./(q2_LAL{id}.^n .* (p2_LAL{id}.^m .* p1_sum + p1_LAL{id}.^n .* p2_sum));
        else
            FAR_HAL{id} = [];
            MAR_HAL{id} = [];
            ADD_HAL{id} = [];
            FAR_LAL{id} = [];
            MAR_LAL{id} = [];
            ADD_LAL{id} = [];
        end
        delete(h_wait);
    end
%%
    function ALMlimit_opt(hObject, eventdata)
%        [dist_type_normal{2},dist_p_normal{2}] = find_dist(design_data(1:n_normal), 'SQRT', 'two');
%        [dist_type_faulty{2},dist_p_faulty{2}] = find_dist(design_data(n_normal+1:n_data), 'SQRT', 'two');
%        x_temp = linspace(min(design_data), max(design_data), 1000);
%        val = get(h_pm_deadband_HAL,'Value');
%        str = get(h_pm_deadband_HAL,'String');
%        switch str{val}
%            case 'Percent of alarm limit (%)'
 %               p1_normal = 1 - dist_cdf(dist_type_normal{2}, x_temp, dist_p_normal{2});
 %               p2_normal = dist_cdf(dist_type_normal{2}, x_temp-deadband_percent_HAL/100*abs(x_temp), dist_p_normal{2});
 %               p1_faulty = 1 - dist_cdf(dist_type_faulty{2}, x_temp, dist_p_faulty{2});
 %               p2_faulty = dist_cdf(dist_type_faulty{2}, x_temp-deadband_percent_HAL/100*abs(x_temp), dist_p_faulty{2});
 %               p2_normal = ksdensity(design_data(1:n_normal), x_temp-deadband_percent_HAL/100*abs(x_temp), 'function', 'cdf');
 %               p1_normal = 1 - ksdensity(design_data(1:n_normal), x_temp, 'function', 'cdf');;
 %               p2_faulty = ksdensity(design_data(1+n_normal:n_data), x_temp-deadband_percent_HAL/100*abs(x_temp), 'function', 'cdf');
 %               p1_faulty = 1 - ksdensity(design_data(1+n_normal:n_data), x_temp, 'function', 'cdf');;
                
 %           case 'User defined'
%                p1_normal = 1 - dist_cdf(dist_type_normal{2}, x_temp, dist_p_normal{2});
%                p2_normal = dist_cdf(dist_type_normal{2}, x_temp-deadband_user_HAL, dist_p_normal{2});
%                p1_faulty = 1 - dist_cdf(dist_type_faulty{2}, x_temp, dist_p_faulty{2});
%                p2_faulty = dist_cdf(dist_type_faulty{2}, x_temp-deadband_user_HAL, dist_p_faulty{2});
 %               p2_normal = ksdensity(design_data(1:n_normal), x_temp-deadband_user_HAL, 'function', 'cdf');
 %               p1_normal = 1 - ksdensity(design_data(1:n_normal), x_temp, 'function', 'cdf');;
 %               p2_faulty = ksdensity(design_data(n_normal+1:n_data), x_temp-deadband_user_HAL, 'function', 'cdf');
 %               p1_faulty = 1 - ksdensity(design_data(1+n_normal:n_data), x_temp, 'function', 'cdf');;
            
 %           otherwise
%                xx_normal = dist_cdf(dist_type_normal{2}, x_temp, dist_p_normal{2});
%                p1_normal = (1-xx_normal);
%                p2_normal = xx_normal;
%                xx_faulty = dist_cdf(dist_type_faulty{2}, x_temp, dist_p_faulty{2});
%                p1_faulty = (1-xx_faulty);
%                p2_faulty = xx_faulty;
 %               p2_normal = ksdensity(design_data(1:n_normal), x_temp, 'function', 'cdf');
 %               p1_normal = 1 - p2_normal;
 %               p2_faulty = ksdensity(design_data(n_normal+1:n_data), x_temp, 'function', 'cdf');
 %               p1_faulty = 1 - p2_faulty;
 %       end
                
 %       p1_normal_sum = zeros(size(x_temp));
 %       for i=1:delay_on{2}
 %           p1_normal_sum = p1_normal_sum + p1_normal.^(i-1);
 %       end
 %       p2_normal_sum = zeros(size(x_temp));
 %       for i=1:delay_off{2}
 %           p2_normal_sum = p2_normal_sum + p2_normal.^(i-1);
 %       end
 %       P_fals_alarm_HAL = (p1_normal.^delay_on{2}).*p2_normal_sum./((p1_normal.^delay_on{2}).*p2_normal_sum + (p2_normal.^delay_off{2}).*p1_normal_sum);
        % P_fals_alarm_HAL = ...
        %     (p1_normal.^delay_on(id)).*(p2_normal.^delay_off(id)-1)./(p2_normal-1)./(...
        %     (p1_normal.^delay_on(id)).*(p2_normal.^delay_off(id)-1)./(p2_normal-1) + ...
        %     (p2_normal.^delay_off(id)).*(p1_normal.^delay_on(id)-1)./(p1_normal-1));
                
 %       p1_faulty_sum = zeros(size(x_temp));
 %       for i=1:delay_on{2}
 %           p1_faulty_sum = p1_faulty_sum + p1_faulty.^(i-1);
 %       end
 %       p2_faulty_sum = zeros(size(x_temp));
 %       for i=1:delay_off{2}
 %           p2_faulty_sum = p2_faulty_sum + p2_faulty.^(i-1);
 %       end
 %       P_miss_alarm_HAL = (p2_faulty.^delay_off{2}).*p1_faulty_sum./((p1_faulty.^delay_on{2}).*p2_faulty_sum + (p2_faulty.^delay_off{2}).*p1_faulty_sum);
                % P_miss_alarm_HAL = ...
                %     (p2_faulty.^delay_off(id)).*(p1_faulty.^delay_on(id)-1)./(p1_faulty-1)./(...
                %     (p1_faulty.^delay_on(id)).*(p2_faulty.^delay_off(id)-1)./(p2_faulty-1) + ...
                %     (p2_faulty.^delay_off(id)).*(p1_faulty.^delay_on(id)-1)./(p1_faulty-1));

%        val = get(h_pm_deadband_LAL,'Value');
%        str = get(h_pm_deadband_LAL,'String');
%        switch str{val}
%            case 'Percent of alarm limit (%)'
%                p1_normal = dist_cdf(dist_type_normal{2}, x_temp, dist_p_normal{2});
%                p2_normal = 1-dist_cdf(dist_type_normal{2}, x_temp+deadband_percent_LAL/100*abs(x_temp), dist_p_normal{2});
%                p1_faulty = dist_cdf(dist_type_faulty{2}, x_temp, dist_p_faulty{2});
%                p2_faulty = 1-dist_cdf(dist_type_faulty{2}, x_temp+deadband_percent_LAL/100*abs(x_temp), dist_p_faulty{2});
%                p1_normal = ksdensity(design_data(1:n_normal), x_temp, 'function', 'cdf');
%                p2_normal = 1 - ksdensity(design_data(1:n_normal), x_temp+deadband_percent_LAL/100*abs(x_temp), 'function', 'cdf');
%                p1_faulty = ksdensity(design_data(n_normal+1:n_data), x_temp, 'function', 'cdf');
%                p2_faulty = 1 - ksdensity(design_data(1+n_normal:n_data), x_temp+deadband_percent_LAL/100*abs(x_temp), 'function', 'cdf');
                
%            case 'User defined'
%                p1_normal = dist_cdf(dist_type_normal{2}, x_temp, dist_p_normal{2});
%                p2_normal = 1-dist_cdf(dist_type_normal{2}, x_temp+deadband_user_LAL, dist_p_normal{2});
%                p1_faulty = dist_cdf(dist_type_faulty{2}, x_temp, dist_p_faulty{2});
%                p2_faulty = 1-dist_cdf(dist_type_faulty{2}, x_temp+deadband_user_LAL, dist_p_faulty{2});
%                p1_normal = ksdensity(design_data(1:n_normal), x_temp, 'function', 'cdf');
%                p2_normal = 1 - ksdensity(design_data(1:n_normal), x_temp+deadband_user_LAL, 'function', 'cdf');
%                p1_faulty = ksdensity(design_data(n_normal+1:n_data), x_temp, 'function', 'cdf');
%                p2_faulty = 1 - ksdensity(design_data(1+n_normal:n_data), x_temp+deadband_user_LAL, 'function', 'cdf');

%            otherwise
%                xx_normal = dist_cdf(dist_type_normal{2}, x_temp, dist_p_normal{2});
%                p1_normal = xx_normal;
%                p2_normal = 1-xx_normal;
%                xx_faulty = dist_cdf(dist_type_faulty{2}, x_temp, dist_p_faulty{2});
%                p1_faulty = xx_faulty;
%                p2_faulty = 1-xx_faulty;
%                p1_normal = ksdensity(design_data(1:n_normal), x_temp, 'function', 'cdf');
%                p2_normal = 1 - p1_normal;
%                p1_faulty = ksdensity(design_data(n_normal+1:n_data), x_temp, 'function', 'cdf');
%                p2_faulty = 1 - p1_faulty;
%        end
                
                % P_fals_alarm_LAL = ...
                %     (p1_normal.^delay_on(id)).*(p2_normal.^delay_off(id)-1)./(p2_normal-1)./(...
                %     (p1_normal.^delay_on(id)).*(p2_normal.^delay_off(id)-1)./(p2_normal-1) + ...
                %     (p2_normal.^delay_off(id)).*(p1_normal.^delay_on(id)-1)./(p1_normal-1));
                
 %       p1_normal_sum = zeros(size(x_temp));
 %       for i=1:delay_on{2}
 %           p1_normal_sum = p1_normal_sum + p1_normal.^(i-1);
 %       end
 %       p2_normal_sum = zeros(size(x_temp));
 %       for i=1:delay_off{2}
 %           p2_normal_sum = p2_normal_sum + p2_normal.^(i-1);
 %       end
 %       P_fals_alarm_LAL = ...
 %                  (p1_normal.^delay_on{2}).*p2_normal_sum./(...
 %                   (p1_normal.^delay_on{2}).*p2_normal_sum + ...
 %                   (p2_normal.^delay_off{2}).*p1_normal_sum);

                % P_miss_alarm_LAL = (p2_faulty.^delay_off(id)).*(p1_faulty.^delay_on(id)-1)...
                %     ./(p1_faulty-1)./((p1_faulty.^delay_on(id)).*(p2_faulty.^delay_off(id)-1)...
                %     ./(p2_faulty-1) + (p2_faulty.^delay_off(id)).*(p1_faulty.^delay_on(id)-1)...
                %     ./(p1_faulty-1));
                
%         p1_faulty_sum = zeros(size(x_temp));
%         for i=1:delay_on{2}
%             p1_faulty_sum = p1_faulty_sum + p1_faulty.^(i-1);
%         end
%         p2_faulty_sum = zeros(size(x_temp));
%         for i=1:delay_off{2}
%             p2_faulty_sum = p2_faulty_sum + p2_faulty.^(i-1);
%         end
%         P_miss_alarm_LAL = ...
%                    (p2_faulty.^delay_off{2}).*p1_faulty_sum./(...
%                    (p1_faulty.^delay_on{2}).*p2_faulty_sum + ...
%                    (p2_faulty.^delay_off{2}).*p1_faulty_sum);

        x_temp = [linspace(min(design_data), max(design_data), 1000)];
        Eval_alarmperf('design');
        LAL_raise{2} = LAL_raise{1}; HAL_raise{2} = HAL_raise{1};

        % optimize HAL
        distance = FAR_HAL{2}(1:1000).^2 + MAR_HAL{2}(1:1000).^2;
        start_LAL = find(x_temp > LAL_raise{2}, 1, 'first');
        [dist_best, point_best] = min(distance(start_LAL:end));
        HAL_raise{2} = x_temp(start_LAL + point_best - 1);
        set(h_pm_method_HAL, 'String',HAL_alarmlimit_methods,'Value',4);
        set(h_edit_user_HAL, 'Visible','on');
        set(h_edit_user_HAL,'String',num2str(HAL_raise{2},'%-6.2f'));
        set(h_pm_deadband_HAL, 'Enable', 'on');
        
        % optimize LAL
        distance = FAR_LAL{2}(1:1000).^2 + MAR_LAL{2}(1:1000).^2;
        end_HAL = find(x_temp >= HAL_raise{2}, 1, 'first');
        if isempty(end_HAL)
             end_HAL = 1000;
        end
        [dist_best, point_best] = min(distance(1:end_HAL));
        LAL_raise{2} = x_temp(point_best);
        set(h_pm_method_LAL, 'String', LAL_alarmlimit_methods,'Value',4);
        set(h_edit_user_LAL, 'Visible','on');
        set(h_edit_user_LAL,'String',num2str(LAL_raise{2},'%-6.2f'));
        set(h_pm_deadband_LAL, 'Enable', 'on');

        set(h_edit_delay_on, 'Enable', 'on');
        set(h_edit_delay_off, 'Enable', 'on');
        set(h_pb_delayopt, 'Enable', 'on');
        set(h_pb_almclear, 'Enable', 'on');
        apply_design('design');
    
    end
%%
    function callback_plotroc(hObject, eventdata)
        h_plotroc = [];
        h_axes_roc_hi = []; h_axes_roc_lo = [];
        h_farmar_hal = []; h_farmar_lal = [];
        h_farmar_halp = []; h_farmar_lalp = [];
        txt_farmar_hal1 = []; txt_farmar_hal2 = [];
        txt_farmar_hal3 = []; txt_farmar_hal4 = [];
        txt_farmar_lal1 = []; txt_farmar_lal2 = [];
        txt_farmar_lal3 = []; txt_farmar_lal4 = [];

        Eval_alarmperf('design'); id = 2;
        width_roc = 800;
        height_roc = 460;
        
        pos_plotroc = CenterFigure(width_roc, height_roc);
        size_plotroc = [pos_plotroc(3:4) pos_plotroc(3:4)];
        h_plotroc = figure('Visible', 'on', 'Position', pos_plotroc, ...
            'Name', 'ROC ', 'NumberTitle', 'off', ...
            'Resize', 'on', 'MenuBar', 'none', ...
            'Color', defaultBackground, ...
            'Toolbar', 'auto');
        set(h_plotroc, 'Color', defaultBackground)
   
        uicontrol('Parent', h_plotroc, ...
            'Style', 'checkbox', ...
            'String' , 'Original', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [380, 20, 100, 30]./size_plotroc, ...
            'Callback', @callback_cb_original); 
        
        h_axes_roc_hi = axes('Units', 'normalized', ...
            'NextPlot', 'add', 'Box', 'on', ...
            'XTick', [0 1], 'YTick', [0 1], ...
            'XGrid', 'on', 'YGrid', 'on', ...
            'XLim', [-0.1 1.1], 'YLim', [-0.1 1.1], ...
            'Position', [60 80 320 320]./size_plotroc);

        plot(h_axes_roc_hi, FAR_HAL{id}(1:1000), MAR_HAL{id}(1:1000), 'b', 'LineWidth', 2);
        plot(h_axes_roc_hi, FAR_HAL{id}(1001), MAR_HAL{id}(1001), '.r', 'Markersize', 15);
        text(FAR_HAL{id}(1001)+0.01, MAR_HAL{id}(1001)+0.05, ['HAL = ' num2str(HAL_raise{id},'%-6.2f')],'Parent',h_axes_roc_hi);
        text(0.45,0.65,['\color{red} P_{false} = ' num2str(FAR_HAL{id}(1001),'%6.4f')],'Parent',h_axes_roc_hi);
        text(0.45,0.55,['\color{red} P_{miss}  = ' num2str(MAR_HAL{id}(1001),'%6.4f')],'Parent',h_axes_roc_hi);
        if ADD_HAL{id}(1001) < 60
            text(0.45,0.45,['\color{red} ADD   = ' num2str(ADD_HAL{id}(1001),'%6.4f')],'Parent',h_axes_roc_hi);
        end
        set(get(h_axes_roc_hi,'XLabel'), 'String', 'Probability of False Alarm');
        set(get(h_axes_roc_hi,'YLabel'), 'String', 'Probability of Missed Alarm');
        set(get(h_axes_roc_hi,'Title'), 'String', 'High Alarm');

        h_axes_roc_lo = axes('Units', 'normalized', ...
            'NextPlot', 'add', 'Box', 'on', ...
            'XGrid', 'on', 'YGrid', 'on', ...
            'XTick', [0 1], 'YTick', [0 1], ...
            'XLim', [-0.1 1.1], 'YLim', [-0.1 1.1], ...
            'Position', [450 80 320 320]./size_plotroc);
 
        plot(h_axes_roc_lo, FAR_LAL{id}(1:1000), MAR_LAL{id}(1:1000), 'b', 'LineWidth', 2);
        plot(h_axes_roc_lo, FAR_LAL{id}(1001), MAR_LAL{id}(1001), '.r', 'Markersize', 15);
        text(FAR_LAL{id}(1001)-0.11, MAR_LAL{id}(1001)-0.05, ['LAL = ' num2str(LAL_raise{id},'%-6.2f')],'Parent',h_axes_roc_lo);
        text(0.45,0.65,['\color{red} P_{false} = ' num2str(FAR_LAL{id}(1001),'%6.4f')],'Parent',h_axes_roc_lo);
        text(0.45,0.55,['\color{red} P_{miss}  = ' num2str(MAR_LAL{id}(1001),'%6.4f')],'Parent',h_axes_roc_lo);
        if ADD_LAL{id}(1001) < 60
            text(0.45,0.45,['\color{red} ADD   = ' num2str(ADD_LAL{id}(1001),'%6.4f')],'Parent',h_axes_roc_lo);
        end
        set(get(h_axes_roc_lo,'XLabel'), 'String', 'Probability of False Alarm');
        set(get(h_axes_roc_lo,'YLabel'), 'String', 'Probability of Missed Alarm');
        set(get(h_axes_roc_lo,'Title'), 'String', 'Low Alarm');

        % functions
        function callback_cb_original(hObject, evendata)
            Eval_alarmperf('original'); id = 1;
        
            val = get(hObject,'Value');
            switch val
                case 1
                    h_farmar_hal = plot(h_axes_roc_hi, FAR_HAL{id}(1:1000), MAR_HAL{id}(1:1000), 'c', 'LineWidth', 2);
                    h_farmar_halp = plot(h_axes_roc_hi, FAR_HAL{id}(1001), MAR_HAL{id}(1001), '.g', 'Markersize', 15);
                    txt_farmar_hal1 = text(FAR_HAL{id}(1001)+0.01, MAR_HAL{id}(1001)-0.05, ['HAL = ' num2str(HAL_raise{id},'%-6.2f')],'Parent',h_axes_roc_hi);
                    txt_farmar_hal2 = text(0.45,0.35,['\color{green} P_{false} = ' num2str(FAR_HAL{id}(1001),'%6.4f')],'Parent',h_axes_roc_hi);
                    txt_farmar_hal3 = text(0.45,0.25,['\color{green} P_{miss}  = ' num2str(MAR_HAL{id}(1001),'%6.4f')],'Parent',h_axes_roc_hi);
                    if ADD_HAL{id}(1001) < 60
                        txt_farmar_hal4 = text(0.45,0.15,['\color{green} ADD   = ' num2str(ADD_HAL{id}(1001),'%6.4f')],'Parent',h_axes_roc_hi);
                    end

                    h_farmar_lal = plot(h_axes_roc_lo, FAR_LAL{id}(1:1000), MAR_LAL{id}(1:1000), 'c', 'LineWidth', 2);
                    h_farmar_lalp = plot(h_axes_roc_lo, FAR_LAL{id}(1001), MAR_LAL{id}(1001), '.g', 'Markersize', 15);
                    txt_farmar_lal1 = text(FAR_LAL{id}(1001)-0.11, MAR_LAL{id}(1001)-0.05, ['LAL = ' num2str(LAL_raise{id},'%-6.2f')],'Parent',h_axes_roc_lo);
                    txt_farmar_lal2 = text(0.45,0.35,['\color{green} P_{false} = ' num2str(FAR_LAL{id}(1001),'%6.4f')],'Parent',h_axes_roc_lo);
                    txt_farmar_lal3 = text(0.45,0.25,['\color{green} P_{miss}  = ' num2str(MAR_LAL{id}(1001),'%6.4f')],'Parent',h_axes_roc_lo);
                    if ADD_LAL{id}(1001) < 60
                        txt_farmar_lal4 = text(0.45,0.15,['\color{green} ADD   = ' num2str(ADD_LAL{id}(1001),'%6.4f')],'Parent',h_axes_roc_lo);
                    end
                otherwise
                    delete(h_farmar_hal,h_farmar_lal);
                    delete(h_farmar_halp,h_farmar_lalp);
                    delete(txt_farmar_hal1,txt_farmar_hal2,txt_farmar_hal3,txt_farmar_hal4);
                    delete(txt_farmar_lal1,txt_farmar_lal2,txt_farmar_lal3,txt_farmar_lal4);
            end
        end
    end
%%
    function callback_optimize(hObject, eventdata)
        val = get(h_pm_filter,'Value');
        str = get(h_pm_filter,'String');
        filter_type = str{val};
        switch filter_type
            case 'None'
                Config_delay(design_data, n_normal, delay_on{2}, delay_off{2});
            case 'Rank order'
                Config_rankfilter(design_data, n_normal, filter_Ranksize_par, filter_Rankorder_par);
            otherwise
        end
    end
%%
    function Config_delay(in_data, in_normal, delayon, delayoff)
        n_data = length(in_data);
        if in_normal < n_data
            is_faulty = 1;
        else
            is_faulty = 0;
        end
        % Initialize Parameters
        defaultBackground = get(0, 'defaultUicontrolBackgroundColor');
        width_opt = 830; height_opt = 450;
        AX_farmar = [];
        h_bg_hilo = [];
        h_far = []; h_mar = []; h_edd = [];
        h_farset = []; h_marset = []; h_eddset = [];
        txt_farset = []; txt_marset = []; txt_eddset = [];
        FAR_setpoint = []; MAR_setpoint = []; ADD_setpoint = [];
        delay_off_opt = delayoff; delay_on_opt = delayon;
        x_trip = []; 
        h_roc_trippoint = []; h_edd_trippoint = [];
        txt_roc_trippoint1 = []; txt_roc_trippoint2 = []; txt_edd_trippoint = [];
        h_edit_farset = []; h_edit_marset = []; h_edit_eddset = []; h_edit_trippoint = [];

        pos_optimize = CenterFigure(width_opt, height_opt);
        size_optimize = [pos_optimize(3:4) pos_optimize(3:4)];
        h_optimize = figure('Visible', 'on', 'Position', pos_optimize, ...
            'Name', 'Interactive Delay-Timer Configuration', 'NumberTitle', 'off', ...
            'Resize', 'on', 'MenuBar', 'figure', ...
            'Color', defaultBackground, ...
            'Toolbar', 'auto');
        set(h_optimize, 'Color', defaultBackground)
   
        uicontrol('Parent', h_optimize, ...
            'Style', 'slider', ...
            'Min', 0.01, 'Max', 1, 'Value', 1, ...
            'Units', 'normalized', ...
            'Position', [400 130 15 24]./size_optimize, ...
            'Callback', @callback_slide_farmar_axis);

        uicontrol('Parent', h_optimize, ...
            'Style', 'slider', ...
            'Min', 1, 'Max', 50, 'Value', 10, ...
            'Units', 'normalized', ...
            'Position', [440 130 15 24]./size_optimize, ...
            'Callback', @callback_slide_edd_axis);

        h_cb_roc = uicontrol('Parent', h_optimize, ...
            'Style', 'checkbox', ...
            'String' , 'ROC', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [380, 80, 100, 30]./size_optimize, ...
            'Callback', @callback_cb_roc); 

        pos_panel_spec = [200, 20, 160, 60];
        size_panel_spec = [pos_panel_spec(3:4) pos_panel_spec(3:4)];
        h_panel_spec = uipanel('Parent', h_optimize, ...
            'Position', pos_panel_spec./size_optimize, ...
            'BorderType', 'etchedin',...
            'Title','Specifications', ...
            'ForegroundColor', 'b');
        uicontrol('Parent', h_panel_spec, ...
            'Style', 'text', ...
            'String' , 'FAR:', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [10, 30, 30, 20]./size_panel_spec);
        h_edit_farset = uicontrol('Parent', h_panel_spec, ...
            'Style', 'edit', ...
            'String' , '', ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [40, 30, 30, 20]./size_panel_spec, ...
            'Callback', @callback_edit_farset);
        uicontrol('Parent', h_panel_spec, ...
            'Style', 'text', ...
            'String' , 'MAR:', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [10, 5, 30, 20]./size_panel_spec);
        h_edit_marset = uicontrol('Parent', h_panel_spec, ...
            'Style', 'edit', ...
            'String' , '', ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [40, 5, 30, 20]./size_panel_spec, ...
            'Callback', @callback_edit_marset);
        uicontrol('Parent', h_panel_spec, ...
            'Style', 'text', ...
            'String' , 'ADD:', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [90, 30, 30, 20]./size_panel_spec);
        h_edit_eddset = uicontrol('Parent', h_panel_spec, ...
            'Style', 'edit', ...
            'String' , '', ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [120, 30, 30, 20]./size_panel_spec, ...
            'Callback', @callback_edit_eddset);

        pos_bg_hilo = [60, 20, 110, 60];
        size_bg_hilo = [pos_bg_hilo(3:4) pos_bg_hilo(3:4)];
        h_bg_hilo = uibuttongroup('Parent', h_optimize, ...
            'Position', pos_bg_hilo./size_optimize, ...
            'BorderType', 'etchedin',...
            'Title', 'Alarm type', ...
            'ForegroundColor', 'b',...
            'SelectionChangeFcn', @callback_bg_hilo);
        uicontrol('Parent', h_bg_hilo, ...
            'Style', 'radiobutton', ...
            'String', 'HI Alarm', ...
            'Units', 'normalized', ...
            'Position', [10 30 80 25]./size_bg_hilo);
        uicontrol('Parent', h_bg_hilo, ...
            'Style', 'radiobutton', ...
            'String', 'LO Alarm', ...
            'Units', 'normalized', ...
            'Position', [10 5 80 25]./size_bg_hilo);

        pos_panel_alarmconfig = [400, 20, 250, 60];
        size_panel_alarmconfig = [pos_panel_alarmconfig(3:4) pos_panel_alarmconfig(3:4)];
        h_panel_alarmconfig = uipanel('Parent', h_optimize, ...
            'Position', pos_panel_alarmconfig./size_optimize, ...
            'BorderType', 'etchedin', ...
            'Title', 'Alarm configuration', ...
            'ForegroundColor', 'b');
        uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'text', ...
            'String', 'Trip point:', ...
            'Units', 'normalized', ...
            'Position', [5 30 60 20]./size_panel_alarmconfig);
        h_edit_trippoint = uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'edit', ...
            'String' , '', ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [65 30 40 20]./size_panel_alarmconfig, ...
            'Callback', @callback_edit_trippoint);
        h_slide_trippoint = uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'slider', ...
            'Min', min(in_data), 'Max', max(in_data), 'Value', min(in_data), ...
            'Units', 'normalized', ...
            'Position', [110 28 15 24]./size_panel_alarmconfig, ...
            'Callback', @callback_slide_trippoint);
        uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'text', ...
            'String', 'OFF-delay:', ...
            'Units', 'normalized', ...
            'Position', [130 30 70 20]./size_panel_alarmconfig);
        uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'edit', ...
            'String' , num2str(delayoff), ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [200, 30, 30, 20]./size_panel_alarmconfig, ...
            'Callback', @callback_edit_delayoffopt);
       uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'text', ...
            'String', 'ON-delay:', ...
            'Units', 'normalized', ...
            'Position', [130 5 70 20]./size_panel_alarmconfig);
       uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'edit', ...
            'String' , num2str(delayon), ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [200, 5, 30, 20]./size_panel_alarmconfig, ...
            'Callback', @callback_edit_delayonopt);

        uicontrol('Parent', h_optimize, ...
            'Style', 'pushbutton', ...
            'String', 'OK', ...
            'Units', 'normalized', ...
            'Position', [700 50 65 25]./size_optimize, ...
            'Callback', @callback_pb_opt_OK); 
        uicontrol('Parent', h_optimize, ...
            'Style', 'pushbutton', ...
            'String', 'Cancel', ...
            'Units', 'normalized', ...
            'Position', [700 20 65 25]./size_optimize, ...
            'Callback', @callback_pb_opt_cancel); 

        h_axes_roc = axes('Units', 'normalized', ...
            'NextPlot', 'add', 'Box', 'on', ...
            'Position', [60 140 320 280]./size_optimize);
        h_axes_edd = axes('Units', 'normalized', ...
            'NextPlot', 'add', 'Box', 'on', ...
            'Position', [480 140 320 280]./size_optimize);

        x_temp = linspace(min(in_data),max(in_data),1000);
        [FAR_HAL,MAR_HAL,ADD_HAL,FAR_LAL,MAR_LAL,ADD_LAL]=Eval_alarm(in_data(1:in_normal),in_data(1+in_normal:n_data), x_temp, delayon, delayoff);
        switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
            case 'HI Alarm'
                FAR = FAR_HAL; MAR = MAR_HAL; ADD = ADD_HAL;
            case 'LO Alarm'
                FAR = FAR_LAL; MAR = MAR_LAL; ADD = ADD_LAL;
        end
%        x_temp = [linspace(min(design_data), max(design_data), 1000)];
        [AX_farmar,h_far, h_mar] = plotyy(h_axes_roc, x_temp, FAR(1:1000), x_temp, MAR(1:1000),'plot','plot');
        set(AX_farmar(2),'NextPlot','add','XTickMode','auto','YTickMode','auto');
        set(AX_farmar(1),'NextPlot','add','XTickMode','auto','YTickMode','auto');
        set(AX_farmar(2),'YColor','r');
        set(h_mar,'Color', 'r');
        set(get(h_axes_roc,'XLabel'), 'String', 'Trip Point');
        set(get(AX_farmar(1),'YLabel'), 'String', 'Probability of False Alarm');
        set(get(AX_farmar(2),'YLabel'), 'String', 'Probability of Missed Alarm');
        
        h_edd = plot(h_axes_edd, x_temp, ADD(1:1000), 'b', 'LineWidth', 1);
        set(h_axes_edd, 'XLim',[min(in_data) max(in_data)], 'YLim', [0 10]);
        set(get(h_axes_edd, 'XLabel'), 'String', 'Trip Point');
        set(get(h_axes_edd, 'YLabel'), 'String', 'Average detection delay');

        % functions
        function plot_FARMAR
            if ~isempty(FAR_setpoint)
                delete(h_farset,txt_farset);
                ylim = get(AX_farmar(1),'YLim'); xlim =get(AX_farmar(1), 'XLim');
                if FAR(1)< FAR(1000)
                    ind = find(FAR >= FAR_setpoint,1,'first');
                    x_far = x_temp(ind);
                    h_farset = plot(AX_farmar(1),[xlim(1) x_far],[FAR_setpoint FAR_setpoint],'b:',[x_far x_far],[ylim(1) FAR_setpoint],'b:');
                else
                    ind = find(FAR <= FAR_setpoint,1,'first');
                    x_far = x_temp(ind);
                    h_farset = plot(AX_farmar(1),[x_far xlim(2)],[FAR_setpoint FAR_setpoint],'b:',[x_far x_far],[ylim(1) FAR_setpoint],'b:');
                end
                txt_farset = text(x_far, FAR_setpoint,num2str(x_far,'%4.2f'),'Parent',AX_farmar(1),'Color','b');
            end
            
            if ~isempty(MAR_setpoint)
                delete(h_marset,txt_marset);
                ylim = get(AX_farmar(2),'YLim'); xlim =get(AX_farmar(2), 'XLim');
                if MAR(1)< MAR(1000)
                    ind = find(MAR >= MAR_setpoint,1,'first');
                    x_mar = x_temp(ind);
                    h_marset = plot(AX_farmar(2),[xlim(1) x_mar],[MAR_setpoint MAR_setpoint],'r:',[x_mar x_mar],[ylim(1) MAR_setpoint],'r:');
                else
                    ind = find(MAR <= MAR_setpoint,1,'first');
                    x_mar = x_temp(ind);
                    h_marset = plot(AX_farmar(2),[x_mar xlim(2)],[MAR_setpoint MAR_setpoint],'r:',[x_mar x_mar],[ylim(1) MAR_setpoint],'r:');
                end
                txt_marset = text(x_mar, MAR_setpoint,[num2str(x_mar,'%4.2f')],'Parent',AX_farmar(2),'Color','r');
            end 
            
            if ~isempty(ADD_setpoint)
                delete(h_eddset, txt_eddset);
                ylim = get(h_axes_edd,'YLim'); xlim =get(h_axes_edd, 'XLim');
                if ADD(1)< ADD(1000)
                    ind = find(ADD >= ADD_setpoint,1,'first');
                    x_edd = x_temp(ind);
                    h_eddset = plot(h_axes_edd,[xlim(1) x_edd],[ADD_setpoint ADD_setpoint],'b:',[x_edd x_edd],[ylim(1) ADD_setpoint],'b:');
                else
                    ind = find(ADD <= ADD_setpoint,1,'first');
                    x_edd = x_temp(ind);
                    h_eddset = plot(h_axes_edd,[x_edd xlim(2)],[ADD_setpoint ADD_setpoint],'b:',[x_edd x_edd],[ylim(1) ADD_setpoint],'b:');
                end
                txt_eddset = text(x_edd, ADD_setpoint,[num2str(x_edd,'%4.2f')],'Parent',h_axes_edd,'Color','b');
            end
            
            if ~isempty(x_trip)
                [FAR_HALx,MAR_HALx,ADD_HALx,FAR_LALx,MAR_LALx,ADD_LALx] = Eval_alarm(in_data(1:in_normal), in_data(1+in_normal:n_data),x_trip,delayon,delayoff);
                switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                    case 'HI Alarm'
                        FARx = FAR_HALx; MARx = MAR_HALx; ADDx = ADD_HALx;
                    case 'LO Alarm'
                        FARx = FAR_LALx; MARx = MAR_LALx; ADDx = ADD_LALx;
                end
                delete(txt_roc_trippoint1,txt_roc_trippoint2);
                txt_roc_trippoint1 = text(x_trip, FARx, ['\leftarrow' num2str(FARx,'%6.4f')], 'Parent', h_axes_roc,'Color','b');
                txt_roc_trippoint2 = text(x_trip, MARx, ['\leftarrow' num2str(MARx,'%6.4f')], 'Parent', h_axes_roc,'Color','r');
                delete(txt_edd_trippoint);
                txt_edd_trippoint = text(x_trip, ADDx,['\leftarrow' num2str(ADDx,'%6.4f')],'Parent',h_axes_edd,'Color','b');
            end
        end
            
        function callback_edit_trippoint(hObject, eventdata)
            trippoint_double = str2double(get(hObject, 'string'));
            if isnan(trippoint_double) || trippoint_double < min(in_data) || trippoint_double > max(in_data)
                errordlg('Trip point must lie between Min and Max of data', 'Invalid trip point', 'modal')
                set(hObject, 'String', ''); 
                if ~isempty(h_roc_trippoint) delete(h_roc_trippoint); h_roc_trippoint = []; end
                if ~isempty(txt_roc_trippoint1) delete(txt_roc_trippoint1); txt_roc_trippoint1 = []; end
                if ~isempty(txt_roc_trippoint2) delete(txt_roc_trippoint2); h_roc_trippoint2 = []; end
                if ~isempty(h_edd_trippoint) delete(h_edd_trippoint); h_edd_trippoint = []; end
                if ~isempty(txt_edd_trippoint) delete(txt_roc_trippoint); txt_roc_trippoint = []; end
            else
                x_trip = trippoint_double; 
                set(h_slide_trippoint, 'Value', x_trip);
                [FAR_HALx,MAR_HALx,ADD_HALx,FAR_LALx,MAR_LALx,ADD_LALx] = Eval_alarm(in_data(1:in_normal), in_data(1+in_normal:n_data),x_trip,delayon,delayoff,deadband_user_HAL);
                switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                    case 'HI Alarm'
                        FARx = FAR_HALx; MARx = MAR_HALx; ADDx = ADD_HALx;
                    case 'LO Alarm'
                        FARx = FAR_LALx; MARx = MAR_LALx; ADDx = ADD_LALx;
                end
                delete(h_roc_trippoint, h_edd_trippoint, txt_roc_trippoint1, txt_roc_trippoint2, txt_edd_trippoint);
                h_roc_trippoint = plot(h_axes_roc, [x_trip x_trip], [0 1],'k:');
                txt_roc_trippoint1 = text(x_trip, FARx, ['\leftarrow' num2str(FARx,'%6.4f')], 'Parent', h_axes_roc,'Color','b');
                txt_roc_trippoint2 = text(x_trip, MARx, ['\leftarrow' num2str(MARx,'%6.4f')], 'Parent', h_axes_roc,'Color','r');
                h_edd_trippoint = plot(h_axes_edd, [x_trip x_trip], [0 50],'k:');
                txt_edd_trippoint = text(x_trip, ADDx, ['\leftarrow' num2str(ADDx,'%6.4f')], 'Parent', h_axes_edd,'Color','b');
            end
        end
        %
        function callback_cb_roc(hObject, evendata)
            delete(h_axes_roc);
            switch get(hObject,'Value') 
                case 1
                    h_axes_roc = axes('Units', 'normalized', ...
                        'NextPlot', 'add', 'Box', 'on', ...
                        'Position', [60 140 320 280]./size_optimize);
                    plot(h_axes_roc, FAR(1:1000), MAR(1:1000),'b');
                    set(get(h_axes_roc,'XLabel'),'String', 'Probability of False Alarm');
                    set(get(h_axes_roc,'YLabel'),'String', 'Probability of Missed Alarm');
                    if ~isempty(FAR_setpoint)
                        plot(h_axes_roc, [FAR_setpoint FAR_setpoint], [0 1], 'b:');
                    end
                    if ~isempty(MAR_setpoint)
                        plot(h_axes_roc, [0 1], [MAR_setpoint MAR_setpoint], 'r:');
                    end
                    set(h_edit_farset, 'Enable', 'off');
                    set(h_edit_marset, 'Enable', 'off');
                    set(h_edit_eddset, 'Enable', 'off');
                    set(h_edit_trippoint, 'Enable', 'off');
                    set(h_slide_trippoint, 'Enable', 'off');
                case 0
                    h_axes_roc = axes('Units', 'normalized', ...
                        'NextPlot', 'add', 'Box', 'on', ...
                        'Position', [60 140 320 280]./size_optimize);
                    x_temp = [linspace(min(in_data), max(in_data), 1000)];
                    [AX_farmar,h_far, h_mar] = plotyy(h_axes_roc, x_temp, FAR(1:1000), x_temp, MAR(1:1000),'plot','plot');
                    set(AX_farmar(2),'NextPlot','add','XTickMode','auto','YTickMode','auto');
                    set(AX_farmar(1),'NextPlot','add','XTickMode','auto','YTickMode','auto');
                    set(AX_farmar(2),'YColor','r');
                    set(h_mar,'Color', 'r');
                    set(get(h_axes_roc,'XLabel'), 'String', 'Trip Point');
                    set(get(AX_farmar(1),'YLabel'), 'String', 'Probability of False Alarm');
                    set(get(AX_farmar(2),'YLabel'), 'String', 'Probability of Missed Alarm');
                    if ~isempty(FAR_setpoint)
                        ylim = get(AX_farmar(1),'YLim'); xlim =get(AX_farmar(1), 'XLim');
                        if FAR(1)< FAR(1000)
                            ind = find(FAR >= FAR_setpoint,1,'first');
                            x_far = x_temp(ind);
%                            h_farset = plot(AX_farmar(1),[xlim(1):(x_far-xlim(1))/100:x_far],FAR_setpoint,'b',x_far,[ylim(1):(FAR_setpoint-ylim(1))/100:FAR_setpoint],'b');
                             h_farset = plot(AX_farmar(1),[xlim(1) x_far],[FAR_setpoint FAR_setpoint],'b:',[x_far x_far],[ylim(1) FAR_setpoint],'b:');
                        else
                            ind = find(FAR <= FAR_setpoint,1,'first');
                            x_far = x_temp(ind);
%                            h_farset = plot(AX_farmar(1),[x_far:(xlim(2)-x_far)/100:xlim(2)],FAR_setpoint,'b',x_far,[ylim(1):(FAR_setpoint-ylim(1))/100:FAR_setpoint],'b');
                            h_farset = plot(AX_farmar(1),[x_far xlim(2)],[FAR_setpoint FAR_setpoint],'b:',[x_far x_far],[ylim(1) FAR_setpoint],'b:');
                        end
                        txt_farset = text(x_far, FAR_setpoint,num2str(x_far,'%4.2f'),'Parent',AX_farmar(1),'Color','b');
                    end            
                    if ~isempty(MAR_setpoint)
                        ylim = get(AX_farmar(2),'YLim'); xlim =get(AX_farmar(2), 'XLim');
                        if MAR(1)< MAR(1000)
                            ind = find(MAR >= MAR_setpoint,1,'first');
                            x_mar = x_temp(ind);
%                            h_marset = plot(AX_farmar(2),[xlim(1):(x_mar-xlim(1))/100:x_mar],MAR_setpoint,'r',x_mar,[ylim(1):(MAR_setpoint-ylim(1))/100:MAR_setpoint],'r');
                            h_marset = plot(AX_farmar(2),[xlim(1) x_mar],[MAR_setpoint MAR_setpoint],'r:',[x_mar x_mar],[ylim(1) MAR_setpoint],'r:');
                        else
                            ind = find(MAR <= MAR_setpoint,1,'first');
                            x_mar = x_temp(ind);
%                            h_marset = plot(AX_farmar(2),[x_mar:(xlim(2)-x_mar)/100:xlim(2)],MAR_setpoint,'r',x_mar,[ylim(1):(MAR_setpoint-ylim(1))/100:MAR_setpoint],'r');
                            h_marset = plot(AX_farmar(2),[x_mar xlim(2)],[MAR_setpoint MAR_setpoint],'r:',[x_mar x_mar],[ylim(1) MAR_setpoint],'r:');
                        end
                        txt_marset = text(x_mar, MAR_setpoint,[num2str(x_mar,'%4.2f')],'Parent',AX_farmar(2),'Color','r');
                    end
                    
                    if ~isempty(x_trip)
                        [FAR_HALx,MAR_HALx,ADD_HALx,FAR_LALx,MAR_LALx,ADD_LALx] = Eval_alarm(in_data(1:in_normal), in_data(1+in_normal:n_data),x_trip,delayon,delayoff);
                        switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                            case 'HI Alarm'
                                FARx = FAR_HALx; MARx = MAR_HALx; ADDx = ADD_HALx;
                            case 'LO Alarm'
                                FARx = FAR_LALx; MARx = MAR_LALx; ADDx = ADD_LALx;
                        end
                        txt_roc_trippoint1 = text(x_trip, FARx, ['\leftarrow' num2str(FARx,'%6.4f')], 'Parent', h_axes_roc,'Color','b');
                        txt_roc_trippoint2 = text(x_trip, MARx, ['\leftarrow' num2str(MARx,'%6.4f')], 'Parent', h_axes_roc,'Color','r');
                        h_roc_trippoint = plot(h_axes_roc, [x_trip x_trip], [0 1],'k:');
                    end
                    set(h_edit_farset, 'Enable', 'on');
                    set(h_edit_marset, 'Enable', 'on');
                    set(h_edit_eddset, 'Enable', 'on');
                    set(h_edit_trippoint, 'Enable', 'on');
                    set(h_slide_trippoint, 'Enable', 'on');
            end
        end
        %
        function callback_bg_hilo(source, eventdata)
            switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                case 'HI Alarm'
%                    Eval_alarmperf('design');
%                    set(h_edit_trippoint, 'String', num2str(HAL_raise{2}));
                    x_temp = linspace(min(in_data),max(in_data),1000);
                    [FAR_HAL,MAR_HAL,ADD_HAL,FAR_LAL,MAR_LAL,ADD_LAL]=Eval_alarm(in_data(1:in_normal),in_data(1+in_normal:n_data), x_temp, delayon, delayoff);
                    FAR = FAR_HAL; MAR = MAR_HAL; ADD = ADD_HAL;
                case 'LO Alarm'
%                    Eval_alarmperf('design');
%                    set(h_edit_trippoint, 'String', num2str(LAL_raise{2}));
                    x_temp = linspace(min(in_data),max(in_data),1000);
                    [FAR_HAL,MAR_HAL,ADD_HAL,FAR_LAL,MAR_LAL,ADD_LAL]=Eval_alarm(in_data(1:in_normal),in_data(1+in_normal:n_data), x_temp, delayon, delayoff);
                    FAR = FAR_LAL; MAR = MAR_LAL; ADD = ADD_LAL;
            end
            switch get(h_cb_roc, 'Value')
                case 1
                    delete(h_axes_roc);
                    h_axes_roc = axes('Units', 'normalized', ...
                        'NextPlot', 'add', 'Box', 'on', ...
                        'Position', [60 140 320 280]./size_optimize);
                    plot(h_axes_roc, FAR(1:1000), MAR(1:1000),'b');
                    set(get(h_axes_roc,'XLabel'),'String', 'Probability of False Alarm');
                    set(get(h_axes_roc,'YLabel'),'String', 'Probability of Missed Alarm');
                    if ~isempty(FAR_setpoint)
                        plot(h_axes_roc, FAR_setpoint, [0:0.01:1], 'b');
                    end
                    if ~isempty(MAR_setpoint)
                        plot(h_axes_roc, [0:0.01:1], MAR_setpoint, 'r');
                    end
                    delete(h_edd);
                    h_edd = plot(h_axes_edd, x_temp, ADD(1:1000),'b');
                otherwise
                    delete(h_far, h_mar); 
                    x_temp = [linspace(min(in_data), max(in_data), 1000)];
                    h_far = plot(AX_farmar(1), x_temp, FAR(1:1000));
                    h_mar = plot(AX_farmar(2), x_temp, MAR(1:1000),'r');
                    delete(h_edd);
                    h_edd = plot(h_axes_edd, x_temp, ADD(1:1000),'b');
                    plot_FARMAR;
            end
        end
        %
        function callback_edit_farset(hObject, eventdata)
            far_setpoint_string = get(hObject, 'string');
            far_setpoint_double = str2double(far_setpoint_string);
            if isnan(far_setpoint_double) || far_setpoint_double < 0 || far_setpoint_double > 100
                errordlg('False alarm rate must be a positive between 0 and 100', 'Invalid false alarm setpoint', 'modal')
                set(hObject, 'String', ''); h_farset=[]; txt_farset = [];
            end
            FAR_setpoint = far_setpoint_double/100;
            x_temp = [linspace(min(in_data), max(in_data), 1000)];
            delete(h_farset, txt_farset);
            ylim = get(AX_farmar(1),'YLim'); xlim =get(AX_farmar(1), 'XLim');
            if FAR(1)< FAR(1000)
                ind = find(FAR >= FAR_setpoint,1,'first');
                x_far = x_temp(ind);
                h_farset = plot(AX_farmar(1),[xlim(1) x_far],[FAR_setpoint FAR_setpoint],'b:',[x_far x_far],[ylim(1) FAR_setpoint],'b:');
            else
                ind = find(FAR <= FAR_setpoint,1,'first');
                x_far = x_temp(ind);
                h_farset = plot(AX_farmar(1),[x_far xlim(2)],[FAR_setpoint FAR_setpoint],'b:',[x_far x_far],[ylim(1) FAR_setpoint],'b:');
            end
            txt_farset = text(x_far, FAR_setpoint,num2str(x_far,'%4.2f'),'Parent',AX_farmar(1),'Color','b');
        end
        %
        function callback_edit_marset(hObject, ~)
            mar_setpoint_string = get(hObject, 'string');
            mar_setpoint_double = str2double(mar_setpoint_string);
            if isnan(mar_setpoint_double) || mar_setpoint_double < 0 || mar_setpoint_double > 100
                errordlg('Missed alarm rate must be a positive between 0 and 100', 'Invalid missed alarm setpoint', 'modal')
                set(hObject, 'String', ''); h_marset = []; txt_marset = [];
            end
            MAR_setpoint = mar_setpoint_double/100;
            x_temp = [linspace(min(in_data), max(in_data), 1000)];
            delete(h_marset, txt_marset);
            ylim = get(AX_farmar(2),'YLim'); xlim =get(AX_farmar(2), 'XLim');
            if MAR(1)< MAR(1000)
                ind = find(MAR >= MAR_setpoint,1,'first');
                x_mar = x_temp(ind);
                h_marset = plot(AX_farmar(2),[xlim(1) x_mar],[MAR_setpoint MAR_setpoint],'r:',[x_mar x_mar],[ylim(1) MAR_setpoint],'r:');
            else
                ind = find(MAR <= MAR_setpoint,1,'first');
                x_mar = x_temp(ind);
                h_marset = plot(AX_farmar(2),[x_mar xlim(2)],[MAR_setpoint MAR_setpoint],'r:',[x_mar x_mar],[ylim(1) MAR_setpoint],'r:');
            end
            txt_marset = text(x_mar, MAR_setpoint,[num2str(x_mar,'%4.2f')],'Parent',AX_farmar(2),'Color','r');
        end
        %
        function callback_edit_eddset(hObject, eventdata)
            edd_setpoint_string = get(hObject, 'string');
            edd_setpoint_double = str2double(edd_setpoint_string);
            if isnan(edd_setpoint_double) || edd_setpoint_double < 0 
                errordlg('Average detection delay must be a positive number', 'Invalid ADD setpoint', 'modal')
                set(hObject, 'String', ''); h_eddset = []; txt_eddset = [];
            end
            ADD_setpoint = edd_setpoint_double;
            x_temp = [linspace(min(in_data), max(in_data), 1000)];
            delete(h_eddset, txt_eddset);
            ylim = get(h_axes_edd,'YLim'); xlim =get(h_axes_edd, 'XLim');
            if ADD(1)< ADD(1000)
                ind = find(ADD >= ADD_setpoint,1,'first');
                x_edd = x_temp(ind);
                h_eddset = plot(h_axes_edd,[xlim(1) x_edd],[ADD_setpoint ADD_setpoint],'b:',[x_edd x_edd],[ylim(1) ADD_setpoint],'b:');
            else
                ind = find(ADD <= ADD_setpoint,1,'first');
                x_edd = x_temp(ind);
                h_eddset = plot(h_axes_edd,[x_edd xlim(2)],[ADD_setpoint ADD_setpoint],'b:',[x_edd x_edd],[ylim(1) ADD_setpoint],'b:');
            end
            txt_eddset = text(x_edd, ADD_setpoint,[num2str(x_edd,'%4.2f')],'Parent',h_axes_edd,'Color','b');
        end
        %
        function callback_edit_delayoffopt(hObject, eventdata)
            delay_off_string = get(hObject, 'string');
            delay_off_double = str2double(delay_off_string);
            if isnan(delay_off_double) || delay_off_double ~= round(delay_off_double)|| delay_off_double < 0 || delay_off_double > 1000
                errordlg('Alarm delay must be a positive integer between 1 and 1000', 'Invalid Alarm Delay', 'modal')
                set(hObject, 'String', num2str(delayoff))
            end
            delayoff = delay_off_double;
            x_temp = linspace(min(in_data),max(in_data),1000);
            [FAR_HAL,MAR_HAL,ADD_HAL,FAR_LAL,MAR_LAL,ADD_LAL]=Eval_alarm(in_data(1:in_normal),in_data(1+in_normal:n_data), x_temp, delayon, delayoff);
%            Eval_alarmperf('design');
            switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                case 'HI Alarm'
                    FAR = FAR_HAL; MAR = MAR_HAL; ADD = ADD_HAL;
                case 'LO Alarm'
                    FAR = FAR_LAL; MAR = MAR_LAL; ADD = ADD_LAL;
            end
            switch get(h_cb_roc, 'Value')
                case 0
                    delete(h_far, h_mar, h_edd);
                    x_temp = [linspace(min(in_data), max(in_data), 1000)];
                    h_far = plot(AX_farmar(1), x_temp, FAR(1:1000),'b');
                    h_mar = plot(AX_farmar(2), x_temp, MAR(1:1000),'r');
                    h_edd = plot(h_axes_edd, x_temp, ADD(1:1000),'b');
                    plot_FARMAR;
                case 1
                    delete(h_axes_roc);
                    h_axes_roc = axes('Units', 'normalized', ...
                        'NextPlot', 'add', 'Box', 'on', ...
                        'Position', [60 140 320 280]./size_optimize);
                    plot(h_axes_roc, FAR(1:1000), MAR(1:1000),'b');
                    set(get(h_axes_roc,'XLabel'),'String', 'Probability of False Alarm');
                    set(get(h_axes_roc,'YLabel'),'String', 'Probability of Missed Alarm');
                    if ~isempty(FAR_setpoint)
                        plot(h_axes_roc, [FAR_setpoint FAR_setpoint], [0 1], 'b:');
                    end
                    if ~isempty(MAR_setpoint)
                        plot(h_axes_roc, [0 1], [MAR_setpoint MAR_setpoint], 'r:');
                    end
            end
        end
        %
        function callback_edit_delayonopt(hObject, eventdata) 
            delay_on_string = get(hObject, 'string');
            delay_on_double = str2double(delay_on_string);
            if isnan(delay_on_double) || delay_on_double ~= round(delay_on_double)|| delay_on_double < 0 || delay_on_double > 1000
                errordlg('Alarm delay must be a positive integer between 1 and 1000', 'Invalid Alarm Delay', 'modal')
                set(hObject, 'String', num2str(delayon))
            end
            delayon = delay_on_double;
            x_temp = linspace(min(in_data),max(in_data),1000);
            [FAR_HAL,MAR_HAL,ADD_HAL,FAR_LAL,MAR_LAL,ADD_LAL]=Eval_alarm(in_data(1:in_normal),in_data(1+in_normal:n_data), x_temp, delayon, delayoff);
%           Eval_alarmperf('design');
            switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                case 'HI Alarm'
                    FAR = FAR_HAL; MAR = MAR_HAL; ADD = ADD_HAL;
                case 'LO Alarm'
                    FAR = FAR_LAL; MAR = MAR_LAL; ADD = ADD_LAL;
            end
            switch get(h_cb_roc, 'Value')
                case 0
                    delete(h_mar, h_far, h_edd);
                    x_temp = [linspace(min(in_data), max(in_data), 1000)];
                    h_far = plot(AX_farmar(1), x_temp, FAR(1:1000),'b');
                    h_mar = plot(AX_farmar(2), x_temp, MAR(1:1000),'r');
                    h_edd = plot(h_axes_edd, x_temp, ADD(1:1000),'b');
                    plot_FARMAR;
                case 1
                    delete(h_axes_roc);
                    h_axes_roc = axes('Units', 'normalized', ...
                        'NextPlot', 'add', 'Box', 'on', ...
                        'Position', [60 140 320 280]./size_optimize);
                    plot(h_axes_roc, FAR(1:1000), MAR(1:1000),'b');
                    set(get(h_axes_roc,'XLabel'),'String', 'Probability of False Alarm');
                    set(get(h_axes_roc,'YLabel'),'String', 'Probability of Missed Alarm');
                    if ~isempty(FAR_setpoint)
                        plot(h_axes_roc, [FAR_setpoint FAR_setpoint], [0 1], 'b:');
                    end
                    if ~isempty(MAR_setpoint)
                        plot(h_axes_roc, [0 1], [MAR_setpoint MAR_setpoint], 'r:');
                    end
            end
        end
        %
        function callback_pb_opt_OK(hObject, eventdata)
            set(h_edit_delay_on, 'String', num2str(delayon));
            set(h_edit_delay_off, 'String', num2str(delayoff));
            switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                case 'HI Alarm'
                    HAL_raise{2} = str2double(get(h_edit_trippoint, 'String'));
                    set(h_pm_method_HAL, 'String',HAL_alarmlimit_methods,'Value',4);
                    set(h_edit_user_HAL, 'Visible','on');
                    set(h_edit_user_HAL,'String',num2str(HAL_raise{2},'%-6.2f'));
                    set(h_pm_deadband_HAL, 'Enable', 'on');
                case 'LO Alarm'
                    LAL_raise{2} = str2double(get(h_edit_trippoint, 'String'));
                    set(h_pm_method_LAL, 'String', LAL_alarmlimit_methods,'Value',4);
                    set(h_edit_user_LAL, 'Visible','on');
                    set(h_edit_user_LAL,'String',num2str(LAL_raise{2},'%-6.2f'));
                    set(h_pm_deadband_LAL, 'Enable', 'on');
            end
            set(h_edit_delay_on, 'Enable', 'on');
            set(h_edit_delay_off, 'Enable', 'on');
            set(h_pb_delayopt, 'Enable', 'on');
            delay_off{2} = delay_off;
            delay_on{2} = delay_on;
            delete(h_optimize);
            apply_design('design');
        end
        %
        function callback_pb_opt_cancel(hObject, eventdata)
            delay_off{2} = delay_off_opt;
            delay_on{2} = delay_on_opt;
            delete(h_optimize);
        end
        %
        function callback_slide_farmar_axis(hObject, eventdata, handles)
            if get(hObject, 'Value') >= 1 
                ylim_roc = 1;
            else
                ylim_roc = get(hObject, 'Value');
            end
            switch get(h_cb_roc,'Value')
                case 0
                    set(AX_farmar(1),'YLim',[0 ylim_roc]);
                    set(AX_farmar(2),'YLim',[0 ylim_roc]);
                case 1
                    set(h_axes_roc,'YLim',[0 ylim_roc],'XLim',[0 ylim_roc]);
            end
        end
        
        function callback_slide_edd_axis(hObject, eventdata, handles)
            if get(hObject, 'Value') >= 50 
                ylim_edd = 50;
            else
                ylim_edd = get(hObject, 'Value');
            end
            set(h_axes_edd,'YLim',[0 ylim_edd]);
        end
        %
        function callback_slide_trippoint(hObject, eventdata, handles)
            if get(hObject, 'Value') >= max(in_data) 
                x_trip = max(in_data);
            else
                x_trip = get(hObject, 'Value');
            end
            set(h_edit_trippoint, 'String', num2str(x_trip,'%6.2f'));
            plot_FARMAR;
            delete(h_roc_trippoint, h_edd_trippoint);
            h_roc_trippoint = plot(h_axes_roc, [x_trip x_trip], [0 1],'k:');
            h_edd_trippoint = plot(h_axes_edd, [x_trip x_trip], [0 50],'k:');

        end
    end
%%
    function Config_rankfilter(in_data, in_normal, rank_size, rank_order)

        n_data = length(in_data);
        % Initialize Parameters
        defaultBackground = get(0, 'defaultUicontrolBackgroundColor');
        width_opt = 830; height_opt = 450;
        AX_farmar = [];
        h_bg_hilo = [];
        h_far = []; h_mar = []; h_edd = [];
        h_farset = []; h_marset = []; h_eddset = [];
        txt_farset = []; txt_marset = []; txt_eddset = [];
        FAR_setpoint = []; MAR_setpoint = []; ADD_setpoint = [];
        rank_size_opt = rank_size; rank_order_opt = rank_order;
        x_trip = []; 
        h_roc_trippoint = []; h_edd_trippoint = [];
        txt_roc_trippoint1 = []; txt_roc_trippoint2 = []; txt_edd_trippoint = [];
        h_edit_farset = []; h_edit_marset = []; h_edit_eddset = []; h_edit_trippoint = [];
        
        pos_optimize = CenterFigure(width_opt, height_opt);
        size_optimize = [pos_optimize(3:4) pos_optimize(3:4)];
        h_optimize = figure('Visible', 'on', 'Position', pos_optimize, ...
            'Name', 'Interactive Rank Filter Configuration Tool', 'NumberTitle', 'off', ...
            'Resize', 'on', 'MenuBar', 'figure', ...
            'Color', defaultBackground, ...
            'Toolbar', 'auto');
        set(h_optimize, 'Color', defaultBackground)
   
        uicontrol('Parent', h_optimize, ...
            'Style', 'slider', ...
            'Min', 0.01, 'Max', 1, 'Value', 1, ...
            'Units', 'normalized', ...
            'Position', [400 130 15 24]./size_optimize, ...
            'Callback', @callback_slide_farmar_axis);

        uicontrol('Parent', h_optimize, ...
            'Style', 'slider', ...
            'Min', 1, 'Max', 50, 'Value', 10, ...
            'Units', 'normalized', ...
            'Position', [440 130 15 24]./size_optimize, ...
            'Callback', @callback_slide_edd_axis);

        h_cb_roc = uicontrol('Parent', h_optimize, ...
            'Style', 'checkbox', ...
            'String' , 'ROC', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [380, 80, 100, 30]./size_optimize, ...
            'Callback', @callback_cb_roc); 

        pos_panel_spec = [200, 20, 160, 60];
        size_panel_spec = [pos_panel_spec(3:4) pos_panel_spec(3:4)];
        h_panel_spec = uipanel('Parent', h_optimize, ...
            'Position', pos_panel_spec./size_optimize, ...
            'BorderType', 'etchedin',...
            'Title','Specifications', ...
            'ForegroundColor', 'b');
        uicontrol('Parent', h_panel_spec, ...
            'Style', 'text', ...
            'String' , 'FAR:', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [10, 30, 30, 20]./size_panel_spec);
        h_edit_farset = uicontrol('Parent', h_panel_spec, ...
            'Style', 'edit', ...
            'String' , '', ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [40, 30, 30, 20]./size_panel_spec, ...
            'Callback', @callback_edit_farset);
        uicontrol('Parent', h_panel_spec, ...
            'Style', 'text', ...
            'String' , 'MAR:', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [10, 5, 30, 20]./size_panel_spec);
        h_edit_marset = uicontrol('Parent', h_panel_spec, ...
            'Style', 'edit', ...
            'String' , '', ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [40, 5, 30, 20]./size_panel_spec, ...
            'Callback', @callback_edit_marset);
        uicontrol('Parent', h_panel_spec, ...
            'Style', 'text', ...
            'String' , 'EDD:', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [90, 30, 30, 20]./size_panel_spec);
        h_edit_eddset = uicontrol('Parent', h_panel_spec, ...
            'Style', 'edit', ...
            'String' , '', ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [120, 30, 30, 20]./size_panel_spec, ...
            'Callback', @callback_edit_eddset);

        pos_bg_hilo = [60, 20, 110, 60];
        size_bg_hilo = [pos_bg_hilo(3:4) pos_bg_hilo(3:4)];
        h_bg_hilo = uibuttongroup('Parent', h_optimize, ...
            'Position', pos_bg_hilo./size_optimize, ...
            'BorderType', 'etchedin',...
            'Title', 'Alarm type', ...
            'ForegroundColor', 'b',...
            'SelectionChangeFcn', @callback_bg_hilo);
        uicontrol('Parent', h_bg_hilo, ...
            'Style', 'radiobutton', ...
            'String', 'HI Alarm', ...
            'Units', 'normalized', ...
            'Position', [10 30 80 25]./size_bg_hilo);
        uicontrol('Parent', h_bg_hilo, ...
            'Style', 'radiobutton', ...
            'String', 'LO Alarm', ...
            'Units', 'normalized', ...
            'Position', [10 5 80 25]./size_bg_hilo);

        pos_panel_alarmconfig = [400, 20, 250, 60];
        size_panel_alarmconfig = [pos_panel_alarmconfig(3:4) pos_panel_alarmconfig(3:4)];
        h_panel_alarmconfig = uipanel('Parent', h_optimize, ...
            'Position', pos_panel_alarmconfig./size_optimize, ...
            'BorderType', 'etchedin', ...
            'Title', 'Alarm configuration', ...
            'ForegroundColor', 'b');
        uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'text', ...
            'String', 'Trip point:', ...
            'Units', 'normalized', ...
            'Position', [5 35 60 20]./size_panel_alarmconfig);
        h_edit_trippoint = uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'edit', ...
            'String' , '', ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [65 35 40 20]./size_panel_alarmconfig, ...
            'Callback', @callback_edit_trippoint);
        h_slide_trippoint = uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'slider', ...
            'Min', min(in_data), 'Max', max(in_data), 'Value', min(in_data), ...
            'Units', 'normalized', ...
            'Position', [110 33 15 24]./size_panel_alarmconfig, ...
            'Callback', @callback_slide_trippoint);
        uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'text', ...
            'String', 'Window size:', ...
            'Units', 'normalized', ...
            'Position', [10 5 70 20]./size_panel_alarmconfig);
        uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'edit', ...
            'String' , num2str(rank_size), ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [90, 5, 30, 20]./size_panel_alarmconfig, ...
            'Callback', @callback_edit_ranksizeopt);
       uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'text', ...
            'String', 'Order:', ...
            'Units', 'normalized', ...
            'Position', [130 5 70 20]./size_panel_alarmconfig);
       uicontrol('Parent', h_panel_alarmconfig, ...
            'Style', 'edit', ...
            'String' , num2str(rank_order), ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [190, 5, 30, 20]./size_panel_alarmconfig, ...
            'Callback', @callback_edit_rankorderopt);

        uicontrol('Parent', h_optimize, ...
            'Style', 'pushbutton', ...
            'String', 'OK', ...
            'Units', 'normalized', ...
            'Position', [700 50 65 25]./size_optimize, ...
            'Callback', @callback_pb_opt_OK); 
        uicontrol('Parent', h_optimize, ...
            'Style', 'pushbutton', ...
            'String', 'Cancel', ...
            'Units', 'normalized', ...
            'Position', [700 20 65 25]./size_optimize, ...
            'Callback', @callback_pb_opt_cancel); 

        h_axes_roc = axes('Units', 'normalized', ...
            'NextPlot', 'add', 'Box', 'on', ...
            'Position', [60 140 320 280]./size_optimize);
        h_axes_edd = axes('Units', 'normalized', ...
            'NextPlot', 'add', 'Box', 'on', ...
            'Position', [480 140 320 280]./size_optimize);

        x_temp = linspace(min(in_data),max(in_data),1000);
        switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
            case 'HI Alarm'
                [FAR,MAR,ADD]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_temp, 'HI');
            case 'LO Alarm'
                [FAR,MAR,ADD]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_temp, 'LO');
        end
        x_temp = [linspace(min(in_data), max(in_data), 1000)];
        [AX_farmar,h_far, h_mar] = plotyy(h_axes_roc, x_temp, FAR(1:1000), x_temp, MAR(1:1000),'plot','plot');
        set(AX_farmar(2),'NextPlot','add','XTickMode','auto','YTickMode','auto');
        set(AX_farmar(1),'NextPlot','add','XTickMode','auto','YTickMode','auto');
        set(AX_farmar(2),'YColor','r');
        set(h_mar,'Color', 'r');
        set(get(h_axes_roc,'XLabel'), 'String', 'Trip Point');
        set(get(AX_farmar(1),'YLabel'), 'String', 'Probability of False Alarm');
        set(get(AX_farmar(2),'YLabel'), 'String', 'Probability of Missed Alarm');
        
        h_edd = plot(h_axes_edd, x_temp, ADD(1:1000), 'b', 'LineWidth', 1);
        set(h_axes_edd, 'XLim',[min(in_data) max(in_data)], 'YLim', [0 10]);
        set(get(h_axes_edd, 'XLabel'), 'String', 'Trip Point');
        set(get(h_axes_edd, 'YLabel'), 'String', 'Average detection delay');

        % functions
        function plot_FARMAR
            if ~isempty(FAR_setpoint)
                delete(h_farset,txt_farset);
                ylim = get(AX_farmar(1),'YLim'); xlim =get(AX_farmar(1), 'XLim');
                if FAR(1)< FAR(1000)
                    ind = find(FAR >= FAR_setpoint,1,'first');
                    x_far = x_temp(ind);
                    h_farset = plot(AX_farmar(1),[xlim(1) x_far],[FAR_setpoint FAR_setpoint],'b:',[x_far x_far],[ylim(1) FAR_setpoint],'b:');
                else
                    ind = find(FAR <= FAR_setpoint,1,'first');
                    x_far = x_temp(ind);
                    h_farset = plot(AX_farmar(1),[x_far xlim(2)],[FAR_setpoint FAR_setpoint],'b:',[x_far x_far],[ylim(1) FAR_setpoint],'b:');
                end
                txt_farset = text(x_far, FAR_setpoint,num2str(x_far,'%4.2f'),'Parent',AX_farmar(1),'Color','b');
            end
            
            if ~isempty(MAR_setpoint)
                delete(h_marset,txt_marset);
                ylim = get(AX_farmar(2),'YLim'); xlim =get(AX_farmar(2), 'XLim');
                if MAR(1)< MAR(1000)
                    ind = find(MAR >= MAR_setpoint,1,'first');
                    x_mar = x_temp(ind);
                    h_marset = plot(AX_farmar(2),[xlim(1) x_mar],[MAR_setpoint MAR_setpoint],'r:',[x_mar x_mar],[ylim(1) MAR_setpoint],'r:');
                else
                    ind = find(MAR <= MAR_setpoint,1,'first');
                    x_mar = x_temp(ind);
                    h_marset = plot(AX_farmar(2),[x_mar xlim(2)],[MAR_setpoint MAR_setpoint],'r:',[x_mar x_mar],[ylim(1) MAR_setpoint],'r:');
                end
                txt_marset = text(x_mar, MAR_setpoint,[num2str(x_mar,'%4.2f')],'Parent',AX_farmar(2),'Color','r');
            end 
            
            if ~isempty(ADD_setpoint)
                delete(h_eddset, txt_eddset);
                ylim = get(h_axes_edd,'YLim'); xlim =get(h_axes_edd, 'XLim');
                if ADD(1)< ADD(1000)
                    ind = find(ADD >= ADD_setpoint,1,'first');
                    x_edd = x_temp(ind);
                    h_eddset = plot(h_axes_edd,[xlim(1) x_edd],[ADD_setpoint ADD_setpoint],'b:',[x_edd x_edd],[ylim(1) ADD_setpoint],'b:');
                else
                    ind = find(ADD <= ADD_setpoint,1,'first');
                    x_edd = x_temp(ind);
                    h_eddset = plot(h_axes_edd,[x_edd xlim(2)],[ADD_setpoint ADD_setpoint],'b:',[x_edd x_edd],[ylim(1) ADD_setpoint],'b:');
                end
                txt_eddset = text(x_edd, ADD_setpoint,[num2str(x_edd,'%4.2f')],'Parent',h_axes_edd,'Color','b');
            end
            
            if ~isempty(x_trip)
                switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                    case 'HI Alarm'
                        [FARx,MARx,ADDx]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_trip, 'HI');
                    case 'LO Alarm'
                        [FARx,MARx,ADDx]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_trip, 'LO');
                end
                delete(txt_roc_trippoint1,txt_roc_trippoint2);
                txt_roc_trippoint1 = text(x_trip, FARx, ['\leftarrow' num2str(FARx,'%6.4f')], 'Parent', h_axes_roc,'Color','b');
                txt_roc_trippoint2 = text(x_trip, MARx, ['\leftarrow' num2str(MARx,'%6.4f')], 'Parent', h_axes_roc,'Color','r');
                delete(txt_edd_trippoint);
                txt_edd_trippoint = text(x_trip, ADDx,['\leftarrow' num2str(ADDx,'%6.4f')],'Parent',h_axes_edd,'Color','b');
            end
        end
            
        function callback_edit_trippoint(hObject, eventdata)
            trippoint_double = str2double(get(hObject, 'string'));
            if isnan(trippoint_double) || trippoint_double < min(in_data) || trippoint_double > max(in_data)
                errordlg('Trip point must lie between Min and Max of data', 'Invalid trip point', 'modal')
                set(hObject, 'String', ''); 
                if ~isempty(h_roc_trippoint) delete(h_roc_trippoint); h_roc_trippoint = []; end
                if ~isempty(txt_roc_trippoint1) delete(txt_roc_trippoint1); txt_roc_trippoint1 = []; end
                if ~isempty(txt_roc_trippoint2) delete(txt_roc_trippoint2); h_roc_trippoint2 = []; end
                if ~isempty(h_edd_trippoint) delete(h_edd_trippoint); h_edd_trippoint = []; end
                if ~isempty(txt_edd_trippoint) delete(txt_roc_trippoint); txt_roc_trippoint = []; end
            else
                x_trip = trippoint_double; 
                set(h_slide_trippoint, 'Value', x_trip);
                switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                    case 'HI Alarm'
                        [FARx,MARx,ADDx]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_trip, 'HI');
                    case 'LO Alarm'
                        [FARx,MARx,ADDx]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_trip, 'LO');
                end
                delete(h_roc_trippoint, h_edd_trippoint, txt_roc_trippoint1, txt_roc_trippoint2, txt_edd_trippoint);
                h_roc_trippoint = plot(h_axes_roc, [x_trip x_trip], [0 1],'k:');
                txt_roc_trippoint1 = text(x_trip, FARx, ['\leftarrow' num2str(FARx,'%6.4f')], 'Parent', h_axes_roc,'Color','b');
                txt_roc_trippoint2 = text(x_trip, MARx, ['\leftarrow' num2str(MARx,'%6.4f')], 'Parent', h_axes_roc,'Color','r');
                h_edd_trippoint = plot(h_axes_edd, [x_trip x_trip], [0 50],'k:');
                txt_edd_trippoint = text(x_trip, ADDx, ['\leftarrow' num2str(ADDx,'%6.4f')], 'Parent', h_axes_edd,'Color','b');
            end
        end
        %
        function callback_cb_roc(hObject, evendata)
            delete(h_axes_roc);
            switch get(hObject,'Value') 
                case 1
                    h_axes_roc = axes('Units', 'normalized', ...
                        'NextPlot', 'add', 'Box', 'on', ...
                        'Position', [60 140 320 280]./size_optimize);
                    plot(h_axes_roc, FAR(1:1000), MAR(1:1000),'b');
                    set(get(h_axes_roc,'XLabel'),'String', 'Probability of False Alarm');
                    set(get(h_axes_roc,'YLabel'),'String', 'Probability of Missed Alarm');
                    if ~isempty(FAR_setpoint)
                        plot(h_axes_roc, [FAR_setpoint FAR_setpoint], [0 1], 'b:');
                    end
                    if ~isempty(MAR_setpoint)
                        plot(h_axes_roc, [0 1], [MAR_setpoint MAR_setpoint], 'r:');
                    end
                    set(h_edit_farset, 'Enable', 'off');
                    set(h_edit_marset, 'Enable', 'off');
                    set(h_edit_eddset, 'Enable', 'off');
                    set(h_edit_trippoint, 'Enable', 'off');
                    set(h_slide_trippoint, 'Enable', 'off');
                case 0
                    h_axes_roc = axes('Units', 'normalized', ...
                        'NextPlot', 'add', 'Box', 'on', ...
                        'Position', [60 140 320 280]./size_optimize);
                    x_temp = [linspace(min(in_data), max(in_data), 1000)];
                    [AX_farmar,h_far, h_mar] = plotyy(h_axes_roc, x_temp, FAR(1:1000), x_temp, MAR(1:1000),'plot','plot');
                    set(AX_farmar(2),'NextPlot','add','XTickMode','auto','YTickMode','auto');
                    set(AX_farmar(1),'NextPlot','add','XTickMode','auto','YTickMode','auto');
                    set(AX_farmar(2),'YColor','r');
                    set(h_mar,'Color', 'r');
                    set(get(h_axes_roc,'XLabel'), 'String', 'Trip Point');
                    set(get(AX_farmar(1),'YLabel'), 'String', 'Probability of False Alarm');
                    set(get(AX_farmar(2),'YLabel'), 'String', 'Probability of Missed Alarm');
                    if ~isempty(FAR_setpoint)
                        ylim = get(AX_farmar(1),'YLim'); xlim =get(AX_farmar(1), 'XLim');
                        if FAR(1)< FAR(1000)
                            ind = find(FAR >= FAR_setpoint,1,'first');
                            x_far = x_temp(ind);
%                            h_farset = plot(AX_farmar(1),[xlim(1):(x_far-xlim(1))/100:x_far],FAR_setpoint,'b',x_far,[ylim(1):(FAR_setpoint-ylim(1))/100:FAR_setpoint],'b');
                             h_farset = plot(AX_farmar(1),[xlim(1) x_far],[FAR_setpoint FAR_setpoint],'b:',[x_far x_far],[ylim(1) FAR_setpoint],'b:');
                        else
                            ind = find(FAR <= FAR_setpoint,1,'first');
                            x_far = x_temp(ind);
%                            h_farset = plot(AX_farmar(1),[x_far:(xlim(2)-x_far)/100:xlim(2)],FAR_setpoint,'b',x_far,[ylim(1):(FAR_setpoint-ylim(1))/100:FAR_setpoint],'b');
                            h_farset = plot(AX_farmar(1),[x_far xlim(2)],[FAR_setpoint FAR_setpoint],'b:',[x_far x_far],[ylim(1) FAR_setpoint],'b:');
                        end
                        txt_farset = text(x_far, FAR_setpoint,num2str(x_far,'%4.2f'),'Parent',AX_farmar(1),'Color','b');
                    end            
                    if ~isempty(MAR_setpoint)
                        ylim = get(AX_farmar(2),'YLim'); xlim =get(AX_farmar(2), 'XLim');
                        if MAR(1)< MAR(1000)
                            ind = find(MAR >= MAR_setpoint,1,'first');
                            x_mar = x_temp(ind);
%                            h_marset = plot(AX_farmar(2),[xlim(1):(x_mar-xlim(1))/100:x_mar],MAR_setpoint,'r',x_mar,[ylim(1):(MAR_setpoint-ylim(1))/100:MAR_setpoint],'r');
                            h_marset = plot(AX_farmar(2),[xlim(1) x_mar],[MAR_setpoint MAR_setpoint],'r:',[x_mar x_mar],[ylim(1) MAR_setpoint],'r:');
                        else
                            ind = find(MAR <= MAR_setpoint,1,'first');
                            x_mar = x_temp(ind);
%                            h_marset = plot(AX_farmar(2),[x_mar:(xlim(2)-x_mar)/100:xlim(2)],MAR_setpoint,'r',x_mar,[ylim(1):(MAR_setpoint-ylim(1))/100:MAR_setpoint],'r');
                            h_marset = plot(AX_farmar(2),[x_mar xlim(2)],[MAR_setpoint MAR_setpoint],'r:',[x_mar x_mar],[ylim(1) MAR_setpoint],'r:');
                        end
                        txt_marset = text(x_mar, MAR_setpoint,[num2str(x_mar,'%4.2f')],'Parent',AX_farmar(2),'Color','r');
                    end
                    
                    if ~isempty(x_trip)
                        switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                            case 'HI Alarm'
                                [FARx,MARx,ADDx]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_trip, 'HI');
                            case 'LO Alarm'
                                [FARx,MARx,ADDx]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_trip, 'LO');
                        end
                        txt_roc_trippoint1 = text(x_trip, FARx, ['\leftarrow' num2str(FARx,'%6.4f')], 'Parent', h_axes_roc,'Color','b');
                        txt_roc_trippoint2 = text(x_trip, MARx, ['\leftarrow' num2str(MARx,'%6.4f')], 'Parent', h_axes_roc,'Color','r');
                        h_roc_trippoint = plot(h_axes_roc, [x_trip x_trip], [0 1],'k:');
                    end
                    set(h_edit_farset, 'Enable', 'on');
                    set(h_edit_marset, 'Enable', 'on');
                    set(h_edit_eddset, 'Enable', 'on');
                    set(h_edit_trippoint, 'Enable', 'on');
                    set(h_slide_trippoint, 'Enable', 'on');
            end
        end
        %
        function callback_bg_hilo(source, eventdata)
            switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                case 'HI Alarm'
%                    Eval_alarmperf('design');
%                    set(h_edit_trippoint, 'String', num2str(HAL_raise{2}));
                    x_temp = linspace(min(in_data),max(in_data),1000);
                    [FAR,MAR,ADD]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_temp, 'HI');
                case 'LO Alarm'
%                    Eval_alarmperf('design');
%                    set(h_edit_trippoint, 'String', num2str(LAL_raise{2}));
                    x_temp = linspace(min(in_data),max(in_data),1000);
                    [FAR,MAR,ADD]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_temp, 'LO');
            end
            switch get(h_cb_roc, 'Value')
                case 1
                    delete(h_axes_roc);
                    h_axes_roc = axes('Units', 'normalized', ...
                        'NextPlot', 'add', 'Box', 'on', ...
                        'Position', [60 140 320 280]./size_optimize);
                    plot(h_axes_roc, FAR(1:1000), MAR(1:1000),'b');
                    set(get(h_axes_roc,'XLabel'),'String', 'Probability of False Alarm');
                    set(get(h_axes_roc,'YLabel'),'String', 'Probability of Missed Alarm');
                    if ~isempty(FAR_setpoint)
                        plot(h_axes_roc, FAR_setpoint, [0:0.01:1], 'b');
                    end
                    if ~isempty(MAR_setpoint)
                        plot(h_axes_roc, [0:0.01:1], MAR_setpoint, 'r');
                    end
                    delete(h_edd);
                    h_edd = plot(h_axes_edd, x_temp, ADD(1:1000),'b');
                otherwise
                    delete(h_far, h_mar); 
                    x_temp = [linspace(min(in_data), max(in_data), 1000)];
                    h_far = plot(AX_farmar(1), x_temp, FAR(1:1000));
                    h_mar = plot(AX_farmar(2), x_temp, MAR(1:1000),'r');
                    delete(h_edd);
                    h_edd = plot(h_axes_edd, x_temp, ADD(1:1000),'b');
                    plot_FARMAR;
            end
        end
        %
        function callback_edit_farset(hObject, eventdata)
            far_setpoint_string = get(hObject, 'string');
            far_setpoint_double = str2double(far_setpoint_string);
            if isnan(far_setpoint_double) || far_setpoint_double < 0 || far_setpoint_double > 100
                errordlg('False alarm rate must be a positive between 0 and 100', 'Invalid false alarm setpoint', 'modal')
                set(hObject, 'String', ''); h_farset=[]; txt_farset = [];
            end
            FAR_setpoint = far_setpoint_double/100;
            x_temp = [linspace(min(in_data), max(in_data), 1000)];
            delete(h_farset, txt_farset);
            ylim = get(AX_farmar(1),'YLim'); xlim =get(AX_farmar(1), 'XLim');
            if FAR(1)< FAR(1000)
                ind = find(FAR >= FAR_setpoint,1,'first');
                x_far = x_temp(ind);
                h_farset = plot(AX_farmar(1),[xlim(1) x_far],[FAR_setpoint FAR_setpoint],'b:',[x_far x_far],[ylim(1) FAR_setpoint],'b:');
            else
                ind = find(FAR <= FAR_setpoint,1,'first');
                x_far = x_temp(ind);
                h_farset = plot(AX_farmar(1),[x_far xlim(2)],[FAR_setpoint FAR_setpoint],'b:',[x_far x_far],[ylim(1) FAR_setpoint],'b:');
            end
            txt_farset = text(x_far, FAR_setpoint,num2str(x_far,'%4.2f'),'Parent',AX_farmar(1),'Color','b');
        end
        %
        function callback_edit_marset(hObject, ~)
            mar_setpoint_string = get(hObject, 'string');
            mar_setpoint_double = str2double(mar_setpoint_string);
            if isnan(mar_setpoint_double) || mar_setpoint_double < 0 || mar_setpoint_double > 100
                errordlg('Missed alarm rate must be a positive between 0 and 100', 'Invalid missed alarm setpoint', 'modal')
                set(hObject, 'String', ''); h_marset = []; txt_marset = [];
            end
            MAR_setpoint = mar_setpoint_double/100;
            x_temp = [linspace(min(in_data), max(in_data), 1000)];
            delete(h_marset, txt_marset);
            ylim = get(AX_farmar(2),'YLim'); xlim =get(AX_farmar(2), 'XLim');
            if MAR(1)< MAR(1000)
                ind = find(MAR >= MAR_setpoint,1,'first');
                x_mar = x_temp(ind);
                h_marset = plot(AX_farmar(2),[xlim(1) x_mar],[MAR_setpoint MAR_setpoint],'r:',[x_mar x_mar],[ylim(1) MAR_setpoint],'r:');
            else
                ind = find(MAR <= MAR_setpoint,1,'first');
                x_mar = x_temp(ind);
                h_marset = plot(AX_farmar(2),[x_mar xlim(2)],[MAR_setpoint MAR_setpoint],'r:',[x_mar x_mar],[ylim(1) MAR_setpoint],'r:');
            end
            txt_marset = text(x_mar, MAR_setpoint,[num2str(x_mar,'%4.2f')],'Parent',AX_farmar(2),'Color','r');
        end
        %
        function callback_edit_eddset(hObject, eventdata)
            edd_setpoint_string = get(hObject, 'string');
            edd_setpoint_double = str2double(edd_setpoint_string);
            if isnan(edd_setpoint_double) || edd_setpoint_double < 0 
                errordlg('Average detection delay must be a positive number', 'Invalid ADD setpoint', 'modal')
                set(hObject, 'String', ''); h_eddset = []; txt_eddset = [];
            end
            ADD_setpoint = edd_setpoint_double;
            x_temp = [linspace(min(in_data), max(in_data), 1000)];
            delete(h_eddset, txt_eddset);
            ylim = get(h_axes_edd,'YLim'); xlim =get(h_axes_edd, 'XLim');
            if ADD(1)< ADD(1000)
                ind = find(ADD >= ADD_setpoint,1,'first');
                x_edd = x_temp(ind);
                h_eddset = plot(h_axes_edd,[xlim(1) x_edd],[ADD_setpoint ADD_setpoint],'b:',[x_edd x_edd],[ylim(1) ADD_setpoint],'b:');
            else
                ind = find(ADD <= ADD_setpoint,1,'first');
                x_edd = x_temp(ind);
                h_eddset = plot(h_axes_edd,[x_edd xlim(2)],[ADD_setpoint ADD_setpoint],'b:',[x_edd x_edd],[ylim(1) ADD_setpoint],'b:');
            end
            txt_eddset = text(x_edd, ADD_setpoint,[num2str(x_edd,'%4.2f')],'Parent',h_axes_edd,'Color','b');
        end
        %
        function callback_edit_ranksizeopt(hObject, eventdata)
            rank_size_string = get(hObject, 'string');
            rank_size_double = str2double(rank_size_string);
            if isnan(rank_size_double) || rank_size_double ~= round(rank_size_double)|| rank_size_double < 0 || rank_size_double > 1000
                errordlg('Alarm delay must be a positive integer between 1 and 1000', 'Invalid Alarm Delay', 'modal')
                set(hObject, 'String', num2str(rank_size))
            end
            rank_size = rank_size_double;
            x_temp = linspace(min(in_data),max(in_data),1000);
%            Eval_alarmperf('design');
            switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                case 'HI Alarm'
                   [FAR,MAR,ADD]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_temp, 'HI');
                case 'LO Alarm'
                   [FAR,MAR,ADD]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_temp, 'LO');
            end
            switch get(h_cb_roc, 'Value')
                case 0
                    delete(h_far, h_mar, h_edd);
                    x_temp = [linspace(min(in_data), max(in_data), 1000)];
                    h_far = plot(AX_farmar(1), x_temp, FAR(1:1000),'b');
                    h_mar = plot(AX_farmar(2), x_temp, MAR(1:1000),'r');
                    h_edd = plot(h_axes_edd, x_temp, ADD(1:1000),'b');
                    plot_FARMAR;
                case 1
                    delete(h_axes_roc);
                    h_axes_roc = axes('Units', 'normalized', ...
                        'NextPlot', 'add', 'Box', 'on', ...
                        'Position', [60 140 320 280]./size_optimize);
                    plot(h_axes_roc, FAR(1:1000), MAR(1:1000),'b');
                    set(get(h_axes_roc,'XLabel'),'String', 'Probability of False Alarm');
                    set(get(h_axes_roc,'YLabel'),'String', 'Probability of Missed Alarm');
                    if ~isempty(FAR_setpoint)
                        plot(h_axes_roc, [FAR_setpoint FAR_setpoint], [0 1], 'b:');
                    end
                    if ~isempty(MAR_setpoint)
                        plot(h_axes_roc, [0 1], [MAR_setpoint MAR_setpoint], 'r:');
                    end
            end
        end
        %
        function callback_edit_rankorderopt(hObject, eventdata) 
            rank_order_string = get(hObject, 'string');
            rank_order_double = str2double(rank_order_string);
            if isnan(rank_order_double) || rank_order_double ~= round(rank_order_double)|| rank_order_double < 0 || rank_order_double > 1000
                errordlg('Alarm delay must be a positive integer between 1 and 1000', 'Invalid Alarm Delay', 'modal')
                set(hObject, 'String', num2str(rank_order))
            end
            rank_order = rank_order_double;
            x_temp = linspace(min(in_data),max(in_data),1000);
            [FAR,MAR,ADD]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_temp, 'HI');
            switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                case 'HI Alarm'
                    [FAR,MAR,ADD]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_temp, 'HI');
                case 'LO Alarm'
                    [FAR,MAR,ADD]=Eval_rankfilter(in_data(1:in_normal),in_data(1+in_normal:n_data), [rank_size rank_order], x_temp, 'LO');
            end
            switch get(h_cb_roc, 'Value')
                case 0
                    delete(h_mar, h_far, h_edd);
                    x_temp = [linspace(min(in_data), max(in_data), 1000)];
                    h_far = plot(AX_farmar(1), x_temp, FAR(1:1000),'b');
                    h_mar = plot(AX_farmar(2), x_temp, MAR(1:1000),'r');
                    h_edd = plot(h_axes_edd, x_temp, ADD(1:1000),'b');
                    plot_FARMAR;
                case 1
                    delete(h_axes_roc);
                    h_axes_roc = axes('Units', 'normalized', ...
                        'NextPlot', 'add', 'Box', 'on', ...
                        'Position', [60 140 320 280]./size_optimize);
                    plot(h_axes_roc, FAR(1:1000), MAR(1:1000),'b');
                    set(get(h_axes_roc,'XLabel'),'String', 'Probability of False Alarm');
                    set(get(h_axes_roc,'YLabel'),'String', 'Probability of Missed Alarm');
                    if ~isempty(FAR_setpoint)
                        plot(h_axes_roc, [FAR_setpoint FAR_setpoint], [0 1], 'b:');
                    end
                    if ~isempty(MAR_setpoint)
                        plot(h_axes_roc, [0 1], [MAR_setpoint MAR_setpoint], 'r:');
                    end
            end
        end
        %
        function callback_pb_opt_OK(hObject, eventdata)
            set(h_edit_filter_Ranksize, 'String', num2str(rank_size));
            set(h_edit_filter_Rankorder, 'String', num2str(rank_order));
            switch get(get(h_bg_hilo, 'SelectedObject'), 'String')
                case 'HI Alarm'
                    HAL_raise{2} = str2double(get(h_edit_trippoint, 'String'));
                    set(h_pm_method_HAL, 'String',HAL_alarmlimit_methods,'Value',4);
                    set(h_edit_user_HAL, 'Visible','on');
                    set(h_edit_user_HAL,'String',num2str(HAL_raise{2},'%-6.2f'));
                    set(h_pm_deadband_HAL, 'Enable', 'on');
                case 'LO Alarm'
                    LAL_raise{2} = str2double(get(h_edit_trippoint, 'String'));
                    set(h_pm_method_LAL, 'String', LAL_alarmlimit_methods,'Value',4);
                    set(h_edit_user_LAL, 'Visible','on');
                    set(h_edit_user_LAL,'String',num2str(LAL_raise{2},'%-6.2f'));
                    set(h_pm_deadband_LAL, 'Enable', 'on');
            end
            set(h_edit_filter_Ranksize, 'Enable', 'on');
            set(h_edit_filter_Rankorder, 'Enable', 'on');
            filter_Ranksize_par = rank_size;
            filter_Rankorder_par = rank_order;
            delete(h_optimize);
            apply_design('design');
        end
        %
        function callback_pb_opt_cancel(hObject, eventdata)
            filter_Ranksize_par = rank_size_opt;
            filter_Rankorder_par = rank_order_opt;
            delete(h_optimize);
        end
        %
        function callback_slide_farmar_axis(hObject, eventdata, handles)
            if get(hObject, 'Value') >= 1 
                ylim_roc = 1;
            else
                ylim_roc = get(hObject, 'Value');
            end
            switch get(h_cb_roc,'Value')
                case 0
                    set(AX_farmar(1),'YLim',[0 ylim_roc]);
                    set(AX_farmar(2),'YLim',[0 ylim_roc]);
                case 1
                    set(h_axes_roc,'YLim',[0 ylim_roc],'XLim',[0 ylim_roc]);
            end
        end
        
        function callback_slide_edd_axis(hObject, eventdata, handles)
            if get(hObject, 'Value') >= 50 
                ylim_edd = 50;
            else
                ylim_edd = get(hObject, 'Value');
            end
            set(h_axes_edd,'YLim',[0 ylim_edd]);
        end
        %
        function callback_slide_trippoint(hObject, eventdata, handles)
            if get(hObject, 'Value') >= max(in_data) 
                x_trip = max(in_data);
            else
                x_trip = get(hObject, 'Value');
            end
            set(h_edit_trippoint, 'String', num2str(x_trip,'%6.2f'));
            plot_FARMAR;
            delete(h_roc_trippoint, h_edd_trippoint);
            h_roc_trippoint = plot(h_axes_roc, [x_trip x_trip], [0 1],'k:');
            h_edd_trippoint = plot(h_axes_edd, [x_trip x_trip], [0 50],'k:');

        end
    end
%%
    function ALMdelay_opt(hObject, eventdata)
        delay_opt = 0.9; delay_off_opt = 1; delay_on_opt = 1;
        dist_rtnalm = [];  dist_almrtn = [];
        center_rtnalm = [];  center_almrtn = [];
%        count_rtnalm = [];   count_almrtn = [];
        AX_almrtn =[];   AX_rtnalm = [];
%        h_axes_rtnalm = []; h_axes_almrtn = [];
        h_delayopt = [];
        h_plotrun = [];

        is_fault_lo = 0;
        is_fault_hi = 0;
        alm_time_hi = [];
        alm_time_lo = [];
        rtn_time_hi = [];
        rtn_time_lo = [];

        for i = 2:n_data
            switch is_fault_hi
                case false
                    is_fault_hi = all(design_data(i) > HAL_raise{2});
                    if is_fault_hi
                        alm_time_hi(end+1) = i;
                    end
                case true
                    if 1 > i
                        continue
                    end
                    is_fault_hi = ~all(design_data(i) < HAL_clear{2});
                    if ~is_fault_hi
                        rtn_time_hi(end+1) = i;
                    end
            end
            
            switch is_fault_lo
                case false
                    is_fault_lo = all(design_data(i) < LAL_raise{2});
                    if is_fault_lo
                        alm_time_lo(end+1) = i;
                    end
                case true
                    if 1 > i
                        continue
                    end
                    is_fault_lo = ~all(design_data(i) > LAL_clear{2});
                    if ~is_fault_lo
                        rtn_time_lo(end+1) = i;
                    end
            end
        end
        
        if size(alm_time_hi, 2) ~= size(rtn_time_hi, 2)
            rtn_time_hi(end+1) = n_data;
        end
        
        if size(alm_time_lo, 2) ~= size(rtn_time_lo, 2)
            rtn_time_lo(end+1) = n_data;
        end

        n = size(alm_time_hi,2);
        run_rtnalm_hi = zeros(n-1,1);
        run_almrtn_hi = zeros(n,1);
        for i=1:n-1
            run_rtnalm_hi(i) = alm_time_hi(i+1) - rtn_time_hi(i);
        end
        for i=1:n
            run_almrtn_hi(i) = rtn_time_hi(i) - alm_time_hi(i);
        end
        m = size(alm_time_lo,2);
        run_rtnalm_lo = zeros(m-1,1);
        run_almrtn_lo = zeros(m,1);
        for i=1:m-1
            run_rtnalm_lo(i) = alm_time_lo(i+1) - rtn_time_lo(i);
        end
        for i=1:m
            run_almrtn_lo(i) = rtn_time_lo(i) - alm_time_lo(i);
        end
        run_rtnalm = [run_rtnalm_hi;run_rtnalm_lo];
        run_almrtn = [run_almrtn_hi;run_almrtn_lo];
        [count_rtnalm, center_rtnalm] = hist(run_rtnalm, 1:max(run_rtnalm));
        [count_almrtn, center_almrtn] = hist(run_almrtn, 1:max(run_almrtn));
        total_rtnalm = sum(count_rtnalm)+2;
        dist_rtnalm = cumsum(count_rtnalm)/total_rtnalm;
        total_almrtn = sum(count_almrtn);
        dist_almrtn = cumsum(count_almrtn)/total_almrtn;
        
        width_run = 800;
        height_run = 460;
        
        pos_plotrun = CenterFigure(width_run, height_run);
        size_plotrun = [pos_plotrun(3:4) pos_plotrun(3:4)];
        h_plotrun = figure('Visible', 'on', 'Position', pos_plotrun, ...
            'Name', 'Run Length', 'NumberTitle', 'off', ...
            'Resize', 'on', 'MenuBar', 'none', ...
            'Color', defaultBackground, ...
            'Toolbar', 'auto');
        set(h_plotrun, 'Color', defaultBackground)
 
        uicontrol('Parent', h_plotrun, ...
            'Style', 'text', ...
            'String' , 'Expected alarm reduction (%):', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [100, 35, 150, 20]./size_plotrun);
        h_edit_delayopt = uicontrol('Parent', h_plotrun, ...
            'Style', 'edit', ...
            'String', num2str(100*delay_opt), 'Units', 'normalized', ...
            'Position', [250 38 40 20]./size_plotrun, ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
            'Callback', @callback_edit_delayopt);

        pos_bg_delayopt = [300, 5, 110, 50];
        size_bg_delayopt = [pos_bg_delayopt(3:4) pos_bg_delayopt(3:4)];
        h_bg_delayopt = uibuttongroup('Parent', h_plotrun, ...
            'Position', pos_bg_delayopt./size_plotrun, ...
            'BorderType', 'none');
        uicontrol('Parent', h_bg_delayopt, ...
            'Style', 'radiobutton', ...
            'String', 'OFF-delay', ...
            'Units', 'normalized', ...
            'Position', [10 25 120 25]./size_bg_delayopt);
        uicontrol('Parent', h_bg_delayopt, ...
            'Style', 'radiobutton', ...
            'String', 'ON-delay', ...
            'Units', 'normalized', ...
            'Position', [10 5 120 25]./size_bg_delayopt);

        uicontrol('Parent', h_plotrun, ...
            'Style', 'pushbutton', ...
            'String', 'Optimize', ...
            'Units', 'normalized', ...
            'Position', [150 10 65 25]./size_plotrun, ...
            'Callback', @callback_pb_delayopt); 
        uicontrol('Parent', h_plotrun, ...
            'Style', 'pushbutton', ...
            'String', 'OK', ...
            'Units', 'normalized', ...
            'Position', [450 25 65 25]./size_plotrun, ...
            'Callback', @callback_pb_delayopt_OK); 
        uicontrol('Parent', h_plotrun, ...
            'Style', 'pushbutton', ...
            'String', 'Cancel', ...
            'Units', 'normalized', ...
            'Position', [550 25 65 25]./size_plotrun, ...
            'Callback', @callback_pb_delayopt_cancel); 
        
        h_axes_rtnalm = axes('Units', 'normalized', ...
            'NextPlot', 'add', 'Box', 'on', ...
            'Position', [60 90 320 320]./size_plotrun);
 
        if isempty(center_rtnalm)
            h_rtn_alm = [];
        else
            [AX_rtnalm,h_rtn_alm,h_rtn_alm_dist] = plotyy(h_axes_rtnalm, center_rtnalm, count_rtnalm, center_rtnalm, dist_rtnalm,'bar','plot');
            set(h_rtn_alm, 'FaceColor', 'none', 'EdgeColor', 'b', 'LineStyle', '-', 'LineWidth', 1)
            set(h_rtn_alm_dist,'LineStyle','-','LineWidth',1.5, 'Color','r');
            set(AX_rtnalm(2),'YColor','r');
            set(AX_rtnalm(2),'NextPlot','add','XTickMode','auto','YTickMode','auto');
            set(AX_rtnalm(1),'NextPlot','add','XTickMode','auto','YTickMode','auto');
        end
        set(get(h_axes_rtnalm,'Title'), 'String', 'RTN to ALM');
        set(get(h_axes_rtnalm,'YLabel'), 'String', 'Run length distribution');

        h_axes_almrtn = axes('Units', 'normalized', ...
            'NextPlot', 'add', 'Box', 'on', ...
            'Position', [450 90 320 320]./size_plotrun);
        if isempty(center_almrtn)
            h_alm_rtn = [];
        else
            [AX_almrtn,h_alm_rtn,h_alm_rtn_dist] = plotyy(h_axes_almrtn, center_almrtn, count_almrtn, center_almrtn, dist_almrtn,'bar','plot');
            set(h_alm_rtn, 'FaceColor', 'none', 'EdgeColor', 'b', 'LineStyle', '-', 'LineWidth', 1)
            set(h_alm_rtn_dist,'LineStyle','-','LineWidth',1.5, 'Color','r');
            set(AX_almrtn(2),'YColor','r');
            set(AX_almrtn(2),'NextPlot','add','XTickMode','auto','YTickMode','auto');
            set(AX_almrtn(1),'NextPlot','add','XTickMode','auto','YTickMode','auto');
        end
        set(get(h_axes_almrtn,'Title'), 'String', 'ALM to RTN');
        set(get(h_axes_almrtn,'YLabel'), 'String', 'Run length distribution');
        
        % functions
        function callback_edit_delayopt(hObject, eventdata)
            delay_opt_string = get(hObject, 'string');
            delay_opt_double = str2double(delay_opt_string);
            if isnan(delay_opt_double) || delay_opt_double ~= round(delay_opt_double)|| ...
                    delay_opt_double < 0 || delay_opt_double > 100
                errordlg('Alarm count reduction (%) must be a positive integer between 1 and 100', ...
                    'Invalid Alarm count reduction', 'modal')
                set(hObject, 'String', num2str(delay_opt*100))
            end
            delay_opt = delay_opt_double/100;
        end
        %
        function callback_pb_delayopt(hObject, eventdata)
            delete(h_delayopt);
            switch get(get(h_bg_delayopt, 'SelectedObject'), 'String')
                case 'OFF-delay'
                    ind = find(dist_rtnalm >= delay_opt,1,'first');
                    delay_off_opt = center_rtnalm(ind);
                    ylim = get(AX_rtnalm(2),'YLim'); xlim =get(AX_rtnalm(2), 'XLim');
                    h_delayopt = plot(AX_rtnalm(2), [delay_off_opt:xlim(2)], delay_opt, 'c.',delay_off_opt, [ylim(1):0.01:delay_opt],'c.');
                case 'ON-delay'
                    ind = find(dist_almrtn >= delay_opt,1,'first');
                    delay_on_opt = center_almrtn(ind);
                    ylim = get(AX_almrtn(2),'YLim'); xlim =get(AX_almrtn(2), 'XLim');
                    h_delayopt = plot(AX_almrtn(2), [delay_on_opt:xlim(2)], delay_opt, 'c.',delay_on_opt, [ylim(1):0.01:delay_opt],'c.');
            end
        end
        %
        function callback_pb_delayopt_OK(hObject, eventdata)
            switch get(get(h_bg_delayopt, 'SelectedObject'), 'String')
                case 'OFF-delay'
                    delay_off{2} = ceil(delay_off_opt)+1;
                    delay_on{2} = 1;
                case 'ON-delay'
                    delay_on{2} = ceil(delay_on_opt)+1;
                    delay_off{2} = 1;
            end
            set(h_edit_delay_on, 'String', num2str(delay_on{2}));
            set(h_edit_delay_off, 'String', num2str(delay_off{2}));
            delete(h_plotrun);
            apply_design('design');
        end
        %
        function callback_pb_delayopt_cancel(hObject, eventdata)
%            delay_on_opt = 1;
%            delay_off_opt = 1;
            delete(h_plotrun);
        end
    end
%%
    function callback_compare(hObject, eventdata)
        color={'r','g','c'};
        if isempty(h_compare)
            cmp_width = left_margin + gap_hmargin + width_data + gap_hmargin + width_data + right_margin;
            cmp_height = 2*bottom_margin + 3*height_data + 5*gap_vmargin;

            pos_compare = CenterFigure(cmp_width, cmp_height);
            size_compare = [pos_compare(3:4) pos_compare(3:4)];
            h_compare = figure('Position', pos_compare, ...
                'Name', 'Comparing Designs', 'NumberTitle', 'off', ...
                'Resize', 'on', 'MenuBar', 'none', ...
                'Color', defaultBackground, ...
                'NextPlot', 'add',...
                'Toolbar', 'auto', ...
                'CloseRequestFcn', @cmp_close_request, ...
                'Visible', 'on', ...
                'WindowStyle', 'normal');
        
            pos_cmp_data{1} = [gap_hmargin, 2*bottom_margin+2*height_data+2*gap_vmargin, width_data, height_data];
            h_cmp_axes{1} = axes('Units', 'normalized', ...
                'NextPlot', 'add', 'Box', 'on', ...
                'XTick', [], 'YTick', [], ...
                'Position', pos_cmp_data{1}./size_compare);

            pos_cmp_data{2} = [left_margin+width_data+2*gap_hmargin, 2*bottom_margin+2*height_data+2*gap_vmargin, width_data, height_data];
            h_cmp_axes{2} = axes('Units', 'normalized', ...
                'NextPlot', 'add', 'Box', 'on', ...
                'XTick', [], 'YTick', [], ...
                'Position', pos_cmp_data{2}./size_compare);

            pos_cmp_data{3} = [gap_hmargin, 2*bottom_margin+150+gap_vmargin, width_data, height_data];
            h_cmp_axes{3} = axes('Units', 'normalized', ...
                'NextPlot', 'add', 'Box', 'on', ...
                'XTick', [], 'YTick', [], ...
                'Position', pos_cmp_data{3}./size_compare);

            pos_cmp_data{4} = [left_margin+width_data+2*gap_hmargin, 2*bottom_margin+150+gap_vmargin, width_data, height_data];
            h_cmp_axes{4} = axes('Units', 'normalized', ...
                'NextPlot', 'add', 'Box', 'on', ...
                'XTick', [], 'YTick', [], ...
                'Position', pos_cmp_data{4}./size_compare);

 %           cmp_cnames = {'Total Alarms','(HI)','(LO)','False Alarms','(HI)','(LO)','Alarm points','(HI)','(LO)','(False)','(Missed)','% of Flase','% of Missed'};
           cmp_cnames = {'Total Alarms','HI_ALM','LO_ALM','False Alarms','HI_False','LO_False','Duration of Alarms','D. HI_ALM','D. LO_ALM','D. False_ALM','D. Missed_ALM','% of False_ALM','% of Missed_ALM'};
           cmp_rnames = {'Current','Design 1', 'Design 2','Design 3'};
            h_cmp_table = uitable('Parent', h_compare, 'Units', 'normalized', ...
                'RowName', cmp_rnames, 'ColumnName', cmp_cnames, ...
                'Position', [gap_hmargin 2*bottom_margin+gap_vmargin gap_hmargin+2*width_data+20 112]./size_compare);

            h_comp_plotroc = uicontrol('Parent', h_compare, ...
            'Style', 'pushbutton', ...
            'String', 'Compare ROC', ...
            'Units', 'normalized', ...
            'Position', [left_margin+width_data+gap_hmargin-35 bottom_margin-10 90 25]./size_compare, ...
            'Callback', @callback_comproc); 

            cmp_id = 0;
            current_data = in_data;
            n_data = length(current_data);
            white_area = (max(current_data) - min(current_data))*0.15;
            set(h_cmp_axes{1}, 'XLim',[0 n_data], 'YLim',[min(current_data)-white_area max(current_data)+white_area], 'XTickMode', 'auto', 'YTickMode', 'auto');
            plot(h_cmp_axes{1}, 1:n_normal, current_data(1:n_normal), 'Color', color_normal);
            if is_faulty
                plot(h_cmp_axes{1}, n_normal+1:n_data, current_data(n_normal+1:n_data), 'Color', color_faulty);
            end
            plot(h_cmp_axes{1}, [0 n_data], [HAL_raise{1} HAL_raise{1}], 'g', 'LineWidth', 1.5, 'LineStyle', '-');
            plot(h_cmp_axes{1}, [0 n_data], [HAL_clear{1} HAL_clear{1}], 'g', 'LineWidth', 1.5, 'LineStyle', '--');
            plot(h_cmp_axes{1}, [0 n_data], [LAL_raise{1} LAL_raise{1}], 'g', 'LineWidth', 1.5, 'LineStyle', '-');
            plot(h_cmp_axes{1}, [0 n_data], [LAL_clear{1} LAL_clear{1}], 'g', 'LineWidth', 1.5, 'LineStyle', '--');
%            temp0 = mean(current_data(1:n_normal));
            temp0 = (min(HAL_raise{1},max(current_data(1:n_normal))) + max(LAL_raise{1},min(current_data(1:n_normal))))/2;
            for i=1:size(alarm_time_hi{1}, 2)
                plot(h_cmp_axes{1},[alarm_time_hi{1}(i) alarm_time_hi{1}(i) RTN_time_hi{1}(i) RTN_time_hi{1}(i)], [temp0 HAL_raise{1} HAL_raise{1} temp0], color_alarm);
            end
            for i=1:size(alarm_time_lo{1}, 2)
                plot(h_cmp_axes{1},[alarm_time_lo{1}(i) alarm_time_lo{1}(i) RTN_time_lo{1}(i) RTN_time_lo{1}(i)], [temp0 LAL_raise{1} LAL_raise{1} temp0], color_alarm);
            end
            title(h_cmp_axes{1},'Current');
            cmp_data(1,:)= [alarm_report{1}(1:3)' alarm_report{1}(7:9)' alarm_report{1}(4:6)' alarm_report{1}(10) alarm_report{1}(19) 100*alarm_report{1}(10)/n_normal 100*alarm_report{1}(19)/(n_data-n_normal)];
        else
            figure(h_compare);
        end
        
        cmp_id = cmp_id + 1;
        if cmp_id > 3
            selection = questdlg('Only 3 designs are allowed in comparison. Update the last design?',...
                '',...
                'Yes', 'No' , 'Yes');
            switch selection
                case 'Yes'
                    cmp_id = 3;
                otherwise
                    return
            end
        end
        
        current_data = design_data;
        n_data = length(current_data);
        white_area = (max(current_data) - min(current_data))*0.15;
        set(h_cmp_axes{cmp_id+1}, 'XLim',[0 n_data], 'YLim',[min(current_data)-white_area max(current_data)+white_area], 'XTickMode', 'auto', 'YTickMode', 'auto');
        plot(h_cmp_axes{cmp_id+1}, 1:n_normal, current_data(1:n_normal), 'Color', color_normal);
        if is_faulty
            plot(h_cmp_axes{cmp_id+1}, n_normal+1:n_data, current_data(n_normal+1:n_data), 'Color', color_faulty);
        end
        plot(h_cmp_axes{cmp_id+1}, [0 n_data], [HAL_raise{2} HAL_raise{2}], 'g', 'LineWidth', 1.5, 'LineStyle', '-');
        plot(h_cmp_axes{cmp_id+1}, [0 n_data], [HAL_clear{2} HAL_clear{2}], 'g', 'LineWidth', 1.5, 'LineStyle', '--');
        plot(h_cmp_axes{cmp_id+1}, [0 n_data], [LAL_raise{2} LAL_raise{2}], 'g', 'LineWidth', 1.5, 'LineStyle', '-');
        plot(h_cmp_axes{cmp_id+1}, [0 n_data], [LAL_clear{2} LAL_clear{2}], 'g', 'LineWidth', 1.5, 'LineStyle', '--');

        %temp0 = mean(current_data(1:n_normal));
        temp0 = (min(HAL_raise{2},max(current_data(1:n_normal))) + max(LAL_raise{2},min(current_data(1:n_normal))))/2;
        for i=1:size(alarm_time_hi{2}, 2)
            plot(h_cmp_axes{cmp_id+1},[alarm_time_hi{2}(i) alarm_time_hi{2}(i) RTN_time_hi{2}(i) RTN_time_hi{2}(i)], [temp0 HAL_raise{2} HAL_raise{2} temp0], color_alarm);
        end
        for i=1:size(alarm_time_lo{2}, 2)
            plot(h_cmp_axes{cmp_id+1},[alarm_time_lo{2}(i) alarm_time_lo{2}(i) RTN_time_lo{2}(i) RTN_time_lo{2}(i)], [temp0 LAL_raise{2} LAL_raise{2} temp0], color_alarm);
        end
        title(h_cmp_axes{cmp_id+1},['Design ' num2str(cmp_id)]);
        cmp_data(cmp_id+1,:) = [alarm_report{2}(1:3)' alarm_report{2}(7:9)' alarm_report{2}(4:6)' alarm_report{2}(10) alarm_report{2}(19) 100*alarm_report{2}(10)/n_normal 100*alarm_report{2}(19)/(n_data-n_normal)]; 
        set(h_cmp_table,'Data',cmp_data);

        data_desn{cmp_id} = current_data; 
        HALcmp_raise{cmp_id} = HAL_raise{2}; LALcmp_raise{cmp_id} = LAL_raise{2};
        delaycmp_on{cmp_id} = delay_on{2}; delaycmp_off{cmp_id} = delay_off{2}; 
        alm_db{cmp_id} = [HAL_DB{2} LAL_DB{2}];
        %
        function callback_comproc(hObject, eventdata)
            h_wait = dialog('pos', CenterFigure(300, 100));
            uicontrol('Parent', h_wait, 'Style', 'text', ...
                'Position', [75 40 150 20], ...
                'FontSize', 10, ...
                'String' , 'Computing. Please wait ...');
            pause(0.1)
            
            width_roc = 800;
            height_roc = 460;
        
            pos_plotroc = CenterFigure(width_roc, height_roc);
            size_plotroc = [pos_plotroc(3:4) pos_plotroc(3:4)];
            h_plotroc = figure('Visible', 'on', 'Position', pos_plotroc, ...
                'Name', 'ROC ', 'NumberTitle', 'off', ...
                'Resize', 'on', 'MenuBar', 'none', ...
                'Color', defaultBackground, ...
                'Toolbar', 'auto');
            set(h_plotroc, 'Color', defaultBackground)
   
            h_axes_roc_hi = axes('Units', 'normalized', ...
                'NextPlot', 'add', 'Box', 'on', ...
                'XTick', [0 1], 'YTick', [0 1], ...
                'XGrid', 'on', 'YGrid', 'on', ...
                'XLim', [-0.1 1.1], 'YLim', [-0.1 1.1], ...
                'Position', [60 80 320 320]./size_plotroc);
            h_axes_roc_lo = axes('Units', 'normalized', ...
                'NextPlot', 'add', 'Box', 'on', ...
                'XGrid', 'on', 'YGrid', 'on', ...
                'XTick', [0 1], 'YTick', [0 1], ...
                'XLim', [-0.1 1.1], 'YLim', [-0.1 1.1], ...
                'Position', [450 80 320 320]./size_plotroc);

            x_tmp = linspace(min(in_data), max(in_data),1000); x_temp=[x_tmp HAL_raise{1} LAL_raise{1}];
            [FAR_HALx,MAR_HALx,ADD_HALx,FAR_LALx,MAR_LALx,ADD_LALx] = Eval_alarm(in_data(1:n_normal), in_data(1+n_normal:n_data),x_temp,delay_on{1},delay_off{1},[HAL_DB{1} LAL_DB{1}]);
            plot(h_axes_roc_hi, FAR_HALx(1:1000), MAR_HALx(1:1000), 'b', 'LineWidth', 2);
            plot(h_axes_roc_hi, FAR_HALx(1001), MAR_HALx(1001), '.k', 'Markersize', 15);
            text(FAR_HALx(1001)+0.01, MAR_HALx(1001)+0.05, ['HAL = ' num2str(HAL_raise{1},'%-6.2f')],'Parent',h_axes_roc_hi,'Color','b');
            plot(h_axes_roc_lo, FAR_LALx(1:1000), MAR_LALx(1:1000), 'b', 'LineWidth', 2);
            plot(h_axes_roc_lo, FAR_LALx(1002), MAR_LALx(1002), '.k', 'Markersize', 15);
            text(FAR_LALx(1002)-0.11, MAR_LALx(1002)-0.05, ['LAL = ' num2str(LAL_raise{1},'%-6.2f')],'Parent',h_axes_roc_lo,'Color','b');
            for i=1:cmp_id
                x_tmp = linspace(min(data_desn{i}), max(data_desn{i}),1000); x_temp=[x_tmp HALcmp_raise{i} LALcmp_raise{i}];
                [FAR_HALx,MAR_HALx,ADD_HALx,FAR_LALx,MAR_LALx,ADD_LALx] = Eval_alarm(data_desn{i}(1:n_normal), data_desn{i}(1+n_normal:n_data),x_temp,delaycmp_on{i},delaycmp_off{i},alm_db{i});
                plot(h_axes_roc_hi, FAR_HALx(1:1000), MAR_HALx(1:1000), color{i}, 'LineWidth', 2);
                plot(h_axes_roc_hi, FAR_HALx(1001), MAR_HALx(1001), '.k', 'Markersize', 15);
                text(FAR_HALx(1001)+0.01, MAR_HALx(1001)+0.05, ['HAL = ' num2str(HALcmp_raise{i},'%-6.2f')],'Parent',h_axes_roc_hi,'Color',color{i});
                plot(h_axes_roc_lo, FAR_LALx(1:1000), MAR_LALx(1:1000), color{i}, 'LineWidth', 2);
                plot(h_axes_roc_lo, FAR_LALx(1002), MAR_LALx(1002), '.k', 'Markersize', 15);
                text(FAR_LALx(1002)-0.11, MAR_LALx(1002)-0.05, ['LAL = ' num2str(LALcmp_raise{i},'%-6.2f')],'Parent',h_axes_roc_lo,'Color',color{i});
            end
            set(get(h_axes_roc_hi,'XLabel'), 'String', 'Probability of False Alarm');
            set(get(h_axes_roc_hi,'YLabel'), 'String', 'Probability of Missed Alarm');
            set(get(h_axes_roc_hi,'Title'), 'String', 'High Alarm');

            set(get(h_axes_roc_lo,'XLabel'), 'String', 'Probability of False Alarm');
            set(get(h_axes_roc_lo,'YLabel'), 'String', 'Probability of Missed Alarm');
            set(get(h_axes_roc_lo,'Title'), 'String', 'Low Alarm');
            delete(h_wait);
        end
    end
%% functions
    function cmp_close_request(hObject, eventdata) 
        % Callback function run when the Close button is pressed
        selection = questdlg('Are you sure you want to close?',...
                    'Close Alarm Designer',...
                    'Yes', 'No' , 'No');
        switch selection
            case 'Yes'
                delete(hObject);
                cmp_id = 0; h_compare = []; h_cmp_axes={[];[];[];[]}; cmp_data = nan*ones(4,13);
            otherwise
                return
        end
    end

end
