%%

FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%% choose params

Ncat_xDay = 5;
Nobj_xCat = 10;

day1 = 5;
day2 = day1+1;

root_path1 = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg',  ['day' num2str(day1)]);
root_path2 = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg',  ['day' num2str(day2)]);

transf = 'SCALE';

camera = 'left';

fidx1 = 1;
fidx2 = 1;
            
%% check labels

feat1 = Features.GenericFeature();
feat1.assign_registry_and_tree_from_folder(root_path1, [], [], [], []);
reg_withno_fnames1 = cellfun(@fileparts, feat1.Registry, 'UniformOutput', 0);

objs_transf1 = unique(reg_withno_fnames1);
objs_transf1 = cellfun(@(s) strsplit(s, '/'), objs_transf1, 'UniformOutput', 0);
objs_transf1 = cellfun(@(s) s{1}, objs_transf1, 'UniformOutput', 0);
objs_transf1 = unique(objs_transf1);

objs1 = cellfun(@(s) strsplit(s, '_'), objs_transf1, 'UniformOutput', 0);
objs1 = cellfun(@(s) s{1}, objs1, 'UniformOutput', 0);
objs1 = unique(objs1);

feat2 = Features.GenericFeature();
feat2.assign_registry_and_tree_from_folder(root_path2, [], [], [], []);
reg_withno_fnames2 = cellfun(@fileparts, feat2.Registry, 'UniformOutput', 0);

objs_transf2 = unique(reg_withno_fnames2);
objs_transf2 = cellfun(@(s) strsplit(s, '/'), objs_transf2, 'UniformOutput', 0);
objs_transf2 = cellfun(@(s) s{1}, objs_transf2, 'UniformOutput', 0);
objs_transf2 = unique(objs_transf2);

objs2 = cellfun(@(s) strsplit(s, '_'), objs_transf2, 'UniformOutput', 0);
objs2 = cellfun(@(s) s{1}, objs2, 'UniformOutput', 0);
objs2 = unique(objs2);

% visualize

if length(objs1)~=length(objs2) 
    error('Different number of directories in the two days!');
elseif sum(strcmp(objs1, objs2))<length(objs1)
    disp(strcat(objs1(~strcmp(objs1, objs2)), repmat({' '}, length(objs1), 1), objs2(~strcmp(objs1, objs2))));
    error('These directories are different!');
else
    
    for cc=1:Ncat_xDay
        
        scrsz = get(groot,'ScreenSize');
        figure('Position',[1 scrsz(4)/2 scrsz(3) scrsz(4)/2])

        for oo=1:Nobj_xCat
            
            fname1 = feat1.Registry(strcmp(reg_withno_fnames1, fullfile([objs1{(cc-1)*Nobj_xCat+oo} '_' transf], camera)));
            fname2 = feat2.Registry(strcmp(reg_withno_fnames2, fullfile([objs2{(cc-1)*Nobj_xCat+oo} '_' transf], camera)));
            
            I1 = imread(fullfile(root_path1, fname1{fidx1}));
            I2 = imread(fullfile(root_path2, fname2{fidx2}));
            
            subplot(2, Nobj_xCat, oo)
            imagesc(I1);
            title(objs1((cc-1)*Nobj_xCat+oo));
            
            subplot(2, Nobj_xCat, oo+Nobj_xCat)
            imagesc(I2);
            title(objs2((cc-1)*Nobj_xCat+oo));
            
        end
        
    end
end

%% correct wrong labels

correction = struct('category', {}, 'flips', {});

% % day 7 e 8
% correction(1).category = 'flower';
% correction(1).flips = [6 7; 7 6];
% correction(2).category = 'glass';
% correction(2).flips = [8 10; 10 8; 4 5; 5 4; 6 7; 7 6];

% day 5 e 6
correction(1).category = 'brush';
correction(1).flips = [9 7; 7 9];
correction(2).category = 'perfume';
correction(2).flips = [4 1; 1 4; 10 8; 8 10; 5 7; 7 5];
correction(3).category = 'mug';
correction(3).flips = [2 1; 1 2; 10 9; 9 10; 5 6; 6 5];

for cc=1:length(correction)
    
    for oo=1:size(correction(cc).flips,1)
        
        idxs_src = find(~cellfun(@isempty,regexp(objs_transf2, ['^' correction(cc).category num2str(correction(cc).flips(oo,1)) '_'])));
        
        for dd=1:length(idxs_src)
            src = fullfile(root_path2, objs_transf2{idxs_src(dd)});
            dst = fullfile(root_path2, [objs_transf2{idxs_src(dd)} '_tmp']);
            if ~exist(dst, 'dir')
                movefile(src, dst);
            else
                error(['The directory: ' dst ' already exist!']);
            end
        end
        
    end
    
    for oo=1:size(correction(cc).flips,1)
        
         idxs_src = find(~cellfun(@isempty,regexp(objs_transf2, ['^' correction(cc).category num2str(correction(cc).flips(oo,1)) '_'])));
         idxs_dst = find(~cellfun(@isempty,regexp(objs_transf2, ['^' correction(cc).category num2str(correction(cc).flips(oo,2)) '_'])));
         
         for dd=1:length(idxs_src)
             src = fullfile(root_path2, [objs_transf2{idxs_src(dd)} '_tmp']);
             dst = fullfile(root_path2, objs_transf2{idxs_dst(dd)});
             if ~exist(dst, 'dir')
                 movefile(src, dst);
             else
                 error(['The directory: ' dst ' already exist!']);
             end
         end
    
    end
       
end

%% check that are corrected

feat1 = Features.GenericFeature();
feat1.assign_registry_and_tree_from_folder(root_path1, [], [], [], []);
reg_withno_fnames1 = cellfun(@fileparts, feat1.Registry, 'UniformOutput', 0);

objs_transf1 = unique(reg_withno_fnames1);
objs_transf1 = cellfun(@(s) strsplit(s, '/'), objs_transf1, 'UniformOutput', 0);
objs_transf1 = cellfun(@(s) s{1}, objs_transf1, 'UniformOutput', 0);
objs_transf1 = unique(objs_transf1);

objs1 = cellfun(@(s) strsplit(s, '_'), objs_transf1, 'UniformOutput', 0);
objs1 = cellfun(@(s) s{1}, objs1, 'UniformOutput', 0);
objs1 = unique(objs1);

feat2 = Features.GenericFeature();
feat2.assign_registry_and_tree_from_folder(root_path2, [], [], [], []);
reg_withno_fnames2 = cellfun(@fileparts, feat2.Registry, 'UniformOutput', 0);

objs_transf2 = unique(reg_withno_fnames2);
objs_transf2 = cellfun(@(s) strsplit(s, '/'), objs_transf2, 'UniformOutput', 0);
objs_transf2 = cellfun(@(s) s{1}, objs_transf2, 'UniformOutput', 0);
objs_transf2 = unique(objs_transf2);

objs2 = cellfun(@(s) strsplit(s, '_'), objs_transf2, 'UniformOutput', 0);
objs2 = cellfun(@(s) s{1}, objs2, 'UniformOutput', 0);
objs2 = unique(objs2);

% visualize

if length(objs1)~=length(objs2) 
    error('Different number of directories in the two days!');
elseif sum(strcmp(objs1, objs2))<length(objs1)
    disp(strcat(objs1(~strcmp(objs1, objs2)), repmat({' '}, length(objs1), 1), objs2(~strcmp(objs1, objs2))));
    error('These directories are different!');
else
    
    for cc=1:Ncat_xDay
        
        scrsz = get(groot,'ScreenSize');
        figure('Position',[1 scrsz(4)/2 scrsz(3) scrsz(4)/2])

        for oo=1:Nobj_xCat
            
            fname1 = feat1.Registry(strcmp(reg_withno_fnames1, fullfile([objs1{(cc-1)*Nobj_xCat+oo} '_' transf], camera)));
            fname2 = feat2.Registry(strcmp(reg_withno_fnames2, fullfile([objs2{(cc-1)*Nobj_xCat+oo} '_' transf], camera)));
            
            I1 = imread(fullfile(root_path1, fname1{fidx1}));
            I2 = imread(fullfile(root_path2, fname2{fidx2}));
            
            subplot(2, Nobj_xCat, oo)
            imagesc(I1);
            title(objs1((cc-1)*Nobj_xCat+oo));
            
            subplot(2, Nobj_xCat, oo+Nobj_xCat)
            imagesc(I2);
            title(objs2((cc-1)*Nobj_xCat+oo));
            
        end
        
    end
end