function [i,NEW]=PCA(xfc,delta_t)           
M=xfc;                  %协方差
[V,D]=eig(M);             %求出协方差矩阵的特征向量、特征根
d=diag(D);                %取出特征根矩阵列向量（提取出每一主成分的贡献率）
eig1=sort(d,'descend');     %将贡献率按从大到小元素排列
v=fliplr(V);                %依照D重新排列特征向量
S=0;
i=0;
while S/sum(eig1)<0.85
    i=i+1;
    S=S+eig1(i);
end  
alpha=v(:,1:i);
NEW=delta_t*v(:,1:i); 
end