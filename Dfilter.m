function RollAf=lisanlvbo(data)
 m = size(data,1);
 da = data';
 Fs = 100;%采样频率
 Wp = 5/(Fs/2); %通带截止频率,这个自定大致定义
 Ws = 10/(Fs/2);%阻带截止频率,这个自定大致定义
 Rp = 2; %通带内的衰减不超过Rp,这个自定大致定义
 Rs = 40;%阻带内的衰减不小于Rs，这个自定大致定义
 [n,Wn] = buttord(Wp,Ws,Rp,Rs);%巴特沃斯数字滤波器最小阶数选择函数
 [b,a] = butter(n,Wn);%巴特沃斯数字滤波器
 [h,w] = freqz(b,a,512,Fs); %计算滤波器的频率响应
%plot(w,abs(h))%,'LineWidth',1绘制滤波器的幅频响应图
%**************************************************************************

%对输入的信号进行滤波
for i=1:m
  SA = da(:,i);
  RollAf(:,i) = filtfilt(b,a,SA);%filtfilt这个函数是0相位滤波，没有偏移。filter有偏移。
end
RollAf=RollAf';
%%  滤波结果绘图

%figure
%plot(Time,SA,Time,RollAf,'r--');

