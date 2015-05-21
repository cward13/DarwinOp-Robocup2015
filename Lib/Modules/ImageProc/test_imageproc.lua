require('ImageProc');
require('carray');

cdt = carray.new('c', 262144);
pcdt = carray.pointer(cdt);

width = 320;
height = 240;

rgb = carray.new('c', 3*width*height);
print(rgb)
for ind=1,3*width*height do
	--print(rgb[ind])
end
prgb = carray.pointer(rgb);
print(prgb)

pyuyv = ImageProc.rgb_to_yuyv(prgb, width, height);
--print(pyuyv);
yuyv = carray.cast(pyuyv, 'i', width*height);
for ind=1,width*height do
	print(yuyv[ind])
end
plabel = ImageProc.yuyv_to_label(pyuyv, pcdt, width, height);
label = carray.cast(plabel, 'c', width*height);
