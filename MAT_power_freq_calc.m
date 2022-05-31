close all; clear all ; clc
%%pause(2)
%%
%device = serialport("COM1",115200);
%%
%flush (device)
%DGIMA       = read(device,11520,"string");
%%
DGIMA = load ("40d.mat").DGIMA;
%%
C           = strsplit(DGIMA);
netDgima    = regexprep(C,'[^0-9,A-G]','');
netDgima = netDgima(~cellfun(@isempty, netDgima));

%%
longDgima = netDgima;
longDgima = longDgima(~cellfun(@isempty, longDgima));
n=1;
while n < length(longDgima);
    if strlength(longDgima(n))~=3 && longDgima(n)~="G" ;
       longDgima(n)="";
    end
    n=n+1;
end
longDgima = longDgima(~cellfun(@isempty, longDgima));
%clear C DGIMA n netDgima
%%
Ts = 1/2000   % ADUC841 or time/length(longDgima)
numofsamples = Ts*length(longDgima)
T = 0:Ts:numofsamples

%clear sample_freq numofsamples
%%
longDgima_withoutG    = regexprep(longDgima,'[^0-9,A-F]','');
D=hex2dec(longDgima_withoutG);
D=(D./4096);
D=D.*360;
R=deg2rad(D);
D=rad2deg(R)

UR = unwrap(R);
UD=rad2deg(UR)

%%
UD_WITHOUT_NOISE = smoothdata(UD)
time_of_wave=T(1:length(UD));
max_locations=islocalmax(UD_WITHOUT_NOISE);
min_locations=islocalmin(UD_WITHOUT_NOISE);

sum_of_max=sum(max_locations);
Freq_of_singal=sum_of_max/time_of_wave(end)

%%
max_values=UD(max_locations);
min_values=UD(min_locations);
max_avg=mean(max_values);
min_avg=min(min_values);
amplitude_of_signal=max_avg-min_avg

%clear device
%% plots    
close all
%plot real graph
plot(T(1:length(UD)),UD)
title("unwrap degree")
xlabel("time [sec]")
ylabel("unwrap degree")
hold on
%plot smoothed graph
plot(T(1:length(UD)),max_locations*mean(UD),"x");
ylim([min(UD) max(UD)]);
hold on
%plot locations of min in graph and max
plot(T(1:length(UD)),max_locations*400,'red')
hold on
plot(T(1:length(UD)),min_locations*400,'green')
%% fft maker
%Y=fft(UD);
%Fs=2000;
%f = (0:length(UD)-1)*Fs/length(UD)
%figure 
%plot(f,abs(Y))
