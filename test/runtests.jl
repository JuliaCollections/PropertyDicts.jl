using OrderedCollections: OrderedDict
using PropertyDicts
using Test

@testset "PropertyDicts" begin
    d = Dict("foo"=>1, :bar=>2)
    _keys = collect(keys(d))
    pd = PropertyDict(d)

    @testset "convert" begin
        expected = OrderedDict
        result = convert(expected, pd)

        @test result isa expected
    end

    @testset "get" begin
        @testset "default value" begin
            default = "baz"

            @test get(pd, "DNE", default) == default
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

    @testset "unwrap" begin
        @test PropertyDicts.unwrap(pd) == d
    end
end
