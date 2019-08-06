function generate_predictions

NS = 0.0193; 
bias_ba = 0.0469;

figure;
hold on;

for plot_ctrl = 1:3
    if plot_ctrl == 1
        %plot beh predition before adaptation
        %beh_resp = [0.8946 0.8640 0.8421 0.5555 0.3143 0.2045 0.1535];
        nerual_resp_file = ['out_t_ba_da_cont_before_IMG_adap'];
    elseif plot_ctrl == 2
        %plot beh predition after adaptation AI
        %beh_resp = [0.9502 0.9502 0.9181 0.7426 0.4298 0.2807 0.2135];
        nerual_resp_file = ['out_t_ba_da_cont_after_IMG_adap_AI'];
    else
        %plot beh predition after adaptation HI
        %beh_resp = [0.9415 0.9356 0.9209 0.6433 0.2662 0.1638 0.0877];
        nerual_resp_file = ['out_t_ba_da_cont_after_IMG_adap_HI'];
    end
    %stand_resp = beh_resp;
    load(nerual_resp_file);
    
    %%%%extract latency of output of layer 2 for ba and da
    for i = 1:size(out_t,3)
        [maxv7(i),maxt7(i)] = max(out_t(:,7,i),[],1); %ba
        [maxv8(i),maxt8(i)] = max(out_t(:,8,i),[],1); %da
    end
    
    %%%%model percentage rating
    model_pc = exp(NS*(maxt8-maxt7))./(1+exp(NS*(maxt8-maxt7))) +bias_ba;    
    %SS_dist = sqrt(mean(model_pc - stand_resp).^2);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%plotting results, comment out when fitting
    load('data_ba');
    %load('data_da');    
    mean_data = squeeze(mean(data,1));
    std_data = squeeze(std(data,1))./sqrt(19);
    
    x = [1:7]'; 
    plot_color_exp = {'-k','-r','-g'};
    plot_color_model = {'--k','--r','--g'};
    plot_legend_exp = {'BL','AI','HI'};
    plot_legend_model = {'BLMD','AIMD','HIMD'};
    
    errbar = [std_data(:,plot_ctrl) std_data(:,plot_ctrl)]';
    shadedErrorBar(x, mean_data(:,plot_ctrl)', errbar, 'lineprops', plot_color_exp{plot_ctrl})
    plot(x,model_pc,plot_color_model{plot_ctrl},'MarkerSize',20,'LineWidth',3)
   
    legend(plot_legend_exp{plot_ctrl},plot_legend_model{plot_ctrl})
end
hold off;
