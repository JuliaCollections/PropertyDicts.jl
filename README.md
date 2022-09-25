# PropertyDicts.jl

[![Build Status](https://github.com/JuliaCollections/PropertyDicts.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaCollections/PropertyDicts.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaCollections/PropertyDicts.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaCollections/PropertyDicts.jl)

Wrap an `AbstractDict` to add `getproperty` support for `Symbol` and `String` keys.

```julia
julia> using PropertyDicts

julia> d = PropertyDict(Dict("foo"=>1, :bar=>2))
PropertyDict{Symbol, Int64, Dict{Symbol, Int64}} with 2 entries:
  :bar => 2
  :foo => 1

julia> d.foo, d.bar, d."foo"
(1, 2, 1)

julia> propertynames(d)
KeySet for a Dict{Symbol, Int64} with 2 entries. Keys:
  :bar
  :foo

julia> d.baz = 3
3

julia> d
PropertyDict{Symbol, Int64, Dict{Symbol, Int64}} with 3 entries:
  :baz => 3
  :bar => 2
  :foo => 1

```
