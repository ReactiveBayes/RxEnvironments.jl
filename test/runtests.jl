using RxEnvironments
using Aqua
using ReTest

include("core/entity.jl")
include("core/markovblanket.jl")
include("core/exceptions.jl")
include("core/environment.jl")
include("core/discreteenvironment.jl")

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
