function pos = CenterFigure(width, height)
% This function calculates the position of the figure such that it is
% located in the center and middle of the monitor. In case of dual monitors,
% the function returns the center of the second monitor. 
%   width = width of the figure
%   height = height of the figure
%   pos = position of the figure

monitor = get(0, 'MonitorPosition'); % Get monitor information

% height of second monitor = monitor(2, 4) - monitor(2,2) + 1
% width of second monitor  = monitor(2, 3) - monitor(2,1) + 1
% x for the bottom left corner of monitor 2 = monitor(2, 1) - 1
% y for the bottom left corner of monitor 2 = monitor(1, 4) - monitor(2,4)

if size(monitor, 1) == 1
    % One monitor
    left_margin = (monitor(1, 3) - width) / 2;
    buttom_margin = (monitor(1, 4) - height) / 2;
    pos = [left_margin, buttom_margin, width, height];
else
    % Two monitors
    left_margin = monitor(2, 1) - 1 + ...
        (monitor(2, 3) +1 - monitor(2,1) - width)/2;
    buttom_margin = monitor(1, 4) - monitor(2,4) + ...
        (monitor(2, 4) + 1 - monitor(2,2) - height)/2;
    pos = [left_margin, buttom_margin-35, width, height];
end
