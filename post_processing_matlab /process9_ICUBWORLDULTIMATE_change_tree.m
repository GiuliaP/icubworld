%%
FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%

days_tobeprocessed = 3:8;

in_root_path = '/media/giulia/DATA/iCubWorldUltimate_centroid256_disp';
out_root_path = '/media/giulia/MyPassport/iCubWorldUltimate_centroid256_disp_finaltree';

src_tree = [];
days = [];

for dd=days_tobeprocessed
    
    feat = Features.GenericFeature();
    feat.assign_registry_and_tree_from_folder(fullfile(in_root_path, ['day' num2str(dd)]), [], [], [], []);
    [src_tree_curr, ~, ~] = cellfun(@fileparts, feat.Registry, 'UniformOutput', 0);
    src_tree_curr = unique(src_tree_curr);
    [src_tree_curr, ~, ~] = cellfun(@fileparts, src_tree_curr, 'UniformOutput', 0);
    src_tree_curr = unique(src_tree_curr);
    src_tree_curr(cellfun(@isempty, src_tree_curr)) = [];
    
    days_curr = repmat({['day' num2str(dd)]}, length(src_tree_curr), 1);
    
    days = [days; days_curr];
    src_tree = [src_tree; src_tree_curr];
    
end

categN_transf = cellfun(@(s) strsplit(s, '_'), src_tree, 'UniformOutput', 0);

categN = cellfun(@(s) s{1}, categN_transf, 'UniformOutput', 0);
transf = cellfun(@(s) s{2}, categN_transf, 'UniformOutput', 0);

categ = cellfun(@(x,n) x(1:(n-1)), categN, num2cell(cellfun(@(x) x(1), regexp(categN, '\d'))), 'UniformOutput', false);
N = cellfun(@(x,n) x(n:end), categN, num2cell(cellfun(@(x) x(1), regexp(categN, '\d'))), 'UniformOutput', false);
transf = cellfun(@(s) s{2}, categN_transf, 'UniformOutput', 0);

categ(strcmp(categ, 'pinza')) = repmat({'hairclip'}, sum(strcmp(categ, 'pinza')), 1);
categ(strcmp(categ, 'binder')) = repmat({'ringbinder'}, sum(strcmp(categ, 'binder')), 1);
categ(strcmp(categ, 'brush')) = repmat({'hairbrush'}, sum(strcmp(categ, 'brush')), 1);
categ(strcmp(categ, 'case')) = repmat({'pencilcase'}, sum(strcmp(categ, 'case')), 1);
categ(strcmp(categ, 'cell')) = repmat({'cellphone'}, sum(strcmp(categ, 'cell')), 1);
categ(strcmp(categ, 'dispenser')) = repmat({'soapdispenser'}, sum(strcmp(categ, 'dispenser')), 1);

categN = strcat(categ, N);

transf(strcmp(transf, '2DROT')) = repmat({'ROT2D'}, sum(strcmp(transf, '2DROT')), 1);
transf(strcmp(transf, '3DROT')) = repmat({'ROT3D'}, sum(strcmp(transf, '3DROT')), 1);

src_tree = cellfun(@fullfile, days, src_tree, 'UniformOutput', false);
dst_tree = cellfun(@fullfile, categ, categN, transf, days, 'UniformOutput', false);

feat = Features.GenericFeature();
feat.assign_registry_and_tree_from_cellarray(dst_tree, [], []);
feat.reproduce_tree(out_root_path);
% if the output folder tree didn't exist, then the fcn 'reprodue_tree' 
% creates all the folders but the ones in the level prior to the very last one
% (i.e., it does not create the 'days' folders)
% but  is good, because, later on, in the for cycle, if the dst directory 
% is not existing, it is created, and the content of the src directory 
% is moved inside it (otherwise, the src directory is moved inside dst,
% but this is not what we want!
% the conclusion is that in order for the script to work
% the dst_tree should be existing!

for dd=1:length(src_tree)
    
    src = fullfile(in_root_path, src_tree{dd});
    dst = fullfile(out_root_path, dst_tree{dd});
    
    if exist(src, 'dir')
        
        if ~exist(dst, 'dir')
            copyfile(src, dst);
        else
            %confirmation = input(['Replace ' dst ' (y/n) ?'], 's');
            
            %if strcmpi(confirmation,'y')
                rmdir(dst, 's');
                copyfile(src, dst);
            %else
            %    disp([dst ' not replaced.']);
            %end
            
        end
        
    else
        disp([src ' not found.']);
    end
    
    disp(dst);
    disp(dd);
end