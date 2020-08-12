function [FAR,MAR,EDD] = Eval_gd(normal_data, faulty_data, x_temp, delay, delay_type)
% compute performance of generalized delay-timer (2 out of n on delay, 2 out of m off delay)
%
n = delay;
m = n;

pdf_xnm = ksdensity(normal_data, x_temp, 'function', 'pdf');
pdf_xnom = ksdensity(faulty_data, x_temp, 'function', 'pdf');
cdf_xnm = ksdensity(normal_data, x_temp, 'function', 'cdf');
cdf_xnom = ksdensity(faulty_data, x_temp, 'function', 'cdf');

p1 = 1 - cdf_xnm; p2 =  cdf_xnm;
q1 = cdf_xnom; q2 = 1 - cdf_xnom;

pp_sum = zeros(size(x_temp));
for i=0:n-2    pp_sum = pp_sum + p2.^i.*(1-q1.^(n-1)+q1.^(n-2-i));   end
            
switch delay_type
    case 'on'  % generalized delay-timer 2 out of n samples on-delay
        FAR = p1.*(1-p2.^(n-1))./(p1.*(1-p2.^(n-1)) + p2.*(2-p2.^(n-1)));
        MAR = q1.*(1-q2.^(n-1))./(q1.*(1-q2.^(n-1)) + q2.*(2-q2.^(n-1)));
        EDD = (p2.*(1-q1.^n+q1)+p1.*q1.*(1-p2.^(n-1)).*(2-q1.^(n-1))+p1.*p2.*q1.*pp_sum)./((p1.*(1-p2.^(n-1)) + p2.*(2-p2.^(n-1))).*q2.*(1-q1.^(n-1)));
    case 'off' % generalized delay-timer 2 out of m samples off-delay
        FAR = p1.*(2-p1.^(m-1))./(p1.*(2-p1.^(m-1)) + p2.*(1-p1.^(m-1)));
        MAR = q1.*(2-q1.^(m-1))./(q1.*(2-q1.^(m-1)) + q2.*(1-q1.^(m-1)));
        EDD = (p2+p1.*q1-p2.*q2).*(1-p1.^(m-1))./(q2.*(p2.*(1-p1.^(m-1))+p1.*(2-p1.^(m-1))));
end
        