%%

FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%

for ddd=3:8
    
    day = ddd;
    
    in_root_path = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg', ['day' num2str(day)]);
    out_root_path = fullfile('/media/giulia/DATA/iCubWorldUltimate_bb30_disp', ['day' num2str(day)]);
    
    feat = Features.GenericFeature();
    feat.assign_registry_and_tree_from_folder(in_root_path, [], [], [], []);
    
    % keep only the paths and the extensions of the files...
    [img_paths, ~, img_exts] = cellfun(@fileparts, feat.Registry, 'UniformOutput', 0);
    clear feat
    % ...to select only the registries, and keep only their paths
    % indeed their name is known to be 'img_info.txt'
    reg_files_path = img_paths(strcmp(img_exts, '.txt'));
    clear img_paths img_exts
    
    % we do not need to keep also the left/right inner folders
    [reg_files_path, ~, ~] = cellfun(@fileparts, reg_files_path, 'UniformOutput', 0);
    reg_files_path = unique(reg_files_path, 'stable');
    reg_files_path(cellfun(@isempty, reg_files_path)) = [];
    
    % now the path to a registry is:
    % fullfile(reg_files_path{ii}, 'left' or 'right', 'img_info.txt')
    
    %%
    
    time_window = 10;
    
    colsR = [5 1:4];
    colsL = [10 1:9];
    
    for ff=1:length(reg_files_path)
        
        fidL = fopen(fullfile(in_root_path, reg_files_path{ff}, 'left', 'img_info.txt'));
        fidR = fopen(fullfile(in_root_path, reg_files_path{ff}, 'right', 'img_info.txt'));
        
        img_infoL = textscan(fidL, '%s %f %f %d %d %d %d %d %d %d');
        img_infoR = textscan(fidR, '%s %f %f %d %d');
        
        fclose(fidL);
        fclose(fidR);
        
        % move img name at last because the fcn expects timestamps to be first
        img_infoL{end+1} = img_infoL{1};
        img_infoR{end+1} = img_infoR{1};
        img_infoL(1) = [];
        img_infoR(1) = [];
        
        % now img_info contains:
        % for left
        % (img_t, bb_t, bb_cx, bb_cy, bb_pxN, bb_tlx, bb_tly, bb_w, bb_h, img_path)
        % for right
        % (img_t, bb_t, bb_cx, bb_cy, img_path)
        
        img_info_R2L = synch_img_info(img_infoR, colsR, img_infoL, colsL, time_window, 0);
        
        % and now img_info contains:
        % (imgR_path, imgR_t, bbR_t, bbR_cx, bbR_cy, imgL_path, imgL_t, bbL_t, bbL_cx, bbL_cy, bbL_pxN, bbL_tlx, bbL_tly, bbL_w, bbL_h)
        
        fidLR = fopen(fullfile(out_root_path, reg_files_path{ff}, 'img_info_LR.txt'), 'w');
        
        for ii=1:length(img_info_R2L{1})
            fprintf(fidLR, '%s %.6f %.6f %d %d %s %.6f %.6f %d %d %d %d %d %d %d\n', ...
                img_info_R2L{1}{ii}, img_info_R2L{2}(ii), img_info_R2L{3}(ii), ...
                img_info_R2L{4}(ii), img_info_R2L{5}(ii), img_info_R2L{6}{ii}, ...
                img_info_R2L{7}(ii), img_info_R2L{8}(ii), img_info_R2L{9}(ii), ...
                img_info_R2L{10}(ii), img_info_R2L{11}(ii), img_info_R2L{12}(ii), ...
                img_info_R2L{13}(ii), img_info_R2L{14}(ii), img_info_R2L{15}(ii));
        end
        
        fclose(fidLR);
    end
    
    disp(['day = ' num2str(day)]);
end