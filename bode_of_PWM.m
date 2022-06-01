clear clear all clc
device = serialport("COM1",115200);
%%
flush(device)
clear DGIMA
i=tic 
DGIMA = read(device,115200,"string");
time=toc(i)
%%
C = strsplit(DGIMA);
%%
netDgima = regexprep(C,'[^0-9,A-G]','');
netDgima = netDgima(~cellfun(@isempty, netDgima));
G_locations = find(netDgima == 'G');
G_locations = G_locations(1:2:end);

%%
longDgima = netDgima;
longDgima = longDgima(~cellfun(@isempty, longDgima));

n=1;
while n < length(longDgima);
    if strlength(longDgima(n))~=3;
       longDgima(n)="";
       %%longDgima = longDgima(~cellfun(@isempty, longDgima));
    end
    n=n+1;
end
%%
Ts=1/2000   % aduc or time/length(longDgima)
numofsamples=Ts*length(longDgima)
T=0:Ts :numofsamples
%%
%Fs = 25000;                           % samples per second
%%
Fpwm = 5;                           % hertz of pwm!!!!!!!!!!
samplbits = 12;
resolution = 2^samplbits;
for i = [2:(size(G_locations,2)-1)]
   current_part = netDgima(G_locations(i)+1:G_locations(i+1)-1);
   
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
end
hold off
%%
clear device
 
