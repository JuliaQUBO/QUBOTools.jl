function run_foreign_tests()::Bool
    return "--run-foreign-tests" ∈ ARGS ||
           Base.get_bool_env("QUBOTOOLS_FOREIGN_TESTS", false)
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
    @info "Activating Test Environment for '$(pkg_spec.name)'"

    Pkg.activate(; temp = true)

    Pkg.develop(; path = dev_path)

    Pkg.add(pkg_spec)

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
