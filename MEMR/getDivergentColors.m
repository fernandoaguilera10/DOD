function cols_n = getDivergentColors(n)

% Colorblind friendly continuous hue/sat changes
cols = [103,0,31;
178,24,43;
214,96,77;
244,165,130;
253,219,199;
%247, 247, 247;
180, 180, 180;
209,229,240;
146,197,222;
67,147,195;
33,102,172;
5,48,97];
cols = cols(end:-1:1, :)/255;

ncols = size(cols, 1);
reds = interp1(1:ncols, cols(:, 1),...
    linspace(1, ncols, n), 'spline');
greens = interp1(1:ncols, cols(:, 2),...
    linspace(1, ncols, n), 'spline');
blues = interp1(1:ncols, cols(:, 3),...
    linspace(1, ncols, n), 'spline');
cols_n = [reds(:), greens(:), blues(:)];
