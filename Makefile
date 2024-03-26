scripts_init:
	julia --startup-file=no --project=scripts/ -e 'using Pkg; Pkg.instantiate(); Pkg.update(); Pkg.precompile();'

format: scripts_init ## Code formating run
	julia --startup-file=no --project=scripts/ scripts/format.jl --overwrite

doc_init:
	julia --project=docs -e 'ENV["PYTHON"]=""; using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate();'

docs: doc_init ## Generate documentation
	julia --project=docs/ docs/make.jl

bench: ## Run benchmark, use `make bench branch=...` to test against a specific branch
	julia --startup-file=no --project=scripts/ scripts/bench.jl $(branch)