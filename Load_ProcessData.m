function [in_data,n_normal] = Load_ProcessData(ProcessData)
%
defaultBackground = get(0, 'defaultUicontrolBackgroundColor');
%
current_data = []; current_tag = [];
start_time = []; sampling_time = [];
in_data = []; n_data = [];
data_normal  = []; n_normal = [];  
data_faulty = []; n_faulty = [];
ylim_data = []; ylim_U = [];
data_change = [];

%handles
h_trend = []; h_hist = []; h_meanch = [];
h_data = []; h_data_select = []; h_data_start = []; h_data_end = [];
h_bins = []; h_bins_select = []; h_pdf = []; h_pdf_select = [];
%h_ChPt = []; h_ChPt_select = []; 
h_chpt_start = []; h_chpt_end = [];
h_data_all = []; 
%h_data_normal = []; h_data_faulty = [];

% slider
select_start = []; select_end = [];
h_slide_start = []; h_slide_end = [];
h_edit_select_start = []; h_edit_select_end = [];

% color
color_normal = 'b'; color_shadow = 'c'; color_faulty = 'r';

%%
width_data = 450; height_data = 200;
width_hist = 220; height_hist = 200;
left_margin = 40; bottom_margin = 40; 
gap_margin = 40; top_margin = 30; 
width = left_margin + width_data + gap_margin + width_hist + gap_margin;
height = bottom_margin + height_data + gap_margin + height_data + gap_margin+top_margin;

pos_main = CenterFigure(width, height);
size_main = [pos_main(3:4) pos_main(3:4)];

h_main = figure('Position', pos_main, ...
            'Name', 'Load Process Data', 'NumberTitle', 'off', ...
            'Resize', 'on', 'MenuBar', 'none', ...
            'Color', defaultBackground, ...
            'Toolbar', 'none', ...
            'CloseRequestFcn', @close_request, ...
            'Visible', 'on', ...
            'WindowStyle', 'normal');

set(h_main, 'Color', defaultBackground)

%% mean change determination
pos_meanch = [left_margin, bottom_margin-15, width_data, height_data];
h_meanch = axes('Units', 'normalized', ...
    'NextPlot', 'add', 'Box', 'on', ...
    'XTick', [], 'YTick', [], ...
    'Position', pos_meanch./size_main);

%% trend and hist plots
pos_trend = [left_margin, bottom_margin+height_data+2*gap_margin, width_data, height_data];
pos_hist = [left_margin+gap_margin+width_data, bottom_margin+height_data+2*gap_margin, width_hist, height_hist];
h_trend = axes('Units', 'normalized', ...
    'NextPlot', 'add', 'Box', 'on', ...
    'XTick', [], 'YTick', [], ...
    'Position', pos_trend./size_main);
h_hist = axes('Units', 'normalized', 'Box', 'on', ...
    'Position', pos_hist./size_main, ...
    'XTick', [], 'YTick', [], ...
    'NextPlot', 'add');

h_slide_start = uicontrol('Parent', h_main, ...
    'Style', 'slider', ...
    'Units', 'normalized', ...
    'Enable', 'off', ...
    'Callback', @callback_slide_start, ...
    'Position', [left_margin-15, bottom_margin+height_data+30, width_data+30 20]./size_main);
h_slide_end = uicontrol('Parent', h_main, ...
    'Style', 'slider', ...
    'Units', 'normalized', ...
    'Enable', 'off', ...
    'Callback', @callback_slide_end, ...
    'Position', [left_margin-15, bottom_margin+height_data+10, width_data+30 20]./size_main);

h_edit_select_start = uicontrol('Parent', h_main, ...
    'Style', 'edit', ...
    'Units', 'normalized', ...
    'String', num2str(select_start), ...
    'Enable', 'off', ...
    'Position', [left_margin+gap_margin+width_data bottom_margin+height_data+30 50 20]./size_main, ...
    'Callback', @callback_edit_select_start);
h_edit_select_end = uicontrol('Parent', h_main, ...
    'Style', 'edit', ...
    'Units', 'normalized', ...
    'String', num2str(select_end), ...
    'Enable', 'off', ...
    'Position', [left_margin+gap_margin+width_data bottom_margin+height_data+10 50 20]./size_main, ...
    'Callback', @callback_edit_select_end);
    
h_pb_zoomin = uicontrol('Parent', h_main, ...
    'Style', 'pushbutton', ...
    'String', 'Zoom In', ...
    'Units', 'normalized', ...
    'Enable', 'off', ...
    'Position', [left_margin+gap_margin+width_data+70 bottom_margin+height_data+30 65 25]./size_main, ...
    'Callback', @callback_pb_zoomin);
h_pb_zoomout = uicontrol('Parent', h_main, ...
    'Style', 'pushbutton', ...
    'String', 'Zoom Out', ...
    'Units', 'normalized', ...
    'Enable', 'off', ...
    'Position', [left_margin+gap_margin+width_data+70 bottom_margin+height_data+5 65 25]./size_main, ...
    'Callback', @callback_pb_zoomout);


%% process data
pos_text_tag = [left_margin+gap_margin+width_data, bottom_margin+height_data-40, 60, 25];
uicontrol('Parent', h_main, ...
    'Style', 'text', 'String' , 'Select Tag: ', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', pos_text_tag./size_main);
pos_tag = [left_margin+gap_margin+width_data+60, bottom_margin+height_data-35, 150, 25];
h_pm_tag = uicontrol('Parent', h_main, ...
    'Style', 'popupmenu', 'String', 'Tag name', ...
    'Units', 'normalized', ...
    'BackgroundColor', 'w', ...
    'Position', pos_tag./size_main, ...
    'Callback', @callback_pm_tag);

h_pb_meanch = uicontrol('Parent', h_main, ...
    'Style', 'pushbutton', ...
    'String', 'Mean Change Detection', ...
    'Units', 'normalized', ...
    'Visible', 'off', ...
    'Position', [left_margin+gap_margin+width_data+60, bottom_margin+height_data-70, 140 25]./size_main, ...
    'Callback', @callback_pb_meanch);

% ok
h_pb_ok = uicontrol('Parent', h_main, ...
    'Style', 'pushbutton', ...
    'String', 'OK', ...
    'Units', 'normalized', ...
    'Enable', 'off', ...
    'Position', [left_margin+gap_margin+width_data+30 bottom_margin 65 25]./size_main, ...
    'Callback', @callback_pb_ok);
% cancel
uicontrol('Parent', h_main, ...
    'Style', 'pushbutton', ...
    'String', 'Cancel', ...
    'Units', 'normalized', ...
    'Position', [left_margin+gap_margin+width_data+30+100 bottom_margin 65 25]./size_main, ...
    'Callback', @close_request); 

%
pos_bg_data = [left_margin+gap_margin+width_data+10 bottom_margin+40 200 70];
size_bg_data = [pos_bg_data(3:4) pos_bg_data(3:4)];
h_bg_data = uibuttongroup('Parent', h_main, ...
            'Position', pos_bg_data./size_main, ...
            'BorderType', 'etchedin',...
            'Title', 'Select Data', ...
            'ForegroundColor', 'b');
%            'SelectionChangeFcn', @callback_bg_data);
uicontrol('Parent', h_bg_data, ...
            'Style', 'radiobutton', ...
            'String', 'Normal', ...
            'Units', 'normalized', ...
            'Position', [10 40 100 25]./size_bg_data);
uicontrol('Parent', h_bg_data, ...
            'Style', 'radiobutton', ...
            'String', 'Abnormal', ...
            'Units', 'normalized', ...
            'Position', [10 10 100 25]./size_bg_data);
h_pb_select = uicontrol('Parent', h_bg_data, ...
    'Style', 'pushbutton', ...
    'String', 'Select Data', ...
    'Units', 'normalized', ...
    'Enable', 'off', ...
    'Position', [100 40 80 30]./size_bg_data, ...
    'Callback', @callback_pb_select);
h_pb_clear = uicontrol('Parent', h_bg_data, ...
    'Style', 'pushbutton', ...
    'String', 'Clear', ...
    'Units', 'normalized', ...
    'Enable', 'off', ...
    'Position', [100 5 80 30]./size_bg_data, ...
    'Callback', @callback_pb_clear);

%% main
n_tag=length(ProcessData);
colheaders={};
for i=1:n_tag
    colheaders=[colheaders,ProcessData{i}.tag];
end
set(h_pm_tag, 'String', colheaders, 'Value', 1);

%% functions
    function close_request(hObject, eventdata) 
        % Callback function run when the Close button is pressed
        delete(h_main);
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
    function callback_pm_tag(hObject, eventdata)
        delete(h_trend);
        h_trend = axes('Units', 'normalized', ...
            'NextPlot', 'add', 'Box', 'on', ...
            'XTick', [], 'YTick', [], ...
            'Position', pos_trend./size_main);
        delete(h_hist);
        h_hist = axes('Units', 'normalized', 'Box', 'on', ...
            'Position', pos_hist./size_main, ...
            'XTick', [], 'YTick', [], ...
            'NextPlot', 'add');
        delete(h_meanch);
        h_meanch = axes('Units', 'normalized', ...
            'NextPlot', 'add', 'Box', 'on', ...
            'XTick', [], 'YTick', [], ...
            'Position', pos_meanch./size_main);
        
        val = get(hObject, 'Value');
        current_data = ProcessData{val}.data;
        current_tag = ProcessData{val}.tag;
        if size(ProcessData{val}.date,2)==1
            date_temp=ProcessData{val-ProcessData{val}.date}.date;
        else
            date_temp=ProcessData{val}.date;
        end
        start_time = [];
        sampling_time=[];
        if ~isempty(date_temp)
            start_time=datenum(date_temp);
            sampling_time=datenum(date_temp(2,:))-datenum(date_temp(1,:));
        end
        n_data = length(current_data);
        
        % plot data
        if ~isempty(start_time)
            h_data = plot(h_trend, start_time([1:n_data]), current_data, 'Color', color_normal);
            set(h_trend,'XLim',start_time([1,n_data]), 'XTickMode', 'auto', 'YTickMode', 'auto');
            h_data_all = plot(h_meanch, start_time([1:n_data]), current_data, 'Color', color_shadow);
            set(h_meanch,'XLim',start_time([1,n_data]), 'XTickMode', 'auto', 'YTickMode', 'auto');
        else
            h_data = plot(h_trend, [1:n_data], current_data, 'Color', color_normal);
            set(h_trend, 'XLim', [1 n_data], 'XTickMode', 'auto', 'YTickMode', 'auto');
            h_data_all = plot(h_meanch, [1:n_data], current_data, 'Color', color_shadow);
            set(h_meanch, 'XLim', [1 n_data], 'XTickMode', 'auto', 'YTickMode', 'auto');
        end
        ylim_data = get(h_trend, 'YLim'); 
        title(h_trend,['Time trend of process tag: ',current_tag]);
        title(h_meanch,['Selcted data']);
        % plot histogram
        set(h_hist, 'XLim', ylim_data, 'XTickMode', 'auto', 'YTickMode', 'auto');
        title(h_hist,['Distribution of process tag: ',current_tag]);
        x_temp = linspace(min(current_data), max(current_data));
        [y_temp, count_hist, center_hist] = Get_PDF(current_data, x_temp);
        h_bins = bar(h_hist, center_hist, count_hist, 'hist');
        view(h_hist,[90 270]);
        set(h_bins, 'FaceColor', 'none', 'EdgeColor', color_normal, 'LineStyle', '-', 'LineWidth', 1)
        h_pdf = plot(h_hist, x_temp, y_temp, 'Color', color_normal, 'LineWidth', 1.5);

        % slider
        select_start = 1; select_end = n_data;
        set(h_slide_start, 'Min', 0, 'Max', n_data, 'Value',select_start); 
        set(h_slide_end, 'Min', 0, 'Max', n_data, 'Value', select_end);
        set(h_edit_select_start, 'String', num2str(select_start));
        set(h_edit_select_end, 'String', num2str(select_end));
        
        if ~isempty(start_time)
            datetick(h_trend, 'keeplimits','keepticks');
            datetick(h_meanch, 'keeplimits','keepticks');
        end
       
        in_data = [];
        data_normal  = []; n_normal = [];  
        data_faulty = []; n_faulty = [];
%        data_change = [];

        %handles
        h_data_select = []; h_data_start = []; h_data_end = [];
        h_bins_select = []; h_pdf_select = [];
%        h_ChPt = []; h_ChPt_select = []; 
        h_chpt_start = []; h_chpt_end = [];
%        h_data_normal = []; h_data_faulty = [];

        set(h_slide_start,'Enable','on');
        set(h_slide_end,'Enable','on');
        set(h_pb_zoomin,'Enable','on');
        set(h_pb_zoomout,'Enable','on');
        set(h_pb_meanch,'Enable','on');
        set(h_pb_ok,'Enable','on');
        set(h_pb_select,'Enable','on');
        set(h_edit_select_start,'Enable','on');
        set(h_edit_select_end,'Enable','on');
    end
%%
    function plot_data(data_start, data_end)
        delete(h_data_select,h_bins_select,h_pdf_select);
        set(h_data, 'Color', color_shadow);
        set(h_bins, 'EdgeColor', color_shadow);
        set(h_pdf, 'Color', color_shadow);
        % plot selected data
        if ~isempty(start_time)
            h_data_select = plot(h_trend, start_time([data_start:data_end]), current_data(data_start:data_end), 'Color', color_normal);
        else
            h_data_select = plot(h_trend, [data_start:data_end], current_data(data_start:data_end), 'Color', color_normal);
        end
        % plot histogram of selected data
%        x_temp = linspace(min(current_data(data_start:data_end)), max(current_data(data_start:data_end)));
         x_temp = linspace(min(current_data), max(current_data));
         [y_temp, count_hist, center_hist] = Get_PDF(current_data(data_start:data_end), x_temp);
        h_bins_select = bar(h_hist, center_hist, count_hist, 'hist');
        view(h_hist,[90 270]);
        set(h_bins_select, 'FaceColor', 'none', 'EdgeColor', color_normal, 'LineStyle', '-', 'LineWidth', 1)
        h_pdf_select = plot(h_hist, x_temp, y_temp, 'Color', color_normal, 'LineWidth', 1.5);
    end
%%
    function plot_meanch(data_start, data_end)
        delete(h_ChPt_select);
        set(h_ChPt, 'Color', color_shadow);
        % plot mean-change for selected data
        if ~isempty(start_time)
            h_ChPt_select = plot(h_meanch, start_time([data_start:data_end]), data_change(data_start:data_end), 'Color', color_normal);
        else
            h_ChPt_select = plot(h_meanch, [data_start:data_end], data_change(data_start:data_end), 'Color', color_normal);
        end
    end
%%
    function callback_pb_meanch(hObject, evendata)
        h_wait = dialog('pos', CenterFigure(300, 100));
        uicontrol('Parent', h_wait, 'Style', 'text', ...
            'Position', [45 40 200 20], ...
            'FontSize', 10, ...
            'String' , 'Analyzing data. Please wait ...');
        pause(0.1)
    
        alpha = 0.01;
        x = current_data(select_start:select_end);
        data_len = length(current_data(select_start:select_end));
        V = zeros(1,data_len);
        for t=1:data_len
            for j=1:data_len
                V(t) = V(t)+(sign(x(t) - x(j)));
            end
        end
        U = cumsum(V);
        [MaxU,MaxT] = max(abs(U));
        MaxUU = max(abs(U(1:data_len-1).^2));
        P = 2*exp(-6*MaxUU/(data_len^2+data_len^3));
        if P < alpha
            T_ChPt = MaxT;
        else
            T_ChPt = data_len;
        end
        data_change = U';
        delete(h_wait);
        delete(h_ChPt, h_ChPt_select);
        if select_start > 1
            data_change = [NaN*ones(select_start-1,1);data_change];
        end
        if select_end < n_data
            data_change = [data_change;NaN*ones(n_data-select_end,1)];
        end
        if isempty(start_time)
            h_ChPt = plot(h_meanch, [1:n_data], data_change, 'Color', color_normal);
            set(h_meanch, 'XLim',[1 n_data], 'XTickMode', 'auto', 'YTickMode', 'auto');
        else
            h_ChPt = plot(h_meanch, start_time([1:n_data]), data_change, 'Color', color_normal);
            set(h_meanch, 'XLim', start_time([1,n_data]), 'XTickMode', 'auto', 'YTickMode', 'auto');
        end
        ylim_U = get(h_meanch, 'YLim');
        h_ChPt_select = [];
        if select_start > 1
            delete(h_chpt_start);
            if isempty(start_time)
                h_chpt_start = plot(h_meanch, [select_start select_start], ylim_U, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
            else
                h_chpt_start = plot(h_meanch, [start_time(select_start) start_time(select_start)], ylim_U, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
            end
        end
        if select_end < n_data
            delete(h_chpt_end);
            if isempty(start_time)
                h_chpt_end = plot(h_meanch, [select_end select_end], ylim_U, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
            else
                h_chpt_end = plot(h_meanch, [start_time(select_end) start_time(select_end)], ylim_U, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
            end
        end
        if ~isempty(start_time)
            datetick(h_meanch, 'keeplimits', 'keepticks');
        end
    end
%% 
    function callback_slide_start(hObject, eventdata, handles)
        if get(hObject, 'Value') <= 1
            select_start = 1;
        else
            if get(hObject, 'Value') <= select_end
               select_start = round(get(hObject, 'Value'));
            else
                select_start = select_end-20;
            end
        end
        set(h_slide_start, 'Value', select_start);
        set(h_edit_select_start, 'String', num2str(select_start));
        % plot the selection line
        delete(h_data_start);
        if isempty(start_time)
            h_data_start = plot(h_trend, [select_start select_start], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
        else
            h_data_start = plot(h_trend, [start_time(select_start) start_time(select_start)], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
        end
        plot_data(select_start, select_end);
        delete(h_chpt_start);
%        if ~isempty(h_ChPt)
            if isempty(start_time)
                h_chpt_start = plot(h_meanch, [select_start select_start], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
            else
                h_chpt_start = plot(h_meanch, [start_time(select_start) start_time(select_start)], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
            end
%            plot_meanch(select_start, select_end);
%        else
%            h_chpt_start = [];
%        end
    end
%%
    function callback_slide_end(hObject, eventdata, handles)
        if get(hObject, 'Value') >= n_data
            select_end = n_data;
        else
            if get(hObject, 'Value') >= select_start
                select_end = round(get(hObject, 'Value'));
            else
                select_end = select_start+20;
            end
        end
        set(h_slide_end, 'Value', select_end);
        set(h_edit_select_end, 'String', num2str(select_end));
        % plot the selection line
        delete(h_data_end);
        if isempty(start_time)
            h_data_end = plot(h_trend, [select_end select_end], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
        else
            h_data_end = plot(h_trend, [start_time(select_end) start_time(select_end)], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
        end
        plot_data(select_start, select_end);
        delete(h_chpt_end);
%        if ~isempty(h_ChPt)
            if isempty(start_time)
                h_chpt_end = plot(h_meanch, [select_end select_end], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
            else
                h_chpt_end = plot(h_meanch, [start_time(select_end) start_time(select_end)], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
            end
%            plot_meanch(select_start, select_end);
%        else
%            h_chpt_end = [];
%        end
    end
%% 
    function callback_pb_zoomin(hObject, evendata)
        set(h_slide_start, 'Min', select_start, 'Max', select_end, 'Value', select_start)
        set(h_slide_end, 'Min', select_start, 'Max', select_end, 'Value', select_end)
        if ~isempty(start_time)
            set(h_trend,'XLim', start_time([select_start, select_end]), 'XTickMode', 'auto', 'YTickMode', 'auto');
        else
            set(h_trend,'XLim', [select_start, select_end], 'XTickMode', 'auto', 'YTickMode', 'auto');
        end
        if ~isempty(start_time)
            datetick(h_trend, 'keeplimits','keepticks');
        end
%        if ~isempty(h_ChPt) 
%            if ~isempty(start_time)
%                set(h_meanch, 'XLim', start_time([select_start,select_end]), 'XTickMode', 'auto', 'YTickMode', 'auto');
%            else
%                set(h_meanch, 'XLim', [select_start,select_end], 'XTickMode', 'auto', 'YTickMode', 'auto');
%            end
%        end
    end
%%
    function callback_pb_zoomout(hObject, evendata)
       % select_start = 1; select_end = n_data;
        set(h_slide_start, 'Min', 1, 'Max', n_data, 'Value', select_start)
        set(h_slide_end, 'Min', 1, 'Max', n_data, 'Value', select_end);
        if ~isempty(start_time)
            set(h_trend,'XLim', start_time([1, n_data]), 'XTickMode', 'auto', 'YTickMode', 'auto');
        else
            set(h_trend,'XLim', [1, n_data], 'XTickMode', 'auto', 'YTickMode', 'auto');
        end
        if ~isempty(start_time)
            datetick(h_trend, 'keeplimits','keepticks');
        end
%        if ~isempty(h_ChPt) 
%            if ~isempty(start_time)
%                set(h_meanch, 'XLim', start_time([1, n_data]), 'XTickMode', 'auto', 'YTickMode', 'auto');
%            else
%                set(h_meanch, 'XLim', [1, n_data], 'XTickMode', 'auto', 'YTickMode', 'auto');
%            end
%        end
    end
%%
    function callback_pb_select(hObject, eventdata)
        switch get(get(h_bg_data, 'SelectedObject'), 'String')
            case 'Normal'
                data_normal = [data_normal;current_data(select_start:select_end)];
                if ~isempty(start_time)
                    plot(h_meanch, start_time(select_start:select_end), current_data(select_start:select_end), 'Color',color_normal);
                    plot(h_meanch, [start_time(select_start) start_time(select_start)], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
                    plot(h_meanch, [start_time(select_end) start_time(select_end)], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
                else
                    plot(h_meanch, select_start:select_end, current_data(select_start:select_end), 'Color',color_normal);
                    plot(h_meanch, [select_start select_start], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
                    plot(h_meanch, [select_end select_end], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
                end
            case 'Abnormal'
                data_faulty = [data_faulty;current_data(select_start:select_end)];
                if ~isempty(start_time)
                    plot(h_meanch, start_time(select_start:select_end), current_data(select_start:select_end), 'Color',color_faulty);
                    plot(h_meanch, [start_time(select_start) start_time(select_start)], ylim_data, 'Color', color_faulty,'LineWidth', 1.5, 'LineStyle', ':');
                    plot(h_meanch, [start_time(select_end) start_time(select_end)], ylim_data, 'Color', color_faulty,'LineWidth', 1.5, 'LineStyle', ':');
                else
                    plot(h_meanch, select_start:select_end, current_data(select_start:select_end), 'Color',color_faulty);
                    plot(h_meanch, [select_start select_start], ylim_data, 'Color', color_faulty,'LineWidth', 1.5, 'LineStyle', ':');
                    plot(h_meanch, [select_end select_end], ylim_data, 'Color', color_faulty,'LineWidth', 1.5, 'LineStyle', ':');
                end
        end
        set(h_pb_clear, 'Enable', 'on');
    end
%%
    function callback_pb_clear(hObject, eventdata)
        data_normal = []; data_faulty = [];
        h_chpt_start = []; h_chpt_end = [];
        delete(h_meanch);
        h_meanch = axes('Units', 'normalized', ...
            'NextPlot', 'add', 'Box', 'on', ...
            'XTick', [], 'YTick', [], ...
            'Position', pos_meanch./size_main);
        if ~isempty(start_time)
            h_data_all = plot(h_meanch, start_time([1:n_data]), current_data, 'Color', color_shadow);
            set(h_meanch,'XLim',start_time([1,n_data]), 'XTickMode', 'auto', 'YTickMode', 'auto');
        else
            h_data_all = plot(h_meanch, [1:n_data], current_data, 'Color', color_shadow);
            set(h_meanch, 'XLim', [1 n_data], 'XTickMode', 'auto', 'YTickMode', 'auto');
        end
        if ~isempty(start_time)
            datetick(h_meanch, 'keeplimits','keepticks');
        end
    end
%%
    function callback_edit_select_start(hObject, eventdata)
        txt_double = str2double(get(hObject, 'string')); 
        if isnan(txt_double) || txt_double ~= round(txt_double) || txt_double < 1 || txt_double > n_data
            errordlg(['Selection must lie between 1 and' num2str(n_data)], 'Invalid selection', 'modal')
            set(hObject, 'String', num2str(select_start));
            return
        end
        if txt_double > select_end
            errordlg(['Start position must be smaller than ' num2str(select_end)], 'Invalid selection', 'modal')
            set(hObject, 'String', num2str(select_end-20));
            return
        end
        select_start = txt_double;
        set(h_slide_start, 'Value', select_start);
        % plot the selection line
        delete(h_data_start);
        if isempty(start_time)
            h_data_start = plot(h_trend, [select_start select_start], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
        else
            h_data_start = plot(h_trend, [start_time(select_start) start_time(select_start)], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
        end
        plot_data(select_start, select_end);
        delete(h_chpt_start);
%        if ~isempty(h_ChPt)
            if isempty(start_time)
                h_chpt_start = plot(h_meanch, [select_start select_start], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
            else
                h_chpt_start = plot(h_meanch, [start_time(select_start) start_time(select_start)], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
            end
%            plot_meanch(select_start, select_end);
%        else
%            h_chpt_start = [];
%        end
    end
%%
    function callback_edit_select_end(hObject, eventdata)
        txt_double = str2double(get(hObject, 'string')); 
        if isnan(txt_double) || txt_double ~= round(txt_double) || txt_double < 1 || txt_double > n_data
            errordlg(['Selection must lie between 1 and' num2str(n_data)], 'Invalid selection', 'modal')
            set(hObject, 'String', num2str(select_end));
            return
        end
        if txt_double < select_start
            errordlg(['End position must be larger than ' num2str(select_start)], 'Invalid selection', 'modal')
            set(hObject, 'String', num2str(select_start+20));
            return
        end
        select_end = txt_double;
        set(h_slide_end, 'Value', select_end);
        % plot the selection line
        delete(h_data_end);
        if isempty(start_time)
            h_data_end = plot(h_trend, [select_end select_end], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
        else
            h_data_end = plot(h_trend, [start_time(select_end) start_time(select_end)], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
        end
        plot_data(select_start, select_end);
        delete(h_chpt_end);
%        if ~isempty(h_ChPt)
            if isempty(start_time)
                h_chpt_end = plot(h_meanch, [select_end select_end], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
            else
                h_chpt_end = plot(h_meanch, [start_time(select_end) start_time(select_end)], ylim_data, 'Color', color_normal,'LineWidth', 1.5, 'LineStyle', ':');
            end
%            plot_meanch(select_start, select_end);
%        else
%            h_chpt_start = [];
%        end
    end
%%
    function callback_pb_ok(hObject, evendata)
        in_data = [data_normal;data_faulty]; 
        n_normal = length(data_normal);
        if isempty(data_normal)
            errordlg('No process data selected', 'Invalid selection', 'modal')
            return
        end
        delete(h_main);
        AlarmConfig(in_data,n_normal); 
    end
end

