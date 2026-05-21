using Documenter
using QUBOTools

const DOCS_REPOSITORY_ROOT = normpath(joinpath(@__DIR__, ".."))
const DOCS_REPOSITORY_REMOTE = Remotes.GitHub("JuliaQUBO", "QUBOTools.jl")

function docs_repository_ref(root::AbstractString)
    try
        git_root = realpath(
            readchomp(pipeline(`git -C $(root) rev-parse --show-toplevel`; stderr = devnull)),
        )

        if git_root == realpath(root)
            return readchomp(pipeline(`git -C $(root) rev-parse HEAD`; stderr = devnull))
        end
    catch
        return "main"
    end

    return "main"
end

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
        "BQPJSON"  => "formats/bqpjson.md",
        "MiniZinc" => "formats/minizinc.md",
        "QUBin"    => "formats/qubin.md",
        "Qubist"   => "formats/qubist.md",
        "QUBO"     => "formats/qubo.md",
        "Rudy"     => "formats/rudy.md",
    ],
    "API Reference" => "api.md",
]

function build_docs(; deploy::Bool = false)
    DocMeta.setdocmeta!(QUBOTools, :DocTestSetup, :(using QUBOTools); recursive = true)

    # Keep Plots on a non-interactive backend only while Documenter runs.
    withenv("GKSwstype" => "100") do
        makedocs(;
            modules  = [QUBOTools, QUBOTools.PBO],
            doctest  = true,
            clean    = true,
            sitename = "QUBOTools.jl",
            authors  = "Pedro Maciel Xavier and Pedro Ripper and Tiago Andrade and Joaquim Garcia and David E. Bernal Neira",
            source   = joinpath(@__DIR__, "src"),
            build    = joinpath(@__DIR__, "build"),
            workdir  = @__DIR__,
            remotes  = Dict(
                DOCS_REPOSITORY_ROOT => (
                    DOCS_REPOSITORY_REMOTE,
                    docs_repository_ref(DOCS_REPOSITORY_ROOT),
                ),
            ),
            warnonly = [:missing_docs, :docs_block],
            pages    = DOCS_PAGES,
            format   = Documenter.HTML(
                assets           = ["assets/extra_styles.css", "assets/favicon.ico"],
                edit_link        = "main",
                mathengine       = Documenter.KaTeX(),
                sidebar_sitename = false,
            ),
        )
    end

    if deploy
        deploydocs(repo = raw"github.com/JuliaQUBO/QUBOTools.jl.git", push_preview = true)
    else
        @info "Skipping deployment"
    end

    return nothing
end
