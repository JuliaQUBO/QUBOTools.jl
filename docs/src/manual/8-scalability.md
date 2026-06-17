# Scalability

QUBOTools keeps the default test suite focused on small fixtures so that
`Pkg.test("QUBOTools")` remains suitable for pull requests and local
development. Large generated instances are covered by an opt-in scale-test tier.

Run the full scale tier from the repository root with:

```bash
QUBOTOOLS_SCALE_TESTS=true julia --project=. -e 'using Pkg; Pkg.test(; test_args = ["scale-only"])'
```

To run a smaller local smoke pass, cap the maximum generated dimension:

```bash
QUBOTOOLS_SCALE_TESTS=true QUBOTOOLS_SCALE_MAX_N=5000 julia --project=. -e 'using Pkg; Pkg.test(; test_args = ["scale-only"])'
```

The scheduled GitHub Actions scale job runs generated sparse cases at
`n = 1000`, `5000`, `20000`, and `100000` with average degree 4. These cases
exercise:

- sparse model construction from generated linear and quadratic dictionaries;
- dense Sherrington-Kirkpatrick and Wishart synthesis smoke cases at `n = 1000`;
- energy evaluation on random states;
- sparse, dictionary, and dense form agreement at `n = 1000`;
- sparse and dictionary form agreement at larger sizes;
- QUBin round-trips at every scale-test size;
- QUBO text round-trips at `n = 20000` and `n = 100000`;
- exact Float64 preservation for a portfolio-like numerical range from
  `1e-3` through `2e10`;
- `SampleSet` construction and duplicate-state merging with large states.

## Practical Envelope

Sparse forms are the intended representation for large generated and archived
instances. A sparse quadratic form is backed by Julia's `SparseMatrixCSC`, which
stores one row index and one value per nonzero term plus one column pointer per
variable. With 64-bit indices and `Float64` coefficients, the dominant storage
is about 16 bytes per quadratic nonzero plus about 8 bytes per variable for
column pointers. Sparse linear terms add about 16 bytes per nonzero. Temporary
construction dictionaries and I/O buffers require additional memory, so peak
memory is higher than the final sparse form.

Dense forms use an `n x n` `Float64` matrix for quadratic terms. That is about
`8n^2` bytes before Julia array overhead, so dense forms are practical only for
small cross-checks. The scale tier limits dense correctness checks to
`n = 1000`.

The current scheduled envelope is sparse instances with 100000 variables and
about 200000 quadratic terms. Denser QOBLib-style archives with millions of
terms should be tested with a dedicated benchmark or data-validation workflow so
their time and memory budgets can be reviewed separately from regular package
tests.
