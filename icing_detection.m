close all
clc
clear

load normal.mat
load normal_t.mat
load failure.mat
g1 = normal;
g2 = [normal;normal_t;failure];


sys = tf(1,[30 1]);
Ts = 7;                   % 采样周期
dsys = c2d(sys, Ts, 'z'); % 转化为差分方程
[num, den] = tfdata(dsys,'v');
t1 = filter(num,den,g1);
t2 = filter(num,den,g2);

vIndex =1:26;  % measurement index
r = 25;        % retained state dimension
p = 15;        % length of past observation
f = 15;        % length of future observation

%% Section 2 Training with normal data sets 2 and 3
% This block loads the available training data sets and selects
% the two data sets used to train the algorithm. The measurements included
% in both data sets are selected according to vIndex
X1 = t1(:,vIndex);
X2 = t2(:,vIndex);

%CCA
[Xp,Xf] = hankelpf(X1,p,f);
[Yp,Yf] = hankelpf(X2,p,f);


%Construct past and future observation matrices of second training data set
%Combined past and future matrices
%Normalization of past and future matrices
pn = size(Xp,2);
pn1 = size(Yp,2);

fmean = mean(Xf,2);
fstd = std(Xf,0,2);
pmean = mean(Xp,2);
pstd = std(Xp,0,2);

Xpmn = (Xp - pmean(:,ones(1,pn)))./pstd(:,ones(1,pn));
Xfmn = (Xf - fmean(:,ones(1,pn)))./fstd(:,ones(1,pn));
Ypmn = (Yp - pmean(:,ones(1,pn1))) ./pstd(:,ones(1,pn1));

%%
%Obtain Cholesky matrices and Hankel matrix
Rp = chol(Xpmn*Xpmn'/(pn-1));            %Past Cholesky matrix
Rf = chol(Xfmn*Xfmn'/(pn-1));              %Future Cholesky matrix
Hfp = Xfmn*Xpmn'/(pn-1);                     %Cross-covariance matrix
H = (Rf'\Hfp)/Rp;                    %Hankel matrix

%%
[U,S,V] = svd(H);%SVD
S = diag(S);
m = numel(S);
V1 = V(:,1:r); %Reduced V matrix
J = V1'/Rp';                        %Transformation matrix of state variables
L = (eye(m)-V1*V1')/Rp';            %Transformation matrix of residuals
z = J * Xpmn;                         %States of training data
 %Residuals of training data   
zk1 = J * Ypmn;

zz = zk1 (:,123633:129632);
T = zz' * zz /6000;
xfc = T'*T;                 %协方差              
[rr,Tsr] = PCA(xfc,T);
x = zz';
y = Tsr;
[sol,yhat] = PLS_Regress(x, y);

xt = zk1';
delta_t = [ones(size(xt, 1), 1), xt]*sol;
Tsr2 = sum(delta_t.*delta_t,2);
Ts2 = sum(zk1.*zk1);

in_data=Ts2;
n_normal=126633;
AlarmConfig(in_data,n_normal)
