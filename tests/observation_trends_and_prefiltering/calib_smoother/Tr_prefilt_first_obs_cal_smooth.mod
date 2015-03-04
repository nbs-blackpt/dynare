var Y_obs P_obs junk1 junk2;
varexo e_y e_p eps_junk;

parameters rho_y rho_p  g_y g_p sigma_y sigma_p;

rho_y=0.5;
rho_p=0.5;
g_y=0.0001;
g_p=-0.0001;
sigma_y=0.001;
sigma_p=0.001;


model;
Y_obs = rho_y*Y_obs(-1)+sigma_y*e_y;
P_obs = rho_p*P_obs(-1)+sigma_p*e_p;
junk1 = 0.9*junk1(+1);
junk2 = 0.9*junk2(-1)+eps_junk;
end;

steady_state_model;
Y_obs = 0;
P_obs = 0;
junk1=0;
junk2=0;
end;

shocks;
var e_p; stderr 1;
var e_y; stderr 1;
var eps_junk; stderr 1;
end;

steady;

varobs P_obs Y_obs junk2;

observation_trends;
P_obs (g_p);
Y_obs (g_y);
end;


options_.plot_priors=0;

calib_smoother(datafile='../AR1_trend_data_with_constant',prefilter=1,first_obs=1000,
        filter_decomposition,
        filtered_vars, filter_step_ahead = [1,2,4]) P_obs Y_obs;
load('../AR1_trend_data_with_constant');
loaded_par=load('../orig_params');
if max(abs((M_.params-loaded_par.orig_params([1:4,7:8]))./loaded_par.orig_params([1:4,7:8])))>0.03
    error('Parameters do not match')
end

if max(abs(oo_.SmoothedVariables.Y_obs-Y_obs(options_.first_obs:end)'))>1e-5 ||...
    max(abs(oo_.SmoothedVariables.P_obs-P_obs(options_.first_obs:end)'))>1e-5 || ...
    max(abs(oo_.SmoothedVariables.junk2-junk2(options_.first_obs:end)'))>1e-5
    error('Smoothed Variables are wrong')
end

if max(abs(oo_.UpdatedVariables.Y_obs-Y_obs(options_.first_obs:end)'))>1e-5 ||...
    max(abs(oo_.UpdatedVariables.P_obs-P_obs(options_.first_obs:end)'))>1e-5 ||...
    max(abs(oo_.UpdatedVariables.junk2-junk2(options_.first_obs:end)'))>1e-5 
    error('Updated Variables are wrong')
end

if mean(abs(oo_.FilteredVariables.Y_obs(1:end-1)-Y_obs(options_.first_obs+1:end)'))>1e-3 ||...
    mean(abs(oo_.FilteredVariables.P_obs(1:end-1)-P_obs(options_.first_obs+1:end)'))>1e-3 
    error('Smoothed Variables are wrong')
end

if abs(corr(oo_.FilteredVariables.Y_obs(2:end-1)-Y_obs(options_.first_obs+2:end)',oo_.FilteredVariables.Y_obs(1:end-2)-Y_obs(options_.first_obs+1:end-1)'))>2e-2 ||...
    abs(corr(oo_.FilteredVariables.P_obs(2:end-1)-P_obs(options_.first_obs+2:end)',oo_.FilteredVariables.P_obs(1:end-2)-P_obs(options_.first_obs+1:end-1)'))>2e-2 ||...
    abs(corr(oo_.FilteredVariables.junk2(2:end-1)-junk2(options_.first_obs+2:end)',oo_.FilteredVariables.junk2(1:end-2)-junk2(options_.first_obs+1:end-1)'))>2e-2 
    error('Filtered Variables are wrong')
end

if max(abs(squeeze(oo_.FilteredVariablesKStepAhead(1,1,2:end-(options_.nk-1)))-oo_.FilteredVariables.Y_obs))>1e-5 ||...
    max(abs(squeeze(oo_.FilteredVariablesKStepAhead(1,2,2:end-(options_.nk-1)))-oo_.FilteredVariables.P_obs))>1e-5 ||...
    max(abs(squeeze(oo_.FilteredVariablesKStepAhead(1,3,2:end-(options_.nk-1)))-oo_.FilteredVariables.junk2))>1e-5 
    error('FilteredVariablesKStepAhead is wrong')
end
   
if max(abs(squeeze(oo_.FilteredVariablesKStepAhead(1,1,2:end-(options_.nk-1)))-oo_.FilteredVariables.Y_obs))>1e-5 ||...
    max(abs(squeeze(oo_.FilteredVariablesKStepAhead(1,2,2:end-(options_.nk-1)))-oo_.FilteredVariables.P_obs))>1e-5 ||...
    max(abs(squeeze(oo_.FilteredVariablesKStepAhead(1,3,2:end-(options_.nk-1)))-oo_.FilteredVariables.junk2))>1e-5 ||...
    max(abs(squeeze(oo_.FilteredVariablesKStepAhead(2,1,3:end-options_.nk))-oo_.FilteredVariables.Y_obs(3:end)))>1e-2 ||...
    max(abs(squeeze(oo_.FilteredVariablesKStepAhead(2,2,3:end-options_.nk))-oo_.FilteredVariables.P_obs(3:end)))>1e-2 ||...
    mean(squeeze(oo_.FilteredVariablesKStepAhead(2,3,3:end-options_.nk)))>1e-1 ||...
    mean(squeeze(oo_.FilteredVariablesKStepAhead(2,4,3:end-options_.nk)))>1e-1
    error('FilteredVariablesKStepAhead is wrong')
end
   
if abs(mean(oo_.SmoothedShocks.e_y))>0.05 || abs(mean(oo_.SmoothedShocks.e_p))>0.05
    error('Residuals are not mean 0')
end