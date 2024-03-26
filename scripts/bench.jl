using RxEnvironments
using BenchmarkTools
using PkgBenchmark

result, name = if ARGS == []
    PkgBenchmark.benchmarkpkg(RxEnvironments), "current"
else
    BenchmarkTools.judge(
        RxEnvironments,
        ARGS[1];
        judgekwargs = Dict(:time_tolerance => 0.1, :memory_tolerance => 0.05),
    ),
    ARGS[1]
end

export_markdown("benchmark_vs_$(name)_result.md", result)
