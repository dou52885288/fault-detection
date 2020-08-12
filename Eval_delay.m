function [FAR,MAR,EDD] = Eval_delay(normal_data, faulty_data, x_trip, delay_on, delay_off, alm_deadband, alm_type)
% compute Expected Detection Delay (EDD) for delay-timers
%
if nargin < 6
    alm_deadband = 0;
end
if nargin < 7
    alm_type = 'HI'; 
end

n = delay_on;
m = delay_off;
switch alm_type
    case 'HI'
        % probability of ALM 
        p1 = 1-ksdensity(normal_data, x_trip, 'function', 'cdf');  
        q2 = 1-ksdensity(faulty_data, x_trip, 'function', 'cdf');
        % probability of NA  
        p2 = ksdensity(normal_data, x_trip-alm_deadband, 'function', 'cdf');
        q1 = ksdensity(faulty_data, x_trip-alm_deadband, 'function', 'cdf');   
    case 'LO'
        % probability of ALM    
        p2 = 1-ksdensity(normal_data, x_trip+alm_deadband, 'function', 'cdf');  
        q1 = 1-ksdensity(faulty_data, x_trip+alm_deadband, 'function', 'cdf');
        % probability of NA 
        p1 = ksdensity(normal_data, x_trip, 'function', 'cdf');
        q2 = ksdensity(faulty_data, x_trip, 'function', 'cdf');   
end

p2_sum = zeros(size(x_trip));
for i=1:m
    p2_sum = p2_sum + p2.^(i-1);
end
p1_sum = zeros(size(x_trip)); 
for i=1:n
    p1_sum = p1_sum + p1.^(i-1);
end
FAR = (p1.^n).*p2_sum./((p1.^n).*p2_sum + (p2.^m).*p1_sum);

q1_sum = zeros(size(x_trip));
for i=1:m
    q1_sum = q1_sum + q1.^(i-1);
end
q2_sum = zeros(size(x_trip));
for i=1:n
    q2_sum = q2_sum + q2.^(i-1);
end
MAR = (q1.^m).*q2_sum./((q1.^m).*q2_sum + (q2.^n).*q1_sum);
           
pq_sum = zeros(size(x_trip));
for j=0:n-1
    for k=0:n-j-1
         pq_sum = pq_sum + (p1.^j) .* (q2.^k);
    end
end
EDD = p2.^(m-1).*(p1.^n .* q1.*q2_sum + p2.*(pq_sum - q2.^n .* p1_sum))./(q2.^n .* (p2.^m .* p1_sum + p1.^n .* p2_sum));
