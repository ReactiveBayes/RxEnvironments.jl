import HypergeometricFunctions: _₂F₁
using RxEnvironments
using Distributions
using ForwardDiff
using DifferentialEquations

export MountainCar

function landscape(x)
    if x < 0
        h = x^2 + x
    else
        h =
            x * _₂F₁(0.5, 0.5, 1.5, -5 * x^2) +
            x^3 * _₂F₁(1.5, 1.5, 2.5, -5 * x^2) / 3 +
            x^5 / 80
    end
    return 0.05 * h
end

mutable struct MountainCarState
    position::Float64
    velocity::Float64
    throttle::Float64
end

position(state::MountainCarState) = state.position
velocity(state::MountainCarState) = state.velocity
throttle(state::MountainCarState) = state.throttle
set_position!(state::MountainCarState, position::Float64) = state.position = position
set_velocity!(state::MountainCarState, velocity::Float64) = state.velocity = velocity
set_throttle!(state::MountainCarState, throttle::Float64) = state.throttle = throttle


struct MountainCarAgent
    state::MountainCarState
    engine_power::Float64
    friction_coefficient::Float64
    target::Float64
end

state(car::MountainCarAgent) = car.state
position(car::MountainCarAgent) = position(state(car))
velocity(car::MountainCarAgent) = velocity(state(car))
throttle(car::MountainCarAgent) = throttle(state(car))
set_position!(car::MountainCarAgent, position::Float64) =
    set_position!(state(car), position)
set_velocity!(car::MountainCarAgent, velocity::Float64) =
    set_velocity!(state(car), velocity)
set_throttle!(car::MountainCarAgent, throttle::Float64) =
    set_throttle!(state(car), throttle)
engine_power(car::MountainCarAgent) = car.engine_power
friction_coefficient(car::MountainCarAgent) = car.friction_coefficient


struct MountainCarEnvironment
    actors::Vector{MountainCarAgent}
    landscape::Any
end

MountainCarEnvironment(landscape) = MountainCarEnvironment([], landscape)
get_agent(env::AbstractEntity{MountainCarEnvironment}; index::Int = 1) =
    entity(env).actors[index]

struct Throttle
    throttle::Real
    Throttle(throttle::Real) = new(clamp(throttle, -1, 1))
end

power(throttle::Throttle, car::MountainCarAgent) =
    car.engine_power * tanh(throttle.throttle)
friction(car::MountainCarAgent) = velocity(car) * -friction_coefficient(car)

function gravitation(car::MountainCarAgent, landscape)
    result = -9.81 * sin(atan(ForwardDiff.derivative(landscape, position(car))))
    return result
end

function RxEnvironments.act!(
    environment::MountainCarEnvironment,
    agent::MountainCarAgent,
    action::Throttle,
)
    set_throttle!(agent, power(action, agent))
end

function RxEnvironments.observe(
    agent::MountainCarAgent,
    environment::MountainCarEnvironment,
)
    return state(agent)
end

function RxEnvironments.update!(environment::MountainCarEnvironment, elapsed_time::Float64)
    for agent in environment.actors
        set_position!(agent, position(agent) + elapsed_time * velocity(agent))
        set_velocity!(
            agent,
            velocity(agent) + (
                elapsed_time * (
                    throttle(agent) +
                    friction(agent) +
                    gravitation(agent, environment.landscape)
                )
            ),
        )
    end
end

function RxEnvironments.add_to_state!(
    environment::MountainCarEnvironment,
    agent::MountainCarAgent,
)
    push!(environment.actors, agent)
end


function MountainCar(
    num_actors::Int;
    engine_power::Float64 = 0.6,
    friction_coefficient::Float64 = 0.9,
    emit_every_ms::Int = 10,
    real_time_factor::Real = 1.0,
    landscape = landscape,
    discrete = false,
)
    env = RxEnvironment(
        MountainCarEnvironment(landscape);
        discrete = discrete,
        emit_every_ms = emit_every_ms,
        real_time_factor = real_time_factor,
    )
    for i = 1:num_actors
        add!(
            env,
            MountainCarAgent(
                MountainCarState(0.0, 0.0, 0.0),
                engine_power,
                friction_coefficient,
                0.0,
            ),
        )
    end
    return env
end
