using RxEnvironments
using Aqua
using ReTest

include("entity/entity.jl")
include("markovblanket.jl")
include("exceptions.jl")
include("environment/environment.jl")
include("environment/discreteenvironment.jl")

module RxEnvironmentsTests

using ReTest
using Aqua
using RxEnvironments

@testset "RxEnvironments.jl" begin
    Aqua.test_all(RxEnvironments; ambiguities = false)
end

end

retest(RxEnvironments, RxEnvironmentsTests)
retest(RxEnvironments, EntityTests)
retest(RxEnvironments, TestMarkovBlanket)
retest(RxEnvironments, TestExceptions)
retest(RxEnvironments, EnvironmentTests)
retest(RxEnvironments, TestDiscreteEnvironment)
