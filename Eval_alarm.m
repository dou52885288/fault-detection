function [FAR_HAL,MAR_HAL,EDD_HAL,FAR_LAL,MAR_LAL,EDD_LAL]=Eval_alarm(normal_data,faulty_data, x_trip, delay_on, delay_off, alm_deadband)
% pointwise False ALarm Rate (FAR), Missed Alarm Rate (MAR), Expected Detection Delay (EDD)
% x_temp = linspace(min(current_data), max(current_data),1000);
% [FAR,MAR,EDD] = Eval_alarm(normal_data, faulty_data, x_temp, delay_on, delay_off, alm_deadband);
%
if nargin<3
    x_trip = linspace(min([normal_data;faulty_data]),max([normal_data;faulty_data]),1000);
end
if nargin<4
    delay_on = 1; 
end
if nargin<5
    delay_off=1; 
end
if nargin<6
    alm_deadband = [0 0];
end
if length(alm_deadband) == 1
    alm_deadband = [alm_deadband alm_deadband];
end
n = delay_on;
m = delay_off;

% HAL
p1_HAL = 1 - ksdensity(normal_data, x_trip, 'function', 'cdf');
p2_HAL = ksdensity(normal_data, x_trip-alm_deadband(1), 'function', 'cdf');
q1_HAL = ksdensity(faulty_data, x_trip-alm_deadband(1), 'function', 'cdf');
q2_HAL = 1 - ksdensity(faulty_data, x_trip, 'function', 'cdf');
            
p2_sum = zeros(size(x_trip));
for i=1:m
    p2_sum = p2_sum + p2_HAL.^(i-1);
end
p1_sum = zeros(size(x_trip)); 
for i=1:n
    p1_sum = p1_sum + p1_HAL.^(i-1);
end
FAR_HAL = (p1_HAL.^n).*p2_sum./((p1_HAL.^n).*p2_sum + (p2_HAL.^m).*p1_sum);

q1_sum = zeros(size(x_trip));
for i=1:m
    q1_sum = q1_sum + q1_HAL.^(i-1);
end
q2_sum = zeros(size(x_trip));
for i=1:n
    q2_sum = q2_sum + q2_HAL.^(i-1);
end
MAR_HAL = (q1_HAL.^m).*q2_sum./((q1_HAL.^m).*q2_sum + (q2_HAL.^n).*q1_sum);
            
pq_sum = zeros(size(x_trip));
for j=0:n-1
    for k=0:n-j-1
         pq_sum = pq_sum + (p1_HAL.^j) .* (q2_HAL.^k);
    end
end
EDD_HAL = p2_HAL.^(m-1).*(p1_HAL.^n .* q1_HAL.*q2_sum + p2_HAL.*(pq_sum - q2_HAL.^n .* p1_sum))./(q2_HAL.^n .* (p2_HAL.^m .* p1_sum + p1_HAL.^n .* p2_sum));
%            EDD_HAL = (1-q2_HAL.^n .* - q1_HAL .* q2_HAL.^n)./(q1_HAL .* q2_HAL.^n);

% LAL
p1_LAL = ksdensity(normal_data, x_trip, 'function', 'cdf');
p2_LAL = 1 - ksdensity(normal_data, x_trip+alm_deadband(2), 'function', 'cdf');
q1_LAL = 1 - ksdensity(faulty_data, x_trip+alm_deadband(2), 'function', 'cdf');
q2_LAL = ksdensity(faulty_data, x_trip, 'function', 'cdf');
 
p2_sum = zeros(size(x_trip));
for i=1:m
    p2_sum = p2_sum + p2_LAL.^(i-1);
end
p1_sum = zeros(size(x_trip));
for i=1:n
    p1_sum = p1_sum + p1_LAL.^(i-1);
end
FAR_LAL = (p1_LAL.^n).*p2_sum./((p1_LAL.^n).*p2_sum + (p2_LAL.^m).*p1_sum);
                
q1_sum = zeros(size(x_trip));
for i=1:m
    q1_sum = q1_sum + q1_LAL.^(i-1);
end
q2_sum = zeros(size(x_trip));
for i=1:n
    q2_sum = q2_sum + q2_LAL.^(i-1);
end
MAR_LAL = (q1_LAL.^m).*q2_sum./((q1_LAL.^m).*q2_sum + (q2_LAL.^n).*q1_sum);
            
pq_sum = zeros(size(x_trip));
for j=0:n-1
    for k=0:n-j-1
        pq_sum = pq_sum + (p1_LAL.^j) .* (q2_LAL.^k);
    end
end
EDD_LAL = p2_LAL.^(m-1).*(p1_LAL.^n .* q1_LAL.*q2_sum + p2_LAL.*(pq_sum - q2_LAL.^n .* p1_sum))./(q2_LAL.^n .* (p2_LAL.^m .* p1_sum + p1_LAL.^n .* p2_sum));
