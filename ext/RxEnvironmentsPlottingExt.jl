module RxEnvironmentsPlottingExt

using RxEnvironments, GLMakie, Rocket

function RxEnvironments.animate_state(subject::AbstractEntity; verbose=true)
    if verbose
        @info "Animating state of $(subject)"
    end
    fig = Figure()
    screen = display(fig)
    actor = PlottingActor(subject, fig, screen)
    subscription = subscribe!(subject, actor)
    RxEnvironments.send!(actor, subject, nothing)
end


struct PlottingActor <: Rocket.Actor{Any}
    entity::AbstractEntity
    fig::Figure
    screen
end

function Rocket.on_next!(actor::PlottingActor, observation)
    empty!(actor.fig)
    subject = RxEnvironments.decorated(actor.entity)
    ax = Axis(actor.fig[1, 1])
    RxEnvironments.plot_state(ax, subject)
end

function Rocket.on_complete!(actor::PlottingActor)
    GLMakie.destroy!(actor.screen)
end

function Rocket.unsubscribe!(x, self::PlottingActor)
    Rocket.complete!(self)
end

end