function polar_movie(aod_ind,sfc_pres_ind,band_ind,const)
        
        dir_video = 'video/';
        
        if ~exist(dir_video,'dir')
            mkdir(dir_video);
            fprintf('%s is created!\n',dir_video)
        else
            fprintf('directory %s exists, continue to save files!\n',dir_video)
        end
        
        file_video = strcat('polar_',num2str(const.Model_OpticalDepthGrid(aod_ind)),'.avi');
        
        cx = [0,0.15];

        writerObj = VideoWriter(strcat(dir_video,'/',file_video));
        writerObj.FrameRate = 8;
        open(writerObj);
        hFig = figure(1);
        set(hFig, 'Position', [10 10 1000 1000])
        for mu0_ind = 1:length(const.Model_mu0Grid)
            clf
            for i = 1:length(const.Component_Particle)
                subplot(4,2,i)
                theta0 = polar_plot(aod_ind,sfc_pres_ind,band_ind,const.Component_Particle(i),mu0_ind,cx,const);               
            end
            M = getframe(gcf);
            writeVideo(writerObj,M);
        end
        
        close(writerObj)

end