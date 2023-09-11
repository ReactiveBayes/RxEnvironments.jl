using Documenter
using RxEnvironments

makedocs(
    sitename = "RxEnvironments.jl",
    format = Documenter.HTML(),
    modules = [RxEnvironments],
    pages = [
        "Introduction" => "index.md",
        "Getting Started" => "lib/getting_started.md",
        "Example: Mountain Car" => "lib/example_mountaincar.md",
        "Advanced Usage" => "lib/advanced_usage.md",
        "Design Philosophy" => "lib/philosophy.md",
        "API Reference" => "lib/api_reference.md",
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/biaslab/RxEnvironments.jl.git"
)
