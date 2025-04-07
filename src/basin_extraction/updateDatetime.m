function [Y, M, D, H] = updateDatetime(oldDatetime, dt)

tmpDate = oldDatetime + dt;
Y = tmpDate.Year;
M = tmpDate.Month;
D = tmpDate.Day;
H = tmpDate.Hour;
end
