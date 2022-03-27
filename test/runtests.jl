using OrderedCollections: OrderedDict
using PropertyDicts
using Test

@testset "PropertyDicts" begin
    d = Dict("foo"=>1, :bar=>2)
    _keys = collect(keys(d))
    pd = PropertyDict(d)

    str_props = PropertyDict("foo" => 1, "bar" => 2)
    sym_props = PropertyDict(:foo => 1, :bar => 2)

    nt = (d =1, )
    pnt = pairs(nt)
    ntpd = PropertyDict(pnt)
    @test keys(PropertyDict(ntpd)) === keys(nt)
    @test values(PropertyDict(ntpd)) === values(pnt)
    @test propertynames(PropertyDict(ntpd)) === propertynames(nt)
    @test empty!(PropertyDict(Dict("foo"=>1, :bar=>2))) isa PropertyDict

    if isdefined(Base, :hasproperty)
        @test hasproperty(sym_props, "bar")
        @test hasproperty(str_props, :bar)
        @test hasproperty(pd, :foo)
        @test hasproperty(pd, "bar")
    end

    @testset "convert" begin
        expected = OrderedDict
        result = convert(expected, pd)

        @test result isa expected
    end

    @testset "get" begin
        @testset "default value" begin
            default = "baz"

            @test get(pd, "DNE", default) == default
            @test get(() -> 3, str_props, :foo) == 1
            @test get(() -> 3, str_props, :baz) == 3
            @test get(str_props, :baz, 3) == 3
            @test get(sym_props, "baz", 3) == 3
            @test get!(str_props, :baz, 3) == 3
            @test get!(sym_props, "baz", 3) == 3
            @test get!(() -> 4, str_props, :baz) == 3
            @test get!(() -> 4, sym_props, "baz") == 3
            @test get!(() -> 4, sym_props, "buz") == 4
        end

        @testset "$(typeof(key))" for key in _keys
            @test get(pd, key, "DNE") == d[key]
        end
    end

    @testset "getindex - $key" for key in _keys
        @test getindex(pd, key) == getindex(d, key)
    end

    @testset "getproperty" begin
        @test pd.foo == 1
        @test pd.bar == 2
        sym_props."spam" = 4
        @test sym_props."spam" == 4

        str_props.spam = 4
        @test str_props.spam == 4
    end

    @testset "iterate" begin
        @test iterate(pd) == iterate(d)
        @test iterate(pd, 1) == iterate(d, 1)
        @test iterate(pd, 2) == iterate(d, 2)
    end

    @testset "iteratorsize" begin
        @test Base.IteratorSize(pd) == Base.IteratorSize(d)
    end

    @testset "iteratoreltype" begin
        @test Base.IteratorEltype(pd) == Base.IteratorEltype(d)
    end

    @testset "length" begin
        @test length(pd) == length(d)
    end

    @testset "string" begin
        @test string(pd) == string(d)
    end

    push!(pd, :buz => 10)
    @test pop!(pd, :buz, 20) == 10
    @test pop!(pd, :buz, 20) == 20
    @test sizehint!(pd, 5) === pd
    @test get(pd, delete!(pd, "foo"), 10) == 10
end
