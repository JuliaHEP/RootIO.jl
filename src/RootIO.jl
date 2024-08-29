module RootIO

import ROOT, Tables, CxxWrap

export TTree, Write, Fill

"""
    struct TTree

A struct representing a ROOT TTree with its associated branches and file.
"""
struct TTree
    _ROOT_ttree::ROOT.TTree                             # The ROOT TTree object.
    _branch_array                                       # An array of branches associated with the TTree.
    _branch_names                                       # An array of names of branches associated with the TTree
    _file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}       # A pointer to the ROOT file where the TTree is stored.
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
    _getTypeCharacter(julia_type::DataType)
Returns the TTree type code for the input Julia data type
# Arguments
- `julia_type::DataType`: The Julia type for which TTree type code is required.
"""
function _getTypeCharacter(julia_type::DataType)
    if julia_type == String
        return "C"
    elseif julia_type == Int8
        return "B"
    elseif julia_type == UInt8
        return "b"
    elseif julia_type == Int16
        return "S"
    elseif julia_type == UInt16
        return "s"
    elseif julia_type == Int32
        return "I"
    elseif julia_type == UInt32
        return "i"
    elseif julia_type == Float32
        return "F"
    # elseif julia_type == ROOT.Half32
    #     return "f"
    elseif julia_type == Float64
        return "D"
    # elseif julia_type == ROOT.Double32
    #     return "d"
    elseif julia_type == Int64
        return "L"
    elseif julia_type == UInt64
        return "l"
    elseif julia_type == Bool
        return "O"
    end
end

"""
    _makeTTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, branch_types, branch_names)

Creates a ROOT TTree with specified branches.

# Arguments
- `file`: A pointer to a ROOT file where the TTree will be stored.
- `name`: The name of the TTree.
- `title`: The title of the TTree.
- `branch_types`: A collection of types for the branches.
- `branch_names`: A collection of names for the branches.

# Returns
- A RootIO `TTree` object containing the ROOT TTree and its branches.
"""
function _makeTTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, branch_types, branch_names)
    tree = ROOT.TTree(name, title)
    current_branches = []
    for i in eachindex(branch_types)
        if isa(branch_types[i], Tuple)
            type_identifier = _getTypeCharacter(branch_types[i][1])
            if isa(branch_types[i][2], Symbol)
                curr_branch = ROOT.Branch(tree, string(branch_names[i]), Ptr{Nothing}(), "$(branch_names[i])[$(string(branch_types[i][2]))]/$(type_identifier)")
                push!(current_branches, curr_branch)
            else
                curr_branch = ROOT.Branch(tree, string(branch_names[i]), Ptr{Nothing}(), "$(branch_names[i])[$(branch_types[i][2])]/$(type_identifier)")
                push!(current_branches, curr_branch)
            end
        elseif branch_types[i] <: CxxWrap.StdVector
            ptr = (branch_types[i])()
            curr_branch = ROOT.Branch(tree, string(branch_names[i]), ptr, 3200, 99)
            push!(current_branches, curr_branch)
        elseif branch_types[i] == String
            curr_branch = ROOT.Branch(tree, string(branch_names[i]), Ptr{Nothing}(), "$(branch_names[i])/C")
            push!(current_branches, curr_branch)
        elseif branch_types[i] == Bool
            curr_branch = ROOT.Branch(tree, string(branch_names[i]), Ptr{Int8}(), "$(branch_names[i])/O")
            push!(current_branches, curr_branch)
        else
            curr_branch = ROOT.Branch(tree, string(branch_names[i]), Ref(one(branch_types[i])), 3200, 99)
            push!(current_branches, curr_branch)
        end
    end
    return TTree(tree, current_branches, branch_names, file)
end

"""
    TTree(file, name, title, data)

Creates a new ROOT TTree with branches of given type or branches having types infered from the given data (data is not written to the tree).

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
```
"""
function TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, data)
    branch_types= []
    branch_names = []
    if isa(data, DataType)
        branch_types = fieldtypes(data)
        branch_names = fieldnames(data)
    else
        branch_types = fieldtypes(typeof(data))
        branch_names = fieldnames(typeof(data))
    end
    return _makeTTree(file, name, title, branch_types, branch_names)
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
    _branch_types_array = []
    _branch_names_array = []

    for (key, value) in kwargs
        push!(_branch_names_array, key)
        if isa(value, Tuple) || isa(value, DataType)
            push!(_branch_types_array, value)
        else
            push!(_branch_types_array, eltype(value))
        end
    end
    
    return _makeTTree(file, name, title, _branch_types_array, _branch_names_array)
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
file = ROOT.TFile!Open("example.root", "RECREATE")
name = "example_tree"
title = "Example TTree"
tree = RootIO.TTree(file, name, title, [Float64])
RootIO.Fill(tree, 1.0)
```
"""
function Fill(tree::TTree, data)
    if Tables.istable(data)
        for row in Tables.rows(data)
            Fill(tree, row)
        end
    else
        row = data
        if !isa(row, Array)
            row = map(field -> getfield(data, field), fieldnames(typeof(data)))
        end
        GC.@preserve row begin
            for i in eachindex(tree._branch_array)
                if isa(row[i], Array)
                    ROOT.SetAddress(tree._branch_array[i], convert(Ptr{Nothing}, pointer(row[i])))
                elseif isa(row[i], CxxWrap.StdVector)  
                    ROOT.SetObject(tree._branch_array[i], row[i])
                elseif isa(row[i], String)
                    ROOT.SetAddress(tree._branch_array[i], convert(Ptr{Nothing}, pointer(row[i])))
                elseif isa(row[i], Bool)
                    ROOT.SetAddress(tree._branch_array[i], convert(Ptr{Nothing}, pointer(fill(row[i]))))
                else
                    ROOT.SetAddress(tree._branch_array[i], Ref(row[i]))
                end
            end
            ROOT.Fill(tree._ROOT_ttree)
        end
    end
end 

end # module RootIO
