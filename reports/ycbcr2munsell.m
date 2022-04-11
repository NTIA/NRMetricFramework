function [munsell] = ycbcr2munsell(ycbcr)
% ycbcr2munsell
%   Instantiate Munsell look-up table using 'Munsell_to_RGB.xls'
%   Transform image or video from YCbCr to Munsel.
%   Use nearest neighbor search, based on KDTree
% SYNTAX
%   [munsell] = ycbcr2munsell(ycbcr)
% SEMANTICS
%
% Input:
%   ycbcr(n,3)      N pixel values (Y, Cb, Cr), on scale
%                   y=0..255, Cb = -128..127, Cr= -128..127
% Output:
%   munsell(n,3)    N pixel values (h', v, c) where:
%                   h' is Munsell hue, encoded as a number [1..40] 
%                      or NaN for neutrals
%                   v is Munsell value (light/dark), a number [0..10]
%                   c is Munsell distance from center, saturation, 
%                     “purity” of the color, [0..28]
%  
% Note that the Munsell color space denotes neutrals as "N" instead of
% zero (0), and uses letters plus numbers instead of 40 hue values. 
% To convert my numbers to those original codes, see Munsell_to_RGB.xlsx
% page "codes" column A. See column C for a rough description of the color.
%
% For better Munsell conversion code and information, see 
%   http://www.munsellcolourscienceforpainters.com/MunsellAndKubelkaMunkToolbox/MunsellAndKubelkaMunkToolbox.html 
%   http://www.munsellcolourscienceforpainters.com/MunsellResources/MunsellResources.html  
%

    persistent munsell_kdtree munsell_colors munsell_values;


    if isempty(munsell_kdtree)

        [ndata, text] = xlsread('Munsell_to_RGB.xlsx', 'transform','A1:I1639','basic');
        [ndata_code, text_code] = xlsread('Munsell_to_RGB.xlsx', 'codes','A1:F42','basic');

        % create look-up table needed for nearest neighbor search
        munsell_kdtree = KDTreeSearcher(ndata(:,6:8));

        % create the rest of the data that we need to return: Munsell
        rows = size(ndata,1);
        munsell_colors = cell(rows,2);
        munsell_values = nan(rows,3);

        % transfer these values into the table
        for loop = 1:rows
            munsell_colors(loop,1) = text(loop+1, 1); % Munsell 'h' value: letter + number [1..10]
            offset = find(strcmp(munsell_colors(loop,1),text_code(:,1) ));
            munsell_colors(loop, 2) = text_code(offset, 3); % Munsell color, spelled out

            munsell_values(loop, 1) = ndata_code(offset-1, 1); % my encoded h value [1..40] 
            munsell_values(loop, 2) = ndata(loop, 1); % Munsell 'v'
            munsell_values(loop, 3) = ndata(loop, 2); % Munsell 'c'
        end

    end

    index = knnsearch(munsell_kdtree,ycbcr);

    munsell = munsell_values(index, :);

end

