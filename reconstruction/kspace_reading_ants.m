function [ksP,ksN,rsP,rsN] = kspace_reading_ants(fid_file,param)
%% kspace_reading_xcorr2
% This function reads the kspace of an EPIP experiment from a .fid varian 
% file. It then performs the reconstruction of the image with a cross
% correlation algorithm to correct the odd and even echoes mismatch.
% Finally, it performs a fourier transform to obtain the real space image.
% It can then compare those images to the .fid generated by varian and/or
% save the images in a .nii file.

% param fields (default value):
% param.data (1): specifies if the data used should be the raw Eplus and Eminus
% images or the intertwined images IprimeP and IprimeN

% param.save_nii (1): specifies if the data should be saved in a .nii files

% param.center_kspace (2): specifies the type of kspace centering to be
% applied before the cross correlation
% 0: no centering
% 1: 1D centering (only in the frequency direction)
% 2: 2D centering

% param.nx (64): Must specify the number of lines in the frequency direction

% param.ny (64): Must specify the number of lines in the phase direction

% param.display (1): Specifies if the data should be displayed or not

% param.fdf_comp (1): Specifies if the fdf data should be readed and
% compared

% param.vol_pour (1): specifies the pourcentage of volumes to be
% kept and analysed. 1=all the volumes. 0=only the first volume

%% Parameter verification
if ~exist(fid_file,'file')
    errordlg('Cannot find the fid_file')
end
field_names={'data','save_nii','center_kspace','nx','ny','display','fdf_comp' 'vol_pour'};
default_values=[1 1 2 64 64 1 1 1];
field_verif = isfield(param,field_names);
if ~isempty(find(field_verif,1));
    default_fields = find(field_verif==0);
    for i=default_fields
        param.(field_names{i})=default_values(i);
        % param = setfield(param,field_names{i},default_values(i));
    end
end

%% Reading
[Eplus,Eminus,Rplus,Rminus,navi,param] = read_and_sort_kspace_from_fid(fid_file,param);
if param.fdf_comp
    [data_fdf] = read_and_sort_kspace_from_fdf(fid_file,param);
end
disp('Done reading')

%% Computing IprimeP and IprimeN
if param.data==1
    disp('Computing IprimeP and IprimeN')
    IprimeP = zeros(param.knx,param.ny,param.knz,param.nt);
    IprimeP(:,1:2:param.ny-1,:,:) = Eplus(:,1:2:param.ny-1,:,:);
    IprimeP(:,2:2:param.ny,:,:) = Eminus(:,2:2:param.ny,:,:);
    IprimeN = zeros(param.knx,param.ny,param.knz,param.nt);
    IprimeN(:,2:2:param.ny,:,:) = Eplus(:,2:2:param.ny,:,:);
    IprimeN(:,1:2:param.ny-1,:,:) = Eminus(:,1:2:param.ny-1,:,:);
    for z=1:param.knz
        for t=1:param.nt
            fftIprimeP(:,:,z,t) = fftshift(fft2(IprimeP(:,:,z,t)));
            fftIprimeN(:,:,z,t) = fftshift(fft2(IprimeN(:,:,z,t)));
        end
    end
elseif param.data==2
    disp('Using the raw scans Eplus and Eminus')
    IprimeP = zeros(param.knx,param.ny,param.knz,param.nt);
    IprimeP(:,1:2:param.ny-1,:,:) = Eplus(:,1:2:param.ny-1,:,:);
    IprimeP(:,2:2:param.ny,:,:) = Eminus(end:-1:1,2:2:param.ny,:,:);
    IprimeN = zeros(param.knx,param.ny,param.knz,param.nt);
    IprimeN(:,2:2:param.ny,:,:) = Eplus(:,2:2:param.ny,:,:);
    IprimeN(:,1:2:param.ny-1,:,:) = Eminus(end:-1:1,1:2:param.ny-1,:,:);
    for z=1:param.knz
        for t=1:param.nt
            fftIprimeP(:,:,z,t) = fftshift(fft2(IprimeP(:,:,z,t)));
            fftIprimeN(:,:,z,t) = fftshift(fft2(IprimeN(:,:,z,t)));
        end
    end
end

%% Display IprimeP and IprimeN
if param.display
    t=4;
    figure(1)
    for z=1:param.knz
        subplot(2,4,1); imagesc(log(abs(Eplus(:,:,z,t)))); title('abs Eplus')
        subplot(2,4,2); imagesc(log(abs(IprimeP(:,:,z,t)))); title('abs IprimeP')
        subplot(2,4,3); imagesc(angle(IprimeP(:,:,z,t))); title('angle IprimeP')
        subplot(2,4,4); imagesc(abs(fftIprimeP(:,:,z,t))); title('fftIprimeP')
        subplot(2,4,5); imagesc(log(abs(Eminus(:,:,z,t)))); title('abs Eminus')
        subplot(2,4,6); imagesc(log(abs(IprimeN(:,:,z,t)))); title('abs IprimeN')
        subplot(2,4,7); imagesc(angle(IprimeN(:,:,z,t))); title('angle IprimeN')
        subplot(2,4,8); imagesc(abs(fftIprimeN(:,:,z,t))); title('fftIprimeN')
        % pause;
    end
end
clear Eplus Eminus

%% Center kspace
[IprimePc,IprimeNc,param] = center_kspace(IprimeP,IprimeN,param);

%% Display centering
if param.display
    z=5;
%     for t=1:param.nt
        figure(2)
        subplot(2,2,1); imagesc(log(abs(IprimeP(:,:,z,t)))); title(['IprimeP z=' num2str(z) ' t=' num2str(t)]);
        subplot(2,2,2); imagesc(log(abs(IprimePc(:,:,z,t)))); title(['IprimePc z=' num2str(z) ' t=' num2str(t)]);
        subplot(2,2,3); imagesc(log(abs(IprimeN(:,:,z,t)))); title(['IprimeN z=' num2str(z) ' t=' num2str(t)]);
        subplot(2,2,4); imagesc(log(abs(IprimeNc(:,:,z,t)))); title(['IprimeNc z=' num2str(z) ' t=' num2str(t)]);
        %         pause;
%     end
end
clear IprimeP IprimeN

%% Save the odd and even echoes half-kspace separatly in 2 nifti files
disp('Correcting odd and even echoes mismatch with ants')
IPodd = IprimePc(:,1:2:end-1,:,:);
IPeven = IprimePc(:,2:2:end,:,:);

[pathstr, name, ext] = fileparts(fid_file);
output_dir=[pathstr filesep name '_recon.nii' filesep];
if ~exist(output_dir,'dir')
    mkdir(output_dir);
end
file_IPodd=[output_dir 'IPodd.nii'];
file_IPeven=[output_dir 'IPeven.nii'];
try
    disp(['Writing ' file_IPodd])
    aedes_write_nifti(IPodd(:,:,:,3),file_IPodd);
    disp(['Writing ' file_IPeven])
    aedes_write_nifti(IPeven(:,:,:,3),file_IPeven);
catch exception
    errordlg(['unable to write IPodd or IPeven files'])
end

% INodd = IprimeNc(:,1:2:end,:,:);
% INeven = IprimeNc(:,2:2:end,:,:);

%% Register the odd kspace on the even kspace
file_IPodd_reg = [output_dir 'reg_IPodd.nii.gz'];
file_IPeven_reg = [output_dir 'reg_IPeven.nii.gz'];
cmd = ['antsRegistration -d 3 -t Affine[0.25] -m CC[' file_IPeven ',' file_IPodd ',1,2,Regular,1] -c 10x10x10 -f 4x2x1 -o reg_'];
cmd = ['flirt -in ' file_IPodd ' -ref ' file_IPeven ' -out ' file_IPodd_reg];
[status,result] = system(cmd,'-echo'); if status, error(result); end
cmd2 = ['antsRegistration -d 3 - -o reg_'];
cmd2 = ['flirt -in ' file_IPeven ' -ref ' file_IPodd_reg ' -out ' file_IPeven_reg];
[status,result] = system(cmd2,'-echo'); if status, error(result); end

%% Load the registered kspaces
DATA_odd_reg =  aedes_read_nifti(file_IPodd_reg);
IPodd_reg = DATA_odd_reg.FTDATA;
DATA_even_reg =  aedes_read_nifti(file_IPeven_reg);
IPeven_reg = DATA_even_reg.FTDATA;
IP(:,1:2:param.ny-1,:) = IPodd_reg;
IP(:,2:2:param.ny,:) = IPeven_reg;

if param.display
    z=3;
    figure
    subplot(1,2,1); imagesc(abs(IprimePc(:,:,z,3))); title('original IprimePC')
    subplot(1,2,2); imagesc(abs(IP(:,:,z))); title('registered IP')
end

%% ifft
disp('computing rspace')
for z=1:param.knz
    for t=1:param.nt
        U = ksP(:,:,z,t);
        rsP(:,:,z,t) = abs(fftshift((fft2(U))));
        U = ksN(:,:,z,t);
        rsN(:,:,z,t) = abs(fftshift((fft2(U))));
    end
end

%% Addition of rsP and rsN
rsP = rsP(end:-1:1,:,:,:);
rs = sqrt(rsP.^2+rsN.^2);
%% Display kspace and rspace
if param.display
    t=330; z=2;
    figure(4)
    for z=1:param.knz
        subplot(1,4,1); imagesc((abs(ksP(:,:,z,t)))); axis image; title(['log ksP z=' num2str(z) ' t=' num2str(t)]);
        subplot(1,4,2); imagesc(rsP(:,:,z,t)); axis image; title(['rsP z=' num2str(z) ' t=' num2str(t)]);
        subplot(1,4,3); imagesc((abs(ksN(:,:,z,t)))); axis image; title(['log ksN z=' num2str(z) ' t=' num2str(t)]);
        subplot(1,4,4); imagesc(rsN(:,:,z,t)); axis image; title(['rsN z=' num2str(z) ' t=' num2str(t)]);
        % subplot(1,5,5); imagesc(rs(:,:,z,t)); axis image; title(['rs z=' num2str(z) ' t=' num2str(t)]);
        colormap gray
%         pause;
    end
end
%% Display data_fdf and data_fid
data_kspace = ksP;
data_fid = rsP(param.knx/4:3*param.knx/4+1,[3*param.ny/4+1:param.ny 1:3*param.ny/4],:,:);
if param.fdf_comp && param.display
    disp('Display data_fdf and data_fid')
    display_function(data_fdf,abs(data_kspace),data_fid,'Varian','kspace','ants');
end

%% Save in .nii
if param.save_nii
    [pathstr, name, ext] = fileparts(fid_file);
    output_dir=[pathstr filesep name '_recon.nii' filesep];
    if ~exist(output_dir,'dir')
        mkdir(output_dir);
    end
    output_file_rs=[output_dir 'rs_xcorr_type' num2str(param.xcorr_type) '.nii'];
    output_file_ks=[output_dir 'ks_xcorr_type' num2str(param.xcorr_type) '.nii'];
    try
        disp(['Writing ' output_file_rs])
        aedes_write_nifti(data_fid,output_file_rs);
        disp(['Writing ' output_file_ks])
        aedes_write_nifti(data_kspace,output_file_ks);    
    catch exception
        errordlg(['unable to write ' output_file_rs])
    end
end
disp('done')