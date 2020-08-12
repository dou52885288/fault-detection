function [ Yp,Yf ] = hankelpf( y,p,f )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% HANKELPF  Constructing the past and future Hankel matrices
 
% Inputs:
%   y:  N x ny observed data with N observation points and ny variables.
%   p:  the number of past observations
%   f:  the number of future observations.
% Outputs:
%   Yp: the past Hankel matrix with dimension p*ny x M, M = N - p - f;
%   Yf: the future Hankel matrix with dimension f*ny x M.

if nargin < 3
    f = p;
end

if nargout < 2
    f = 0;
end

[N,ny] = size(y);                     % number of observations
Ip = flipud(hankel(1:p,p:N-f));       % indices of past observations
Yp = reshape(y(Ip,:)',ny*p,[]);       % Hankel observation matrix

if nargout>1
    If = hankel(p+1:p+f,p+f:N);       % indices of future observations
    Yf = reshape(y(If,:)',ny*f,[]);   % Hankel observation matrix
end


end

