using Documenter
using QUBOTools

const DOCS_PAGES = [
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
]

function build_docs(; deploy::Bool = false)
    # Keep Plots on a non-interactive backend for CI and test runs.
    get!(ENV, "GKSwstype", "100")

    DocMeta.setdocmeta!(QUBOTools, :DocTestSetup, :(using QUBOTools); recursive = true)

    makedocs(;
        modules  = [QUBOTools, QUBOTools.PBO],
        doctest  = true,
        clean    = true,
        sitename = "QUBOTools.jl",
        authors  = "Pedro Maciel Xavier and Pedro Ripper and Tiago Andrade and Joaquim Garcia and David E. Bernal Neira",
        source   = joinpath(@__DIR__, "src"),
        build    = joinpath(@__DIR__, "build"),
        workdir  = @__DIR__,
        warnonly = [:missing_docs],
        pages    = DOCS_PAGES,
        format   = Documenter.HTML(
            assets           = ["assets/extra_styles.css", "assets/favicon.ico"],
            mathengine       = Documenter.KaTeX(),
            sidebar_sitename = false,
        ),
    )

    if deploy
        deploydocs(repo = raw"github.com/JuliaQUBO/QUBOTools.jl.git", push_preview = true)
    else
        @warn "Skipping deployment"
    end

    return nothing
end
