function peek_NRpars( nr_dataset, base_dir, feature_function, parnum, min_value, max_value)
% View media that trigger a certain range of parameter values
% SYNTAX
%   peek_NRpars( nr_dataset, base_dir, feature_function, parnum, min_value, max_value)
% SEMANTICS
%   Intended for debugging NR parameters that provide root cause analysis.
%   Images or videos with a specific impairment should produce high or low
%   values. This function lets the user specify the range of parameter
%   values where the impairment should be detected. The media in that range
%   are displayed, first as thumbnails in a 3x4 matrix, then as full
%   resolution images. For videos, the first frame is displayed. Additional
%   information is printed to the command line. 
%
% Input Parameters:
%   nr_dataset          Data structure. Each describes an entire dataset (name, file location, ...)
%   base_dir            Path to directory where NR features and NR parameters are stored.
%   feature_function    Pointer to a no-reference feature functions (NRFF) that must 
%                       adhere to the interface specified in calculate_NRpars.
%   parnum              Parameter number, within @feature_function.
%   min_value           Minimum parameter value to select.
%   max_value           Maximum parameter value to select.

    % load the parameters. This will calculate them, if not yet computed. 
    for dcnt = 1:length(nr_dataset)
        fprintf('-------------------------------------------------------\n');
        fprintf('Dataset %s\n\n', nr_dataset(dcnt).test);
        
        fprintf('Loading NR parameters. This will be very slow, if not yet calculated\n');
        NRpars = calculate_NRpars(nr_dataset(dcnt), base_dir, 'none', feature_function);

        % find media that fit these criteria (range of values)
        want=find(NRpars.data(parnum,:) <= max_value & NRpars.data(parnum,:) >= min_value);
        
        % sort media by MOS
        ismos = [nr_dataset(dcnt).media(want).mos];
        [~,order] = sort(ismos);
        want = want(order);
        
        for cnt=1:length(want)
            % start new figure every 12 media
            if mod(cnt,12) == 1
                figure(ceil(cnt/12));
            end
            
            % subplot for a thumbnail
            curr = mod(cnt,12);
            if curr == 0
                curr = 12; 
            end
            subplot(3,4,curr);
            [y, cb, cr] = read_media('frames', nr_dataset(dcnt), want(cnt), 1, 1);
            display_color_xyt(y,cb,cr,'subplot');
            
            % print to command line full information
            fprintf('%4d) mos %4.2f par %5.2f %s\n', ...
                want(cnt), nr_dataset(dcnt).media(want(cnt)).mos, NRpars.data(parnum,want(cnt)), ...
                nr_dataset(dcnt).media(want(cnt)).name); 
            
            % print to thumbnail title partial information
            title(sprintf('%4d) mos %4.2f par %5.2f', ...
                want(cnt), nr_dataset(dcnt).media(want(cnt)).mos, NRpars.data(parnum,want(cnt))), ...
                'interpreter','none'); 
        end
        
        % loop through a 2nd time and open full size images
        for cnt=1:length(want)
            [y, cb, cr] = read_media('frames', nr_dataset(dcnt), want(cnt), 1, 1);
            display_color_xyt(y,cb,cr);
        end
    end
end
