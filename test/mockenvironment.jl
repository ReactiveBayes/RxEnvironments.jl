using RxEnvironments
using Rocket

struct MockAgent end

struct SecondMockAgent end

mutable struct MockEnvironment
    state::Any
end

RxEnvironments.update!(environment::MockEnvironment) = nothing
RxEnvironments.update!(environment::MockEnvironment, elapsed_time) = nothing
RxEnvironments.receive!(environment::MockEnvironment, agent::Any, action::Any) = nothing
RxEnvironments.send!(agent::MockAgent, environment::MockEnvironment) = nothing
RxEnvironments.send!(agent::SecondMockAgent, environment::MockEnvironment) =
    RxEnvironments.EmptyMessage()

RxEnvironments.send!(agent::Rocket.Actor{Any}, environment::MockEnvironment) =
    environment.state

RxEnvironments.emits(subject::MockEnvironment, listener::MockEnvironment, action::Any) =
    false

RxEnvironments.send!(agent::MockAgent, environment::MockEnvironment, action::Int) =
    "Integer sent"
RxEnvironments.send!(
    agent::MockAgent,
    environment::RxEnvironments.RxEntity{
        MockEnvironment,
        RxEnvironments.DiscreteEntity,
        RxEnvironments.IsEnvironment,
    },
    action::Float64,
) = "Float sent"
