%%%%perform fitting baseline responses to /ba/-/da/ continumm using the neural peak latency 

clear;
%close all;

%starting points
NS = 0.0189;  
bias_ba = 0.04;  
init_val = [NS bias_ba]; 

stand_resp = [0.8946 0.8640 0.8421 0.5555 0.3143 0.2045 0.1535];
neural_resp_file = ['out_t_ba_da_cont_before_IMG_adap'];
plot_ind = 0;

[x,fval,exitflag,output] = fminsearch(@(x)beh_model_from_NN_output(x,stand_resp,neural_resp_file,plot_ind),init_val);
