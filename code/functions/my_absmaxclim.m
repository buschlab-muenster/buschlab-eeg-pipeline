function h = my_absmaxclim(h)
% function my_absmaxclim(plotdata)
% Scales a contourf or imagesc figure so that the color scale is symmetric.

plotdata = get(get(h,'Children'), 'ZData');
% plotdata = get(h, 'ZData');

absmax = max(abs([min(plotdata(:)) max(plotdata(:))]));
set(h, 'clim', [-absmax absmax]);
