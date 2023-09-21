%% Startup and Load Files
%clearvars;
clearvars -except lookuptable output_data DFM*
%% Load Recording Files
test=DFM14full011022;
%% determine day of year recording began
days_in_months = [0 31 28 31 30 31 30 31 31 30 31 30 31];
cumulative_days = zeros(12,1);
for i = 1:12
    cumulative_days(i) = sum(days_in_months(1:i));
end
%% determine light schedule
LightsOnTime = 7;
LightsOffTime = 19;
light_schedule = zeros(23,7);
light_schedule(LightsOnTime:LightsOffTime,:)=1

%% ZT0 values
ZT0=LightsOnTime;

    StartMonth = str2num(datestr(test.Date(1),'mm'))
    StartDOM = str2num(datestr(test.Date(1),'dd'))
    [StartDay,StartDOW] = weekday(datetime(datestr([datestr(test.Time(1),'hh:mm:ss'),' ',datestr(test.Date(1),'dd-mmm-yyyy')])),'long')
    StartTimePull = str2num(datestr(test.Time(1),'HH'))+5
    NumDay = [cumulative_days(StartMonth)+(StartDOM)]
%%
%Use these to test if the conditional statements work properly   
  % StartTimePull = 23
  % StartDay = 6   
light_query = light_schedule(StartTimePull,StartDay)     
%Conditional Statements Determine Location of ZT0 and Start Day    
    if StartTimePull> 23;
        StartTimePull = 0;
        NumDay = NumDay+1
    elseif light_query == 0 & StartTimePull < LightsOnTime-5;
        NumDay = NumDay
    else
        NumDay = NumDay+1
    end
%%
% Change Time and Date Values from 'test' to matrix of values, also
% includes the running integer value of each day (e.g. 365)
days = str2num(datestr(test.Date(:),'dd'));
months = str2num(datestr(test.Date(:),'mm'));
hours = str2num(datestr(test.Time(:),'HH'));
minutes = str2num(datestr(test.Time(:),'MM'));
seconds = str2num(datestr(test.Time(:),'SS'));
numerical_day = [cumulative_days(months)+days];
time_matrix = [numerical_day,months, days, hours, minutes, seconds];
%%
%Using ZT0 and numerical day, determine the index within time_matrix
times = [numerical_day,hours, minutes, seconds];
ZT0_Time=[NumDay,ZT0, 0, 0]
[q, ZT0_idx] = ismember(ZT0_Time, times, 'rows')

%Also find the index of additional 24h later
Times_Table = datetime(datestr([datestr(test.Time(ZT0_idx),'hh:00:00'),' ',datestr(test.Date(ZT0_idx),'dd-mmm-yyyy')]))
ZT0_D2 = datestr(addtodate(datenum(Times_Table),24,'h'))

change_day=str2num(datestr(ZT0_D2,'DD'))-str2num(datestr(Times_Table,'DD'))
ZT0_D2_idx = [NumDay+change_day,str2num(datestr(ZT0_D2,'HH')),0,0] 
[q, ZT0_D2_idx] = ismember(ZT0_D2_idx, times, 'rows');

%Use those indices to extract well data from 'test'
day_indices = [ZT0_idx, ZT0_D2_idx];
%% Begin Loop of Plotting and Selecting Days for individual wells
order = 2;
framelen = 2001;

output_data=[];
for i = 5:size(test,2);

plot_data = test(:,i);        % this selects the well of interest
plot_data = table2array(plot_data);
%Fit smooth line 
FittedA = sgolayfilt(plot_data,order,framelen);
plot_dataA = plot_data - FittedA;%normalize to savgol
plot_dataA(plot_dataA<0)=0;%set negatives to zero
plot_dataA=plot_dataA>40;
%plot_dataA=plot_dataA>40;


%Plot smoothed values
sleep_actogram = figure('Position',[1050,449,791,217]);
subplot(2,1,1);
hold on
patch([diff(day_indices)/2 diff(day_indices) diff(day_indices) diff(day_indices)/2],[0 0 1 1],'black','FaceAlpha',0.5)
plot(plot_dataA(day_indices(1):day_indices(2)+28000));
hold off
subplot(2,1,2);
hold on
plot(plot_data(day_indices(1):day_indices(2)+28000));
patch([diff(day_indices)/2 diff(day_indices) diff(day_indices) diff(day_indices)/2],[0 0 500 500],'black','FaceAlpha',0.5)
hold off


% Set inclusion and exclusion criteria for wells

if sum(plot_dataA(day_indices(1):day_indices(2)) == 1)<50==1
    output_range = [day_indices(1):day_indices(2)-1];
    output_data(:,i) = zeros(size(output_range));
    title('Exclude')

% elseif sum(plot_dataA(day_indices(2):day_indices(2)+28000,:))==0
%     output_range = [day_indices(1):day_indices(2)-1];
%     output_data(:,i) = zeros(size(output_range));
%     title('Exclude')
% 
elseif sum(plot_data(day_indices(1):day_indices(2))>=1023)>2000==1
    output_range = [day_indices(1):day_indices(2)-1];
    output_data(:,i) = zeros(size(output_range));
    title('Exclude')
% elseif sum(plot_data(day_indices(1):day_indices(2))>=1023)>8000==1
%     output_range = [day_indices(1):day_indices(2)-1];
%     output_data(:,i) = zeros(size(output_range));
%     title('Exclude')
else
    output_range = [day_indices(1):day_indices(2)-1];
    output_data(:,i) = plot_data(output_range);
    title('Include')
end
%close all
hold off
end
%test=output_data;
output_data( :, all(~output_data,1) ) = [];%clear zero columns


