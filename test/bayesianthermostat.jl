using RxEnvironments
using Distributions

struct ThermostatAgent end

mutable struct BayesianThermostat
    temperature::Float64
    min_temp::Float64
    max_temp::Float64
end

temperature(env::BayesianThermostat) = env.temperature
min_temp(env::BayesianThermostat) = env.min_temp
max_temp(env::BayesianThermostat) = env.max_temp
noise(env::BayesianThermostat) = Normal(0.0, 0.1)


function RxEnvironments.act!(
    env::BayesianThermostat,
    actor::ThermostatAgent,
    action::Float64,
)
    env.temperature += action

    if env.temperature < env.min_temp
        env.temperature = env.min_temp
    elseif env.temperature > env.max_temp
        env.temperature = env.max_temp
    end
end

function RxEnvironments.observe(
    receiver::ThermostatAgent,
    emitter::BayesianThermostat,
    stimulus,
)
    # The agent receives a noisy observation of the environment's temperature
    return tempreature(emitter) + rand(noise(emitter))
end

function RxEnvironments.update!(env::BayesianThermostat, elapsed_time)
    #The environment cools down over time
    env.temperature -= 0.1 * elapsed_time
end
