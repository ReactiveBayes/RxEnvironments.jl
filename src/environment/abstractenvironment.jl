using Rocket

export AbstractEnvironment, observation_type, add!, act!

"""
    AbstractEnvironment

The AbstractEnvironment type supertypes all environments. It describes basic functionality all environments should have.
"""
abstract type AbstractEnvironment end

function add_subscription_loop!(env::AbstractEnvironment, entity::AbstractEntity)
    ltr = ObservationActor(entity, env)
    rtl = ActionActor(entity, env)
    subscribe!(subject(env), ltr)
    subscribe!(action_subject(entity), rtl)
end  

function observation_type end
function update! end
function act! end
function observe end