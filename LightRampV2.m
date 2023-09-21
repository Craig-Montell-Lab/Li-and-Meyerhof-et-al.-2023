%% Light ramping 
prompt = {
    'Lights on time',...
    'Lights off time',...
    'Red %',...
    'Green %',...
    'Blue %',...
    'Peak Intensity %',...
    'Length of Day (h)'}; 

dlgtitle = 'Light ramp Parameters';
dims = [1 35];

definput = {
    '8',...
    '20',...
    '100',...
    '100',...
    '100',...
    '100',...
    '24'};



answer = inputdlg(prompt,dlgtitle,dims,definput);

LoD = str2num(answer{7})*3600; %length of day in seconds
Scale = LoD/86400


OnT = str2num(answer{1})*3600; %on time in seconds
OffT = str2num(answer{2})*3600; %off time in seconds

red_int = str2num(answer{3})/100;
green_int = str2num(answer{4})/100;
blue_int = str2num(answer{5})/100;
intensity_int = str2num(answer{6})/100;

blue = 'D5'
green = 'D6'
red = 'D9'
Lambda = 'D3'

% Connect arduino
clear a
a = arduino();
%% Build second-by-second light intensity schedule for first day
LPhase = (OffT - OnT);
numIntensitySteps = LPhase*500/LPhase;
TimeArray = nan(500,1);
TimeArray(:,1) = round((OnT:LPhase/(numIntensitySteps-1):OffT))';


%Generate cos wave for ramp
Fs = 500;
dt = 1/Fs;
StopTime = 1;
t = (0:dt:StopTime-dt);

Fc = 1;
IntensityArray = -cos(2*pi*Fc*t) + 1;
IntensityArray = IntensityArray*(5/2);

TimeSchedule = zeros(86400*Scale,1);
for i = 1:size(TimeArray,1)-1
    idx = TimeArray(i);
    Reps = TimeArray(i+1) - TimeArray(i);
    TimeSchedule(idx:idx+Reps) = IntensityArray(i);
end

idx = max(TimeArray);
Reps = TimeArray(end) - TimeArray(end-1);
TimeSchedule(idx-Reps:idx) = IntensityArray(end-1);

%% Start timer 
TimeZero = datetime(datestr(now,'yyyy-mmm-dd'),'InputFormat','yyyy-MMM-dd','Format','yyyy-MMM-dd HH:mm:SS')
currTime = datetime()
endTime = datetime() + 10

%First Time check (to avoid flickering)
    %Time check
    TimeCheck = datetime();
    TimeCheck = round(mod(seconds(TimeCheck - TimeZero),LoD));

    if TimeCheck>size(TimeSchedule,1)
        TimeCheck = size(TimeSchedule,1);
    end
    
    if TimeCheck ==0
        TimeCheck = 1;
    end
    %only update lights when intensity actually changes to avoid flickering
    CurrentIntensity = TimeSchedule(TimeCheck);

    writePWMVoltage(a, red, red_int*intensity_int*CurrentIntensity);
    writePWMVoltage(a, green, green_int*intensity_int*CurrentIntensity);
    writePWMVoltage(a, blue, blue_int*intensity_int*CurrentIntensity);
    writePWMVoltage(a, Lambda, blue_int*intensity_int*CurrentIntensity);

figure
while currTime<endTime
    %Time check
    TimeCheck = datetime();
    TimeCheck = round(mod(seconds(TimeCheck - TimeZero),LoD));
    if TimeCheck>size(TimeSchedule,1)
        TimeCheck = size(TimeSchedule,1);
    end
    %bump time check up one at 12:00 AM to avoid zero index
    if TimeCheck == 0
        TimeCheck = 1;
    end
    %only update lights when intensity actually changes to avoid flickering
    CurrentIntensity_check = TimeSchedule(TimeCheck);
    if CurrentIntensity_check ~= CurrentIntensity
        CurrentIntensity = CurrentIntensity_check;
        writePWMVoltage(a, red, red_int*intensity_int*CurrentIntensity);
        writePWMVoltage(a, green, green_int*intensity_int*CurrentIntensity);
        writePWMVoltage(a, blue, blue_int*intensity_int*CurrentIntensity);
        writePWMVoltage(a, Lambda, blue_int*intensity_int*CurrentIntensity);
    end
    %create plot to track light intensity throughout the day 
    title('Daily Light Intensity')
    plot((1:86400*Scale)/3600,TimeSchedule/5,'color','b')
    ylabel('Relative Light Intensity')
    xlabel('Time')
    TimeLine = xline(TimeCheck/3600,'r');
    TimeText = text(TimeCheck/3600,.85,'Current Time','Color','r','FontSize',15);
    xlim([0,24*Scale])
    xticks([0:2:24*Scale])
    drawnow()
    currTime = datetime();
end
close all
 


