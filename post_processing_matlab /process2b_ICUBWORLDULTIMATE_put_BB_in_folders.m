FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%
root_dir = '/media/giulia/Elements/ICUBWORLD_ULTIMATE';

%%

fifty_group = 1;
day = 2;
camera = 'right';

session_dir = fullfile(root_dir, ['ICUBWORLD_' num2str(fifty_group)], ['day' num2str(day)]);

out_dir = fullfile('/media/giulia/MyPassport/ICUBWORLD_ULTIMATE_folderized_png', ['day' num2str(day)], camera);

out_filext = '.png';

%%

dir_list = strsplit(ls(session_dir));
dir_list(end) = [];

t_img_info = [];

for ii=1:length(dir_list)
    
    curr_dir = fullfile(session_dir, dir_list{ii});
    
    disp(curr_dir);
    
    % read
    
    file_association = fullfile(curr_dir, [camera '_img_info.txt']);
    fid_association = fopen(file_association);
    t_img_info_current = textscan(fid_association, '%s %*[^\n]', 'Delimiter', '/');
    fclose(fid_association);
    
    disp(length(t_img_info_current{1}));

    idxstart = length(t_img_info) + 1;
    
    t_img_info = [t_img_info; t_img_info_current{1}];
    clear t_img_info_current;
    
    flag = 0;
    
    % update paths based on the same algo used to put images into folders
    
    for idx=idxstart:length(t_img_info)
        
        dirname = t_img_info{idx};
       
        if strcmp(dirname, 'skip')  
            
            % append '_skipped' to all dirs previously listed in the registry
            t_img_info(strncmp(t_img_info(1:(idx-1)), obj, length(obj))) = strcat(t_img_info(strncmp(t_img_info(1:(idx-1)), obj, length(obj))), '_skipped');
            
        else
           
            if idx==idxstart || ~strcmp(t_img_info{idx}, t_img_info{idx-1})
                
                if flag==0
                    newdir = dirname;
                    obj = strsplit(dirname, '_');
                    obj = obj{1};

                    if sum(strcmp(t_img_info(1:(idx-1)), newdir))>0
                        counter = 0;
                        while strcmp(t_img_info(idx+counter),t_img_info(idx+1+counter))
                            counter = counter + 1;
                        end
                        flag = 1;
                        while sum(strcmp(t_img_info(1:(idx-1)), newdir))>0
                            newdir = [newdir '_redo'];
                        end
                    end
                else
                    counter = counter - 1;
                    if counter==0
                        flag=0;
                    end
                end
            end
            
            % update path
            t_img_info{idx} = newdir;
            
        end
        
    end
    
end

disp(length(t_img_info));

t_img_info(strcmp(t_img_info,'skip'))=[];

%% write the updated registry file

idxstart = 1;

for ii=1:length(dir_list)
    
    curr_dir = fullfile(session_dir, dir_list{ii});
    
    disp(curr_dir);
    
    % read
    
    file_association = fullfile(curr_dir, [camera '_img_info.txt']);
    fid_association = fopen(file_association);
    if strcmp(camera, 'left')
        t_img_info_current = textscan(fid_association, '%s %f %f %d %d %d %d %d %d %d');
    elseif strcmp(camera, 'right')
        t_img_info_current = textscan(fid_association, '%s %f %f %d %d');
    end
    fclose(fid_association);
    
     for cc=1:length(t_img_info_current)
         t_img_info_current{cc}(strcmp(t_img_info_current{1}, 'skip')) = [];
     end

    [~, filenames, filext] = cellfun(@fileparts, t_img_info_current{1}, 'UniformOutput', 0);
    t_img_info_current{1} = strcat(filenames, out_filext);
    
    % first iteration out of for cycle
    idx=1;
    ofile_association = fullfile(out_dir, t_img_info{idxstart+idx-1}, 'img_info.txt');
    ofid_association = fopen(ofile_association, 'w');
    
    if strcmp(camera, 'left')
        fprintf(ofid_association, '%s %.6f %.6f %d %d %d %d %d %d %d\n', t_img_info_current{1}{idx}, t_img_info_current{2}(idx), t_img_info_current{3}(idx), ...
            t_img_info_current{4}(idx), t_img_info_current{5}(idx), t_img_info_current{6}(idx), ...
            t_img_info_current{7}(idx), t_img_info_current{8}(idx), t_img_info_current{9}(idx), t_img_info_current{10}(idx));
    elseif strcmp(camera, 'right')
        fprintf(ofid_association, '%s %.6f %.6f %d %d\n', t_img_info_current{1}{idx}, t_img_info_current{2}(idx), t_img_info_current{3}(idx), ...
            t_img_info_current{4}(idx), t_img_info_current{5}(idx));
    end
        
    for idx=2:length(t_img_info_current{1})
        
        if ~strcmp(t_img_info(idxstart+idx-1),t_img_info(idxstart+idx-2))
            fclose(ofid_association);
            ofile_association = fullfile(out_dir, t_img_info{idxstart+idx-1}, 'img_info.txt');
            ofid_association = fopen(ofile_association, 'w');
        end
        
        if strcmp(camera, 'left')
            fprintf(ofid_association, '%s %.6f %.6f %d %d %d %d %d %d %d\n', t_img_info_current{1}{idx}, t_img_info_current{2}(idx), t_img_info_current{3}(idx), ...
                t_img_info_current{4}(idx), t_img_info_current{5}(idx), t_img_info_current{6}(idx), ...
                t_img_info_current{7}(idx), t_img_info_current{8}(idx), t_img_info_current{9}(idx), t_img_info_current{10}(idx));
        elseif strcmp(camera, 'right')
            fprintf(ofid_association, '%s %.6f %.6f %d %d\n', t_img_info_current{1}{idx}, t_img_info_current{2}(idx), t_img_info_current{3}(idx), ...
                t_img_info_current{4}(idx), t_img_info_current{5}(idx));
        end 

    end
    
     idxstart = idxstart + length(t_img_info_current{1});
     
end

fclose(fid_association);

%%

% ofile_folderlist = fullfile(out_dir, 'folder_list.txt');
% 
% folder_list = unique(t_img_info, 'stable');
% 
% ofid_folderlist = fopen(ofile_folderlist,'w');
% 
% for ff=1:length(folder_list)
%     fprintf(ofid_folderlist, '%s\n', folder_list{ff});
% end
% 
% fclose(ofid_folderlist);