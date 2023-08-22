using RxEnvironments
using Distributions

struct ThermostatAgent 

end

struct ThermostatAction 
    action::Float64
end


mutable struct BayesianThermostat
    temperature::Float64
    min_temp::Float64
    max_temp::Float64
end

min_temp(env::BayesianThermostat) = env.min_temp
max_temp(env::BayesianThermostat) = env.max_temp
noise(env::BayesianThermostat) = Normal(0.0, 0.1)


function RxEnvironments.act!(env::BayesianThermostat, actor::ThermostatAgent, action::ThermostatAction)
    value = action.action
    env.temperature += value

    if env.temperature < env.min_temp
        env.temperature = env.min_temp
    elseif env.temperature > env.max_temp
        env.temperature = env.max_temp
    end
end

function RxEnvironments.observe(receiver::ThermostatAgent, emitter::BayesianThermostat, stimulus)
    return emitter.temperature + rand(noise(emitter))
end

function RxEnvironments.update!(env::BayesianThermostat, elapsed_time)
    # Do nothing
end

