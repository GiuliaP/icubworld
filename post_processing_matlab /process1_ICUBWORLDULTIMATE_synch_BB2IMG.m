FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%
root_dir = '/media/giulia/Elements/ICUBWORLD_ULTIMATE';

%%
fifty_group = 'ICUBWORLD_1';
day = 'day2';

session_dir = fullfile(root_dir, fifty_group, day);

camera = 'left'; % left and right!

%%

dir_list = strsplit(ls(session_dir));
dir_list(end) = [];

for ii=1:length(dir_list)
    %% io paths
    
    dir_imgs = fullfile(session_dir, dir_list{ii}, 'imgs', camera);
    dir_imginfos = fullfile(session_dir, dir_list{ii}, 'imginfos', camera);
    
    file_imgs = fullfile(dir_imgs, 'data.log');
    file_infos = fullfile(dir_imginfos, 'data.log');
    
    file_association = fullfile(session_dir, dir_list{ii}, [camera '_img_info.txt']);

    %% read
    
    fid_imgs = fopen(file_imgs);
    fid_infos = fopen(file_infos);
    
    if ~strcmp(fifty_group, 'ICUBWORLD_1')
        t_imgs = textscan(fid_imgs, '%d %f %s %s');
        t_imgs(1) = [];
        t_imgs(end) = [];
    else
        t_imgs = textscan(fid_imgs, '%d %f %s');
        t_imgs(1) = [];
    end
    if strcmp(camera, 'left')
        t_infos = textscan(fid_infos, '%d %f %d %d %d %d %d %d %d %s', 'TreatAsEmpty', 'skip', 'EmptyValue', -1);
    elseif strcmp(camera, 'right')
        t_infos = textscan(fid_infos, '%d %f %d %d %s', 'TreatAsEmpty', 'skip', 'EmptyValue', -1);
    end
    t_infos(1) = [];
    
    fclose(fid_imgs);
    fclose(fid_infos);
    
    %% compute
    
    % store the skipping signals and clear info cell array
    skipping_idxs = find(t_infos{2}==-1);
    skipping_timestamps = t_infos{1}(skipping_idxs);
    for cc=1:length(t_infos)
        t_infos{cc}(skipping_idxs) = [];
    end

    % associate
    time_window = 30;
    cols_imgs = length(t_imgs):-1:1;
    cols_info = 1:length(t_infos);
    t_img_info = synch_img_info(t_imgs, cols_imgs, t_infos, cols_infos, time_window, 1);
    
    % now t_img_info contains:
    % for left
    % (img_name, img_t, bb_t, bb_cx, bb_cy, bb_pxN, bb_tlx, bb_tly, bb_w, bb_h, classname)
    % for right
    % (img_name, img_t, bb_t, bb_cx, bb_cy, classname)
    
    % clear from spurious images
    for ss=1:length(t_img_info)
        t_img_info{ss}(cellfun(@isempty, strfind(t_img_info{end}, '_'))) = [];
    end 

    % compute the skipping points
    if ~isempty(skipping_timestamps)
        skipping_idxs = zeros(length(skipping_timestamps),1);
        for ss=1:length(skipping_timestamps)
            [foo, skipping_idxs(ss)] = min(abs(t_img_info{3}-skipping_timestamps(ss)));
            if t_img_info{3}(skipping_idxs(ss))-skipping_timestamps(ss)>0
                skipping_idxs(ss) = skipping_idxs(ss) - 1;
            end
        end
    else
        skipping_idxs = [];
    end

    %% write
 
    fid_association = fopen(file_association,'w');
    if (fid_association==-1)
        error('Error!');
    end

    for idx_img=1:length(t_img_info{1})
        
        if strcmp(camera, 'left')
            fprintf(fid_association, '%s/%s %.6f %.6f %d %d %d %d %d %d %d\n', t_img_info{end}{idx_img}, t_img_info{1}{idx_img}, t_img_info{2}(idx_img), t_img_info{3}(idx_img), ...
                t_img_info{4}(idx_img), t_img_info{5}(idx_img), t_img_info{6}(idx_img), t_img_info{7}(idx_img), t_img_info{8}(idx_img), t_img_info{9}(idx_img), t_img_info{10}(idx_img));
        elseif strcmp(camera, 'right')
            fprintf(fid_association, '%s/%s %.6f %.6f %d %d\n', t_img_info{end}{idx_img}, t_img_info{1}{idx_img}, t_img_info{2}(idx_img), t_img_info{3}(idx_img), ...
                t_img_info{4}(idx_img), t_img_info{5}(idx_img));
        end
        
        if sum(skipping_idxs==idx_img)
            fprintf(fid_association, 'skip\n');
        end
        
    end
    
    fclose(fid_association);
    
end
