function neural_output_before_IMG_adap
%%%%using the original gains to generate neural output for beh_model

clear;
close all;

repNO =7; %%%%7 levels of ba-da continue

input_bada_first100 = [1 0; 
              0.833 0.167;
              0.667 0.333;
              0.5 0.5; 
              0.333 0.667;
              0.167 0.833;
              0 1];
          
input_bada_101to300 = ones(7,2).*0.5;

%%%%time of input to layer1
audi_present_time_consonant = 100; %the duration of format transition in /ba/ /da/ as shown in F2
audi_present_time_vowel = 300; %stimuli duration in total in the beh exp;

inhibit= .3; 
thresh= .15; 
leak=.15;
VErev = 1; 
VIrev = -0.29; 
VLrev = 0; 
feedback= 0;
depletion= 0.324; 
recovery= 0.022; 

dtmem_orig = [.046; .015]./1.5; 
dtmem = dtmem_orig;
%dtmeminh = dtmem_orig; %%%%may have a synaptic gain for inh and leak unchanged
dtamp= dtmem_orig;

for repetition =1:repNO 
    % create 2 layers with 6 nodes per layer
    mem=zeros(2,6); % membrane potential
    amp=ones(2,6); % spike amplitude %%%%this is really the available neural resources
    out=zeros(2,6); % output
    
    % creat full connection from layer1 to layer2
    %%%%first 3 units nearby, last 3 units far away
    adjw = 0.22;
    farw = 0;
    cw1to2 = [1 adjw adjw farw farw farw;
        adjw 1 adjw farw farw farw;
        adjw adjw 1 farw farw farw;
        farw farw farw 1 adjw adjw;
        farw farw farw adjw 1 adjw;
        farw farw farw adjw adjw 1];

    cw2to1 = zeros(6,6);
    
    for t=1:2000
        
        % put spike amplitude (available resouces) and syanptic output into a results matrix
        % the order goes 1-6 in layer1 then 1-6 for layer2, ....
        amp_t(t,:,repetition)=reshape(amp',12,1);
        mem_t(t,:,repetition)=reshape(mem',12,1);
        out_t(t,:,repetition)=reshape(out',12,1);
        
        % establish excitatory inputs to layer 1
        %%%%clear input of ba-da continuum
        if t<=audi_present_time_consonant
            exc(1,:)=[input_bada_first100(repetition,:),zeros(1,4)]; %%%%assign input accordingly consonants
        elseif t>audi_present_time_consonant && t<=audi_present_time_vowel
            exc(1,:)=[input_bada_101to300(repetition,:),zeros(1,4)]; %%%%assign input accordingly vowel
        else %%%%no sound presented after audi_present_time
            exc(1,:) = zeros(1,6);
        end
        
        % inlcude one-to-two mapping for feedback to layer 1
        % no feedback, as the value sets to zero
        exc(1,:)=exc(1,:)+feedback.*out(2,:)*cw2to1;
        
        % one-to-many mapping (full) from layer 1 to 2
        exc(2,:)=out(1,:)*cw1to2;
        
        % calculate inhibition at each layer
        % this assumes self and lateral inhibition
        inh=sum(out,2);

        % update membrane potential for each layer
        for layer=1:2      
            mem(layer,:)=mem(layer,:) + (dtmem(layer,:).* (  ((VErev - mem(layer,:)).*exc(layer,:))   +  (leak.*(VLrev-mem(layer,:)))  +  (inhibit.*inh(layer,:)*(VIrev-mem(layer,:)))  ));
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
        exc_t(t,:,repetition)=reshape(exc',12,1);
    end
end

%%%%plot output of layer 2 for ba and da 
for i = 1:repNO
figure(i);
plot(out_t(1:1000,7,i),'r','LineWidth',3)
hold on; 
plot(out_t(1:1000,8,i),'k','LineWidth',3)
end

save('out_t_ba_da_cont_before_IMG_adap','out_t','input_bada_first100','input_bada_101to300');
fprintf('done');