function world = update_features(world, cor, model, ...
    fGlobalID, imgID, fLocalID)
% Jai Juneja, www.jaijuneja.com
% University of Oxford
% 20/11/2013
% -------------------------------------------------------------------------
% 
% UPDATE_FEATURES
% world = update_features(world, cor, model, fGlobalID, imgID, fLocalID)
%
% Given a global feature fGlobalID and a local feature fLocalID in an image
% imgID to be added to the world, update the feature map, words and frames
% in the the world structure.
%
% Inputs:
%   - world:        World structure containing global features. Type 'help 
%                   build_world' for more info
%   - cor:          Correspondence structure containing links between
%                   different images. Type 'help build_correspondence' for
%                   more info
%   - model:        Index of images from visualindex. Type 'help
%                   visualindex_build' for more info
%   - fGlobalID:    Global ID of feature to be added (could be a new ID)
%   - imgID:        Image ID from which the feature is being added to the
%                   global map
%   - fLocalID:     Local ID of feature to be added from image imgID
%
% Outputs:
%   - world

% Insert the feature into the global map
world.feature_map(:, end+1) = ...
    [fGlobalID; imgID; fLocalID];

% Also update words in same way
world.words_local(:, end+1) = ...
    [fGlobalID; imgID; ...
    model.index.words{imgID}(fLocalID)];

if ~isempty(cor.H_to_world{imgID})
    % Transform local frames to global co-ordinate system
    global_frame = transform_frames(model.index.frames{imgID}(:,fLocalID), ...
        cor.H_to_world{imgID});
else
    global_frame = nan(6,1);
end

world.frames_local(:, end+1) = [  fGlobalID; imgID; ...
                               model.index.frames{imgID}(:,fLocalID) ];
                    
feat_pos = global_frame;

% If the feature is new
if isequal(fGlobalID, world.num_features+1)
    % Increment number of features in global map
    world.num_features = world.num_features + 1;
    
    % Add the new global feature
    world.features_global(:,end+1) = [fGlobalID; 1; feat_pos];
    world.feature_indices(1,end+1) = size(world.feature_map, 2);
    
    % Only update global words if feature is new
    world.words_global(:, end+1) = [fGlobalID; ...
        model.index.words{imgID}(fLocalID)];
    
    if isnan(feat_pos(1))
        % The feature's global co-ordinates are unknown - it cannot be mapped
        world.features_mappable(end+1) = false;
    else
        % The feature's global co-ords are known - yay!
        world.features_mappable(end+1) = true;
    end
    
elseif fGlobalID > world.num_features+1
    error('You cannot initialise a global feature that has ID greater than world.num_features + 1')
else
    % The feature has already been initialised
    numMatches = world.features_global(2,fGlobalID);

    % Increment the number of local features mapped to the global feature
    world.features_global(2,fGlobalID) = numMatches + 1;
    
    % If the previous position was unknown, we ONLY use the new info to
    % determine the global position
    feat_pos_before = world.features_global(3:end,fGlobalID);
    if isnan(feat_pos_before(1)) && ~isnan(feat_pos(1))
        world.features_global(3:end,fGlobalID) = feat_pos;
        % The global feature is now mappable
        world.features_mappable(fGlobalID) = true;
        
    % Else, we take linearly interpolate between the old an new positions
    % using a weighted average of the two
    elseif ~isnan(feat_pos_before(1))
        feat_pos_after = (feat_pos + numMatches * feat_pos_before) / ...
            (numMatches+1);
        % Update global feature position estimate
        world.features_global(3:end,fGlobalID) = feat_pos_after;
    end
    
    % Add latest index to the global feature
    world.feature_indices(numMatches+1,fGlobalID) = size(world.feature_map, 2);
end

end