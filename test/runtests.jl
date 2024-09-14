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

function _test_tree(eltype, num_events, data)
    file = ROOT.TFile!Open("test.root")
    t = ROOT.GetTTree(file[], "test_tree")
    nevts = ROOT.GetEntries(t)

    #Check number of written rows
    @test nevts == num_events
    
    a = Array{eltype, 0}(undef)
    ROOT.SetBranchAddress(t[], "col", Ptr{Nothing}(pointer(a)))

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

function _test_tree(eltype::Type{String}, num_events, data)
    file = ROOT.TFile!Open("test.root")
    t = ROOT.GetTTree(file[], "test_tree")
    nevts = ROOT.GetEntries(t)

    #Check number of written rows
    @test nevts == num_events
    
    maxbufferLen = ROOT.GetLenStatic(ROOT.GetLeaf(t, "col"))
    s = zeros(Int8, maxbufferLen)
    ROOT.SetBranchAddress(t[], "col", Ptr{Nothing}(pointer(s)))

    for i in 1:nevts
        ROOT.GetEntry(t, i - 1)
        @test GC.@preserve s data[:col][i] == unsafe_string(pointer(s))
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
        _test_tree(Bool, num_events, data)
    end
end

@testset "Writing String" begin
    @testset "String" begin
        data = Dict(:col => ["CERN", "ROOT", "RootIO"])
        _create_test_tree(data)
        _test_tree(String, 3, data)
    end
end

@testset "Writing C-style arrays" begin
    @testset "Fixed size C-array" begin
        file = ROOT.TFile!Open("test.root", "RECREATE")
        name = "test_tree"
        title = "Test TTree"
        my_arr_fixed_length = 3
        tree = RootIO.TTree(file, name, title; my_arr = (Int64, my_arr_fixed_length))
        RootIO.Fill(tree, [[1,2,3]])
        RootIO.Fill(tree, [[-1,1,-1]])
        RootIO.Write(tree)
        ROOT.Close(file)

        file = ROOT.TFile!Open("test.root")
        t = file["test_tree"]
        maxbufferLen = ROOT.GetLenStatic(ROOT.GetLeaf(t, "my_arr"))
        arr = zeros(Int64, maxbufferLen)
        ROOT.SetBranchAddress(t, "my_arr", Ptr{Nothing}(pointer(arr)))
        nevts = ROOT.GetEntries(t)
        @test nevts == 2
        for i in 1:nevts
            ROOT.GetEntry(t, i - 1)
            if i == 1
                @test arr == [1,2,3]
            else
                @test arr == [-1,1,-1]
            end
        end
        ROOT.Close(file)
        rm("test.root")
    end

    @testset "Variable size C-array" begin
        file = ROOT.TFile!Open("test.root", "RECREATE")
        name = "test_tree"
        title = "Test TTree"
        arrays = [[1,10,100], [2,20]]
        tree = RootIO.TTree(file, name, title; arr_size = Int64, my_arr = (Int64, :arr_size))
        for arr in arrays 
            RootIO.Fill(tree, [length(arr), arr])
        end
        RootIO.Write(tree)
        ROOT.Close(file)

        file = ROOT.TFile!Open("test.root")
        t = file["test_tree"]
        maxbufferLen = 3
        arr_sz = fill(0)
        arr = zeros(Int64, maxbufferLen)
        ROOT.SetBranchAddress(t, "arr_size", arr_sz)
        ROOT.SetBranchAddress(t, "my_arr", Ptr{Nothing}(pointer(arr)))
        nevts = ROOT.GetEntries(t)
        @test nevts == 2
        ROOT.GetEntry(t, 0)
        @test isa((arr_sz[]), Int64)
        for i in 1:nevts
            ROOT.GetEntry(t, i - 1)
            @test arr_sz[] == length(arrays[i])
            for j in 1:arr_sz[]
                @test arr[j] == arrays[i][j]
            end
        end
        ROOT.Close(file)
        rm("test.root")
    end
end
