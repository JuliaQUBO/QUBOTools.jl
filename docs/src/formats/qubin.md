# QUBin

## Format

```@docs
QUBOTools.qubin_fmt
```

## Structure

Below, an outline of the HDF5 file layout that QUBin files follow:

```text
🗂️ HDF5.File: (read-only) test/data/02/bool.qb
├─ 📂 model
│  ├─ 📂 form
│  │  ├─ 🔢 dimension
│  │  ├─ 🔢 domain
│  │  ├─ 📂 linear
│  │  │  ├─ 🔢 i
│  │  │  └─ 🔢 v
│  │  ├─ 🔢 offset
│  │  ├─ 📂 quadratic
│  │  │  ├─ 🔢 i
│  │  │  ├─ 🔢 j
│  │  │  └─ 🔢 v
│  │  ├─ 🔢 scale
│  │  └─ 🔢 sense
│  ├─ 🔢 metadata
│  └─ 🔢 variables
└─ 📂 solution
   ├─ 📂 data
   │  ├─ 🔢 reads
   │  ├─ 🔢 state
   │  └─ 🔢 value
   ├─ 🔢 domain
   ├─ 🔢 metadata
   └─ 🔢 sense
```
