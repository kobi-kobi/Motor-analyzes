clear clear all clc
%%
A = load('DGIMA005HZ_WITH_DOWN.mat')
DGIMA = A.DGIMA
clear A
%%
C  = strsplit(DGIMA);
netDgima    = regexprep(C,'[^0-9,A-G]','');
netDgima = netDgima(~cellfun(@isempty, netDgima));
longDgima = netDgima;
longDgima = longDgima(~cellfun(@isempty, longDgima));

n=1;
while n < length(longDgima);
    if strlength(longDgima(n))~=3;
       longDgima(n)="";
       longDgima = longDgima(~cellfun(@isempty, longDgima));
    end
    n=n+1;
end

%%
%clear n DGIMA netDgima i C
%%
Ts=1/2000   % aduc or time/length(longDgima)
numofsamples=Ts*length(longDgima)
T=0:Ts :numofsamples
%%
%clear sample_freq Ts numofsamples
%%
D=hex2dec(longDgima);
D=(D./4096);
D=D.*360;
R=deg2rad(D);
UR = unwrap(R);
UD=rad2deg(UR)
plot(T(1:length(UD)),UD)
hold on 
plot(T(1:length(D)),D)
legend("unrwap","real")
%%
clear device;


%%