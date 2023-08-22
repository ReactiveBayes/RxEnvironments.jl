using RxEnvironments
using Distributions

struct MockAgent end

struct SecondMockAgent end

mutable struct MockEnvironment
    state::Any
end

RxEnvironments.update!(environment::MockEnvironment, time::Float64) = nothing
RxEnvironments.act!(environment::MockEnvironment, agent::Any, action::Any) = nothing
RxEnvironments.observe(agent::MockAgent, environment::MockEnvironment, stimulus) = nothing
RxEnvironments.observe(agent::SecondMockAgent, environment::MockEnvironment, stimulus) =
    RxEnvironments.EmptyMessage()
