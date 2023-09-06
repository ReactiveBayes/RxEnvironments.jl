# [Advanced Usage](@id lib-advanced-examples)

## Changing the emission rate and environment speed

By default, any `RxEnvironment` emits an observation to any subscribed agents every `1000` milliseconds, or whenever any agent in the environment conducts an action. To change this, one can use the `emit_every_ms` keyword argument to the `RxEnvironment` function. Taking the environment from the example:

```julia
environment = RxEnvironment(BayesianThermostat(0.0, -10, 10); emit_every_ms = 10)
```
Will emit an observation to any agents in the environment every `10` milliseconds.

By adjusting the `real_time_factor` keyword argument to the `RxEnvironment` function, one can play with the amount of computation time we give to agents to conduct their actions. For example:
```
environment = RxEnvironment(BayesianThermostat(0.0, -10, 10); emit_every_ms = 1000, real_time_factor=2)
```
Will emit an observation to every subscribed agent every 1000 milliseconds. However, the environment will only have moved 500 milliseconds forward, giving any subscribed agent twice as much time to choose an action than that it would have in a real-time setting.

## Discrete Environments

`RxEnvironments` natively represents any environment as a continuous environment. However, discrete environments are also supported. By including the keyword argument `discrete=true` to the `RxEnvironment` function, we convert the environment to a discrete environment. There are 2 major differences between a discrete `RxEnvironment` and a continuous one:

- A discrete environment waits until all agents in the environment have conducted an action, and only then takes the last action emitted by every agent into account. I.e. if we have an environment with `agent_1` and `agent_2` as agents. If `agent_1` emits two actions before `agent_2` emits, the environment will only incorporate the second action emitted by `agent_1` whenever `agent_2` emits.
- A discrete environment needs to implement `update!(::EnvironmentType)`, without the `elapsed_time` argument, since the state-transition does not depend on the elapsed time.

Tip: by implementing `update!(::Environment) = update!(::Environment, dt)` for a constant `dt`, a custom environment can be initialized both as a continuous as a discrete environment.

## Animating Environments
Animating an environment is done using the `GLMakie` package. In order to animate your custom environments, please implement `RxEnvironments.plot_state(ax, ::EnvironmentType)`, where `ax` is the `GLMakie` axis object that you can plot towards. If you need access to other agents or entities in order to plot your environments, you can extend `RxEnvironments.add_to_state!(::EnvironmentType, ::AgentType)` to make sure you have access to subscribed agents in the state.

By calling `RxEnvironments.animate_state(::RxEnvironment; fps)`, `RxEnvironments` animates the plots you generate in the `plot_state` function to accurately reflect the state of your environment in real time.

## Multi-Agent Environments
RxEnvironments natively supports multi-agent environments, similarly to how we call `add!(environment, agent)` in the example page, we can call `add!` with additional agents in order to create a multi-agent environment. 

## Inspecting Observations
By using `RxEnvironments.subscribe_to_observations!` we can subscribe any `Rocket` actor to the observations of any entity. Note that these observations will be of type `Observation`, that also contains a reference to the entity that emitted the observation. In order to retrieve the value of the observation, you can call `RxEnvironments.data` on the `Observation` instance.