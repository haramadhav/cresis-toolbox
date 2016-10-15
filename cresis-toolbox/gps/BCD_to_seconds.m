function seconds = BCD_to_seconds(seconds_BCD)

seconds_BCD = double(seconds_BCD);

seconds = ...
  3600*(10*mod(floor(seconds_BCD/2^8),2^4) + mod(floor(seconds_BCD/2^12),2^4)) ...
  + 60*(10*mod(floor(seconds_BCD/2^16),2^4) + mod(floor(seconds_BCD/2^20),2^4)) ...
  + (10*mod(floor(seconds_BCD/2^24),2^4) + mod(floor(seconds_BCD/2^28),2^4));

%seconds = uint32(seconds);

return;

