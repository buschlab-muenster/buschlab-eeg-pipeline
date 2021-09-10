function wv = get_wavelets(CFG, srate, npnts, ntrials)

%%
wv = [];

% The time axis of the wavelet.
wv.wavtime = -2:1/srate:2;
wv.half_wave = (length(wv.wavtime)-1)/2;

% FFT parameters
wv.nWave = length(wv.wavtime);
nData = npnts * ntrials;
wv.nConv = wv.nWave + nData - 1;

for ifreq = 1:CFG.num_frex       
    
    % create Gaussian window
    wv.gaus_win{ifreq} = exp((-4 * log(2) * wv.wavtime .^2) / (CFG.fwhm_t(ifreq)^2) ); 
     
     
    
    % create wavelet and get its FFT
    % the wavelet doesn't change on each trial...
    wv.wavelet{ifreq} = exp(2 * 1i * pi * CFG.frex(ifreq) .* wv.wavtime) .* ...
        wv.gaus_win{ifreq};
    
    wv.waveletX{ifreq} = fft(wv.wavelet{ifreq}, wv.nConv);
    wv.waveletX{ifreq} = wv.waveletX{ifreq} ./ max(wv.waveletX{ifreq});
    
    
    
    % Calculate the empirical FWHM in the time domain.
    midp = dsearchn(wv.wavtime',0); 
    wv.fwhm_t_emp(ifreq) = wv.wavtime(midp-1+dsearchn(wv.gaus_win{ifreq}(midp:end)',.5)) ...
        - wv.wavtime(dsearchn(wv.gaus_win{ifreq}(1:midp)',.5));
    
    
    
    % Calculate the empirical FWHM in the frequency domain.
    wv.wvamp{ifreq} = abs(wv.waveletX{ifreq}(1:ceil(wv.nConv/2))); % left half of the wavelet'S amplitude spectrum.
    wv.wvhz{ifreq}  = srate / 2 * linspace(0,1,wv.nConv/2);       
    midp = dsearchn(wv.wvhz{ifreq}', CFG.frex(ifreq));     
    wv.fwhm_f_emp(ifreq) = wv.wvhz{ifreq}(midp-1+dsearchn(wv.wvamp{ifreq}(midp:end)',.5)) ...
        - wv.wvhz{ifreq}(dsearchn(wv.wvamp{ifreq}(1:midp)',.5));
    
end

%% For testing, plot the wavelets and their properties.

% figure('color', 'w')
% 
% for ifreq = 1:CFG.num_frex     
%     
%     % Plot the FWHM in frequency domain.
%     sanesubplot(2, CFG.num_frex, {1, ifreq}); hold all
%     
%     plot(wv.wvhz{ifreq}, wv.wvamp{ifreq},'k','linew',2) 
%     set(gca,'xlim',[0 CFG.frex(ifreq)*3])
%     gridxy([CFG.frex(ifreq)],[])
%     
%     halfmax = 0.5 * max(abs(wv.wvamp{ifreq}));
%     line([CFG.frex(ifreq)-0.5*wv.fwhm_f_emp(ifreq) CFG.frex(ifreq)+0.5*wv.fwhm_f_emp(ifreq)], [halfmax halfmax], ...
%         'color', 'r', 'linewidth', 2)
%     
%     title(sprintf('%2.2f Hz, fwhm_f: %2.2f Hz', CFG.frex(ifreq), wv.fwhm_f_emp(ifreq)))
%     
%     
%     % Plot the FWHM in time domain.
%     sanesubplot(2, CFG.num_frex, {2 ifreq}); hold all
%     plot(wv.wavtime, real(wv.wavelet{ifreq}))
%     plot(wv.wavtime,  abs(wv.wavelet{ifreq}))
%     
%     halfmax = 0.5 * max(abs(wv.wavelet{ifreq}));
%     line([0-0.5*wv.fwhm_t_emp(ifreq) 0+0.5*wv.fwhm_t_emp(ifreq)], [halfmax halfmax], ...
%         'color', 'r', 'linewidth', 2)
%     
%     title(sprintf('%2.2f Hz, fwhm_t: %2.2f s', CFG.frex(ifreq), wv.fwhm_t_emp(ifreq)))
% end
%     
