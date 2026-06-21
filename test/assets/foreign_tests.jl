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
           (
               occursin("no versions left", message) ||
               occursin("no compatible versions left", message)
           ) &&
           (
               occursin(pkg_name, message) ||
               occursin("package project", message) ||
               occursin("restricted by compatibility requirements with QUBOTools", message) ||
               occursin("found to have no compatible versions left with", message)
           )
end

function record_foreign_pkg_compatibility_skip(pkg_name::AbstractString)
    @warn "Skipping Foreign Test because package does not declare compatibility with this QUBOTools version" pkg = pkg_name qubotools = string(QUBOTools.__version__())

    @testset "⋆ $(pkg_name) compatibility" begin
        @test_broken false
    end

    return nothing
end

function test_foreign_pkg_compatibility_detection()
    add_error = PkgError("""
    Unsatisfiable requirements detected for package QUBODrivers [a9c8d775]:
    QUBODrivers [a9c8d775] is restricted by compatibility requirements with QUBOTools [60eb5b62] to versions: uninstalled — no versions left
    """)

    test_error = PkgError("""
    Unsatisfiable requirements detected for package project [d893b29c]:
    project [d893b29c] is restricted by compatibility requirements with QUBOTools [60eb5b62] to versions: uninstalled — no versions left
    QUBOTools [60eb5b62] is fixed to version 0.14.3
    """)

    nested_test_error = PkgError("""
    Unsatisfiable requirements detected for package QUBODrivers [a3f166f7]:
    QUBODrivers [a3f166f7] is restricted by compatibility requirements with QUBOTools [60eb5b62] to versions: uninstalled — no versions left
    QUBOTools [60eb5b62] is fixed to version 0.14.3
    """)

    reverse_error = PkgError("""
    Unsatisfiable requirements detected for package QUBOTools [60eb5b62]:
    QUBOTools [60eb5b62] is fixed to version 0.14.3
    QUBOTools [60eb5b62] found to have no compatible versions left with QUBO [ce8c2e91]
    """)

    unrelated_error = PkgError("""
    Unsatisfiable requirements detected for package JSON [682c06a0]:
    JSON [682c06a0] is restricted to versions: uninstalled — no versions left
    """)

    @test foreign_pkg_declines_current_qubotools(add_error, "QUBODrivers")
    @test foreign_pkg_declines_current_qubotools(test_error, "ToQUBO")
    @test foreign_pkg_declines_current_qubotools(nested_test_error, "ToQUBO")
    @test foreign_pkg_declines_current_qubotools(reverse_error, "QUBO")
    @test !foreign_pkg_declines_current_qubotools(unrelated_error, "ToQUBO")

    return nothing
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
            record_foreign_pkg_compatibility_skip(pkg_name)

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
        try
            Pkg.test(pkg_info.name; test_kws...)

            @test true
        catch e
            if foreign_pkg_declines_current_qubotools(e, pkg_info.name)
                @warn "Skipping Foreign Test because package does not declare compatibility with this QUBOTools version" pkg = pkg_info.name qubotools = string(QUBOTools.__version__())

                @test_broken false
            elseif e isa PkgError
                @test false
            else
                rethrow(e)
            end
        end
    end

    return nothing
end
