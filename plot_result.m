function plot_result(plot_name,const,varargin)
    
    cols = const.cols;
    
    if ~exist('plots','dir')
        mkdir('plots')
        fprintf('directory plots is created!\n')
    end
    
    if strcmp(plot_name,'scatter')
        Location = varargin{1};
        aod_max = 0;
        
        if nargin<4
            error('not enough args for scatter plot!\n')
        else
            figure
            for p = 2:length(varargin)
                [aod_model,aod_aeronet] = load_aod_batch(varargin{p},Location,const);
                aod_max = 1.1*max([aod_max;aod_model;aod_aeronet]);
                h = scatter(aod_aeronet,aod_model,'MarkerEdgeColor',cols(p-1,:),'MarkerFaceColor',cols(p-1,:));
                fprintf('correlation with aeronet is %f\n',corr(aod_model,aod_aeronet));
                xlim([0,aod_max]),ylim([0,aod_max])
                currentunits = get(gca,'Units');
                set(gca, 'Units', 'Points');
                axpos = get(gca,'Position');
                set(gca, 'Units', currentunits);
                markerWidth = 0.01/diff(xlim)*axpos(3); % Calculate Marker width in points
                set(h, 'SizeData', markerWidth^2)
                hold on
            end
            line('XData', [0 aod_max], 'YData', [0 aod_max], 'LineStyle', '-','LineWidth', 1, 'Color','k')
            legend(varargin{2:end},'Location','northwest')
            xlabel('AERONET Measurement','FontSize',18)
            ylabel('AOD Retrieval','FontSize',18)
        end
        
        set(gca,'FontSize',18)
        export_fig(strcat('plots/',plot_name,'_',strjoin(varargin,'_')),'-png','-transparent')

    elseif strcmp(plot_name,'overlay')
        Date = varargin{1};
        Path = varargin{2};
        Orbit = varargin{3};
        Block = varargin{4};
        Location = varargin{5};
        Method = varargin{6};
        cmap = varargin{7};
        
        [aod_model, ~, ~, lon1,lat1] = load_aod(Date,Path,Orbit,Block,const,Method);
        [aod_aeronet, ~, ~, lon2,lat2] = load_aeronet(Date,Path,Block,Location,const);
        
        aod = [aod_model;aod_aeronet];
        aod_min = min(aod);aod_max = max(aod);
                
        cols = colormap(cmap);
        colsize = size(cols,1);
        map_model = round(1 + (aod_model - aod_min) / (aod_max-aod_min) .* (colsize-1));
        map_aeronet = round(1 + (aod_aeronet - aod_min) / (aod_max-aod_min) .* (colsize-1));
        
        h = scatter_patches(lon1,lat1,36,cols(map_model,:),'s','FaceAlpha',0.6,'EdgeColor','none');hold on
        scatter_patches(lon2,lat2,50,cols(map_aeronet,:),'o','EdgeColor',[0 0 0]);
        colorbar,caxis([aod_min aod_max])
        uistack(h,'bottom');
        
        plot_google_map('MapType','hybrid','ShowLabels',0,'Alpha',0.8)
        file_model = strcat('plots/',plot_name,'_',strjoin({Date,Location,Method},'_'));
        export_fig(file_model,'-png','-transparent')
    
    elseif strcmp(plot_name,'resid')
        
        Date = varargin{1};
        Path = varargin{2};
        Orbit = varargin{3};
        Block = varargin{4};
        Method = varargin{5};
        band_ind = varargin{6};
        cam_ind = varargin{7};
        cmap = varargin{8};
        
        [sample,reg] = load_cache(Date,Path,Orbit,Block,const,'sample','reg',Method);
        [x,y] = find(reg.reg_is_used);
        
        resid = sample.resid((band_ind-1)*9+cam_ind,:,end);
        
        plot_1d(resid,x,y,cmap,const)
        title('Reflectance Residual','FontSize',18)
        export_fig(strcat('plots/',plot_name,'_',strjoin({Date,Method})),'-png','-transparent')

    end

end