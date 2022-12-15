using Documenter
using QUBOTools

# Set up to run docstrings with jldoctest
DocMeta.setdocmeta!(QUBOTools, :DocTestSetup, :(using QUBOTools); recursive = true)

makedocs(;
    modules = [QUBOTools],
    doctest = true,
    clean = true,
    format = Documenter.HTML(
        assets = ["assets/extra_styles.css", "assets/favicon.ico"],
        mathengine = Documenter.KaTeX(),
        sidebar_sitename = false,
    ),
    sitename = "QUBOTools.jl",
    authors = "Pedro Xavier and and Pedro Ripper and Tiago Andrade and Joaquim Garcia and David Bernal",
    pages = [
        "Home"    => "index.md",
        "Manual"  => "manual.md",
        "Formats" => [
            "BQPJSON"  => "formats/BQPJSON.md",
            "HFS"      => "formats/HFS.md",
            "MiniZinc" => "formats/MiniZinc.md",
            "Qubist"   => "formats/Qubist.md",
            "QUBO"     => "formats/QUBO.md",
        ],
        "Analysis"      => "analysis.md",
        "API Reference" => "api.md",
    ],
    workdir = @__DIR__,
)

if "--skip-deploy" ∈ ARGS
    @warn "Skipping deployment"
else
    deploydocs(repo = raw"github.com/psrenergy/QUBOTools.jl.git", push_preview = true)
end
