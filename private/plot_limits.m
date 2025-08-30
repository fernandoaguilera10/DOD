function limits = plot_limits(EXPname,EXPname2,idx_plot_relative)
if isempty(idx_plot_relative)   % limits including baseline
    switch EXPname
        case 'OAE'
            limits.avg = [-20,20];
            limits.ind = [-60,60];
        case 'MEMR'
            limits.avg = [70,105];
            limits.ind = [70,105];
        case 'EFR'
            switch EXPname2
                case 'RAM'
                    limits.avg = [0,1.1];
                    limits.ind = [0,1.1];
                case 'dAM'
                    limits.avg = [-40,40];
                    limits.ind = [-90,20];
            end
        case 'ABR'
            switch EXPname2 
                case 'Thresholds'
                    limits.avg = [0,55];
                    limits.ind = [0,80];
                case 'Peaks'
                    limits.avg.peaks = [-inf,inf];
                    limits.ind.peaks = [-3,5];
                    limits.avg.latency = [-inf,inf];
                    limits.ind.latency = [-inf,inf];
            end
    end
else    % limits relative to baseline
    switch EXPname
        case 'OAE'
            limits.avg = [-60,60];
            limits.ind = [-60,60];
        case 'MEMR'
            limits.avg = [70,105];
            limits.ind = [70,105];
        case 'EFR'
            switch EXPname2
                case 'RAM'
                    limits.avg = [-1,1];
                    limits.ind = [-1,1];
                case 'dAM'
                    limits.avg = [-40,40];
                    limits.ind = [-90,20];
            end
        case 'ABR'
            switch EXPname2 
                case 'Thresholds'
                    limits.avg = [-30,30];
                    limits.ind = [0,80];
                case 'Peaks'
                    limits.avg.peaks = [-inf,inf];
                    limits.ind.peaks = [-3,5];
                    limits.avg.latency = [-inf,inf];
                    limits.ind.latency = [-inf,inf];
            end
    end
end
end