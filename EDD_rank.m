function [EDD,Pn,Qn] = EDD_rank(p1,q1,N,p,n)
%
p2 = 1-p1;
q2 = 1-q1;

if nargin < 5
    n = N;
end

Pn = zeros(n,1);
Qn = zeros(n,1);

if p==N  % Q(k)=q1*Q(k-1); P(k)=q2*Q(k-1);
    for i=1:n
        Pn(i) = p2^(N-1)*q1^i*q2;
        Qn(i) = p2^(N-1)*q1^(i+1);  
    end
    EDD = p2^(N-1)*q1/q2;
%    alpha = [zeros(1,N-1) q1^N];
%    beta = zeros(1,N);
%    for i=1:N
%        beta(i) = (1-sum(alpha(1:N-i)))/(1-sum(alpha(1:N)));
%    end
%    EDD = beta * [p2^(N-1)*q1;Qn(1:N-1)];
else
    ALPHA = zeros(N,N-p);
    for k=1:N
        for i=0:N-p-1
            if p+i <= k
                ALPHA(k,i+1) = q2*nchoosek(p+i-1,p-1)*q1^p*q2^i;
            else
                temp = 0;
                for j=0:p-1
                    if i+j>=k & k>=j
                        temp = temp + nchoosek(k,j)*q1^j*q2^(k-j)*nchoosek(p+i-k-1,p-1-j)*p2^(p-1-j)*p1^(i+j-k);
                    end
                end
                ALPHA(k,i+1) = q2*p2*temp;
            end
        end
    end

    Yn = zeros(N,1);
    for k=1:N-p
        Yn(k) = 1;
    end
    for k = N-p+1:N-1
        for i=0:N-p
            Yn(k) = Yn(k) + nchoosek(k,i)*p1^i*p2^(k-i);
        end
    end
    for i=p:N-1
        Yn(N) = Yn(N) + nchoosek(N-1,i)*p2^i*p1^(N-1-i);
    end
    Yn(N) = Yn(N) + q1*nchoosek(N-1,p-1)*p2^(p-1)*p1^(N-p);

    Qn(1) = q1*Yn(N) + ALPHA(1,:)*Yn(N-p:-1:1);
    Pn(1) = Yn(N) - Qn(1);

    %% k<=(p+1)
    for k=2:p+1
        Qn(k) = q1*Qn(k-1) + ALPHA(k,:)*Yn(N-p+k-1:-1:k);
        Pn(k) = Qn(k-1) - Qn(k);
    end
    %% N>=k>(p+1)
    for k=p+2:N
        Qn(k) = q1*Qn(k-1) + ALPHA(k,:)*[Qn(k-p-1:-1:1);Yn(N:-1:k)];
        Pn(k) = Qn(k-1) - Qn(k);
    end
    %% k>N
    for k=N+1:n
        Qn(k) = q1*Qn(k-1) + ALPHA(N,:)*Qn(k-p-1:-1:k-N);
        Pn(k) = Qn(k-1) - Qn(k);
    end

    %% computing expected detection delay (EDD) 
%    A = [q1 zeros(1,p-1) ALPHA(N,:);eye(N-1,N-1) zeros(N-1,1)];
%    C = [-1 1 zeros(1,N-2)];
%    EDD = Yn(N) + sum(Qn(1:N-1)) + C*A*inv(eye(N,N)-A)^2*Qn(N:-1:1)
    alpha = [q1 zeros(1,p-1) ALPHA(N,:)];
    beta = zeros(1,N);
    for i=1:N
        beta(i) = (1-sum(alpha(1:N-i)))/(1-sum(alpha(1:N)));
    end
    EDD = beta*[Yn(N);Qn(1:N-1)];
%    EDD = Yn(N) + beta * Qn
end
%stem(1:n,Pn,'x');