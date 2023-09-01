module RxEnvironmentsPlottingExt

using RxEnvironments, GLMakie



RxEnvironments.animate_state(subject::AbstractEntity; fps = 60, seconds = 10) =
    @async(__animate_state(subject, fps, seconds))



function __animate_state(subject::AbstractEntity, fps, seconds)
    @info "Animating state of $(subject)"
    figure = Figure()
    ax = Axis(figure[1, 1])
    display(figure)
    underlying = entity(subject)
    while !is_terminated(subject)
        empty!(ax)
        ax.cycler.counters[Scatter] = 0
        ax.cycler.counters[Lines] = 0
        plot_state(ax, underlying) 
        sleep(1 / fps)
    end
end

end