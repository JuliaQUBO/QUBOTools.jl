include("build.jl")

build_docs(; deploy = !("--skip-deploy" ∈ ARGS))
