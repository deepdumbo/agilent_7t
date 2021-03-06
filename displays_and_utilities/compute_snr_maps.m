function [snr_maps] = compute_snr_maps (data,names)
% compute_snr_maps
% This function computes the snr maps for a struct of cell containing
% multiple scans. The noise standard deviation is computed with a region
% corresponding to a corner of size x/10 and y/10 of the image

if iscell(data)
    nb_acq = length(data);
    for acq = 1:nb_acq
        [nx,ny,nz] = size(data{acq});
        for z=1:nz
            noise_std(1,1,z) = std2(data{acq}(1:round(nx/10),1:round(ny/10),z));
        end
        noise_mat = repmat(noise_std,[nx ny]);
        snr_maps{acq} = data{acq}./noise_mat;
        for z=1:nz
            h=figure;
            imagesc(snr_maps{acq}(:,:,z));
            title([names{acq} ' z=' num2str(z)]);
            colorbar
            saveas(h,[names{acq} 'z' num2str(z)],'png')
            saveas(h,[names{acq} 'z' num2str(z)],'fig')
        end
        clear noise_std
        close all
    end
elseif isnumeric(data)  %single scan
    nb_acq=1;
    for acq = 1:nb_acq
        [nx,ny,nz] = size(data);
        for z=1:nz
            noise_std(1,1,z) = std2(data(1:round(nx/10),1:round(ny/10),z));
        end
        noise_mat = repmat(noise_std,[nx ny]);
        snr_maps = data./noise_mat;
        display_function(snr_maps);
    end
else
    error('data format not supported')
end


end

