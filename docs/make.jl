using Documenter
using RxEnvironments

makedocs(
    sitename = "RxEnvironments",
    format = Documenter.HTML(),
    modules = [RxEnvironments]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/biaslab/RxEnvironments.jl.git"
)
