close all
clear
clc
vIndex = 2:16;  % measurement index
r = 25;        % retained state dimension
p = 15;        % length of past observation
f = 15;        % length of future observation

%% Section 2 Training with normal data sets 2 and 3
% This block loads the available training data sets and selects
% the two data sets used to train the algorithm. The measurements included
% in both data sets are selected according to vIndex

load data_test_no2.mat 
load data_test_f2_2.mat
load data_test_f2_3.mat
t1=Dfilter(datano2(vIndex,:));
t2=Dfilter(dataf2_2(vIndex,:));
t3=Dfilter(dataf2_3(vIndex,:));

for i=1:5000
    X1(i,:)=t1(:,i*100)';
    X2(i,:)=t2(:,i*100)';
    X3(i,:)=t3(:,i*100)';
end

%CCA
[Xp,Xf]=hankelpf(X1,p,f);
[Yp1,Yf1]=hankelpf(X2,p,f);
[Yp2,Yf2]=hankelpf(X3,p,f);

%Construct past and future observation matrices of second training data set
%Combined past and future matrices
%Normalization of past and future matrices
pn = size(Xp,2);

fmean = mean(Xf,2);
fstd = std(Xf,0,2);
pmean = mean(Xp,2);
pstd = std(Xp,0,2);

Xpmn = (Xp - pmean(:,ones(1,pn)))./pstd(:,ones(1,pn));
Xfmn = (Xf - fmean(:,ones(1,pn)))./fstd(:,ones(1,pn));
Yp1mn = (Yp1 - pmean(:,ones(1,pn))) ./pstd(:,ones(1,pn));
Yp2mn = (Yp2 - pmean(:,ones(1,pn))) ./pstd(:,ones(1,pn));


%%
%Obtain Cholesky matrices and Hankel matrix
Rp = chol(Xpmn*Xpmn'/(pn-1));            %Past Cholesky matrix
Rf = chol(Xfmn*Xfmn'/(pn-1));            %Future Cholesky matrix
Hfp = Xfmn*Xpmn'/(pn-1);                 %Cross-covariance matrix
H = (Rf'\Hfp)/Rp;                        %Hankel matrix

%%
[U,S,V] = svd(H);                   %SVD
S = diag(S);
m = numel(S);
V1 = V(:,1:r);                      %Reduced V matrix
J = V1'/Rp';                        %Transformation matrix of state variables
L = (eye(m)-V1*V1')/Rp';            %Transformation matrix of residuals
z = J * Xpmn;                       %States of training data
e = L * Xpmn;                       %Residuals of training data   
          
ek1 = L*Yp1mn;      
ek2 = L*Yp2mn;

Tr = ek1'*ek1;
xfc = Tr'*Tr;                 %covariance matrix             
[rr,Tsr] = PCA(xfc,Tr);       %new features
x = ek1';
y = Tsr;
[sol,yhat] = PLS_Regress(x, y);


xt = ek2';
delta_t = [ones(size(xt, 1), 1), xt]*sol;
Tr2 = sum(ek2.*ek2)/pn;
Tsr2 =sum(delta_t.*delta_t,2)/pn;

figure;
subplot(2,1,1)
plot(Tr2,'b') 
legend('Tr2')
subplot(2,1,2)
plot(Tsr2,'r')
legend('Tsr2')


in_data=Tsr2;  %=Tr2
n_normal=2975;
AlarmConfig(in_data,n_normal)  %GUI decides the alarm value,miss rate and false rate
