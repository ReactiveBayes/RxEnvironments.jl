using Documenter
using RxEnvironments

makedocs(
    sitename="RxEnvironments.jl",
    format=Documenter.HTML(),
    modules=[RxEnvironments],
    pages=[
        "Introduction" => "index.md",
        "Getting Started" => "lib/getting_started.md",
        "Examples" => ["Mountain Car" => "lib/example_mountaincar.md",
            "Windy Gridworld" => "lib/example_discrete_control_space_env.md"],
        "Advanced Usage" => "lib/advanced_usage.md",
        "Design Philosophy" => "lib/philosophy.md",
        "API Reference" => "lib/api_reference.md",
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo="github.com/biaslab/RxEnvironments.jl.git"
)
