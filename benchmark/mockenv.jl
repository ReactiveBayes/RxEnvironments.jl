using RxEnvironments

struct MockEntity end

struct MockEnvironment end

RxEnvironments.update!(subject::MockEnvironment, elapsed_time) = nothing
RxEnvironments.what_to_send(
    recipient::MockEntity,
    emitter::MockEnvironment,
    observation::Float64,
) = 1.0

RxEnvironments.what_to_send(
    recipient::MockEnvironment,
    emitter::MockEntity,
    observation::Float64,
) = 1.0

RxEnvironments.emits(
    subject::MockEntity,
    listener::MockEnvironment,
    action::Float64,
) = false

RxEnvironments.emits(
    subject::MockEnvironment,
    listener::MockEntity,
    action::Float64,
) = true