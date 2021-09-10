function y = mmean(x, dims)
dims = sort(dims, 'descend');

for idim = 1:length(dims)
    x = nanmean(x, dims(idim));
end

y = squeeze(x);

