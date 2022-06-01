clear clear all clc
device = serialport("COM1",115200);
%%
DGIMA=load("DGIMA100HZ.mat").DGIMA
%%
C  = strsplit(DGIMA);
netDgima = regexprep(C,'[^0-9,A-G]','');
netDgima = netDgima(~cellfun(@isempty, netDgima));
G_locations = find(netDgima == 'G');
G_locations = G_locations(1:2:end);
%%
Fpwm = 5;
Ts = 1/2000;
%%
1/((G_locations(2)-G_locations(1))*Ts)  %% freq of signal
%%
%a = netDgima(G_locations(1)+1:G_locations(2)-1)
a = netDgima
neta = regexprep(a,'[^0-9,A-F]','');
D=hex2dec(neta)
D=(D./4096);
D=D.*360;
R=deg2rad(D);
UR = unwrap(R);
UD=rad2deg(UR)
clear min max
[max,index]=max(D)
plot(UD)
%%
index*Ts               %time when we got max in signal refer to the "first" G
%%
1/(Fpwm*4)
%%



%%
t_dgima = (1:1:length(a))*Ts
D=(D./4096);
D=D.*360;
R=deg2rad(D);
UR = unwrap(R);
UD=rad2deg(UR)
plot(t_dgima(1:length(UD)),UD)
hold on 


y = sin(2*pi*Fpwm*t_dgima)*30;
plot(t_dgima,y);

%%
close all
i=1
   current_part = netDgima(G_locations(i)+1:G_locations(i+1)-1);
   current_part = regexprep(current_part,'[^0-9,A-F]','');

    D=hex2dec(current_part);
    D=(D./4096);
    D=D.*360;
    R=deg2rad(D);
    UR = unwrap(R);
    UD=rad2deg(UR)
    %plot(T(1:length(UD)),UD)
    %hold on 
    %plot(T(1:length(D)),D)
    %legend("unrwap","real")



   t_dgima = (G_locations(i)+1:1:G_locations(i+1)-1)*Ts;
   plot(t_dgima,UD);             % sample of angle =?= Freq. of PWM 
   hold on
   
   y = sin(2*pi*Fpwm*t_dgima)*max(UD)+180;
   plot(t_dgima,y);
   
   xlabel('sample');
   title('Signal versus Time');
   %
   % zoom xon;
   hold on


