cmax_lnmo = 23286.29529;
cmax_xno = 35259;

c_lnmo = linspace(cmax_lnmo,0,100);
c_xno = 0 + (cmax_lnmo-c_lnmo);

ocp_lnmo = computeOCP_LNMO_Morrow(c_lnmo,T,cmax_lnmo);
ocp_xno = computeOCP_XNO_Morrow(c_xno,T,cmax_xno);

ocp_cell = ocp_lnmo - ocp_xno;

soc = c_lnmo ./ cmax_lnmo;


figure()
plot(soc,ocp_lnmo)
hold on
plot(soc,ocp_xno)
hold on
plot(soc,ocp_cell)
hold off
