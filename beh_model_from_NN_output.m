function [SS_dist]=beh_model_from_NN_output(input, beh_resp, nerual_resp_file,plot_ind)
%fitting procedure: fitting baseline responses to /ba/-/da/ continumm using the neural peak latency

stand_resp = beh_resp; 
load(nerual_resp_file);
NS = input(1); %decision noise
bias_ba = input(2); %decision bia towards choice of /ba/

%%%%extract latency of output of layer 2 for ba and da
for i = 1:size(out_t,3)
    [maxv7(i),maxt7(i)] = max(out_t(:,7,i),[],1); %ba
    [maxv8(i),maxt8(i)] = max(out_t(:,8,i),[],1); %da
end

%%%%model percentage rating
model_pc = exp(NS*(maxt8-maxt7))./(1+exp(NS*(maxt8-maxt7))) + bias_ba;

SS_dist = sqrt(mean(model_pc - stand_resp).^2)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if plot_ind
    load('./beh_data/data_ba');
    %load('data_da');
    
    mean_data = squeeze(mean(data,1));
    std_data = squeeze(std(data,1))./sqrt(19);
    
    x = [1:7]';
    figure;
    errbar = [std_data(:,1) std_data(:,1)]';
    shadedErrorBar(x, mean_data(:,1)', errbar, 'lineprops', '-k')
    hold on
    plot(x,model_pc,'.r')
    hold off
    
    legend('BL','MD')
end


