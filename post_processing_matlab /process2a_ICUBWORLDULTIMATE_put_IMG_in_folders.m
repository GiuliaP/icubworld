FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%
root_dir = '/media/giulia/DATA/ICUBWORLD_ULTIMATE';

%%

fifty_group = 4;
day = 8;
camera = 'right';

session_dir = fullfile(root_dir, ['ICUBWORLD_' num2str(fifty_group)], ['day' num2str(day)]);

out_dir = fullfile('/media/giulia/MyPassport/ICUBWORLD_ULTIMATE_folderized_png', ['day' num2str(day)], camera);

out_filext = '.png';

if exist(out_dir, 'dir')
   error('out_dir already existing!!!!!');
end
check_output_dir(out_dir);

% % output registry with updated img paths
% ofile_association = fullfile(out_dir, 'img_info.txt');
% ofid_association = fopen(ofile_association, 'w');

%%

dir_list = strsplit(ls(session_dir));
dir_list(end) = [];

for ii=1:length(dir_list)
    
    curr_dir = fullfile(session_dir, dir_list{ii});
    
    disp(curr_dir);
    
    % read
    
    file_association = fullfile(curr_dir, [camera '_img_info.txt']);
    fid_association = fopen(file_association);
    if strcmp(camera, 'left')
        t_img_info = textscan(fid_association, '%s %f %f %d %d %d %d %d %d %d');
    elseif strcmp(camera, 'right')
        t_img_info = textscan(fid_association, '%s %f %f %d %d');
    end
    fclose(fid_association);
    
    % make folders and move stuff
    
    for idx=1:length(t_img_info{1})
        
        [dirname, filename, filext] = fileparts(t_img_info{1}{idx});
        
        if strcmp(filename, 'skip')  
            %% append '_skipped' to all dirs in obj
            dirlist = dir(out_dir);
            dirlist_old = {dirlist.name}';
            dirlist_old = dirlist_old([dirlist.isdir]);
            dirlist_old = dirlist_old(~cellfun(@isempty,strfind(dirlist_old, '_')));
            dirlist_new = dirlist_old;
            dirlist_new(strncmp(dirlist_old, obj, length(obj))) = strcat(dirlist_old(strncmp(dirlist_old, obj, length(obj))), '_skipped');
            for dd=length(dirlist_old):-1:1
                if ~strcmp(dirlist_old{dd}, dirlist_new{dd})
                    movefile(fullfile(out_dir, dirlist_old{dd}), fullfile(out_dir, dirlist_new{dd}));
                end
            end
            
        else
           
            if idx==1 || ~strcmp(fileparts(t_img_info{1}{idx}), fileparts(t_img_info{1}{idx-1}))
                
                newdir = fullfile(out_dir, dirname);
                obj = strsplit(dirname, '_');
                transf = obj{2};
                obj = obj{1};
                
                if exist(newdir, 'dir')
                    while exist(newdir, 'dir')
                        newdir = [newdir '_redo'];
                    end
                end
                mkdir(newdir);
            end
            
            % copy file
            src = fullfile(curr_dir, 'imgs', camera, [filename filext]);
            dst = fullfile(newdir, [filename out_filext]);
            %movefile(src, dst);
            
            I = imread(src);
            imwrite(I, dst);
            delete(src);
            
            if mod(idx,500)==0 || idx==length(t_img_info{1})
                disp(idx);
            end
            
%             % update registry file
%             
%             if strcmp(camera, 'left')
%                 fprintf(ofid_association, '%s %.6f %.6f %d %d %d %d %d %d %d\n', fullfile(day, camera, dirname, [filename filext]), t_img_info{2}(idx), t_img_info{3}(idx), ...
%                     t_img_info{4}(idx), t_img_info{5}(idx), t_img_info{6}(idx), ...
%                     t_img_info{7}(idx), t_img_info{8}(idx), t_img_info{9}(idx), t_img_info{10}(idx));
%             elseif strcmp(camera, 'right')
%                 fprintf(ofid_association, '%s %.6f %.6f %d %d\n', fullfile(day, camera, dirname, [filename filext]), t_img_info{2}(idx), t_img_info{3}(idx), ...
%                     t_img_info{4}(idx), t_img_info{5}(idx));
%             end
    
        end
        
    end
    
end

%%

% fclose(ofid_association);
