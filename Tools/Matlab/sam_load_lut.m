function [ lut ] = sam_load_lut()
%loads a lut
    
[filename, pathname] = uigetfile('*.raw', 'Select lut file to load');
    if (filename ~= 0)
      MONITOR.lutname=filename;
      fid = fopen([pathname filename], 'r');
      lut = fread(fid, 'uint8');
      fclose(fid);
    end

end

