T = 298;
cmax_lnmo = 2.3286e+04;
c = linspace(0,cmax_lnmo,1000);
OCP = computeOCP_LNMO_Morrow(c,T, cmax_lnmo);

plot(c./cmax_lnmo,OCP)



cmax_xno = 35259;
c = linspace(0,cmax_xno,1000);
OCP = computeOCP_XNO_Morrow(c,T, cmax_xno);

plot(c./cmax_xno,OCP)