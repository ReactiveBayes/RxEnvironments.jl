using RxEnvironments
using Distributions

struct ThermostatAgent 

end

struct ThermostatAction 
    action::Float64
end

RxEnvironments.observation_type(agent::ThermostatAgent) = Float64

mutable struct BayesianThermostat
    temperature::Float64
    min_temp::Float64
    max_temp::Float64
end

min_temp(env::BayesianThermostat) = env.min_temp
max_temp(env::BayesianThermostat) = env.max_temp
noise(env::BayesianThermostat) = Normal(0.0, 0.1)

RxEnvironments.observation_type(env::BayesianThermostat) = ThermostatAction

function RxEnvironments.act!(env::BayesianThermostat, actor::ThermostatAgent, action::ThermostatAction)
    value = action.action
    env.temperature += value

    if env.temperature < env.min_temp
        env.temperature = env.min_temp
    elseif env.temperature > env.max_temp
        env.temperature = env.max_temp
    end
end

function RxEnvironments.observe(env::BayesianThermostat, actor::ThermostatAgent)
    return env.temperature + rand(noise(env))
end

function RxEnvironments.update!(env::BayesianThermostat)
    # Do nothing
end

