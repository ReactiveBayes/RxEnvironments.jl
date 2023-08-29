using RxEnvironments
using Rocket

struct MockAgent end

struct SecondMockAgent end

mutable struct MockEnvironment
    state::Any
end

RxEnvironments.update!(environment::MockEnvironment) = nothing
RxEnvironments.update!(environment::MockEnvironment, elapsed_time) = nothing
RxEnvironments.act!(environment::MockEnvironment, agent::Any, action::Any) = nothing
RxEnvironments.observe(agent::MockAgent, environment::MockEnvironment) = nothing
RxEnvironments.observe(agent::SecondMockAgent, environment::MockEnvironment) =
    RxEnvironments.EmptyMessage()

RxEnvironments.observe(agent::Rocket.Actor{Any}, environment::MockEnvironment) =
    environment.state
