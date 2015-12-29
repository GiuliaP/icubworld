%%
FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%

day = 4;
root_path = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg',  ['day' num2str(day)]);

feat = Features.GenericFeature();
feat.assign_registry_and_tree_from_folder(root_path, [], [], [], []);

fdirs = cellfun(@fileparts, feat.Registry, 'UniformOutput', 0);
fdirs = unique(fdirs);
fdirs = cellfun(@(s) strsplit(s, '/'), fdirs, 'UniformOutput', 0);
fdirs = [fdirs{:}];
fdirs = fdirs(1:2:end)';
fdirs = unique(fdirs);

fdirs_new = regexprep(fdirs, '^glass\d', 'sunglasses');

for dd=1:length(fdirs)
    if ~strcmp(fdirs{dd}, fdirs_new{dd})
        if ~exist(fullfile(root_path, fdirs_new{dd}), 'dir')
            movefile(fullfile(root_path, fdirs{dd}), fullfile(root_path, fdirs_new{dd}));
        else
            error(['The directory: ' fullfile(root_path, fdirs_new{dd}) ' already exist!']);
        end
    end
end