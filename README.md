# RxEnvironments

[![Build Status](https://github.com/biaslab/RxEnvironments.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/biaslab/RxEnvironments.jl/actions/workflows/CI.yml?query=branch%3Amain)

`RxEnvironments` contains all boilerplate code to create reactive environments for self-learning agents. `RxEnvironments` exports the `RxEnvironment` and `RxEntity` wrapper structs, that facilitate all plumbing to make an environment fully reactive. Under the hood, `RxEnvironments` uses [Rocket.jl](https://www.github.com/biaslab/Rocket.jl).

# Usage

When using RxEnvironments, you only have to specify the dynamics of your environment. Let's create the Bayesian Thermostat environment in `RxEnvironments`. For this example, you need `Distributions.jl` installed in your environment as well. 

Let's create the basics of our environment:

```julia
using RxEnvironments
using Distributions

# Empty agent, could contain states as well
struct ThermostatAgent end

mutable struct BayesianThermostat
    temperature::Float64
    min_temp::Float64
    max_temp::Float64
end

# Helper functions
temperature(env::BayesianThermostat) = env.temperature
min_temp(env::BayesianThermostat) = env.min_temp
max_temp(env::BayesianThermostat) = env.max_temp
noise(env::BayesianThermostat) = Normal(0.0, 0.1)
```

By overriding `RxEnvironments.act!`, `RxEnvironments.observe` and `RxEnvironments.update!` for our environment, we can fully specify the behaviour of our environment, and `RxEnvironments` will take care of the rest. In order to follow along with the sanity checks, please install `Rocket.jl` as well.

```julia
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
    return temperature(emitter) + rand(noise(emitter))
end

function RxEnvironments.update!(env::BayesianThermostat, elapsed_time)
    #The environment cools down over time
    env.temperature -= 0.1 * elapsed_time
end

```

Now we've fully specified our environment, and we can interact with it. In order to create the environment, we use the `RxEnvironment` struct, and we add an agent to this environment using `add!`:

```julia
environment = RxEnvironments.RxEnvironment(BayesianThermostat(0.0, -10, 10))
agent = add!(environment, ThermostatAgent())
```

Now we can have the agent conduct actions in our environment. Let's have the agent conduct some actions, and inspect the observations that are being returned by the environment:

```julia
# Subscribe a logger actor to the observations of the agent
observations_observable = RxEnvironments.observations(agent) |> map(Any, x -> x[2])
subscribe!(observations_observable, logger())

# Conduct 10 actions:
for i in 1:10
    action = rand()
    next!(agent, environment, action)
end
```

```
[LogActor] Data: 0.8783651611603845
[LogActor] Data: 1.3849534176631442
[LogActor] Data: 1.5085848744196275
[LogActor] Data: 1.8361924994230445
[LogActor] Data: 2.266499744384115
[LogActor] Data: 2.6178644173932644
[LogActor] Data: 3.168452713434807
[LogActor] Data: 3.4012300021644557
[LogActor] Data: 3.304506414146602
[LogActor] Data: 3.909972365773481
```

Congratulations! You've now implemented a basic environment in `RxEnvironments`.