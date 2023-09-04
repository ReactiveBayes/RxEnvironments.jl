module RxEnvironmentsPlottingExt

using RxEnvironments, GLMakie



RxEnvironments.animate_state(subject::AbstractEntity; fps = 60, seconds = 10) =
    @async(__animate_state(subject, fps, seconds))



function __animate_state(subject::AbstractEntity, fps, seconds)
    @info "Animating state of $(subject)"
    figure = Figure()
    ax = Axis(figure[1, 1])
    display(figure)
    underlying = RxEnvironments.entity(subject)
    while !RxEnvironments.is_terminated(subject)
        empty!(ax)
        ax.cycler.counters[Scatter] = 0
        ax.cycler.counters[Lines] = 0
        RxEnvironments.plot_state(ax, underlying) 
        sleep(1 / fps)
    end
end

function RxEnvironments.plot_state(ax, environment::RxEnvironments.MountainCarEnvironment)
    x = range(-2, 2, 100)
    y = environment.landscape.(x)
    lines!(ax, x, y)
    for agent in environment.actors
        position = RxEnvironments.position(agent)
        scatter!(ax, position, environment.landscape(position))
    end
end

end