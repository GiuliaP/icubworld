%%

FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%

for ddd=3:8
    
    day = ddd;
    
    in_root_path = fullfile('/Users/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg', ['day' num2str(day)]);
    
    %%
    
    out_root_path_bb_disp = fullfile('/media/giulia/DATA/iCubWorldUltimate_bb_disp', ['day' num2str(day)]);
    out_root_path_centroid_disp = fullfile('/media/giulia/DATA/iCubWorldUltimate_centroid_disp', ['day' num2str(day)]);
    
    box_radius = 127; % half side of the bounding box
    % e.g. 191 to crop 2x191+1+1 = 384 squared images
    % e.g. 127 to crop 2x127+1+1 = 256 squared images
    % e.g. 63 to crop 2x63+1+1 = 128 squared images
    % e.g. 31 to crop 2x31+1+1 = 64 squared images
    
    widthc = 2*box_radius+1;
    heightc = 2*box_radius+1;
    
    width = 2*box_radius+1;
    height = 2*box_radius+1;
    
    disp_bb_margin = 10;
    
    tic
    %%
    
    feat = Features.GenericFeature();
    feat.assign_registry_and_tree_from_folder(in_root_path, {'left'}, [], [], []);
    
    feat.reproduce_tree(out_root_path_bb_disp);
    feat.reproduce_tree(out_root_path_centroid_disp);
    
    [img_paths, ~, img_exts] = cellfun(@fileparts, feat.Registry, 'UniformOutput', 0);
    
    reg_files = feat.Registry(strcmp(img_exts, '.txt'));
    reg_files_path = img_paths(strcmp(img_exts, '.txt'));
    
    feat.Registry(strcmp(img_exts, '.txt')) = [];
    img_paths(strcmp(img_exts, '.txt')) = [];
    
    change_dir = [1; ~strcmp(img_paths(1:(end-1)), img_paths(2:end))];
    
    %figure(1);
    %figure(2);
    
    tic
    
    for ii=1:length(feat.Registry)
        
        if change_dir(ii)
            regfile_current = reg_files{strcmp(reg_files_path, img_paths{ii})};
            fid = fopen(fullfile(in_root_path, regfile_current));
            % as the camera is 'left'
            img_info = textscan(fid, '%s %f %f %d %d %d %d %d %d %d');
            fclose(fid);
            
            img_counter = 1;
            
            copyfile(fullfile(in_root_path, regfile_current), fullfile(out_root_path_bb_disp, regfile_current));
            copyfile(fullfile(in_root_path, regfile_current), fullfile(out_root_path_centroid_disp, regfile_current));
        end
        
        I = imread(fullfile(in_root_path, feat.Registry{ii}));
        
        xc = img_info{4}(img_counter);
        yc = img_info{5}(img_counter);
        
        %     radius = min(box_radius,xc-1);
        %     radius = min(radius,yc-1);
        %     radius = min(radius,size(I,2)-xc);
        %     radius = min(radius,size(I,1)-yc);
        
        if img_info{7}(img_counter)==0 && img_info{8}(img_counter)==0 && img_info{9}(img_counter)==0 && img_info{10}(img_counter)==0
            
            xmin = xc - (width-1)/2;
            ymin = yc - (height-1)/2;
            
        else
            
            xmin = img_info{7}(img_counter);
            ymin = img_info{8}(img_counter);
            
            width = img_info{9}(img_counter);
            height = img_info{10}(img_counter);
            
            xmin = xmin - disp_bb_margin;
            ymin = ymin - disp_bb_margin;
            width = width + 2*disp_bb_margin;
            height = height + 2*disp_bb_margin;
            
        end
        
        I2 = imcrop(I, [xmin ymin width height]);
        
        %     if radius>10
        %
        %         radius2 = radius*2+1;
        %
        %         xminc = xc - radius;
        %         yminc = yc - radius;
        %         widthc = radius2;
        %         heightc = radius2;
        %
        %     else
        %
        %         disp(['SKIPPED: ' feat.Registry{ii} '.']);
        %
        %     end
        
        xminc = xc - box_radius;
        yminc = yc - box_radius;
        
        I3 = imcrop(I, [xminc yminc widthc heightc]);
        
        imwrite(I2, fullfile(out_root_path_bb_disp, feat.Registry{ii}));
        imwrite(I3, fullfile(out_root_path_centroid_disp, feat.Registry{ii}));
        
        %figure(1), imshow(I2);
        %figure(2), imshow(I3);
        
        img_counter = img_counter + 1;
        
        if  mod(ii,500)==0
            disp([num2str(ii) '/' num2str(length(feat.Registry))]);
            toc
            tic
        end
    end
    
    disp(['day = ' num2str(day)]);
end