using Test
import RootIO, ROOT

function _create_test_tree(data)
    file = ROOT.TFile!Open("test.root", "RECREATE")

    name = "test_tree"
    title = "Test TTree"
    tree = RootIO.TTree(file, name, title; data...)
    mat = hcat([col[2] for col in data]...)
    for i in axes(mat, 1)
        RootIO.Fill(tree, mat[i, :])
    end

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
    @test isa((a[]), ele_type)
    mat = hcat([col[2] for col in data]...)
    for i in 1:nevts
        ROOT.GetEntry(t, i - 1)
        for j in axes(mat, 2)
            @test mat[i][j] == a[j]
        end
    end

    ROOT.Close(file)
    rm("test.root")
end

@testset "Writing Integers" begin
    @testset "Int8" begin
        data = [:col => rand(Int8, 2)]
        _create_test_tree(data)
        _test_tree(Int8, 2, data)
    end

    @testset "UInt8" begin
        data = [:col => rand(UInt8, 2)]
        _create_test_tree(data)
        _test_tree(UInt8, 2, data)
    end

    @testset "Int16" begin
        data = [:col => rand(Int16, 2)]
        _create_test_tree(data)
        _test_tree(Int16, 2, data)
    end

    @testset "UInt16" begin
        data = [:col => rand(UInt16, 2)]
        _create_test_tree(data)
        _test_tree(UInt16, 2, data)
    end

    @testset "Int32" begin
        data = [:col => rand(Int32, 2)]
        _create_test_tree(data)
        _test_tree(Int32, 2, data)
    end

    @testset "UInt32" begin
        data = [:col => rand(UInt32, 2)]
        _create_test_tree(data)
        _test_tree(UInt32, 2, data)
    end

    @testset "Int64" begin
        data = [:col => rand(Int64, 2)]
        _create_test_tree(data)
        _test_tree(Int64, 2, data)
    end

    @testset "UInt64" begin
        data = [:col => rand(UInt64, 2)]
        _create_test_tree(data)
        _test_tree(UInt64, 2, data)
    end
end

@testset "Writing Float" begin
    @testset "Float32" begin
        data = [:col => rand(Float32, 2)]
        _create_test_tree(data)
        _test_tree(Float32, 2, data)
    end

    @testset "Float64" begin
        data = [:col => rand(Float64, 2)]
        _create_test_tree(data)
        _test_tree(Float64, 2, data)
    end
end

@testset "Writing Booleans" begin
    @testset "Bools" begin
        num_events = 3
        data = [:col => rand(Bool, num_events)]
        _create_test_tree(data)

        file = ROOT.TFile!Open("test.root")
        t = ROOT.GetTTree(file[], "test_tree")

        a = fill(false)
        ROOT.SetBranchAddress(t[], "col", Ptr{Nothing}(pointer(a)))
        nevts = ROOT.GetEntries(t)

        @test nevts == num_events
        ROOT.GetEntry(t, 0)
        @test isa(a[], Bool)
        mat = hcat([col[2] for col in data]...)
        for i in 1:nevts
            ROOT.GetEntry(t, i - 1)
            for j in axes(mat, 2)
                @test mat[i][j] == a[j]
            end
        end

        ROOT.Close(file)
        rm("test.root")
    end
end

@testset "Writing String" begin
    @testset "String" begin
        data = Dict(:col => ["CERN", "ROOT", "RootIO"])
        _create_test_tree(data)

        file = ROOT.TFile!Open("test.root")
        t = ROOT.GetTTree(file[], "test_tree")

        maxbufferLen = ROOT.GetLenStatic(ROOT.GetLeaf(t, "col"))
        s = zeros(Int8, maxbufferLen)
        ROOT.SetBranchAddress(t[], "col", Ptr{Nothing}(pointer(s)))
        nevts = ROOT.GetEntries(t)

        @test nevts == 3
        ROOT.GetEntry(t, 0)
        @test isa(unsafe_string(pointer(s)), String)
        for i in 1:nevts
            ROOT.GetEntry(t, i - 1)
            @test data[:col][i] == unsafe_string(pointer(s))
        end

        ROOT.Close(file)
        rm("test.root")
    end
end