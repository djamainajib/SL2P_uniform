function SL2P_uniform(varargin)

%% 1. Initialization
if ~ismember(nargin,[2,3]), disp({'!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!ERROR!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';'--usage : Matlab SL2P_uniform [input_path\] [S2 tiff data folder] [output_path\ (optional)]'});return; end;

addpath(genpath('.\tools'));


bio_vars={'LAI','FCOVER','FAPAR','LAI_Cab','LAI_Cw'};
BIO_VAR_bounding_box=importdata('aux_data\BIO_VAR_bounding_box.mat');

file_name=dir([varargin{1},varargin{2},'\S2*B3.tif']);
file_name=file_name(1).name(1:end-6);

if nargin==3,   out_path=[varargin{3},strrep(varargin{2},'L2A','L2B'),'_SL2P_uniform\'];
    else,out_path=[varargin{1},strrep(varargin{2},'L2A','L2B'),'_SL2P_uniform\'];
end;
if ~isfolder(out_path), mkdir (out_path); end;   
%% 2.1 Loading data........................................................
disp({'===============',file_name,'==============='});
disp({'--Loading data--------------------------------------'});
Input_NNT=[]; 
h = waitbar(0,'Loading data...');
for bb={'B3','B4','B5','B6','B7','B8A','B11','B12','view_zenith_mean','sun_zenith','view_azimuth_mean','sun_azimuth'}
    waitbar(size(Input_NNT,2)/11)
    file_name_band=[file_name,char(bb),'.tif'];
    [band,xb,yb,Ib] = geoimread([varargin{1},varargin{2},'\',file_name_band]);
    [r,c]=size(band);
    Input_NNT= [Input_NNT,double(reshape(band,r*c,1))]; 
end;
%% 2.2 Organizing input data for NNET (NNET_IN)
Input_NNT(:,end-1)=abs(Input_NNT(:,end-1)-Input_NNT(:,end));Input_NNT(:,end)=[];
Input_NNT(:,end-2:end)=cos(deg2rad(Input_NNT(:,end-2:end))); 
Input_NNT(:,1:end-3)=Input_NNT(:,1:end-3)/10000;
NNT_IN=[Input_NNT(:,end-2:end),Input_NNT(:,1:end-3)]';
close(h)

%% 3. Loading NET
h = waitbar(0,'Simulating vegetation variables...');
disp({'--Loading NNET--------------------------------------'});
NET=importdata('tools\aux_data\S2_SL2P_uniform_NET.mat');
NET_uncer=importdata('tools\aux_data\S2_SL2P_uniform_uncert_NET.mat');
%% 2.4 Computing input_flags 
input_flags=input_out_of_range_flag_function(Input_NNT(:,1:end-3),NET.Input_Convex_Hull,r,c);
%% 5. Simulating biophysical parameters (SL2P).....................................
disp({'--Simulating vegetation biophysical variables ------'});
NNT_OUT=[];
for ivar=1:length(bio_vars),
    waitbar(ivar/length(bio_vars))
    bio=bio_vars{ivar};
    bio_sim= NaN+Input_NNT(:,1);
    eval(['NET_ivar= NET.',bio,'.NET;']);
    bio_sim (:,1)= sim(NET_ivar, NNT_IN)';
    
    eval(['BOX=BIO_VAR_bounding_box.',bio,';']);
    bio_sim (:,2)=reshape(input_flags,r*c,1);
    bio_sim=output_out_of_range_flag_function(bio_sim,BOX);
    
    
    eval(['NET_u= NET_uncer.',bio,'.NET;']);
    bio_sim_uncer= sim(NET_u, NNT_IN)';  
    %% *********
    eval(['NNT_OUT.',lower(bio),'=reshape(bio_sim(:,1),r,c);']);
    eval(['NNT_OUT.',lower(bio),'_uncertainties=reshape(bio_sim_uncer(:,1),r,c);']);

    eval(['NNT_OUT.',lower(bio),'_input_out_of_range= reshape(bio_sim(:,2),r,c);']);
    eval(['NNT_OUT.',lower(bio),'_output_thresholded_to_min_outpout= reshape(bio_sim(:,3),r,c);']);
    eval(['NNT_OUT.',lower(bio),'_output_thresholded_to_max_outpout= reshape(bio_sim(:,4),r,c);']);
    eval(['NNT_OUT.',lower(bio),'_output_too_low= reshape(bio_sim(:,5),r,c);']);
    eval(['NNT_OUT.',lower(bio),'_output_too_high= reshape(bio_sim(:,6),r,c);']);
    eval(['NNT_OUT.',lower(bio),'_flags=reshape(bio_sim(:,7),r,c);']);   
    
    
    bbox=Ib.BoundingBox;
    utmzone=strsplit(Ib.GeoAsciiParamsTag,' ');
    utmzone=utmzone{6};utmzone=[utmzone(1:2),' ',utmzone(3)];
    [bbox(:,2),bbox(:,1)] = utm2deg(bbox(:,1),bbox(:,2),[utmzone;utmzone]);
    bit_depth=32;
    geotiffwrite([out_path,strrep(file_name,'L2A','L2B'),lower(bio),'.tif'], bbox, eval(['NNT_OUT.',lower(bio)]), bit_depth, Ib);
    geotiffwrite([out_path,strrep(file_name,'L2A','L2B'),lower(bio),'_uncertainties.tif'], bbox, eval(['NNT_OUT.',lower(bio),'_uncertainties']), bit_depth, Ib);
    geotiffwrite([out_path,strrep(file_name,'L2A','L2B'),lower(bio),'_flags.tif'], bbox, eval(['NNT_OUT.',lower(bio),'_flags']), bit_depth, Ib);
    waitbar(ivar/length(bio_vars))
end;
save([out_path,strrep(file_name(1:end-1),'L2A','L2B'),'.mat'],'NNT_OUT','-v7.3');
close(h)
end


