%%
FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%

day = 5;
camera = {'right'}; % or [] or {'left'} or {'right'}

in_root_path = fullfile('/media/giulia/MyPassport/ICUBWORLD_ULTIMATE_folderized_png',  ['day' num2str(day)]);
%out_root_path = fullfile('/media/giulia/MyPassport/ICUBWORLD_ULTIMATE_BB_disp',  ['day' num2str(day)]);
out_root_path = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_temporary', ['day' num2str(day)]);

convert_images = 0;
copy_registries = 1;

%%

feat = Features.GenericFeature();
feat.assign_registry_and_tree_from_folder(in_root_path, camera, [], [], []);

[~, ~, fexts] = cellfun(@fileparts, feat.Registry, 'UniformOutput', 0);

check_output_dir(out_root_path);
feat.reproduce_tree(out_root_path);

if convert_images
    
    in_ext = '.png';
    out_ext = '.jpg';
    imlist = feat.Registry(strcmp(fexts, in_ext));
    for ii=1:length(imlist)
        I = imread(fullfile(in_root_path, imlist{ii}));
        imwrite(I, [fullfile(out_root_path, imlist{ii}(1:(end-4))) out_ext]);
        disp([num2str(ii) '/' num2str(length(imlist))]);
    end
    
end

if copy_registries
    
    reglist = feat.Registry(strcmp(fexts, '.txt'));
    for ii=1:length(reglist)
        copyfile(fullfile(in_root_path, reglist{ii}), fullfile(out_root_path, reglist{ii}));
        disp([num2str(ii) '/' num2str(length(reglist))]);
    end
    
end