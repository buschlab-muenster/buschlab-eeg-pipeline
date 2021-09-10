function wv = optimized_wavelet(data, srate, CFG)

% Make sure the data are three dimensional: chans * time * trials.
if ndims(data) == 1
    data(1,1,:) = data;
elseif ndims(data) == 2 %#ok<ISMAT>
    data(1,:,:) = data;
end

[nchans, npnts, ntrials] = size(data);

% comments!
% CFG.fwhm_t = 2./CFG.frex; !!! the minimal advised is 1/f. even if it is
% not recommended, it might be a good idea to allow in the CFG to have a
% different ratio?

% internal computation of CFG parameters dependent on fundamental inputs
CFG.frex = linspace(CFG.min_freq, CFG.max_freq, CFG.num_frex);
CFG.fwhm_t = 2./CFG.frex;
nfreqs = length(CFG.frex);

% Prepare wavelets.
wv = local_get_wavelets(CFG, srate, npnts, ntrials);

% concatenate data along the time dimension
long_data = reshape(data, nchans, npnts*ntrials);

% compute the FFT
FFT_longdata = fft(long_data, wv.nConvPow2, 2);

% ########### commented since low performance ###########################
% preallocate nan for complex signal (leaving single trials)
% tf_cmplx = single(complex(zeros(nfreqs, npnts, nchans, ntrials)));
% #######################################################################

% preallocate zeros for pow and itc
[wv.mn_pow, wv.itc] = deal(single(zeros(nfreqs, npnts, nchans)));
[wv.st_pow] = deal(single(zeros(nfreqs, npnts, nchans, ntrials)));

% loop over frequencies
for ifreq = 1:nfreqs
    
    fprintf('%2.2f|',CFG.frex(ifreq))
    
    % expand wavelet to allow matrix multiplication
    this_wav = wv.waveletX{ifreq};
    wavmat = repmat(this_wav, nchans, 1);
    
    % actually compute multiplication in freq domain
    as = ifft(FFT_longdata .* wavmat, [], 2);
    as = as(:, 1:wv.nConv);
    as = as(:, wv.half_wave+1:end-wv.half_wave);
    
    % bring data back in original form, then change dimord for
    % compatibility with 4D representation
    as = reshape(as, nchans, npnts, ntrials);
    as = permute(as, [2, 1, 3]);
    
    % #################### commented out for performance ##################
    % store data (single trials)
    %     tf_cmplx(ifreq, :, :, :) = as;
    % #####################################################################
    
    % compute power & ITC
    temp_abs = abs(as);
    temp_pow = abs(as).^2;
    wv.st_pow(ifreq,:,:,:) = temp_pow;
    wv.mn_pow(ifreq,:,:) = mean(temp_pow, 3);
    
    % speed up itc computation by avoiding the call to "angle" function
    nrmzd_as = as ./ temp_abs;
    wv.itc(ifreq,:,:) = abs(mean(nrmzd_as, 3));
    
end
fprintf('\n')
% ################# commented out for performance ########################
% wv.pow = mean(abs(tf_cmplx).^2, 4);
% wv.itc = abs(mean(exp(1i*angle(tf_cmplx)), 4));
% wv.tf_cmplx = tf_cmplx;
% ########################################################################

end

%% ######################## LOCAL FUNCTIONS

function wv = local_get_wavelets(CFG, srate, npnts, ntrials)

% The time axis of the wavelet.
wv.wavtime = -2:1/srate:2;
wv.half_wave = (length(wv.wavtime)-1)/2;

% general parameters to perform the tf
wv.nWave = length(wv.wavtime);
nData = npnts * ntrials;
wv.nConv = wv.nWave + nData - 1;
wv.nConvPow2 = pow2(nextpow2(wv.nConv));

% preallocate cell for wavelets
wv.waveletX = cell(CFG.num_frex, 1);

for ifreq = 1:CFG.num_frex
    
    % create Gaussian window
    this_gaus_win = exp((-4 * log(2) * wv.wavtime .^2) / (CFG.fwhm_t(ifreq)^2) );
    
    % create wavelet and get its FFT
    % the wavelet doesn't change on each trial...
    this_wavelet = exp(2 * 1i * pi * CFG.frex(ifreq) .* wv.wavtime) .* ...
        this_gaus_win;
    
    freq_domain_wave = fft(this_wavelet, wv.nConvPow2 );
    wv.waveletX{ifreq} = single(freq_domain_wave ./ max(freq_domain_wave));
    
    %     % Calculate the empirical FWHM in the time domain.
    %     midp = dsearchn(wv.wavtime',0);
    %     wv.fwhm_t_emp(ifreq) = wv.wavtime(midp-1+dsearchn(wv.gaus_win{ifreq}(midp:end)',.5)) ...
    %         - wv.wavtime(dsearchn(wv.gaus_win{ifreq}(1:midp)',.5));
    %
    %     % Calculate the empirical FWHM in the frequency domain.
    %     wv.wvamp{ifreq} = abs(wv.waveletX{ifreq}(1:ceil(wv.nConv/2))); % left half of the wavelet'S amplitude spectrum.
    %     wv.wvhz{ifreq}  = srate / 2 * linspace(0,1,wv.nConv/2);
    %     midp = dsearchn(wv.wvhz{ifreq}', CFG.frex(ifreq));
    %     wv.fwhm_f_emp(ifreq) = wv.wvhz{ifreq}(midp-1+dsearchn(wv.wvamp{ifreq}(midp:end)',.5)) ...
    %         - wv.wvhz{ifreq}(dsearchn(wv.wvamp{ifreq}(1:midp)',.5));
    
end



end