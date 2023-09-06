
# [Getting Started](@id lib-started)
When using RxEnvironments, you only have to specify the dynamics of your environment. Let's create the Bayesian Thermostat environment in `RxEnvironments`. For this example, you need `Distributions.jl` installed in your environment as well. 

Let's create the basics of our environment:

```julia
using RxEnvironments
using Distributions

# Empty agent, could contain states as well
struct ThermostatAgent end

mutable struct BayesianThermostat
    temperature::Real
    min_temp::Real
    max_temp::Real
end

# Helper functions
temperature(env::BayesianThermostat) = env.temperature
min_temp(env::BayesianThermostat) = env.min_temp
max_temp(env::BayesianThermostat) = env.max_temp
noise(env::BayesianThermostat) = Normal(0.0, 0.1)
set_temperature!(env::BayesianThermostat, temp::Real) = env.temperature = temp
function add_temperature!(env::BayesianThermostat, diff::Real) 
    env.temperature += diff
    if temperature(env) < min_temp(env)
        set_temperature!(env, min_temp(env))
    elseif temperature(env) > max_temp(env)
        set_temperature!(env, max_temp(env))
    end
end
```

By implementing `RxEnvironments.act!`, `RxEnvironments.observe` and `RxEnvironments.update!` for our environment, we can fully specify the behaviour of our environment, and `RxEnvironments` will take care of the rest. In order to follow along with the sanity checks, please install `Rocket.jl` as well.

```julia
RxEnvironments.act!(env::BayesianThermostat, actor::ThermostatAgent, action::Float64) = add_temperature!(env, action)

# The agent receives a noisy observation of the environment's temperature 
RxEnvironments.observe(receiver::ThermostatAgent, emitter::BayesianThermostat) = temperature(emitter) + rand(noise(emitter))

# The environment cools down over time.
RxEnvironments.update!(env::BayesianThermostat, elapsed_time)= add_temperature!(env, -0.1 * elapsed_time)
```

Now we've fully specified our environment, and we can interact with it. In order to create the environment, we use the `RxEnvironment` struct, and we add an agent to this environment using `add!`:

```julia
environment = RxEnvironment(BayesianThermostat(0.0, -10, 10))
agent = add!(environment, ThermostatAgent())
```

Now we can have the agent conduct actions in our environment. Let's have the agent conduct some actions, and inspect the observations that are being returned by the environment:

```julia
using Rocket

# Subscribe a logger actor to the observations of the agent
RxEnvironments.subscribe_to_observations!(agent, logger())

# Conduct 10 actions:
for i in 1:10
    action = rand()
    RxEnvironments.conduct_action!(agent, environment, action)
    sleep(1/5)
end
```

```
[LogActor] Data: 0.006170718477015863
[LogActor] Data: -0.09624863445330185
[LogActor] Data: -0.3269267933074502
[LogActor] Data: 0.001304207094952492
[LogActor] Data: 0.03626599314271475
[LogActor] Data: 0.010733164205412482
[LogActor] Data: 0.12313893922057219
[LogActor] Data: -0.013042652548091921
[LogActor] Data: 0.03561033321842316
[LogActor] Data: 0.6763921880509323
[LogActor] Data: 0.8313618838112217
[LogActor] Data: 1.7408316683602163
[LogActor] Data: 1.7322639115928715
[LogActor] Data: 1.458556241545732
[LogActor] Data: 1.6689296645689367
[LogActor] Data: 1.683300152848493
[LogActor] Data: 2.087509970813057
[LogActor] Data: 2.258940017058188
[LogActor] Data: 2.6537100822978372
[LogActor] Data: 2.6012179767058408
[LogActor] Data: 3.0775745739101716
[LogActor] Data: 2.7326464283572727
```

Congratulations! You've now implemented a basic environment in `RxEnvironments`.
