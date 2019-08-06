function neural_output_after_IMG_adap
%using fitted parameters of gain modulation for AI or HI
%to derive neural output for generating prediction of 
%the behavioral experiemnt (modulation effects of imagery to the perception of /ba/-/da/ continum)

clear;
close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%using modulated gain of AI or HI to generate neural output separately
AI_HI_control = 1; %1 for AI; 2 for HI;

dtmemgainAI = 1.2002; 
dtmemsuppAI = 0.8991; 
dtmemgainHI = 1.1574; 
dtmemsuppHI = 1.0270; 
dtmem_attAI = 0.0009; 
dtmem_attHI = 0.0013; 

repNO =7; %%%%7 levels of ba-da continue
input_bada_first100 = [1 0; 
              0.833 0.167;
              0.667 0.333;
              0.5 0.5; 
              0.333 0.667;
              0.167 0.833;
              0 1];        
input_bada_101to300 = ones(7,2).*0.5;
audi_present_time_consonant = 100; 
audi_present_time_vowel = 300; %total duration

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
dtmeminh = dtmem_orig; 
dtamp= dtmem_orig;

       if AI_HI_control ==1            
            dtmem = dtmem_orig*ones(1,6);
            dtmem(2,1) = dtmem_orig(2,1).*dtmemgainAI; 
            dtmem(2,2) = dtmem_orig(2,1).*dtmemsuppAI; 
            dtmem(2,3) = dtmem_orig(2,1).*dtmemsuppAI;            
            dtmem = dtmem +dtmem_attAI;            
       else
            dtmem = dtmem_orig*ones(1,6);
            dtmem(2,1) = dtmem_orig(2,1).*dtmemgainHI;
            dtmem(2,2) = dtmem_orig(2,1).*dtmemsuppHI;
            dtmem(2,3) = dtmem_orig(2,1).*dtmemsuppHI;            
            dtmem = dtmem + dtmem_attHI;
        end

for repetition =1:repNO
    mem=zeros(2,6); 
    amp=ones(2,6); 
    out=zeros(2,6);

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
        amp_t(t,:,repetition)=reshape(amp',12,1);
        mem_t(t,:,repetition)=reshape(mem',12,1);
        out_t(t,:,repetition)=reshape(out',12,1);

        if t<=audi_present_time_consonant
            exc(1,:)=[input_bada_first100(repetition,:),zeros(1,4)]; 
elseif t>audi_present_time_consonant && t<=audi_present_time_vowel
            exc(1,:)=[input_bada_101to300(repetition,:),zeros(1,4)]; 
        else 
            exc(1,:) = zeros(1,6);
        end

        exc(1,:)=exc(1,:)+feedback.*out(2,:)*cw2to1;
        exc(2,:)=out(1,:)*cw1to2;
        inh=sum(out,2);
        
        for layer=1:2            
            mem(layer,:)=mem(layer,:) + (dtmem(layer,:).* (  ((VErev - mem(layer,:)).*exc(layer,:))   +  (leak.*(VLrev-mem(layer,:)))  +  (inhibit.*inh(layer,:)*(VIrev-mem(layer,:)))  ));
        end
       for layer=1:2
            amp(layer,:)=amp(layer,:)+(dtamp(layer).*  (  (recovery.*(1-amp(layer,:)))  -  (depletion.*out(layer,:))  ));
        end

        prob=zeros(2,6);
        prob((mem-thresh)>0)=mem((mem-thresh)>0)-thresh;
        out=amp.*prob; 
        exc_t(t,:,repetition)=reshape(exc',12,1);
    end
end

for i = 1:repNO
figure(i);
plot(out_t(:,7,i),'r','LineWidth',3)
hold on; 
plot(out_t(:,8,i),'k')
end

if AI_HI_control == 1
    save('out_t_ba_da_cont_after_IMG_adap_AI','out_t','input_bada_first100','input_bada_101to300');
else
    save('out_t_ba_da_cont_after_IMG_adap_HI','out_t','input_bada_first100','input_bada_101to300');
end
fprintf('done');