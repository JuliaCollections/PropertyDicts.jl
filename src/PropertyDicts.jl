module PropertyDicts

export PropertyDict

@static if !hasmethod(mergewith, Tuple{Any,NamedTuple,NamedTuple})
    function Base.mergewith(combine, a::NamedTuple{an}, b::NamedTuple{bn}) where {an, bn}
        names = Base.merge_names(an, bn)
        NamedTuple{names}(ntuple(Val{nfields(names)}()) do i
            n = getfield(names, i)
            if Base.sym_in(n, an)
                if Base.sym_in(n, bn)
                    combine(getfield(a, n), getfield(b, n))
                else
                    getfield(a, n)
                end
            else
                getfield(b, n)
            end
        end)
    end
end

struct PropertyDict{K<:Union{String,Symbol}, V, D <: Union{AbstractDict{K,V},NamedTuple{<:Any,<:Tuple{Vararg{V}}}}} <: AbstractDict{K, V}
    d::D

    # PropertyDict{K,V}(args...)
    PropertyDict{Symbol,V}(d::AbstractDict{Symbol,V}) where {V} = new{Symbol,V,typeof(d)}(d)
    PropertyDict{String,V}(d::AbstractDict{String,V}) where {V} = new{String,V,typeof(d)}(d)
    PropertyDict{Symbol,V}(pd::PropertyDict{Symbol,V}) where {V} = pd
    PropertyDict{String,V}(pd::PropertyDict{String,V}) where {V} = pd
    function PropertyDict{K,V}(@nospecialize d::PropertyDict) where {K,V}
        PropertyDict{K,V}(getfield(d, :d))
    end
    function PropertyDict{K,V}(d::AbstractDict) where {K,V}
        dsym = PropertyDict(Dict{K,V}())
        for (k,v) in d
            dsym[K(k)] = v
        end
        dsym
    end
    function PropertyDict{Symbol,V}(nt::NamedTuple{syms,<:Tuple{Vararg{V}}}) where {syms,V}
        new{Symbol,V,typeof(nt)}(nt)
    end
    function PropertyDict{Symbol,V}(nt::NamedTuple{syms}) where {V,syms}
        PropertyDict{Symbol,V}(NamedTuple{syms}(Tuple{Vararg{V}}(Tuple(nt))))
    end
    PropertyDict{K,V}(arg, args...) where {K,V} = PropertyDict{K,V}(Dict(arg, args...))
    PropertyDict{K,V}(; kwargs...) where {K,V} = PropertyDict{K,V}(values(kwargs))

    # PropertyDict{K}(args...)
    function PropertyDict{K}(@nospecialize(d::AbstractDict)) where {K}
        PropertyDict{K,valtype(d)}(d)
    end
    function PropertyDict{String}(@nospecialize(d::AbstractDict{String}))
        new{String,valtype(d),typeof(d)}(d)
    end
    function PropertyDict{Symbol}(@nospecialize(d::AbstractDict{Symbol}))
        new{Symbol,valtype(d),typeof(d)}(d)
    end
    PropertyDict{Symbol}(@nospecialize(d::NamedTuple)) = new{Symbol,eltype(d),typeof(d)}(d)
    PropertyDict{Symbol}(@nospecialize(pd::PropertyDict{Symbol})) = pd
    PropertyDict{String}(@nospecialize(pd::PropertyDict{String})) = pd
    PropertyDict{K}(arg, args...) where {K} = PropertyDict{K}(Dict(arg, args...))
    PropertyDict{K}(; kwargs...) where {K} = PropertyDict{K}(values(kwargs))

    # PropertyDict(args...)
    PropertyDict(@nospecialize pd::PropertyDict) = pd
    PropertyDict(@nospecialize d::AbstractDict{String}) = PropertyDict{String}(d)
    function PropertyDict(@nospecialize d::Union{AbstractDict{Symbol},NamedTuple})
        PropertyDict{Symbol}(d)
    end
    PropertyDict(@nospecialize d::AbstractDict) = PropertyDict{Symbol}(d)
    PropertyDict(arg, args...) = PropertyDict(Dict(arg, args...))
    PropertyDict(; kwargs...) = PropertyDict(values(kwargs))
end

const NamedProperties{syms,T<:Tuple,V} = PropertyDict{Symbol,V,NamedTuple{syms,T}}

@inline function Base.setindex(npd::NamedProperties{syms}, v, key::Symbol) where {syms}
    nt = getfield(npd, :d)
    idx = Base.fieldindex(typeof(nt), key, false)
    if idx === 0
        return PropertyDict(NamedTuple{(syms..., key)}((values(nt)..., v)))
    else
        return PropertyDict(NamedTuple{syms}(ntuple(i -> idx === i ? v : getfield(nt, i), Val{nfields(syms)}())))
    end
end

Base.IteratorSize(@nospecialize T::Type{<:PropertyDict}) = Base.IteratorSize(fieldtype(T, :d))
Base.IteratorEltype(@nospecialize T::Type{<:PropertyDict}) = Base.IteratorEltype(eltype(T))

Base.length(pd::PropertyDict) = length(getfield(pd, :d))

function Base.sizehint!(pd::PropertyDict, n::Integer)
    sizehint!(getfield(pd, :d), n)
    return pd
end

Base.keytype(@nospecialize T::Type{<:PropertyDict{String}}) = String
Base.keytype(@nospecialize T::Type{<:PropertyDict{Symbol}}) = Symbol

_tokey(@nospecialize(pd::PropertyDict{String}), k::AbstractString) = k
_tokey(@nospecialize(pd::PropertyDict{String}), k::Symbol) = String(k)
_tokey(@nospecialize(pd::PropertyDict{Symbol}), k::Symbol) = k
_tokey(@nospecialize(pd::PropertyDict{Symbol}), k::AbstractString) = Symbol(k)

Base.pop!(pd::PropertyDict, k) = pop!(getfield(pd, :d), _tokey(pd, k))
Base.pop!(pd::PropertyDict, k, d) = pop!(getfield(pd, :d), _tokey(pd, k), d)

function Base.empty!(pd::PropertyDict)
    empty!(getfield(pd, :d))
    return pd
end
Base.isempty(::NamedProperties{(),Tuple{},Union{}}) = true
Base.isempty(@nospecialize(npd::NamedProperties)) = false
Base.isempty(pd::PropertyDict) = isempty(getfield(pd, :d))
function Base.empty(pd::PropertyDict, ::Type{K}=keytype(pd), ::Type{V}=valtype(pd)) where {K,V}
    PropertyDict(empty(getfield(pd, :d), K, V))
end
function Base.empty(@nospecialize(pd::NamedProperties), ::Type{K}, ::Type{V}) where {K,V}
    PropertyDict()
end

function Base.delete!(pd::PropertyDict, k)
    delete!(getfield(pd, :d), _tokey(pd, k))
    return pd
end

function Base.get(pd::PropertyDict, k, d)
    get(getfield(pd, :d), _tokey(pd, k), d)
end
function Base.get(f::Union{Function,Type}, pd::PropertyDict, k)
    get(f, getfield(pd, :d), _tokey(pd, k))
end
function Base.get!(pd::PropertyDict, k, d)
    get!(getfield(pd, :d), _tokey(pd, k), d)
end
function Base.get!(f::Union{Function,Type}, pd::PropertyDict, k)
    get!(f, getfield(pd, :d), _tokey(pd, k))
end
Base.@propagate_inbounds function Base.getindex(pd::NamedProperties, k::Symbol)
    getfield(getfield(pd, :d), k)
end
Base.@propagate_inbounds function Base.getindex(pd::PropertyDict, k)
    getindex(getfield(pd, :d), _tokey(pd, k))
end
Base.@propagate_inbounds function Base.setindex!(pd::PropertyDict, v, k)
    setindex!(getfield(pd, :d), v, _tokey(pd, k))
end

@inline function Base.iterate(pd::NamedProperties)
    if isempty(pd)
        nothing
    else
        Pair{Symbol,valtype(pd)}(getfield(keys(pd), 1), getfield(getfield(pd, :d), 1)), 2
    end
end
@inline function Base.iterate(pd::NamedProperties, s::Int)
    if length(pd) < s
        nothing
    else
        Pair{Symbol,valtype(pd)}(getfield(keys(getfield(pd, :d)), s), getfield(getfield(pd, :d), s)), s + 1
    end
end
Base.iterate(pd::PropertyDict) = iterate(getfield(pd, :d))
Base.iterate(pd::PropertyDict, i) = iterate(getfield(pd, :d), i)

Base.values(pd::PropertyDict) = values(getfield(pd, :d))

Base.haskey(pd::PropertyDict, k) = haskey(getfield(pd, :d), _tokey(pd, k))
Base.getkey(pd::PropertyDict, k, d) = getkey(getfield(pd, :d), _tokey(pd, k), d)
Base.keys(pd::PropertyDict) = keys(getfield(pd, :d))

Base.hasproperty(pd::PropertyDict, k::Symbol) = haskey(pd, _tokey(pd, k))
Base.hasproperty(pd::PropertyDict, k::AbstractString) = haskey(pd, _tokey(pd, k))
Base.propertynames(pd::PropertyDict) = keys(getfield(pd, :d))
Base.getproperty(pd::NamedProperties, k::Symbol) = getfield(getfield(pd, :d), k)
Base.getproperty(pd::PropertyDict, k::Symbol) = getindex(pd, k)
Base.getproperty(pd::PropertyDict, k::AbstractString) = getindex(pd, k)
Base.setproperty!(pd::PropertyDict, k::Symbol, v) = setindex!(pd, v, k)
Base.setproperty!(pd::PropertyDict, k::AbstractString, v) = setindex!(pd, v, k)

Base.copy(pd::NamedProperties) = pd
Base.copy(pd::PropertyDict) = PropertyDict(copy(getfield(pd, :d)))

## merge and mergewith
Base.merge(pd::PropertyDict) = copy(pd)
Base.merge(pd::NamedProperties, pds::NamedProperties...) = _mergeprops(_getarg2, pd, pds...)
_getarg2(@nospecialize(arg1), @nospecialize(arg2)) = arg2
function Base.merge(pd::PropertyDict, pds::PropertyDict...)
    K = _promote_keytypes((pd, pds...))
    V = _promote_valtypes(valtype(pd), pds...)
    out = PropertyDict(Dict{K,V}())
    for (k,v) in pd
        out[k] = v
    end
    merge!(out, pds...)
end

Base.mergewith(combine, pd::PropertyDict) = copy(pd)
function Base.mergewith(combine, pd::PropertyDict, pds::PropertyDict...)
    K = _promote_keytypes((pd, pds...))
    V0 = _promote_valtypes(valtype(pd), pds...)
    V = promote_type(Core.Compiler.return_type(combine, Tuple{V0,V0}), V0)
    out = PropertyDict(Dict{K,V}())
    for (k,v) in pd
        out[k] = v
    end
    mergewith!(combine, out, pds...)
end
@inline function Base.mergewith(combine, pd::NamedProperties, pds::NamedProperties...)
    _mergeprops(combine, pd, pds...)
end
_mergeprops(combine, @nospecialize(x::NamedProperties)) = x
@inline function _mergeprops(combine, x::NamedProperties, y::NamedProperties)
    PropertyDict(mergewith(combine, getfield(x, :d), getfield(y, :d)))
end
@inline function _mergeprops(combine, x::NamedProperties, y::NamedProperties, zs::NamedProperties...)
    _mergeprops(combine, _mergeprops(combine, x, y), zs...)
end

# fall back to Symbol if we don't clearly have String
_promote_keytypes(@nospecialize(pds::Tuple{Vararg{PropertyDict{String}}})) = String
_promote_keytypes(@nospecialize(pds::Tuple{Vararg{PropertyDict}})) = Symbol
_promote_valtypes(V) = V
function _promote_valtypes(V, d, ds...)  # give up if promoted to any
    V === Any ? Any : _promote_valtypes(promote_type(V, valtype(d)), ds...)
end

end # module PropertyDicts
