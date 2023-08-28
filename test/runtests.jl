using RxEnvironments
using Aqua
using ReTest

include("entity.jl")
include("environment.jl")
include("markovblanket.jl")

module RxEnvironmentsTests

using ReTest
using Aqua
using RxEnvironments

@testset "RxEnvironments.jl" begin
    Aqua.test_all(RxEnvironments)
end

end

retest(RxEnvironments, RxEnvironmentsTests)
retest(RxEnvironments, EntityTests)
retest(RxEnvironments, EnvironmentTests)
retest(RxEnvironments, TestMarkovBlanket)
