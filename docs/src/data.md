# Data Model

| Fields            |           Type           | Description | Required |
| :---------------- | :----------------------: | ----------- | :------: |
| `linear_terms`    |      `Dict{Int, T}`      |             |   YES    |
| `quadratic_terms` | `Dict{Tuple{Int,Int} T}` |             |   YES    |
| `offset`          |           `T`            |             |   YES    |
| `scale`           |           `T`            |             |   YES    |
| `id`              |          `Int`           |             |    NO    |