%%
FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%

day = 5;
root_path = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_temporary',  ['day' num2str(day)]);

featL = Features.GenericFeature();
featL.assign_registry_and_tree_from_folder(fullfile(root_path, 'left'), [], [], [], []);

featR = Features.GenericFeature();
featR.assign_registry_and_tree_from_folder(fullfile(root_path, 'right'), [], [], [], []);

[fdirsL, fnamesL, fextsL] = cellfun(@fileparts, featL.Registry, 'UniformOutput', 0);
[fdirsR, fnamesR, fextsR] = cellfun(@fileparts, featR.Registry, 'UniformOutput', 0);

if sum(strcmp(unique(fdirsL), unique(fdirsR)))==length(unique(fdirsL))

    for ff=1:length(featL.Registry)
        srcL = fullfile(root_path, 'left');
        dstL = fullfile(root_path, fdirsL{ff}, 'left');
        if ~exist(dstL, 'dir')
            mkdir(dstL);
        end
        if exist(srcL, 'file')
            movefile(fullfile(srcL,  featL.Registry{ff}), fullfile(dstL, [fnamesL{ff}, fextsL{ff}]));
        else
            disp([srcL ' not found.']);
        end
        if mod(ff,500)==0
            disp([num2str(ff) '/' num2str(length(featL.Registry))]);
        end
    end
    disp(num2str(length(featL.Registry)));
    
    for ff=1:length(featR.Registry)
        srcR = fullfile(root_path, 'right');
        dstR = fullfile(root_path, fdirsR{ff}, 'right');
        if ~exist(dstR, 'dir')
            mkdir(dstR);
        end
        if exist(srcR, 'file')
            movefile(fullfile(srcR,  featR.Registry{ff}), fullfile(dstR, [fnamesR{ff}, fextsR{ff}]));
        else
            disp([srcR ' not found.']);
        end
        if mod(ff,500)==0
            disp([num2str(ff) '/' num2str(length(featR.Registry))]);
        end
    end
    disp(num2str(length(featR.Registry)));
    
    rmdir(fullfile(root_path, 'left'),'s');
    rmdir(fullfile(root_path, 'right'), 's');
else
    error('LEFT and RIGHT dirs do not correspond!');
    load gong.mat;
    sound(y);
end

load handel.mat;
sound(y);
