function [SS_dist]=NN_model(input,fitcontrol)

%%%%fit AI and HI separately
if fitcontrol == 1 %%%%fit AI
    dtmemgainAI = input(1); %gain (propotional) for a specific unit after AI
    dtmemsuppAI = input(2); %suppression (propotional) for two nearby units after AI
    dtmem_attAI = input(3); %attentional gain
    
    dtmemgainHI = 1.15; %fixed for HI, no use when fitting AI
    dtmemsuppHI = 1.05;
    dtmem_attHI = 0.0013;
    
else %%%%fit HI
    dtmemgainHI = input(1);
    dtmemsuppHI = input(2);
    dtmem_attHI = input(3);
    
    dtmemgainAI = 1.2;
    dtmemsuppAI = 0.85;
    dtmem_attAI = 0.0009;
end

%%%%fixed parameters
repNO =2; %%%%simulate same or different trials
stageNO =3; %%%%for first sound, after AI, and after HI

%%%%time of input to layer1
audi_present_time = 600; %as in Tian&Poeppel,2013 paper

for repetition =1:repNO
    for stage = 1:stageNO

        inhibit= .3; %inhibition strength
        thresh= .15; %firing threshold
        leak=.15; %leak strength
        VErev = 1; %reversal potential for excitation
        VIrev = -0.29; %reversal potential for inhibition
        VLrev = 0; %reversal potential for leaking, set to resting potential
        feedback= 0; %no feedback
        depletion= 0.324; %depletion rate
        recovery= 0.022; %recovery rate
        
        %%%%step size at each layer %%%%postsyn gain;
        %%%%updating this structure as the modulation effects of preceding AI and HI
        dtmem_orig = [.046; .015]./1.5; %time constants in two layers
        dtmeminh = dtmem_orig; %%%%synaptic gain for inhibition and leak unchanged
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % create 2 layers with 6 nodes per layer
        mem=zeros(2,6); % membrane potential
        amp=ones(2,6); % spike amplitude %%%%this is really the available neural resources
        out=zeros(2,6); % output
        
        % creat full connection from layer1 to layer2
        %%%%first 3 units nearby (ba/da/ga), last 3 units far away (pi/ti/ki)
        adjw = 0.22; 
        farw = 0;
        cw1to2 = [1 adjw adjw farw farw farw;
            adjw 1 adjw farw farw farw;
            adjw adjw 1 farw farw farw;
            farw farw farw 1 adjw adjw;
            farw farw farw adjw 1 adjw;
            farw farw farw adjw adjw 1];

        cw2to1 = zeros(6,6);
                     
        if stage == 1
            %%%%for first sound
            dtmem = dtmem_orig;
        elseif stage ==2
            %%%%for AI            
            dtmem = dtmem_orig*ones(1,6);          
            dtmem(2,1) = dtmem_orig(2,1).*dtmemgainAI; 
            dtmem(2,2) = dtmem_orig(2,1).*dtmemsuppAI; 
            dtmem(2,3) = dtmem_orig(2,1).*dtmemsuppAI;           
            dtmem = dtmem +dtmem_attAI;   
        else
            %%%%for HI
            dtmem = dtmem_orig*ones(1,6);
            dtmem(2,1) = dtmem_orig(2,1).*dtmemgainHI;
            dtmem(2,2) = dtmem_orig(2,1).*dtmemsuppHI;
            dtmem(2,3) = dtmem_orig(2,1).*dtmemsuppHI;
            dtmem(2,[1:3]) = dtmem(2,[1:3]) - dtmem_attHI;
            dtmem(2,[4:6]) = dtmem(2,[4:6]) + dtmem_attHI;
        end
        
        %%%%stepsize for resources (amp)
        dtamp= dtmem_orig;
        
        for t=1:2000
            
            % put spike amplitude (available resouces) and syanptic output into a results matrix
            % the order goes 1-6 in layer1 then 1-6 for layer2, ....
            amp_t(t,:,stage,repetition)=reshape(amp',12,1);
            mem_t(t,:,stage,repetition)=reshape(mem',12,1);
            out_t(t,:,stage,repetition)=reshape(out',12,1);
            
            % establish excitatory inputs to layer 1
            if t<=audi_present_time
                if repetition ==1
                    exc(1,:)=[1,zeros(1,5)];
                else
                    exc(1,:)=[zeros(1,5),1];
                end
            else
                exc(1,:) = zeros(1,6);
            end
            
            % inlcude one-to-two mapping for feedback to layer 1
            % no feedback, as the value set to 0
            exc(1,:)=exc(1,:)+feedback.*out(2,:)*cw2to1;
            
            % one-to-many mapping (full) from layer 1 to 2
            exc(2,:)=out(1,:)*cw1to2;
            
            % calculate inhibition at each layer
            % this assumes self and lateral inhibition
            inh=sum(out,2);
            
            % update membrane potential for each layer
            for layer=1:2          
                    mem(layer,:)=mem(layer,:) + ( dtmem(layer,:).* (  ((VErev - mem(layer,:)).*exc(layer,:)) )  + ( dtmeminh(layer).*(inhibit.*inh(layer,:) *(VIrev-mem(layer,:))+  (leak.*(VLrev-mem(layer,:)))) ));   
            end
            
            % update spike amplitude (available resources) for each layer
            for layer=1:2
                amp(layer,:)=amp(layer,:)+(dtamp(layer).*  (  (recovery.*(1-amp(layer,:)))  -  (depletion.*out(layer,:))  ));
            end
            
            % calculate above treshold spike probability
            prob=zeros(2,6);
            prob((mem-thresh)>0)=mem((mem-thresh)>0)-thresh;
            
            % calculate output
            out=amp.*prob; 
            exc_t(t,:,stage,repetition)=reshape(exc',12,1);
        end
    end
end

%%%%calculate the cost function
halfwidth = 12;

for TI = 1:size(mem_t,3)
    for RI = 1:size(mem_t,4)     
        sum_signal_t_costfun = squeeze(sum(out_t(:,7:12,:,:),2));       
        [maxv_costfun,maxt_costfun] = max(sum_signal_t_costfun,[],1);
        timeavg_costfun(TI,RI) = mean(sum_signal_t_costfun(maxt_costfun(1,TI,RI)-halfwidth:maxt_costfun(1,TI,RI)+halfwidth,TI,RI),1);
        
    end
end

AI_same_percent_costfun = [timeavg_costfun(2,1)- timeavg_costfun(1,1)]./timeavg_costfun(1,1);
AI_diff_percent_costfun = [timeavg_costfun(2,2)- timeavg_costfun(1,2)]./timeavg_costfun(1,1);
HI_same_percent_costfun = [timeavg_costfun(3,1)- timeavg_costfun(1,1)]./timeavg_costfun(1,1);
HI_diff_percent_costfun = [timeavg_costfun(3,2)- timeavg_costfun(1,2)]./timeavg_costfun(1,1);
mean_sim_costfun = [AI_same_percent_costfun AI_diff_percent_costfun HI_same_percent_costfun HI_diff_percent_costfun];

AI_same_exp = 0.23;
AI_diff_exp = 0.08;
HI_same_exp = 0.02;
HI_diff_exp = 0.11;
exp_mean = [AI_same_exp AI_diff_exp HI_same_exp HI_diff_exp];

%%%%fit AI HI separately
if fitcontrol ==1 %%%%fit AI
    SS_dist = sqrt(sum((mean_sim_costfun(1:2) - exp_mean(1:2)).^2))
else %%%%fit HI
    SS_dist = sqrt(sum((mean_sim_costfun(3:4) - exp_mean(3:4)).^2))
end