# Release Process

Release changes live in this repository first. The release preflight checks the package-specific metadata that can drift while preparing QUBOTools releases.

## Prepare the Release PR

1. Update `Project.toml` to the target version.
2. Add a `CHANGELOG.md` section for `vX.Y.Z`.
3. Update `docs/Project.toml` and `benchmark/Project.toml` self-compat for `QUBOTools` so each includes the target release line.
   - For `0.Y.Z`, include `0.Y`.
   - For `0.0.Z`, include `0.0.Z`.
   - For `X.Y.Z` with `X > 0`, include `X`.
4. Run the static release preflight:

```sh
julia --project=. scripts/release_check.jl
```

5. Run the package and documentation checks:

```sh
julia --project=. -e 'import Pkg; Pkg.test()'
julia --project=docs -e 'using Pkg; Pkg.develop(path=pwd()); Pkg.instantiate()'
julia --project=docs docs/make.jl --skip-deploy
```

6. Open and merge the release PR after CI is green.

## Register

After the release PR is merged, invoke Registrator on the merge commit, not on the pull request. Use the template in `release-notes-template.md`.

The release notes for a pre-1.0 minor release should include a `Breaking changes` or `Changelog` section. General may label pre-1.0 minor releases as `BREAKING`, and AutoMerge requires one of those words in the release notes when that label is present.

```sh
gh api repos/JuliaQUBO/QUBOTools.jl/commits/<merge-sha>/comments -f body="$(cat release-notes-template.md)"
```

Watch the General registry PR:

```sh
gh pr checks <general-pr-number> --repo JuliaRegistries/General --watch
gh pr view <general-pr-number> --repo JuliaRegistries/General --json state,mergedAt,mergeCommit,url
```

If AutoMerge fails because release notes are missing the breaking-change wording, re-invoke Registrator on the same merge commit with corrected release notes.

## Verify TagBot

After the General PR merges, wait for TagBot and verify the tag and release:

```sh
gh run list --workflow TagBot.yml --limit 10
git ls-remote --tags origin vX.Y.Z
gh release view vX.Y.Z
```

## Verify Pkg.add

Use a fresh depot and project so the check does not reuse a local development path:

```sh
tmp="$(mktemp -d)"
mkdir -p "$tmp/depot" "$tmp/proj"
JULIA_DEPOT_PATH="$tmp/depot" julia --startup-file=no --project="$tmp/proj" -e 'using Pkg; Pkg.add("QUBOTools"); deps = Pkg.dependencies(); versions = [(pkg.name, pkg.version) for pkg in values(deps) if pkg.name == "QUBOTools"]; @show versions'
```
