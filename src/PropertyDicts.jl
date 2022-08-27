module PropertyDicts

export PropertyDict

struct PropertyDict{K<:Union{String,Symbol}, V, T <: AbstractDict{K, V}} <: AbstractDict{K, V}
    d::T

    PropertyDict(@nospecialize pd::PropertyDict) = pd
    PropertyDict(d::AbstractDict{String,V}) where {V} = new{String,V,typeof(d)}(d)
    PropertyDict(d::AbstractDict{Symbol,V}) where {V} = new{Symbol,V,typeof(d)}(d)
    function PropertyDict(d::AbstractDict)
        dsym = Dict{Symbol,valtype(d)}()
        for (k,v) in d
            dsym[Symbol(k)] = v
        end
        PropertyDict(dsym)
    end
    PropertyDict(args...) = PropertyDict(Dict(args...))
end

Base.IteratorSize(@nospecialize T::Type{<:PropertyDict}) = Base.IteratorSize(fieldtype(T, :d))
Base.IteratorEltype(@nospecialize T::Type{<:PropertyDict}) = Base.IteratorEltype(eltype(T))

Base.length(pd::PropertyDict) = length(getfield(pd, :d))

function Base.sizehint!(pd::PropertyDict, n::Integer)
    sizehint!(getfield(pd, :d), n)
    return pd
end

_tokey(@nospecialize(pd::PropertyDict{String}), k::AbstractString) = k
_tokey(@nospecialize(pd::PropertyDict{String}), k) = String(k)
_tokey(@nospecialize(pd::PropertyDict{Symbol}), k::Symbol) = k
_tokey(@nospecialize(pd::PropertyDict{Symbol}), k) = Symbol(k)

Base.pop!(pd::PropertyDict, k) = pop!(getfield(pd, :d), _tokey(pd, k))
Base.pop!(pd::PropertyDict, k, d) = pop!(getfield(pd, :d), _tokey(pd, k), d)

function Base.empty!(pd::PropertyDict)
    empty!(getfield(pd, :d))
    return pd
end
function Base.delete!(pd::PropertyDict, k)
    delete!(getfield(pd, :d), _tokey(pd, k))
    return pd
end
Base.empty(pd::PropertyDict) = PropertyDict(empty(getfield(pd, :d)))

Base.get(pd::PropertyDict, k, d) = get(getfield(pd, :d), _tokey(pd, k), d)
function Base.get(f::Union{Function,Type}, pd::PropertyDict, k)
    get(f, getfield(pd, :d), _tokey(pd, k))
end
Base.get!(pd::PropertyDict, k, d) = get!(getfield(pd, :d), _tokey(pd, k), d)
function Base.get!(f::Union{Function,Type}, pd::PropertyDict, k)
    get!(f, getfield(pd, :d), _tokey(pd, k))
end

Base.@propagate_inbounds function Base.getindex(pd::PropertyDict, k)
    getindex(getfield(pd, :d), _tokey(pd, k))
end
Base.@propagate_inbounds function Base.setindex!(pd::PropertyDict, v, k)
    setindex!(getfield(pd, :d), v, _tokey(pd, k))
end

Base.haskey(pd::PropertyDict, k) = haskey(getfield(pd, :d), _tokey(pd, k))

Base.getkey(pd::PropertyDict, k, d) = getkey(getfield(pd, :d), _tokey(pd, k), d)

Base.iterate(pd::PropertyDict) = iterate(getfield(pd, :d))
Base.iterate(pd::PropertyDict, i) = iterate(getfield(pd, :d), i)

# a handful of dictionaries aren't just wrapped in `KeySet` and `ValueIterator`
Base.keys(pd::PropertyDict) = keys(getfield(pd, :d))
Base.values(pd::PropertyDict) = values(getfield(pd, :d))

## property methods
Base.getproperty(pd::PropertyDict, n::Symbol) = getindex(pd, n)
Base.getproperty(pd::PropertyDict, n::String) = getindex(pd, n)

Base.setproperty!(pd::PropertyDict, n::Symbol, v) = setindex!(pd, v, n)
Base.setproperty!(pd::PropertyDict, n::String, v) = setindex!(pd, v, n)

Base.propertynames(pd::PropertyDict) = keys(pd)

@static if isdefined(Base, :hasproperty)
    Base.hasproperty(pd::PropertyDict, k::Symbol) = haskey(pd, _tokey(pd, k))
    Base.hasproperty(pd::PropertyDict, k) = haskey(pd, _tokey(pd, k))
end

end # module PropertyDicts
