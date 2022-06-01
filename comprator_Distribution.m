clear all; close all

a= [100, 90, 80, 70.6, 60, 51, 41, 29.5]
Freq_of_singal = [13.8949 13.0265 18.2371 18.2371 20.8424 23.4477 32.1320 89.4485]
amplitude_of_signal = [116.3397 121.4824 40.1744 27.0159 21.1633 11.0775 5.9172 1.5692 ]

plot(a,Freq_of_singal,"-o")

hold on
plot(a,amplitude_of_signal,"-x")
legend ("Freq of singal","amplitude of signal")

