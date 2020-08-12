function [FAR,MAR,EDD]=Eval_rank(pdf_xnm,pdf_xnom, x_trip, N, r)
% pointwise False ALarm Rate (FAR), Missed Alarm Rate (MAR), Expected Detection Delay (EDD)
%
[pdf_ynm,cdf_ynm] = Get_rankPDF(pdf_xnm,x_trip,N,r);
[pdf_ynom,cdf_ynom] = Get_rankPDF(pdf_xnom,x_trip,N,r);

FAR = 1-cdf_ynm; MAR = cdf_ynom;

cdf_xnm = cumsum(pdf_xnm)/sum(pdf_xnm);
cdf_xnom = cumsum(pdf_xnom)/sum(pdf_xnom);
p1 = 1 - cdf_xnm; q1 = cdf_xnom; 
n = max(size(x_trip));
EDD = zeros(n,1);
for i=1:n
    EDD(i) = EDD_rank(p1(i),q1(i),N,r);
end
