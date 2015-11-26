x = [1,2,4,8,16,32];
t_local = [288,133,69,37,27,23];
t_cluster = [117,70,39,25,22,20];
t_local_n = t_local(1)./t_local;
t_cluster_n = t_cluster(1)./t_cluster;
figure
loglog(x,t_local_n,'-o','LineWidth',2),hold on
loglog(x,t_cluster_n,'-o','LineWidth',2)
xlim([1,50]),ylim([1,50])
set(gca,'xtick',[1,10,50],'xticklabel',{'10^0','10^1','50'})
set(gca,'ytick',[1,10,50],'yticklabel',{'10^0','10^1','50'})
legend({'Local Mode','Cluster Mode'})
set(gca,'FontSize',18)
grid on
xlabel('Number of Cores')
ylabel('Normalized Speed')
title('Normalized Speed v.s. Parallelism')

figure,
plot(tau,sample_rls.tau,'o'),hold on
plot(tau,mean(sample_mcmc.tau(:,50:10:end),2),'o'),hold on,
plot(tau,sample_cd.tau,'o')
xlim([0.18,0.4]),ylim([0.18,0.4])
refline(1,0)
legend({'Random Local Search','MCMC','Coordinate Descent'})
set(gca,'FontSize',18)
xlabel('True AOD in Simulation')
ylabel('Retrieved AOD')


figure
subplot(3,1,1),plot_1d(4400,tau,x,y,jet,const)
subplot(3,1,2),plot_1d(4400,sample.tau,x,y,jet,const)
subplot(3,1,3),plot_1d(4400,sample.tau-tau,x,y,jet,const)

figure
for p = 1:50:reg.num_reg_used
    chisq = zeros(100,1);
    tau_grid = linspace(0,0.5,100);
    for i = 1:100
        chisq(i) = get_chisq(r,tau_grid(i),sample_cd.theta,p,sample_cd.sigmasq(:,end),x,y,const,ExtCroSect,CompSSA,smart,reg,reg_sim);
    end
    semilogy(tau_grid,chisq,'k'),hold on
end
set(gca,'FontSize',18)
xlabel('AOD')
ylabel('\chi^2_p','rot',0)
title('Convexity near Optima')
    
for j = 1:const.Component_Num
    h = subplot(4,2,j);
    p = get(h, 'pos');
    p(1) = p(1) - 0.05;
    p(3) = p(3) + 0.05;
    set(h, 'pos', p);

    plot_1d(r, sample.theta(j,:), x, y, jet, const,[0,1])

    title(strcat('Component Num:',num2str(const.Component_Particle(j))))
    set(gca,'FontSize',18)
end 