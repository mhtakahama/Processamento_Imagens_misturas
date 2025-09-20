function conc = gray2conc(grayValue)
a=5.520332803270045; b=0.014969507001766; c=-3.719099648208014;
conc = (a./(grayValue - c)) - b;
conc(conc<0)=0;
end
