function [P_xtrip,count_hist,center_hist] = Get_PDF(Process_data, x_trip)
% pointwise Probability Density Function (PDF) at x_trip 
% x_temp = linspace(min(current_data), max(current_data));
% PDF = ksdensity(Process_data, x_temp);
%
P_xtrip = ksdensity(Process_data, x_trip);
% integral of PDF from -\inf to x_trip
% cumP_xtrip = ksdensity(Process_data, x_trip, 'function', 'cdf');

% data distribution
n_data = length(Process_data);
% estimate the bins to compute data distribution
data_range = range(Process_data);
data_IQR = iqr(Process_data);
binw = 2*data_IQR*(n_data)^(-1/3);  n_bins = round(data_range/binw);
if isinf(n_bins) || isnan(n_bins)
    n_bins = round(sqrt(n_data-1)-1);
end
%
[fbins, xbins] = ecdf(Process_data, 'Function', 'cdf');
[count_hist, center_hist] = ecdfhist(fbins, xbins, n_bins);
%bar(center_hist, count_hist, 'hist');
