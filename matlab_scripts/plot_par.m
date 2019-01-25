function [ abs_distance] = plot_par( infile )
    %PLOT_PAR plots the output of mcflirt. It makes one plot with all motion
    %parameters, and one plot with relative/absolute rms motion.
    %Args:
        %infile: path to mcflirt .par file
    %Output: 
        %abs_distance: rms motion
    close all;
    params = load(infile);
    figure;
    
    for i = 1:6
        subplot(6,1,i); plot(params(:,i));
    end


    abs_distance = sqrt(sum(params(:,4:6).^2,2));
    rel_distance = abs(diff(abs_distance));
    figure; plot(abs_distance); hold on; plot(rel_distance, 'o'); legend('absolute distance', 'relative distance');

end
