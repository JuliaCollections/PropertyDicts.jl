module PropertyDicts

export PropertyDict

@static if !hasmethod(reverse, Tuple{NamedTuple})
    Base.reverse(nt::NamedTuple) = NamedTuple{reverse(keys(nt))}(reverse(values(nt)))
end
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

struct PropertyDict{K<:Union{String,Symbol}, V, D <: Union{AbstractDict,NamedTuple}} <: AbstractDict{K, V}
    d::D

    PropertyDict(@nospecialize pd::PropertyDict) = pd
    PropertyDict(d::AbstractDict{String,V}) where {V} = new{String,V,typeof(d)}(d)
    PropertyDict(d::AbstractDict{Symbol,V}) where {V} = new{Symbol,V,typeof(d)}(d)
    PropertyDict(nt::NamedTuple) = new{Symbol,eltype(nt),typeof(nt)}(nt)
    function PropertyDict(d::AbstractDict)
        dsym = Dict{Symbol,valtype(d)}()
        for (k,v) in d
            dsym[Symbol(k)] = v
        end
        PropertyDict(dsym)
    end
    PropertyDict() = PropertyDict(NamedTuple())
    PropertyDict(arg, args...) = PropertyDict(Dict(arg, args...))
end

const NamedProperties{syms,T<:Tuple,V} = PropertyDict{Symbol,V,NamedTuple{syms,T}}

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
_tokey(@nospecialize(pd::PropertyDict{String}), k) = String(k)
_tokey(@nospecialize(pd::PropertyDict{Symbol}), k::Symbol) = k
_tokey(@nospecialize(pd::PropertyDict{Symbol}), k) = Symbol(k)

Base.pop!(pd::PropertyDict, k) = pop!(getfield(pd, :d), _tokey(pd, k))
Base.pop!(pd::PropertyDict, k, d) = pop!(getfield(pd, :d), _tokey(pd, k), d)

function Base.empty!(pd::PropertyDict)
    empty!(getfield(pd, :d))
    return pd
end
Base.isempty(pd::PropertyDict) = isempty(getfield(pd, :d))
function Base.empty(pd::PropertyDict, ::Type{K}=keytype(pd), ::Type{V}=valtype(pd)) where {K,V}
    PropertyDict(empty(getfield(pd, :d), K, V))
end
Base.empty(pd::NamedProperties, ::Type{Symbol}, ::Type{Union{}}) = PropertyDict()

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

Base.reverse(pd::PropertyDict) = PropertyDict(reverse(getfield(pd, :d)))

@inline function Base.iterate(pd::NamedProperties)
    if isempty(pd)
        nothing
    else
        Pair{Symbol,valtype(pd)}(getfield(keys(pd), 1), getfield(getfield(pd, :d), 1)), 2
    end
end
@inline function Base.iterate(pd::NamedProperties, s::Int) where {V}
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

@static if isdefined(Base, :hasproperty)
    Base.hasproperty(pd::PropertyDict, k::Symbol) = haskey(pd, _tokey(pd, k))
    Base.hasproperty(pd::PropertyDict, k::AbstractString) = haskey(pd, _tokey(pd, k))
end
Base.propertynames(pd::PropertyDict) = keys(getfield(pd, :d))
Base.getproperty(pd::NamedProperties, k::Symbol) = getfield(getfield(pd, :d), k)
Base.getproperty(pd::PropertyDict, k::Symbol) = getindex(pd, k)
Base.getproperty(pd::PropertyDict, k::String) = getindex(pd, k)
Base.setproperty!(pd::PropertyDict, k::Symbol, v) = setindex!(pd, v, k)
Base.setproperty!(pd::PropertyDict, k::String, v) = setindex!(pd, v, k)

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
