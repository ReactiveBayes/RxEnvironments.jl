using RxEnvironments
using Aqua
using ReTest

include("entity.jl")
include("environment.jl")
include("markovblanket.jl")
include("exceptions.jl")

module RxEnvironmentsTests

using ReTest
using Aqua
using RxEnvironments

@testset "RxEnvironments.jl" begin
    Aqua.test_all(RxEnvironments; ambiguities=false)
end

end

retest(RxEnvironments, RxEnvironmentsTests)
retest(RxEnvironments, EntityTests)
retest(RxEnvironments, EnvironmentTests)
retest(RxEnvironments, TestMarkovBlanket)
retest(RxEnvironments, TestExceptions)
