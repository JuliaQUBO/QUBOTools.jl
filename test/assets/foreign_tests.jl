function is_breaking_version()::Bool
    v = QUBOTools.__version__()::VersionNumber

    return iszero(v.patch) && isempty(v.build)
end

function env_bool(name::AbstractString, default::Bool = false)::Bool
    value = get(ENV, name, nothing)

    isnothing(value) && return default

    return lowercase(value) in ("1", "true", "yes", "on")
end

function run_foreign_tests()::Bool
    # Command-line option to be used to force running even with breaking versions
    if "--run-foreign-tests" ∈ ARGS
        if is_breaking_version()
            @warn "This seems to be a breaking version and Foreign Tests might fail."
        end

        return true
    elseif env_bool("QUBOTOOLS_FOREIGN_TESTS", false)
        if is_breaking_version()
            @warn "Skipping Foreign Tests for breaking release."

            return false
        else
            return true
        end
    else
        return false
    end
end

function foreign_pkg_label(pkg_spec::Pkg.PackageSpec)::String
    if !isnothing(pkg_spec.name)
        return pkg_spec.name
    elseif !isnothing(pkg_spec.url)
        return pkg_spec.url
    else
        return string(pkg_spec)
    end
end

function foreign_pkg_declines_current_qubotools(e, pkg_name::AbstractString)::Bool
    message = sprint(showerror, e)

    return occursin("Unsatisfiable requirements detected for package", message) &&
           occursin("QUBOTools", message) &&
           occursin(pkg_name, message) &&
           occursin("restricted to versions", message)
end

# Test foreign packages
function test_foreign_pkg(
    pkg_name::AbstractString,
    dev_path::AbstractString = QUBOTools.__project__();
    test_kws...,
)
    test_foreign_pkg(PackageSpec(name = pkg_name), dev_path; test_kws...)

    return nothing
end

function test_foreign_pkg(
    pkg_spec::Pkg.PackageSpec,
    dev_path::AbstractString = QUBOTools.__project__();
    test_kws...,
)
    pkg_name = foreign_pkg_label(pkg_spec)

    @info "Activating Test Environment for '$(pkg_name)'"

    Pkg.activate(; temp = true)

    Pkg.develop(; path = dev_path)

    try
        Pkg.add(pkg_spec)
    catch e
        if foreign_pkg_declines_current_qubotools(e, pkg_name)
            @warn "Skipping Foreign Test because package does not declare compatibility with this QUBOTools version" pkg = pkg_name qubotools = string(QUBOTools.__version__())

            @testset "⋆ $(pkg_name) compatibility" begin
                @test_broken false
            end

            return nothing
        end

        rethrow(e)
    end

    Pkg.status()

    pkg_info = let
        proj = Pkg.project()
        deps = Pkg.dependencies()

        deps[proj.dependencies[pkg_spec.name]]
    end

    @testset "⋆ $(pkg_info.name)@$(pkg_info.version)" begin
        @test try
            Pkg.test(pkg_info.name; test_kws...)

            true
        catch e
            if !(e isa PkgError)
                rethrow(e)
            end

            false
        end
    end

    return nothing
end
