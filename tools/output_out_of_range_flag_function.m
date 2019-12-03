function [bio_sim]=output_out_of_range(bio_sim,bounding_box)
%% Creating output_thresholded_to_min/max_outpout flag
    f_idx=find(bio_sim(:,1)<bounding_box.Pmin & bio_sim(:,1)>=bounding_box.Pmin-bounding_box.Tolerance);
    bio_sim(f_idx,end+1)=1;
    bio_sim(f_idx,1)=bounding_box.Pmin;
    
    f_idx=find(bio_sim(:,1)>bounding_box.Pmax & bio_sim(:,1)<=bounding_box.Pmax+bounding_box.Tolerance);
    bio_sim(f_idx,end+1)=1;
    bio_sim(f_idx,1)=bounding_box.Pmax;  
    %% Creating output too low/high flag
    f_idx=find(bio_sim(:,1)<bounding_box.Pmin-bounding_box.Tolerance);
    bio_sim(f_idx,end+1)=1;

    f_idx=find(bio_sim(:,1)>bounding_box.Pmax+bounding_box.Tolerance);
    bio_sim(f_idx,end+1)=1;

    %% *********
    bio_sim(:,end+1)=sum([bio_sim(:,2:end).*(2.^[0:size(bio_sim,2)-2])]')';  
end