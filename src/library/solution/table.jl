const _SAMPLE_TABLE_FORMAT = "QUBOTools.samples"
const _SAMPLE_TABLE_VERSION = 1
const _SAMPLE_TABLE_METADATA_PREFIX = "# QUBOTools.samples.metadata="

@doc raw"""
    sampleset_table(sampleset::AbstractSolution; bit_order = :native, include_probability = true)

Return a row table for `sampleset` as a `Vector{NamedTuple}` with stable columns.
The default columns are `rank`, `state`, `reads`, `value`, and `probability`;
`probability` is omitted when `include_probability = false`.

The returned vector is compatible with the Tables.jl row-table convention without
making Tables.jl a package dependency.
"""
function sampleset_table(
    sol::AbstractSolution;
    bit_order::Union{Symbol,AbstractString} = :native,
    include_probability::Bool = true,
)
    bit_order = _samples_bit_order(bit_order)
    sample_domain = domain(sol)

    total_reads = reads(sol)

    if include_probability
        return [
            (
                rank = i,
                state = _samples_state_string(sample, sample_domain; bit_order),
                reads = reads(sample),
                value = value(sample),
                probability = _samples_probability(reads(sample), total_reads),
            ) for (i, sample) in enumerate(sol)
        ]
    else
        return [
            (
                rank = i,
                state = _samples_state_string(sample, sample_domain; bit_order),
                reads = reads(sample),
                value = value(sample),
            ) for (i, sample) in enumerate(sol)
        ]
    end
end

@doc raw"""
    write_samples(path::AbstractString, sampleset::AbstractSolution; format = :csv,
        metadata_path = nothing, bit_order = :native, include_probability = true)

Write a `SampleSet`-like solution as a stable tabular distribution file.

Only `format = :csv` is currently supported. By default, JSON metadata is embedded
in a leading CSV comment so `read_samples` can recover the solution frame and
metadata. If `metadata_path` is provided, the JSON metadata is written to that
sidecar path instead and must be passed to `read_samples` to recover the recorded
frame and metadata. When `model` context is provided, model scale, offset, and
variable names are recorded in the JSON metadata.
"""
function write_samples(
    path::AbstractString,
    sol::AbstractSolution;
    format::Union{Symbol,AbstractString} = :csv,
    metadata_path::Union{AbstractString,Nothing} = nothing,
    bit_order::Union{Symbol,AbstractString} = :native,
    include_probability::Bool = true,
    model::Union{AbstractModel,Nothing} = nothing,
)
    format = Symbol(format)

    format === :csv || format_error("Unsupported samples format '$(format)'")

    bit_order = _samples_bit_order(bit_order)
    columns = _samples_columns(; include_probability)
    file_metadata = _samples_file_metadata(sol; columns, bit_order, model)

    if !isnothing(metadata_path)
        _write_samples_metadata(metadata_path, file_metadata)
    end

    return open(path, "w") do io
        return write_samples(
            io,
            sol;
            format,
            metadata = isnothing(metadata_path) ? file_metadata : nothing,
            bit_order,
            include_probability,
        )
    end
end

function write_samples(
    path::AbstractString,
    model::AbstractModel;
    kws...,
)
    return write_samples(path, solution(model); model, kws...)
end

function write_samples(
    io::IO,
    sol::AbstractSolution;
    format::Union{Symbol,AbstractString} = :csv,
    bit_order::Union{Symbol,AbstractString} = :native,
    include_probability::Bool = true,
    metadata::Union{Dict{String,Any},Nothing} = _samples_file_metadata(
        sol;
        columns = _samples_columns(; include_probability),
        bit_order = _samples_bit_order(bit_order),
    ),
)
    format = Symbol(format)

    format === :csv || format_error("Unsupported samples format '$(format)'")

    bit_order = _samples_bit_order(bit_order)

    if !isnothing(metadata)
        println(io, _SAMPLE_TABLE_METADATA_PREFIX, JSON.json(metadata))
    end

    table = sampleset_table(sol; bit_order, include_probability)
    columns = _samples_columns(; include_probability)

    _write_samples_csv_record(io, String.(columns))

    for row in table
        _write_samples_csv_record(io, getproperty.(Ref(row), columns))
    end

    return nothing
end

@doc raw"""
    read_samples(path::AbstractString; metadata_path = nothing, bit_order = :native)

Read a CSV distribution written by [`write_samples`](@ref) and return a
`SampleSet`. Duplicate states with matching values are merged by the `SampleSet`
constructor. The `probability` column, when present, is treated as derived data;
`reads` remains authoritative. Imported values use `Float64` and reads use `Int`.

When embedded or sidecar metadata records `bit_order`, that recorded order is
used to recover the native state order; the `bit_order` keyword is used only for
metadata-less input. Sidecar metadata written by `write_samples` must be supplied
with `metadata_path` to recover the recorded frame and solution metadata.
`read_samples` returns a `SampleSet` and does not reconstruct model context from
the optional metadata `model` block.
"""
function read_samples(
    path::AbstractString;
    metadata_path::Union{AbstractString,Nothing} = nothing,
    bit_order::Union{Symbol,AbstractString} = :native,
)
    sidecar_metadata = if isnothing(metadata_path)
        nothing
    else
        _read_samples_metadata(metadata_path)
    end

    return open(path, "r") do io
        return read_samples(io; metadata = sidecar_metadata, bit_order)
    end
end

function read_samples(
    io::IO;
    metadata::Union{Dict{String,Any},Nothing} = nothing,
    bit_order::Union{Symbol,AbstractString} = :native,
)
    bit_order = _samples_bit_order(bit_order)
    rows, embedded_metadata = _read_samples_csv(io)
    file_metadata = isnothing(metadata) ? embedded_metadata : metadata
    bit_order = _samples_read_bit_order(file_metadata, bit_order)

    sample_metadata = _samples_solution_metadata(file_metadata)
    sample_sense = _samples_sense(file_metadata)
    sample_domain = _samples_domain(file_metadata)

    samples = Sample{Float64,Int}[]

    for row in rows
        ψ = _parse_samples_state(row[:state], sample_domain)

        if bit_order === :reverse
            reverse!(ψ)
        end

        push!(
            samples,
            Sample{Float64,Int}(
                ψ,
                parse(Float64, row[:value]),
                parse(Int, row[:reads]),
            ),
        )
    end

    return SampleSet{Float64,Int}(
        samples;
        metadata = sample_metadata,
        sense = sample_sense,
        domain = sample_domain,
    )
end

function _samples_columns(; include_probability::Bool)
    if include_probability
        return (:rank, :state, :reads, :value, :probability)
    else
        return (:rank, :state, :reads, :value)
    end
end

function _samples_bit_order(bit_order::Union{Symbol,AbstractString})
    bit_order = Symbol(bit_order)

    if bit_order === :native || bit_order === :reverse
        return bit_order
    else
        format_error("Unsupported sample bit order '$(bit_order)'")
    end
end

function _samples_read_bit_order(file_metadata::Nothing, bit_order::Symbol)
    return bit_order
end

function _samples_read_bit_order(file_metadata::Dict{String,Any}, bit_order::Symbol)
    return _samples_bit_order(get(file_metadata, "bit_order", bit_order))
end

function _samples_probability(sample_reads::Integer, total_reads::Integer)
    if total_reads == 0
        return 0.0
    else
        return sample_reads / total_reads
    end
end

function _samples_state_string(
    sample::AbstractSample,
    sample_domain::Domain;
    bit_order::Symbol,
)
    ψ = collect(state(sample))

    if bit_order === :reverse
        reverse!(ψ)
    end

    if sample_domain === 𝔹
        return join(string.(ψ), "")
    else
        return join(string.(ψ), " ")
    end
end

function _samples_file_metadata(
    sol::AbstractSolution;
    columns,
    bit_order::Symbol,
    model::Union{AbstractModel,Nothing} = nothing,
)
    file_metadata = Dict{String,Any}(
        "format" => _SAMPLE_TABLE_FORMAT,
        "version" => _SAMPLE_TABLE_VERSION,
        "package_versions" => Dict{String,Any}(
            "QUBOTools" => string(__version__()),
            "Julia" => string(VERSION),
        ),
        "sense" => String(sense(sol)),
        "domain" => String(domain(sol)),
        "bit_order" => String(bit_order),
        "columns" => String.(columns),
        "metadata" => deepcopy(metadata(sol)),
    )

    if !isnothing(model)
        file_metadata["model"] = Dict{String,Any}(
            "scale" => scale(model),
            "offset" => offset(model),
            "variables" => string.(variables(model)),
        )
    end

    return file_metadata
end

function _samples_solution_metadata(file_metadata::Nothing)
    return Dict{String,Any}()
end

function _samples_solution_metadata(file_metadata::Dict{String,Any})
    data = get(file_metadata, "metadata", Dict{String,Any}())

    return _json_object(data)
end

function _samples_sense(file_metadata::Nothing)
    return Min
end

function _samples_sense(file_metadata::Dict{String,Any})
    return QUBOTools.sense(get(file_metadata, "sense", "min"))
end

function _samples_domain(file_metadata::Nothing)
    return 𝔹
end

function _samples_domain(file_metadata::Dict{String,Any})
    return QUBOTools.domain(get(file_metadata, "domain", "bool"))
end

function _write_samples_metadata(path::AbstractString, metadata::Dict{String,Any})
    return open(path, "w") do io
        JSON.print(io, metadata, 2)
        println(io)

        return nothing
    end
end

function _read_samples_metadata(path::AbstractString)
    return _json_object(JSON.parsefile(path))
end

function _write_samples_csv_record(io::IO, values)
    println(io, join(_samples_csv_cell.(values), ","))

    return nothing
end

function _samples_csv_cell(value)
    str = string(value)

    if occursin("\"", str) || occursin(",", str) || occursin("\n", str) ||
       occursin("\r", str) || startswith(str, "#")
        return "\"" * replace(str, "\"" => "\"\"") * "\""
    else
        return str
    end
end

function _read_samples_csv(io::IO)
    metadata = nothing
    header = nothing
    rows = Vector{Dict{Symbol,String}}()

    for line in eachline(io)
        isempty(strip(line)) && continue

        if startswith(line, "#")
            if startswith(line, _SAMPLE_TABLE_METADATA_PREFIX)
                metadata_json = line[nextind(line, lastindex(_SAMPLE_TABLE_METADATA_PREFIX)):end]
                metadata = _json_object(JSON.parse(metadata_json))
            end

            continue
        end

        fields = _parse_samples_csv_record(line)

        if isnothing(header)
            header = Symbol.(fields)
            _validate_samples_csv_header(header)

            continue
        end

        if length(fields) != length(header)
            syntax_error(
                "CSV sample row has $(length(fields)) fields, expected $(length(header))",
            )
        end

        push!(rows, Dict{Symbol,String}(header[i] => fields[i] for i in eachindex(header)))
    end

    isnothing(header) && syntax_error("CSV samples file is missing a header row")

    return rows, metadata
end

function _validate_samples_csv_header(header::Vector{Symbol})
    for column in (:state, :reads, :value)
        column in header || syntax_error("CSV samples file is missing required column '$(column)'")
    end

    return nothing
end

function _parse_samples_csv_record(line::AbstractString)
    fields = String[]
    buffer = IOBuffer()
    quoted = false
    i = firstindex(line)

    while i <= lastindex(line)
        c = line[i]

        if quoted
            if c == '"'
                j = nextind(line, i)

                if j <= lastindex(line) && line[j] == '"'
                    print(buffer, '"')
                    i = nextind(line, j)
                else
                    quoted = false
                    i = j
                end
            else
                print(buffer, c)
                i = nextind(line, i)
            end
        else
            if c == ','
                push!(fields, String(take!(buffer)))
                i = nextind(line, i)
            elseif c == '"'
                quoted = true
                i = nextind(line, i)
            else
                print(buffer, c)
                i = nextind(line, i)
            end
        end
    end

    quoted && syntax_error("CSV sample row has an unterminated quoted field")

    push!(fields, String(take!(buffer)))

    return fields
end

function _parse_samples_state(cell::AbstractString, sample_domain::Domain)
    text = strip(cell)

    isempty(text) && return Int[]

    tokens = if occursin(r"[\s,;]", text)
        split(replace(replace(text, "," => " "), ";" => " "))
    elseif sample_domain === 𝔹 && all(c -> c == '0' || c == '1', text)
        string.(collect(text))
    else
        [text]
    end

    return parse.(Int, tokens)
end
