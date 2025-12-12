function limits = plot_limits(EXPname,EXPname2,idx_plot_relative)

%% Limits including baseline
if isempty(idx_plot_relative)
    switch EXPname
        case 'OAE'
            limits.avg = [-60,60];
            limits.ind = [-60,60];
        case 'MEMR'
            limits.avg = [70,105];
            limits.ind = [70,105];
            limits.threshold = [60,80];
        case 'EFR'
            switch EXPname2
                case 'RAM'
                    limits.avg = [0,1.2];
                    limits.ind = [0,1.1];
                case 'dAM'
                    limits.avg = [-40,40];
                    limits.ind = [-90,20];
            end
        case 'ABR'
            switch EXPname2 
                case 'Thresholds'
                    limits.avg = [-5,65];
                    limits.ind = [0,80];
                case 'Peaks'
                    limits.avg.peaks = [-inf,inf];
                    limits.ind.peaks = [-4,6];
                    limits.avg.latency = [-inf,inf];
                    limits.ind.latency = [-inf,inf];
            end
    end

    %% Limits relative to  baseline
else
    switch EXPname
        case 'OAE'
            limits.avg = [-30,25];
            limits.ind = [-60,60];
        case 'MEMR'
            limits.avg = [45,105];
            limits.ind = [45,105];
            limits.threshold = [-10,10];
        case 'EFR'
            switch EXPname2
                case 'RAM'
                    limits.avg = [-0.7,0.7];
                    limits.ind = [-1,1];
                case 'dAM'
                    limits.avg = [-40,40];
                    limits.ind = [-90,20];
            end
        case 'ABR'
            switch EXPname2 
                case 'Thresholds'
                    limits.avg = [-40,70];
                    limits.ind = [0,80];
                case 'Peaks'
                    limits.avg.peaks = [-inf,inf];
                    limits.ind.peaks = [-4,6];
                    limits.avg.latency = [-inf,inf];
                    limits.ind.latency = [-inf,inf];
            end
    end
end
end