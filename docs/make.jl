using Documenter
using QUBO

# Set up to run docstrings with jldoctest
DocMeta.setdocmeta!(
    QUBO, :DocTestSetup, :(using QUBO); recursive=true
)

makedocs(;
    modules=[QUBO],
    doctest=true,
    clean=true,
    format=Documenter.HTML(
        assets = ["assets/extra_styles.css", "assets/favicon.ico"],
        mathengine=Documenter.MathJax2(),
        sidebar_sitename=false,
    ), 
    sitename="QUBOTools.jl",
    authors="Pedro Xavier and Tiago Andrade and Joaquim Garcia and David Bernal",
    pages=[
        "Home" => "index.md",
        "manual.md",
        "examples.md",
    ],
    workdir="."
)

# deploydocs(
#     repo=raw"github.com/psrenergy/QUBOTools.jl.git",
#     push_preview = true
# )