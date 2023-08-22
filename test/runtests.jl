using RxEnvironments
using Aqua
using ReTest

include("entity.jl")
include("environment.jl")

module RxEnvironmentsTests

using ReTest
using Aqua
using RxEnvironments

@testset "RxEnvironments.jl" begin
    Aqua.test_all(RxEnvironments)
end

end

retest(RxEnvironments, RxEnvironmentsTests)
retest(RxEnvironments, test_entity)
retest(RxEnvironments, test_environment)
