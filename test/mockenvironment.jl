using RxEnvironments
using Rocket

struct MockEntity end
struct SelectiveSendingEntity end

RxEnvironments.update!(subject::SelectiveSendingEntity) = nothing
RxEnvironments.update!(subject::SelectiveSendingEntity, elapsed_time) = nothing

struct SelectiveReceivingEntity end

RxEnvironments.emits(subject::SelectiveSendingEntity, listener::MockEntity, action) = true

RxEnvironments.emits(
    subject::SelectiveSendingEntity,
    listener::SelectiveReceivingEntity,
    action::Nothing,
) = false

RxEnvironments.what_to_send(
    recipient::SelectiveReceivingEntity,
    emitter::SelectiveSendingEntity,
    observation::Float64,
) = 1.0

RxEnvironments.what_to_send(
    recipient::SelectiveReceivingEntity,
    emitter::SelectiveSendingEntity,
    observation::Bool,
) = true

struct MockEnvironment end

RxEnvironments.update!(subject::MockEnvironment) = nothing
RxEnvironments.update!(subject::MockEnvironment, elapsed_time) = nothing


struct DiscreteMockEnvironment end

RxEnvironments.update!(subject::DiscreteMockEnvironment) = nothing
RxEnvironments.update!(subject::DiscreteMockEnvironment, elapsed_time) = nothing

struct DiscreteMockEntity end

RxEnvironments.update!(subject::DiscreteMockEntity) = nothing
RxEnvironments.update!(subject::DiscreteMockEntity, elapsed_time) = nothing

RxEnvironments.emits(
    subject::DiscreteMockEntity,
    listener::DiscreteMockEnvironment,
    action::Int,
) = true
RxEnvironments.emits(
    subject::DiscreteMockEntity,
    listener::DiscreteMockEnvironment,
    action,
) = false

RxEnvironments.what_to_send(
    env::DiscreteMockEnvironment,
    entity::DiscreteMockEntity,
    action::Int,
) = 1

RxEnvironments.what_to_send(
    entity::DiscreteMockEntity,
    env::DiscreteMockEnvironment,
    action::Int,
) = "action"
RxEnvironments.what_to_send(
    entity::DiscreteMockEntity,
    env::DiscreteMockEnvironment,
    action,
) = 1
