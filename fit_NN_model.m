%%%%fitting MEG_model_repetition_AI_HI_fitting

clear;
%close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%fit AI and HI separately
%%%%1: AI
%%%%2: HI
fitcontrol_init = 1;

if fitcontrol_init == 1
    %%%%fit AI, starting points 
    dtmemgain_init = 1.2; %gain (propotional) for a specific unit after AI
    dtmemsupp_init = 0.9; %suppression (propotional) for two nearby units after AI
    dtmem_att_init = 0.0009; %attention for AI
else
    %%%%fit HI, starting points 
    dtmemgain_init = 1.15; %gain (propotional) for a specific unit after AI
    dtmemsupp_init = 1.05; %suppression (propotional) for two nearby units after AI
    dtmem_att_init = 0.0013; %attention for HI
end

initial_val = [dtmemgain_init,dtmemsupp_init,dtmem_att_init];

[x,fval,exitflag,output] = fminsearch(@(x) NN_model(x,fitcontrol_init),initial_val);

fprintf('done');

