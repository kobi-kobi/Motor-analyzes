clear clear all clc
%%
DG=load("DGIMA010HZ_WITH_DOWN.mat").DGIMA;
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
clear C DGIMA n netDgima
%%
Ts=1/2000   % aduc or time/length(longDgima)
numofsamples=Ts*length(longDgima)
T=0:Ts :numofsamples
Fpwm=5

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
part0 = UD(1:G_location(1)+1)
timerpart0=T(1:G_location(1)+1)
part1 = UD(G_location(1)+1:G_location(2)-1)
timerpart1=T(G_location(1)+1:G_location(2)-1)
part2 = UD(G_location(2)+1:G_location(3)-1)
timerpart2=T(G_location(2)+1:G_location(3)-1)
%%
plot(timerpart0,part0)
hold on
plot(timerpart1,part1)
hold on
plot(timerpart2,part2)
hold on

y1 = -1*sin(2*pi*Fpwm*T)*max(part1)-180;
clear min max
[bla,Y1_1]=min(y1)
[bla,Y1_2]=max(y1)
y1_min=min(Y1_1,Y1_2)

clear min max
[bla,Y2_1]=min(part1)
[bla,Y2_2]=max(part1)
sampled_min=min(Y2_1,Y2_2)

phase_change=abs(sampled_min-y1_min)*Ts*360*Fpwm
%%
plot(timerpart1,y1(1:length(timerpart1)));

%%
clear device;


%%