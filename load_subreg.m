function [rad_1100, rad_550, rad_275] = load_subreg(Date,Path,Orbit,Block,const)
    
    Orbit = num2str(Orbit,'%06d');
    Path = num2str(Path,'%03d');

    % Load MI1B2T data, make averages and conversions
    rad_1100 = NaN *ones(const.XDim_r1100, const.YDim_r1100, const.Band_Dim, const.Cam_Dim);
    rad_550 = NaN * ones(const.XDim_r550, const.YDim_r550, const.Cam_Dim);
    rad_275 = NaN * ones(const.XDim_r275, const.YDim_r275, const.Cam_Dim);
    
    dir_radiance = fullfile('products/MI1B2T/',Date);

    for cam = 1:const.Cam_Dim
        
        file_rad = strcat(dir_radiance,'/',const.header_MI1B2T_filename,Path,'_O',Orbit,'_',const.Cam_Name{cam},'_F03_0024.hdf');
        disp(['Loading', file_rad, '...']);

        for band = 1:const.Band_Dim
            
            disp(['Loading band', const.Band_Name{band}, '...']);
            block_resolution = hdfread(file_rad, ['/', const.Band_Name{band}, '/Grid Attributes/Block_size.resolution_x'], 'Fields', 'AttrValues', 'FirstRecord',1 ,'NumRecords',1);
            block_size_x = hdfread(file_rad, ['/', const.Band_Name{band}, '/Grid Attributes/Block_size.size_x'], 'Fields', 'AttrValues', 'FirstRecord',1 ,'NumRecords',1);
            block_size_y = hdfread(file_rad, ['/', const.Band_Name{band}, '/Grid Attributes/Block_size.size_y'], 'Fields', 'AttrValues', 'FirstRecord',1 ,'NumRecords',1);
            scale_factor = hdfread(file_rad, ['/', const.Band_Name{band}, '/Grid Attributes/Scale factor'], 'Fields', 'AttrValues', 'FirstRecord',1 ,'NumRecords',1);
            sun_distance_au = hdfread(file_rad, ['/', const.Band_Name{band}, '/Grid Attributes/SunDistanceAU'], 'Fields', 'AttrValues', 'FirstRecord',1 ,'NumRecords',1);
            std_solar_wgted_height = hdfread(file_rad, ['/', const.Band_Name{band}, '/Grid Attributes/std_solar_wgted_height'], 'Fields', 'AttrValues', 'FirstRecord',1 ,'NumRecords',1);

            radiance_rdqi = hdfread(file_rad, const.Band_Name{band}, 'Fields', const.Band_Radiance{band}, ...
                'Index', {[Block  1  1], [1  1  1], [1  double(block_size_x{1})  double(block_size_y{1})]});

            rdqi = bitand(radiance_rdqi,3);
            radiance = double(bitshift(radiance_rdqi,-2));
            radiance(radiance >= 16377) = NaN;
            radiance = double(radiance)*scale_factor{1};
            radiance(rdqi > const.Config_rdqi1) = NaN;

            if  double(block_resolution{1}) == const.r275
                              
                disp('Averaging radiances to 1.1km resolution ...')
                radiance_1100 = NaN * ones(const.XDim_r1100, const.YDim_r1100);           
                
                for kk = 1:const.XDim_r1100
                    for ll = 1:const.YDim_r1100
                        r = radiance(4*kk-3:4*kk, 4*ll-3:4*ll);
                        if any(r(:))
                            radiance_1100(kk,ll) = nanmean(r(:));
                        end
                    end
                end
                
                if band == const.Band_Red
               
                    disp('Collect radiances at 275m resolution ...')
                    radiance_275 = radiance;

                    disp('Averaging radiances to 550m resolution ...')
                    radiance_550 = NaN * ones(const.XDim_r550, const.YDim_r550);

                    for kk = 1:const.XDim_r550
                        for ll = 1:const.YDim_r550
                            r = radiance(2*kk-1:2*kk, 2*ll-1:2*ll);
                            if any(r(:))
                                radiance_550(kk,ll) = nanmean(r(:));
                            end
                        end
                    end
                
                    rad_550(:,:,cam) = pi*radiance_550*sun_distance_au{1}^2/std_solar_wgted_height{1};
                    rad_275(:,:,cam) = pi*radiance_275*sun_distance_au{1}^2/std_solar_wgted_height{1};
                end
                        
            else
                fprintf('already 1.1km resolution, no need to average...\n')
                radiance_1100 = radiance;
            end

            rad_1100(:,:,band,cam) = pi*radiance_1100*sun_distance_au{1}^2/std_solar_wgted_height{1};
            
        end
        
    end   

    % Apply spectral out-of-band correction
    disp('apply spectral out-of-band correction')
    
    for ii = 1:const.XDim_r1100
        for jj = 1:const.YDim_r1100
            for cam = 1:const.Cam_Dim
                rho = squeeze(rad_1100(ii, jj, :, cam));
                if all(~isnan(rho))
                    rad_1100(ii,jj,:,cam) = const.Config_spectral_corr_matrix*rho;
                end
            end
        end
    end
       
    rad_550 = rad_550 * 1.0145;
    rad_275 = rad_275 * 1.0145;
    
    dir_aerosol = fullfile('products/MIL2ASAE/',Date);
    file_aerosol = strcat(dir_aerosol,'/',const.header_MIL2ASAE_filename,Path,'_O',Orbit,'_F12_0022.hdf');
    
    % Correct for ozone absorption
    disp('correct for ozone absorption')
    ColOzAbund = hdfread(file_aerosol, 'RegParamsEnvironmental', 'Fields', 'ColOzAbund', ...
        'Index',{[Block  1  1],[1  1  1],[1  const.XDim_r17600  const.YDim_r17600]});
    SolZenAng = hdfread(file_aerosol, 'RegParamsGeometry', 'Fields', 'SolZenAng', ...
        'Index',{[Block  1  1],[1  1  1],[1  const.XDim_r17600  const.YDim_r17600]});
    ViewZenAng = hdfread(file_aerosol, 'RegParamsGeometry', 'Fields', 'ViewZenAng', ...
        'Index',{[Block  1  1  1],[1  1  1  1],[1  const.XDim_r17600  const.YDim_r17600  const.Cam_Dim]});
    for band = 1:const.Band_Dim  
        for cam = 1:const.Cam_Dim            
            c = exp(const.Config_c_lambda(band)*ColOzAbund.*(1./cosd(SolZenAng)+1./cosd(ViewZenAng(:,:,cam))));
            rad_1100(:, :, band, cam) = rad_1100(:, :, band, cam) .* kron(c, ones(const.r17600/const.r1100));
            if band == const.Band_Red
                rad_550(:,:,cam) = rad_550(:,:,cam) .* kron(c,ones(const.r17600/const.r550));
                rad_275(:,:,cam) = rad_275(:,:,cam) .* kron(c,ones(const.r17600/const.r275));
            end
        end        
    end
    
    % Subregions screening
    disp('subregion screening')
    RetrAppMask = hdfread(file_aerosol, 'SubregParamsAer', 'Fields', 'RetrAppMask', ...
        'Index',{[Block  1  1  1  1],[1  1  1  1  1],[1  const.XDim_r1100  const.YDim_r1100  const.Band_Dim  const.Cam_Dim]});
    rad_1100(RetrAppMask ~= 0) = NaN;
    
    rad_550 = reshape(rad_550,const.XDim_r550*const.YDim_r550,const.Cam_Dim);
    rad_275 = reshape(rad_275,const.XDim_r275*const.YDim_r275,const.Cam_Dim); 
    for cam = 1:const.Cam_Dim
        valid = kron(squeeze(RetrAppMask(:,:,const.Band_Red,cam)),uint8(ones(const.r1100/const.r550))) ~= 0;
        rad_550(valid,cam) = NaN;
        valid = kron(squeeze(RetrAppMask(:,:,const.Band_Red,cam)),uint8(ones(const.r1100/const.r275))) ~= 0;
        rad_275(valid,cam) = NaN;
    end
    rad_550 = reshape(rad_550,const.XDim_r550,const.YDim_r550,const.Cam_Dim);
    rad_275 = reshape(rad_275,const.XDim_r275,const.YDim_r275,const.Cam_Dim);
    
end