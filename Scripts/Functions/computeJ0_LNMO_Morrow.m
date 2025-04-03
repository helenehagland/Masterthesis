function j0 = computeJ0_LNMO_Morrow(soc)
    k_ref = 1e-8;  % boost for debugging
    j0 = k_ref .* (1 - (2*soc - 1).^4);
    j0(j0 < 0) = 0;
end