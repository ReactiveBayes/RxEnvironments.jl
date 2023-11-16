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

struct MockEnvironment end

RxEnvironments.update!(subject::MockEnvironment) = nothing
RxEnvironments.update!(subject::MockEnvironment, elapsed_time) = nothing
