module RootIO

import ROOT, Tables, CxxWrap

"""
    struct TTree

A struct representing a ROOT TTree with its associated branches and file.

# Fields
- `_ROOT_ttree`: The ROOT TTree object.
- `_branch_array`: An array of branches associated with the TTree.
- `_file`: A pointer to the ROOT file where the TTree is stored.
"""
struct TTree
    _ROOT_ttree::ROOT.TTree
    _branch_array
    _branch_names
    _file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}
end

"""
    Write(tree::TTree)

Writes a ROOT TTree to the associated ROOT file.

# Arguments
- `tree::TTree`: The TTree object to be written to the ROOT file.
"""
function Write(tree::TTree)
    ROOT.Write(tree._ROOT_ttree)
end


"""
    _makeTTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, _branch_types, _branch_names)

Creates a ROOT TTree with specified branches.

# Arguments
- `file`: A pointer to a ROOT file where the TTree will be stored.
- `name`: The name of the TTree.
- `title`: The title of the TTree.
- `_branch_types`: A collection of types for the branches.
- `_branch_names`: A collection of names for the branches.

# Returns
- A RootIO `TTree` object containing the ROOT TTree and its branches.
"""
function _makeTTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, _branch_types, _branch_names)
    _tree = ROOT.TTree(name, title)
    _curr_branch_array = []
    for i in 1:length(_branch_types)
        if _branch_types[i] <: CxxWrap.StdVector
            _ptr = (_branch_types[i])()
            _curr_branch = ROOT.Branch(_tree, string(_branch_names[i]), _ptr, 100, 99)
            push!(_curr_branch_array, _curr_branch)
        elseif _branch_types[i] == String
            _curr_branch = ROOT.Branch(_tree, string(_branch_names[i]), Ptr{Nothing}(), "$(_branch_names[i])/C")
            push!(_curr_branch_array, _curr_branch)
        elseif _branch_types[i] == Bool
            _curr_branch = ROOT.Branch(_tree, string(_branch_names[i]), Ptr{Int8}(), "$(_branch_names[i])/O")
            push!(_curr_branch_array, _curr_branch)
        else
            _curr_branch = ROOT.Branch(_tree, string(_branch_names[i]), Ref(one(_branch_types[i])), 100, 99)
            push!(_curr_branch_array, _curr_branch)
        end
    end
    return TTree(_tree, _curr_branch_array, _branch_names, file)
end

"""
    TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, data)

Creates a new ROOT TTree and fills it with the provided data.

# Arguments
- `file`: A pointer to a ROOT file where the TTree will be stored.
- `name`: The name of the TTree.
- `title`: The title of the TTree.
- `data`: The data used to define and optionally fill the branches of the TTree. This can be a `DataType` or an instance of a type with fields.

# Example
```julia
mutable struct Event
    x::Float32
    y::Float32
    z::Float32
    v::StdVector{Float32}
end
f = ROOT.TFile!Open("data.root", "RECREATE")
Event()  = Event(0., 0., 0., StdVector{Float32}())
tree = RootIO.TTree(f, "mytree", "mytreetitle", Event)
e = Event()
for i in 1:10
    e.x, e.y, e.z = rand(3)
    resize!.([e.v], 5)
    e.v .= rand(Float32, 5)
    RootIO.Fill(tree, e)
end
````
"""
function TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, data)
    println("Creating a new TTree")

    _branch_types_array = []
    _branch_names_array = []
    if isa(data, DataType)
        _branch_types_array = fieldtypes(data)
        _branch_names_array = fieldnames(data)
    else
        _branch_types_array = fieldtypes(typeof(data))
        _branch_names_array = fieldnames(typeof(data))
    end

    it = _makeTTree(file, name, title, _branch_types_array, _branch_names_array)

    if !isa(data, DataType)
        Fill(it, data)
    end

    return it
end

"""
    TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String; kwargs...)

Creates a new ROOT TTree and fills it with the provided data.

# Arguments
- `file`: A pointer to a ROOT file where the TTree will be stored.
- `name`: The name of the TTree.
- `title`: The title of the TTree.
- `kwargs...`: Named arguments representing the branches of the TTree. Each named argument is either a data type or an array of data.

# Example
```julia
file = ROOT.TFile!Open("example.root", "RECREATE")
name = "example_tree"
title = "Example TTree"
data = (col_float=rand(Float64, 3), col_int=rand(Int32, 3))
tree = RootIO.TTree(file, name, title; data...)
"""
function TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String; kwargs...)
    println("Creating a new TTree")

    _branch_types_array = []
    _branch_names_array = NTuple{length(kwargs), Symbol}(collect(keys(kwargs)))
    if isa(kwargs[1], DataType)
        _branch_types_array = NTuple{length(kwargs), DataType}(collect(values(kwargs)))
    else
        _branch_types_array = NTuple{length(kwargs), DataType}([eltype(value) for value in values(kwargs)])
    end

    it = _makeTTree(file, name, title, _branch_types_array, _branch_names_array)

    if !isa(kwargs[1], DataType)
        num_rows = length(kwargs[1])
        for curr_row in 1:num_rows
            for curr_branch in 1:length(kwargs)
                if typeof(kwargs[curr_branch][curr_row]) <: CxxWrap.StdVector
                    ROOT.SetObject(it._branch_array[curr_branch], kwargs[curr_branch][curr_row])
                elseif typeof(kwargs[curr_branch][curr_row]) == String
                    str = kwargs[curr_branch][curr_row]
                    GC.@preserve str begin
                        ROOT.SetBranchAddress(it._ROOT_ttree, string(_branch_names_array[curr_branch]), convert(Ptr{Int8}, pointer(str)))
                    end
                elseif typeof(kwargs[curr_branch][curr_row]) == Bool
                    b = fill(kwargs[curr_branch][curr_row])
                    GC.@preserve b begin
                        ROOT.SetBranchAddress(it._ROOT_ttree, string(_branch_names_array[curr_branch]), convert(Ptr{Int8}, pointer(b)))
                    end
                else    
                    ROOT.SetAddress(it._branch_array[curr_branch], Ref(kwargs[curr_branch][curr_row]))
                end
            end
            _preserved_vars = it._branch_array
            GC.@preserve _preserved_vars ROOT.Fill(it._ROOT_ttree)
        end
    end

    return it
end

"""
    Fill(tree::TTree, data)

Fills a ROOT TTree with the provided data.

# Arguments
- `tree`: The TTree object to be filled.
- `data`: The data to fill the TTree with. This can be a table or a row.

# Example
```julia
# Assuming `tree` is an existing TTree and `data` is a table or row
Fill(tree, data)
"""
function Fill(tree::TTree, data)
    if Tables.istable(data)
        println("Filling the TTree with a table")
        for row in Tables.rows(data)
            Fill(tree, row)
        end
    else
        println("Filling the TTtree with a row")
        row = data
        if !(typeof(row) <: Vector)
            row = map(field -> getfield(data, field), fieldnames(typeof(data)))
        end
        for i in 1:length(tree._branch_array)
            if typeof(row[i]) <: CxxWrap.StdVector
                ROOT.SetObject(tree._branch_array[i], row[i])
            elseif typeof(row[i]) == String
                str = row[i]
                GC.@preserve str begin
                    ROOT.SetBranchAddress(tree._ROOT_ttree, string(tree._branch_names[i]), convert(Ptr{Int8}, pointer(str)))
                end
            elseif typeof(row[i]) == Bool
                b = fill(row[i])
                GC.@preserve b begin
                    ROOT.SetBranchAddress(tree._ROOT_ttree, string(tree._branch_names[i]), convert(Ptr{Int8}, pointer(b)))
                end
            else
                ROOT.SetAddress(tree._branch_array[i], Ref(row[i]))
            end
        end
        _preserved_vars = tree._branch_array
        GC.@preserve _preserved_vars ROOT.Fill(tree._ROOT_ttree)
    end
end 

end # module RootIO
