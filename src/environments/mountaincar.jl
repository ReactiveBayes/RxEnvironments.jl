import HypergeometricFunctions: _₂F₁
using RxEnvironments
using Distributions
using ForwardDiff
using DifferentialEquations

export MountainCar, get_agent

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
set_position!(state::MountainCarState, position::Real) = state.position = position
set_velocity!(state::MountainCarState, velocity::Real) = state.velocity = velocity
set_throttle!(state::MountainCarState, throttle::Real) = state.throttle = throttle


struct MountainCarAgent
    state::MountainCarState
    engine_power::Float64
    friction_coefficient::Float64
    target::Float64
end

MountainCarAgent(position::Real, engine_power::Real, friction_coefficient::Real, target::Real) =
    MountainCarAgent(
        MountainCarState(position, 0.0, 0.0),
        engine_power,
        friction_coefficient,
        target
    )

state(car::MountainCarAgent) = car.state
position(car::MountainCarAgent) = position(state(car))
velocity(car::MountainCarAgent) = velocity(state(car))
throttle(car::MountainCarAgent) = throttle(state(car))
set_position!(car::MountainCarAgent, position::Real) =
    set_position!(state(car), position)
set_velocity!(car::MountainCarAgent, velocity::Real) =
    set_velocity!(state(car), velocity)
set_throttle!(car::MountainCarAgent, throttle::Real) =
    set_throttle!(state(car), throttle)
engine_power(car::MountainCarAgent) = car.engine_power
friction_coefficient(car::MountainCarAgent) = car.friction_coefficient


struct MountainCarEnvironment
    actors::Vector{MountainCarAgent}
    landscape::Any
end

MountainCarEnvironment(landscape) = MountainCarEnvironment([], landscape)
get_agent(env::AbstractEntity{MountainCarEnvironment}; index::Int = 1) =
    subscribers(env)[index]

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

function act!(
    environment::MountainCarEnvironment,
    agent::MountainCarAgent,
    action::Throttle,
)
    set_throttle!(agent, action.throttle * agent.engine_power)
end

function observe(
    agent::MountainCarAgent,
    environment::MountainCarEnvironment,
)
    return state(agent)
end

function update!(environment::MountainCarEnvironment, elapsed_time::Float64)
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

update!(environment::MountainCarEnvironment) = update!(environment, 0.0025)

function add_to_state!(
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
