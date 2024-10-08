using Documenter
using DocumenterDiagrams
using QUBOTools

# Set up to run docstrings with jldoctest
DocMeta.setdocmeta!(QUBOTools, :DocTestSetup, :(using QUBOTools); recursive = true)

makedocs(;
    modules  = [QUBOTools, QUBOTools.PBO],
    doctest  = true,
    clean    = true,
    sitename = "QUBOTools.jl",
    authors  = "Pedro Maciel Xavier and Pedro Ripper and Tiago Andrade and Joaquim Garcia and David E. Bernal Neira",
    workdir  = @__DIR__,
    warnonly = [:missing_docs],
    pages    = [
        "Home" => "index.md",
        "Manual" => [
            "Introduction"             => "manual/1-start.md",
            "Mathematical Formulation" => "manual/2-math.md",
            "Basic Usage"              => "manual/3-usage.md",
            "Models"                   => "manual/4-models.md",
            "File Formats"             => "manual/5-formats.md",
            "Solutions"                => "manual/6-solutions.md",
            "Analysis"                 => "manual/7-analysis.md",
        ],
        "Formats" => [
            "BQPJSON"  => "formats/BQPJSON.md",
            "MiniZinc" => "formats/MiniZinc.md",
            "QUBin"    => "formats/QUBin.md",
            "Qubist"   => "formats/Qubist.md",
            "QUBO"     => "formats/QUBO.md",
        ],
        "API Reference" => "api.md",
    ],
    format   = Documenter.HTML(
        assets           = ["assets/extra_styles.css", "assets/favicon.ico"],
        mathengine       = Documenter.KaTeX(),
        sidebar_sitename = false,
    ),
)

if "--skip-deploy" ∈ ARGS
    @warn "Skipping deployment"
else
    deploydocs(repo = raw"github.com/JuliaQUBO/QUBOTools.jl.git", push_preview = true)
end
