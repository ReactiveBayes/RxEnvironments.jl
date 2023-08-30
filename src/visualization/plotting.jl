using GLMakie

export animate_state

function plot_state end

function animate_state(subject::AbstractEntity; fps=60, seconds=10)
    figure = Figure()
    ax = Axis(figure[1,1])
    underlying = entity(subject)
    display(figure)
    for _ in 1:fps*seconds
        empty!(ax)
        ax.cycler.counters[Scatter] = 0
        ax.cycler.counters[Lines] = 0
        plot_state(ax, underlying)
        sleep(1/fps)
    end
end