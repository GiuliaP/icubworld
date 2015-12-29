%%

FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%

for ddd=3:8
    
    day = ddd;
    
    in_root_path = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg', ['day' num2str(day)]);
    
    %%
    
    out_root_path_centroid_disp = fullfile('/media/giulia/DATA/iCubWorldUltimate_centroid256_disp', ['day' num2str(day)]);
    
    box_radius = 127; % half side of the bounding box
    % e.g. 191 to crop 2x191+1+1 = 384 squared images
    % e.g. 127 to crop 2x127+1+1 = 256 squared images
    % e.g. 63 to crop 2x63+1+1 = 128 squared images
    % e.g. 31 to crop 2x31+1+1 = 64 squared images
    
    widthc = 2*box_radius+1;
    heightc = 2*box_radius+1;
    
    %%
    
    feat = Features.GenericFeature();
    feat.assign_registry_and_tree_from_folder(in_root_path, {'right'}, [], [], []);
    
    feat.reproduce_tree(out_root_path_centroid_disp);
    
    [img_paths, ~, img_exts] = cellfun(@fileparts, feat.Registry, 'UniformOutput', 0);
    
    reg_files = feat.Registry(strcmp(img_exts, '.txt'));
    reg_files_path = img_paths(strcmp(img_exts, '.txt'));
    
    feat.Registry(strcmp(img_exts, '.txt')) = [];
    img_paths(strcmp(img_exts, '.txt')) = [];
    
    change_dir = [1; ~strcmp(img_paths(1:(end-1)), img_paths(2:end))];
    
    %figure(1)
    
    tic
    
    for ii=1:length(feat.Registry)
        
        if change_dir(ii)
            regfile_current = reg_files{strcmp(reg_files_path, img_paths{ii})};
            fid = fopen(fullfile(in_root_path, regfile_current));
            img_info = textscan(fid, '%s %f %f %d %d'); % as the camera is 'right'
            fclose(fid);
            
            img_counter = 1;
            
            copyfile(fullfile(in_root_path, regfile_current), fullfile(out_root_path_centroid_disp, regfile_current));
        end
        
        I = imread(fullfile(in_root_path, feat.Registry{ii}));
        
        if ~(img_info{4}(img_counter)==0 && img_info{5}(img_counter)==0)
            
            xc = img_info{4}(img_counter);
            yc = img_info{5}(img_counter);
            
            xminc = xc - box_radius;
            yminc = yc - box_radius;
            
        else
            disp(['ATTENTION, 0 0: ' feat.Registry{ii} '.']);
        end
        
        %        radius = min(box_radius,xc-1);
        %        radius = min(radius,yc-1);
        %        radius = min(radius,size(I,2)-xc);
        %        radius = min(radius,size(I,1)-yc);
        %
        %        if radius>10
        %
        %           radius2 = radius*2+1;
        %
        %           xminc = xc - radius;
        %           yminc = yc - radius;
        %           widthc = radius2;
        %           heightc = radius2;
        %
        %        else
        %
        %           disp(['SKIPPED: ' feat.Registry{ii} '.']);
        %
        %        end
        
        I3 = imcrop(I, [xminc yminc widthc heightc]);
        
        %figure(1), imshow(I3);
        
        imwrite(I3, fullfile(out_root_path_centroid_disp, feat.Registry{ii}));
        
        img_counter = img_counter + 1;
        
        if  mod(ii,500)==0
            disp([num2str(ii) '/' num2str(length(feat.Registry))]);
            toc
            tic
        end
        
    end
    
    disp(['day = ' num2str(day)]);
end