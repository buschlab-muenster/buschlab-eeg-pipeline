clear; 
% close all; 
clc

load sampleEEGdata.mat

% Frequency parameters.
CFG.min_freq =  2;
CFG.max_freq = 30;
CFG.num_frex = 40;
CFG.frex = linspace(CFG.min_freq, CFG.max_freq, CFG.num_frex);
CFG.fwhm_t = 2 .* 1./CFG.frex;

% Run wavelet transform.
tic
wv = wavelet_mxc(EEG.data, EEG.srate, CFG);
toc

% Run optimized version of wavelet transform
tic
wv_opt = optimized_wavelet(EEG.data, EEG.srate, CFG);
toc

%% plot results
figure('color', 'w')
subplot(2,1,1); hold all
contourf(EEG.times, CFG.frex, wv.pow(:,:,32), 40,'linecolor','none')
title('Power')
xlabel('Time [ms]')
ylabel('Frequency [Hz]')
% set(gca,'clim',[0 5],'ydir','normal')
% set(gca,'ydir','normal','xlim',[-300 1000])

plot(EEG.times(1)+(1000.*wv.wvlt.fwhm_t_emp), CFG.frex, 'r')
plot(EEG.times(end)-(1000.*wv.wvlt.fwhm_t_emp), CFG.frex, 'r')

subplot(2,1,2); hold all
contourf(EEG.times, CFG.frex, wv.itc(:,:,32), 40,'linecolor','none')
title('ITC')
xlabel('Time [ms]')
ylabel('Frequency [Hz]')
% set(gca,'clim',[0 5],'ydir','normal')
% set(gca,'ydir','normal','xlim',[-300 1000])

plot(EEG.times(1)+(1000.*wv.wvlt.fwhm_t_emp), CFG.frex, 'r')
plot(EEG.times(end)-(1000.*wv.wvlt.fwhm_t_emp), CFG.frex, 'r')
