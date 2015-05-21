module(..., package.seeall);
require('vector')
--require('vcm')

-- Camera Parameters

camera = {};
camera.ncamera = 1;
camera.switchFreq = 0; --unused for OP
camera.width = 640;--switch back to 640!!!
camera.height = 480; -- switch back to 480!!
camera.x_center = 328;
camera.y_center = 248;

camera.focal_length = 533; -- in pixels
camera.focal_base = 640; -- image width used in focal length calculation

--[[
queryctrl: "White Balance Temperature" 0x98091a
queryctrl: "Sharpness" 0x98091b
queryctrl: "Backlight Compensation" 0x98091c
queryctrl: "Exposure, Auto" 0x9a0901
querymenu: Auto Mode
querymenu: Manual Mode
querymenu: Shutter Priority Mode
querymenu: Aperture Priority Mode
queryctrl: "Exposure (Absolute)" 0x9a0902
queryctrl: "Exposure, Auto Priority" 0x9a0903
queryctrl: "Pan (Absolute)" 0x9a0908
queryctrl: "Tilt (Absolute)" 0x9a0909
queryctrl: "Brightness" 0x980900
queryctrl: "Contrast" 0x980901
queryctrl: "Saturation" 0x980902
queryctrl: "White Balance Temperature, Auto" 0x98090c
queryctrl: "Gain" 0x980913
queryctrl: "Power Line Frequency" 0x980918
--]]

camera.auto_param = {};
camera.auto_param[1] = {key='white balance temperature, auto', val={0}};
camera.auto_param[2] = {key='power line frequency',   val={0}};
camera.auto_param[3] = {key='backlight compensation', val={0}};
camera.auto_param[4] = {key='exposure, auto',val={1}}; --1 for manual
camera.auto_param[5] = {key="exposure, auto priority",val={0}};


camera.param = {};
camera.param[1] = {key='brightness',    val={128}};
camera.param[2] = {key='contrast',      val={32}};
camera.param[3] = {key='saturation',    val={42}};
camera.param[4] = {key='gain',          val={67}};
-- 3000-9000 produce light spectrums which shift to contain more orange and blue wavelengths,respectively
camera.param[5] = {key='white balance temperature', val={70}};
camera.param[6] = {key='sharpness',     val={191}};
camera.param[7] = {key='exposure (absolute)',      val={538}};

--camera.lut_file = 'lut_low_contrast_pink_n_green.raw';

--camera.lut_file = 'grasp_low_contrast_1643_samarth.raw';
--camera.lut_file = 'lut_Grasp_Greenonly.raw';
--camera.lut_file = 'lut_OP_Grasp_GreenOnly.raw';
--camera.lut_file = '0427_grasp.raw'; --Red ball, not orange 
--camera.lut_file = 'lut_Grasp_GreenOnly_SJ.raw';
--camera.lut_file = 'lut_ob_test';
--camera.lut_file = 'lut_ob_new';
--camera.lut_file = 'lut_802A';
--camera.lut_file_obs = 'lut_ob_test';
--camera.lut_file_new = 'lut_ob_new';
--camera.lut_file_obs = '0427_grasp';
--camera.lut_file = '0427_grasp';
--camera.lut_file = 'lut_empty';
--camera.lut_file = 'lut_0811_L512_4PM.raw';
--camera.lut_file = 'lut_0811_L512_5PM.raw';
--camera.lut_file = 'lut_0811_L512_6PM.raw';
--camera.lut_file = 'lut_0812_L512.raw';
--camera.lut_file = 'grasp_low_contrast_loc_1800.raw';
--camera.lut_file = 'grasp_low_contrast_1643_samarth.raw';
--camera.lut_file = 'grasp_high_contrast_2030_samarth.raw';
--camera.lut_file = 'grasp_high_contrast_2030_samarth.raw';

camera.lut_file = 'lut_demoOP';
