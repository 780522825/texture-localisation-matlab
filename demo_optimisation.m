%% Simple single feature, multiple view scenario

f_glob = [1; 1];
f_loc{1} = [1; 0];
H{1} = eye(3);
f_loc{2} = [1; -1];
H{2} = [cos(pi/3) -sin(pi/3) 0; sin(pi/3) cos(pi/3) 0; 0 0 1];

numLocalFeats = length(f_loc);
numIterations = 5;
locfeats = cell(1, numLocalFeats);

for i = 1:numIterations
    subplot(1,numIterations,i)
    plot(f_glob(1), f_glob(2), 'rx'); hold on
    [f_glob, H] = optimise_many_features(f_glob, f_loc, H);
    
    for j = 1:numLocalFeats
    locfeat = H{j} * [f_loc{j}; 1];
    locfeat = locfeat(1:2)/locfeat(3);
    plot(locfeat(1), locfeat(2), 'bx');
        if isequal(i, numIterations)
            locfeats{j} = locfeat;
        end
    end
end

%% Real application
clear
load('/Users/jai/Documents/MATLAB/4yp/test_images/loop_resized/etc/index.mat')
load('/Users/jai/Documents/MATLAB/4yp/test_images/loop_resized/etc/cor_ba.mat')
load('/Users/jai/Documents/MATLAB/4yp/test_images/loop_resized/etc/world_ba.mat')

%% Make a sample world and cor struct
% Some basic cases first:
% e.g. only move global features, only adjust H etc.
%% Global feature bundle adjustment
numIters = 50;
cor3 = cor; world2 = world;
figure; plot_features(world2);
figure; plot3d_poses(index, cor3, world2, 'showMosaic', true);
for i = 1:numIters
    [world2, cor3] = bundle_adjustment_world(world2, cor3, 'perspDistPenalty', 1, ...
        'onlyOptimiseH', false, 'weighted', false, 'constrainScale', false);
end
world2 = update_world(world2, cor3);
figure; plot_features(world2);
figure; plot3d_poses(index, cor3, world2, 'showMosaic', true);
%% Local feature bundle adjustment
numIters = 1;
for i = 1:numIters
    [world, cor] = bundle_adjustment_local(world, cor, 'perspDistPenalty', 0, ...
        'onlyOptimiseH', false, 'imsToInclude', []);
end
%% Update world
world = update_world(world, cor);
%%
figure;
% plot_feature_matches(world, cor);
plot_everything(index, world, cor, 'showFeatures', true,  ...
    'matchesOnly', true, 'showImgBorders', true, 'showMosaic', true)