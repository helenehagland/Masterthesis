function cost = cost_function(thickness_vector)
    neg_thick = thickness_vector(1);
    pos_thick = thickness_vector(2);
    cost = simulate_and_get_rmse(neg_thick, pos_thick);
end