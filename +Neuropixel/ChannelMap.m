classdef ChannelMap
% Author: Daniel J. O'Shea (2019)

    properties
        file 
        
        channelIdsMapped uint32
        connected logical
        shankInd
        xcoords
        ycoords
        zcoords
        
        syncChannelIndex uint32 % actual index in the AP bin file
        syncChannelId uint32 % arbitrary channel id, typically the same as index
    end
    
    properties(Dependent)
        syncInAPFile
        channelIds
        nChannels
        nChannelsMapped
        connectedChannels
        referenceChannels
        
        invertChannelsY % plot first channel at bottom? (if first channel has lower 
        
        yspacing
        xspacing
        zspacing
        
        xlim
        ylim
        zlim
    end
    
    methods
        function map = ChannelMap(fname)
            if isa(fname, 'Neuropixel.ChannelMap')
                map = fname;
                return;
            end
            
            d = load(fname);
            map.file = fname;
            map.channelIdsMapped = Neuropixel.Utils.makecol(d.chanMap);
            map.connected = Neuropixel.Utils.makecol(d.connected);
            map.shankInd = Neuropixel.Utils.makecol(d.shankInd);
            map.xcoords = Neuropixel.Utils.makecol(d.xcoords);
            map.ycoords = Neuropixel.Utils.makecol(d.ycoords);
            if isfield(d, 'zcoords')
                map.zcoords = Neuropixel.Utils.makecol(d.zcoords);
            else
                map.zcoords = zeros(size(map.ycoords), 'like', map.ycoords);
            end
            
            if isfield(d, 'syncChannelIndex')
                map.syncChannelIndex = uint32(d.syncChannelId);
            else
                map.syncChannelIndex = uint32(d.chanMap(end)+ 1);
            end
            if isfield(d, 'syncChannelId')
                map.syncChannelId = uint32(d.syncChannelId);
            else
                map.syncChannelId = map.syncChannelIndex;
            end
        end
        
        function tf = get.syncInAPFile(map)
            tf = ~isempty(map.syncChannelIndex);
        end
        
        function zcoords = get.zcoords(map)
            if isempty(map.zcoords)
                zcoords = zeros(size(map.ycoords), 'like', map.ycoords);
            else
                zcoords = map.zcoords;
            end
        end
        
        function v = get.channelIds(map)
            v = map.channelIdsMapped;
            if ~isempty(map.syncChannelIndex)
                v(map.syncChannelIndex) = map.syncChannelId;
            end
        end
        
        function nChannels = get.nChannelsMapped(map)
            nChannels = numel(map.channelIdsMapped);
        end
        
        function nChannels = get.nChannels(map)
            nChannels = numel(map.channelIds);
        end
            
        function sites = get.connectedChannels(map)
            sites = map.channelIds(map.connected);
        end
        
        function sites = get.referenceChannels(map)
            sites = setdiff(map.channelIdsMapped, map.connectedChannels);
        end
        
        function zspacing = get.zspacing(map)
            zs = sort(map.zcoords(map.connected));
            dzs = diff(zs);
            dzs = dzs(dzs > 0);
            zspacing = min(dzs);
        end
        
        function yspacing = get.yspacing(map)
            ys = sort(map.ycoords(map.connected));
            dys = diff(ys);
            dys = dys(dys > 0);
            yspacing = min(dys);
        end
        
        function xspacing = get.xspacing(map)
            xs = sort(map.xcoords(map.connected));
            dxs = diff(xs);
            dxs = dxs(dxs > 0);
            xspacing = min(dxs);
        end
        
        function ylim = get.ylim(map)
            ys = map.yspacing;
            ylim = [min(map.ycoords) - ys, max(map.ycoords) + ys];
        end
        
        function xlim = get.xlim(map)
            xs = map.yspacing;
            xlim = [min(map.xcoords) - xs, max(map.xcoords) + xs];
        end
        
        function zlim = get.zlim(map)
            zs = map.yspacing;
            zlim = [min(map.zcoords) - zs, maz(map.zcoords) + zs];
        end
        
        function tf = get.invertChannelsY(map)
            % bigger y coords are higher up on the probe. This is used when we want to plot stacked traces. If false, 
            % channel 1 belongs at the top (has largest y coord). If true, channel 1 belongs at the bottom (has smallest y coord)
            
            tf = map.ycoords(1) < map.ycoords(end);
        end
        
        function [channelInds, channelIds] = lookup_channelIds(map, channelIds)
             if islogical(channelIds)
                channelIds = map.channelIds(channelIds);
             end
            [tf, channelInds] = ismember(channelIds, map.channelIds);
            assert(all(tf), 'Some channel ids not found');
        end
        
        function closest_ids = getClosestChannels(map, nClosest, channel_ids, eligibleChannelIds)
            % channel_idx is is in 1:nChannels raw data indices
            % closest is numel(channel_idx) x nClosest
            
            if nargin < 3
                channel_ids = map.connectedChannels;
            end
            if nargin < 4
                eligibleChannelIds = map.connectedChannels;
            end
            
            eligibleChannelInds = map.lookup_channelIds(eligibleChannelIds);
                
            x = map.xcoords(eligibleChannelInds);
            y = map.ycoords(eligibleChannelInds);
            z = map.zcoords(eligibleChannelInds);
            N = numel(x);

            X = repmat(x, 1, N);
            Y = repmat(y, 1, N);
            Z = repmat(z, 1, N);

            % distance between all connected and non-connected channels
            distSq = (X - X').^2 + (Y - Y').^2 + (Z - Z').^2;
            distSq(logical(eye(N))) = Inf; % don't localize each channel to itself
            
            [tf, channel_inds] = ismember(channel_ids, eligibleChannelInds);
            assert(all(tf), 'Cannot localize non-connected channels or channels not in eligibleChannelIds');
            
            closest_ids = nan(numel(channel_inds), nClosest);
            for iC = 1:numel(channel_inds)
                [~, idxSort] = sort(distSq(channel_inds(iC), :), 'ascend');
                % idxSort will be in indices into eligible
                closest_ids(iC, :) = eligibleChannelIds(idxSort(1:nClosest));
            end
            
%             function idxFull = indicesIntoMaskToOriginalIndices(idxIntoMasked, mask)
%                 maskInds = find(mask);
%                 idxFull = maskInds(idxIntoMasked);
%             end
        end
        
        function plotRecordingSites(map, varargin)
            p = inputParser();
            p.addParameter('channel_ids', map.channelIdsMapped, @isvector);
            p.addParameter('goodChannels', [], @isvector);
            p.addParameter('badChannels', [], @isvector);
            
            p.addParameter('markerSize', 20, @isscalar);
            p.addParameter('showChannelLabels', false, @islogical);
            p.addParameter('labelArgs', {}, @iscell);
            
            p.addParameter('color_connected', [0.7 0.7 0.7], @(x) true);
            p.addParameter('color_bad', [1 0.7 0.7], @(x) true);
            p.addParameter('color_good', [0.7 1 0.7], @(x) true);
            p.addParameter('color_reference', [0.5 0.5 1], @(x) true);
            p.parse(varargin{:});
            
            [channelInds, channelIds] = map.lookup_channelIds(p.Results.channel_ids);
            xc = map.xcoords(channelInds);
            yc = map.ycoords(channelInds);
            
            is_connected = ismember(channelIds, map.connectedChannels);
            is_good = ismember(channelIds, p.Results.goodChannels);
            is_bad = ismember(channelIds, p.Results.badChannels);
            is_ref = ismember(channelIds, map.referenceChannels);
            cmap = zeros(numel(channelInds), 3);
            cmap(is_connected, :) = repmat(p.Results.color_connected, nnz(is_connected), 1);
            cmap(is_good, :) = repmat(p.Results.color_good, nnz(is_good), 1);
            cmap(is_bad, :) = repmat(p.Results.color_bad, nnz(is_bad), 1);
            cmap(is_ref, :) = repmat(p.Results.color_reference, nnz(is_ref), 1);
            
            channelTypes = strings(numel(channelInds), 1);
            channelTypes(is_connected) = "Connected";
            channelTypes(is_good) = "Good";
            channelTypes(is_bad) = "Bad";
            channelTypes(is_ref) = "Reference";
            
            h = scatter(xc, yc, p.Results.markerSize, cmap, 's', 'filled');
            h.DataTipTemplate.DataTipRows(1).Format = '%g um';
            h.DataTipTemplate.DataTipRows(2).Format = '%g um';
            h.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('channel id', double(channelIds));
            h.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('type', channelTypes);

            if p.Results.showChannelLabels
                for iC = 1:numel(channelInds)
                    text(xc(iC), yc(iC), sprintf('ch %d', m.channel_ids(channelInds(iC))), ...
                            'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
                            'Background', 'none', ...
                            p.Results.labelArgs{:});
                end
            end
        end
            
    end
end