function [FAR,MAR,EDD]=Eval_rankfilter(normal_data, faulty_data, filter_par, x_trip, alm_type)
% pointwise False ALarm Rate (FAR), Missed Alarm Rate (MAR), Expected Detection Delay (EDD)
%
if nargin < 5
    alm_type = 'HI'; 
end

N = filter_par(1); r = filter_par(2);

switch alm_type
    case 'HI'
        % probability of ALM 
        p1 = 1-ksdensity(normal_data, x_trip, 'function', 'cdf');  
        q2 = 1-ksdensity(faulty_data, x_trip, 'function', 'cdf');
        % probability of NA  
        p2 = ksdensity(normal_data, x_trip, 'function', 'cdf');
        q1 = ksdensity(faulty_data, x_trip, 'function', 'cdf');   
    case 'LO'
        % probability of ALM    
        p2 = 1-ksdensity(normal_data, x_trip, 'function', 'cdf');  
        q1 = 1-ksdensity(faulty_data, x_trip, 'function', 'cdf');
        % probability of NA 
        p1 = ksdensity(normal_data, x_trip, 'function', 'cdf');
        q2 = ksdensity(faulty_data, x_trip, 'function', 'cdf');   
end

FAR = zeros(size(x_trip));
for i=(N-r+1):N
    FAR = FAR + nchoosek(N,i)*p1.^i.*p2.^(N-i);
end
MAR = zeros(size(x_trip));
for i=r:N
    MAR = MAR + nchoosek(N,i)*q1.^i.*q2.^(N-i);
end

EDD = zeros(size(x_trip));
for i=1:length(x_trip)
    EDD(i) = EDD_rank(p1(i),q1(i),N,r);
end
