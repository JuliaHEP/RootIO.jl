using Test
import RootIO, ROOT

function _create_test_tree(data)
    file = ROOT.TFile!Open("test.root", "RECREATE")

    name = "test_tree"
    title = "Test TTree"
    tree = RootIO.TTree(file, name, title; data...)

    RootIO.Write(tree)
    ROOT.Close(file)
end

function _test_tree(ele_type, num_events, data)
    file = ROOT.TFile!Open("test.root")
    t = ROOT.GetTTree(file[], "test_tree")

    a = fill(ele_type(0))
    ROOT.SetBranchAddress(t[], "col", a)
    nevts = ROOT.GetEntries(t)

    @test nevts == num_events
    ROOT.GetEntry(t, 0)
    @test typeof(a[]) == ele_type
    for i in 1:nevts
        ROOT.GetEntry(t, i - 1)
        @test data[:col][i] == a[]
    end

    ROOT.Close(file)
    rm("test.root")
end

@testset "Writing Integers" begin
    @testset "Int8" begin
        data = Dict(:col => rand(Int8, 2))
        _create_test_tree(data)
        _test_tree(Int8, 2, data)
    end

    @testset "UInt8" begin
        data = Dict(:col => rand(UInt8, 2))
        _create_test_tree(data)
        _test_tree(UInt8, 2, data)
    end

    @testset "Int16" begin
        data = Dict(:col => rand(Int16, 2))
        _create_test_tree(data)
        _test_tree(Int16, 2, data)
    end

    @testset "UInt16" begin
        data = Dict(:col => rand(UInt16, 2))
        _create_test_tree(data)
        _test_tree(UInt16, 2, data)
    end

    @testset "Int32" begin
        data = Dict(:col => rand(Int32, 2))
        _create_test_tree(data)
        _test_tree(Int32, 2, data)
    end

    @testset "UInt32" begin
        data = Dict(:col => rand(UInt32, 2))
        _create_test_tree(data)
        _test_tree(UInt32, 2, data)
    end

    @testset "Int64" begin
        data = Dict(:col => rand(Int64, 2))
        _create_test_tree(data)
        _test_tree(Int64, 2, data)
    end

    @testset "UInt64" begin
        data = Dict(:col => rand(UInt64, 2))
        _create_test_tree(data)
        _test_tree(UInt64, 2, data)
    end
end

@testset "Writing Float" begin
    @testset "Float32" begin
        data = Dict(:col => rand(Float32, 2))
        _create_test_tree(data)
        _test_tree(Float32, 2, data)
    end

    @testset "Float64" begin
        data = Dict(:col => rand(Float64, 2))
        _create_test_tree(data)
        _test_tree(Float64, 2, data)
    end
end