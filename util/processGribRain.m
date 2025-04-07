function processGribRain(startDateStr, endDateStr, grib2_dec_path, rain_base_path)
% processGribRain Process grib2 data files over a specified date range.
% THIS FUNCTION PROCESSES DATA OF EVERY HOUR(original data is available for every 30 min)
%
%   processGribData(startDateStr, endDateStr) processes the grib2 data files
%   for all days from startDateStr to endDateStr (inclusive). The input date 
%   strings should be provided in 'yyyymmdd' format.
%
%   For each day, the function loops over time values from 000000 to 230000 
%   (in steps of 10000) and constructs the appropriate file path. It then calls 
%   an external program (grib2_dec) to process each file.
%
%   Example:
%       startDateStr = '20200725';
%       endDateStr   = '20200729';
%       grib2_dec_path = fullfile('src', 'cpp', 'code', 'grib2_dec');  % grib2_dec の実行ファイルパス
%       rain_base_path  = fullfile('test', 'data', 'kaiseki', 'DATA'); % 雨量データのベースディレクトリ
%       processGribRain(startDateStr, endDateStr, grib2_dec_path, rain_base_path);
%
%   Author: T. Koshiba
%   Date: 2025-04-01

    % Convert input strings to datetime objects
    startDate = datetime(startDateStr, 'InputFormat', 'yyyyMMdd');
    endDate   = datetime(endDateStr,   'InputFormat', 'yyyyMMdd');

    % Loop over each day in the date range
    for currentDate = startDate : endDate
        % Extract year, month, and day strings (with proper zero-padding)
        yearStr  = datestr(currentDate, 'yyyy');
        monthStr = datestr(currentDate, 'mm');
        dayStr   = datestr(currentDate, 'dd');
        
        % Loop over time values from 000000 to 230000 in steps of 10000
        for current_time = 0:10000:230000
            timeStr = sprintf('%06d', current_time);  % Zero-pad time to 6 digits
            
            % Construct the file name.
            % Format: Z__C_RJTD_YYYYMMDDHHMMSS_SRF_GPV_Ggis1km_Prr60lv_ANAL_grib2.bin
            fileName = sprintf('Z__C_RJTD_%s%s%s%s_SRF_GPV_Ggis1km_Prr60lv_ANAL_grib2.bin', ...
                               yearStr, monthStr, dayStr, timeStr);
                           
            % Construct the full file path
            rain_path = fullfile(rain_base_path, yearStr, monthStr, dayStr, fileName);
            
            % Construct the system command.
            % Quotes are used to safely handle paths with spaces.
            cmd = sprintf('"%s" "%s"', grib2_dec_path, rain_path);
            
            % Execute the command
            status = system(cmd);
            
            % Check the return status and print message
            if status ~= 0
                fprintf('Error processing file: %s\n', rain_path);
            else
                fprintf('Processed: %s\n', rain_path);
            end
        end
    end
end