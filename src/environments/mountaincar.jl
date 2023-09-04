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

mutable struct MountainCarTrajectory
    recompute::Bool
    time_left::Real
    trajectory
    T::Real
end

recompute(trajectory::MountainCarTrajectory) = trajectory.recompute
time_left(trajectory::MountainCarTrajectory) = trajectory.time_left
total_time(trajectory::MountainCarTrajectory) = trajectory.T
Base.getindex(trajectory::MountainCarTrajectory, index) = trajectory.trajectory(index)
set_trajectory!(t::MountainCarTrajectory, trajectory) =
    t.trajectory = trajectory
set_recompute!(trajectory::MountainCarTrajectory, recompute) =
    trajectory.recompute = recompute
set_time_left!(trajectory::MountainCarTrajectory, time_left) =
    trajectory.time_left = time_left
reduce_time_left!(trajectory::MountainCarTrajectory, elapsed_time) =
    set_time_left!(trajectory, time_left(trajectory) - elapsed_time)
set_total_time!(trajectory::MountainCarTrajectory, T) =
    trajectory.T = T

mutable struct MountainCarState
    position::Float64
    velocity::Float64
    throttle::Float64
    trajectory::MountainCarTrajectory
end

MountainCarState(position::Real, velocity::Real, throttle::Real) =
    MountainCarState(position, velocity, throttle, MountainCarTrajectory(true, 0.0, [], 0.0))

position(state::MountainCarState) = state.position
velocity(state::MountainCarState) = state.velocity
throttle(state::MountainCarState) = state.throttle
set_position!(state::MountainCarState, position::Real) = state.position = position
set_velocity!(state::MountainCarState, velocity::Real) = state.velocity = velocity
set_throttle!(state::MountainCarState, throttle::Real) = state.throttle = throttle
trajectory(state::MountainCarState) = state.trajectory



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
trajectory(car::MountainCarAgent) = trajectory(state(car))


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

friction(car::MountainCarAgent, velocity) = velocity * -friction_coefficient(car)

function gravitation(position, landscape)
    result = -9.81 * sin(atan(ForwardDiff.derivative(landscape, position)))
    return result
end

function act!(
    environment::MountainCarEnvironment,
    agent::MountainCarAgent,
    action::Throttle,
)
    set_throttle!(agent, action.throttle * engine_power(agent))
end

function observe(
    agent::MountainCarAgent,
    environment::MountainCarEnvironment,
)
    return state(agent)
end

function __mountain_car_dynamics(du, u, s, t)
    agent, env = s
    momentum = u[2]
    du[1] = momentum
    du[2] = throttle(agent) + friction(agent, momentum) + gravitation(u[1], env.landscape)
end

function __compute_mountain_car_dynamics(agent::MountainCarAgent, environment::MountainCarEnvironment)
    T = 10.0
    initial_state = [position(agent), velocity(agent)]
    tspan = (0.0, T)
    prob = ODEProblem(__mountain_car_dynamics, initial_state, tspan, (agent, environment))
    sol = solve(prob, Tsit5())
    set_trajectory!(trajectory(agent), sol)
    set_recompute!(trajectory(agent), false)
    set_time_left!(trajectory(agent), T)
    set_total_time!(trajectory(agent), T)
end

function update!(environment::MountainCarEnvironment, elapsed_time::Float64)
    for agent in environment.actors
        if recompute(trajectory(agent)) || time_left(trajectory(agent)) < elapsed_time
            __compute_mountain_car_dynamics(agent, environment)
        end
        reduce_time_left!(trajectory(agent), elapsed_time)
        new_state = trajectory(agent)[total_time(trajectory(agent)) - time_left(trajectory(agent))]
        set_position!(agent, new_state[1])
        set_velocity!(agent, new_state[2])
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
    engine_power::Real = 0.6,
    friction_coefficient::Real = 3,
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
