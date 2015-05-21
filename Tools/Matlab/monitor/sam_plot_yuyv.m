function h=sam_plot_yuyv(yuyv, lut)
  [ycbcr,rgb]=yuyv2rgb(yuyv);
  label = sam_yuyv2label(yuyv, lut);
  %imagesc( rgb ); 
  imagesc(label);
end 
