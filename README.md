# PropertyDicts.jl

Wrap an `AbstractDict` to add `getproperty` support for `Symbol` and `AbstractString` keys.

```julia
d = PropertyDict(Dict("foo"=>1, :bar=>2))

d.foo, d.bar, d."foo"
> (1, 2, 1)

d."bar"
> ERROR: KeyError: key "bar" not found
```
