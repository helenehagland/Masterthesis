function j0 = computeJ0_LNMO_Morrow(soc)
    % Display something so we know it runs
    disp('✅ Using computeJ0_LNMO_Morrow!');

    % Make j0 absurdly small to check effect
    j0 = 1e-10 * soc .* (1 - soc);
end