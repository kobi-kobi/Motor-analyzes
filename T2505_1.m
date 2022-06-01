clear clear all clc
%%
Fpwm = 2.5
DG=load("DGIMA005HZ_WITH_DOWN.mat").DGIMA;
DGIMA=DG;
clear DG;
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
G_location = find(longDgima == 'G');
G_location = G_location(1:2:end)
G_location = G_location(1:2:end)
clear C DGIMA n netDgima
%%
Ts=1/2000   % aduc or time/length(longDgima)
numofsamples=Ts*length(longDgima)
T=0:Ts :numofsamples
Fpwm = Fpwm

clear sample_freq numofsamples
%%
longDgima_withoutG    = regexprep(longDgima,'[^0-9,A-F]','');
D=hex2dec(longDgima_withoutG);
D=(D./4096);
D=D.*360;
R=deg2rad(D);
UR = unwrap(R);
UD=rad2deg(UR)
D=rad2deg(R)
plot(T(1:length(UD)),UD)
%%
phase_change_list=[];

for i = 1 : length(G_location)-1
    loc1=G_location(i);
    loc2=G_location(i+1);
    part = UD(loc1+1:loc2-1);
    timerpart=T(loc1+1:loc2-1);

    plot(timerpart,part);
    hold on;
% until here is cutted
% ideal funct
y1 = -1*sin(2*pi*Fpwm*T)*max(part)-180;
clear min max;
[bla,Y1_1]=min(y1);
[bla,Y1_2]=max(y1);
y1_min=min(Y1_1,Y1_2);
clear min max;
%sampled function 
[bla,Y2_1]=min(part);
[bla,Y2_2]=max(part);
sampled_min=min(Y2_1,Y2_2);

phase_change=abs(sampled_min-y1_min)*Ts*360*Fpwm;
phase_change_list(i)=phase_change;
end
%%
median(phase_change_list)
mean(phase_change_list)

%%
clear device;


%%