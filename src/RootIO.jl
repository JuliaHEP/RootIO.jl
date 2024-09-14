module RootIO

import ROOT, Tables, CxxWrap
import ROOT.Write, ROOT.Fill, ROOT.Scan, ROOT.Print, ROOT.GetEntries, CxxWrap.StdVector

export TTree, Write, Fill, Print, Scan, GetEntries, StdVector

"""
    `TTree`

Type representing a `ROOT` tree. It must be used in place of the `TTree` type of the `ROOT` module.
"""
struct TTree
    _ROOT_ttree::ROOT.TTree                             # The ROOT TTree object.
    _branch_array                                       # An array of branches associated with the TTree.
    _branch_names                                       # An array of names of branches associated with the TTree
    _file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}       # A pointer to the ROOT file where the TTree is stored.
end

"""
   `Scan(tree, varexp = "", selection = "", option = "", nentries = -1, firstentry = 0) `

Loop over tree entries and print entries passing selection.

 - If varexp is 0 (or "") then print only first 8 columns.
 - If varexp = "*" print all columns.

Otherwise a column selection can be made using "var1:var2:var3".
"""
Scan(tree::RootIO.TTree, args...) = Scan(tree._ROOT_ttree, args...)

"""
    Print(tree, options = "")

Print a summary of the tree contents.

   - If option contains "all" friend trees are also printed.
   - If option contains "toponly" only the top level branches are printed.
   - If option contains "clusters" information about the cluster of baskets is printed.

Wildcarding can be used to print only a subset of the branches, e.g., Print(tree, "Elec*") will print all branches with name starting with "Elec".

"""
Print(tree::RootIO.TTree) = Print(tree._ROOT_ttree)

"""
`GetEntries(tree)`

Returns the number of entries (aka rows) stored in the `tree`.

"""
GetEntries(tree::RootIO.TTree) = GetEntries(tree._ROOT_ttree)

"""
    Write(tree::TTree)

Save the `tree` into the associated `ROOT` file. This method needs to be called to finalize the writing to disk.

"""
function Write(tree::TTree)
    ROOT.Write(tree._ROOT_ttree)
end

#     _getTypeCharacter(julia_type::DataType)
# Returns the TTree type code for the input Julia data type
# # Arguments
# - `julia_type::DataType`: The Julia type for which TTree type code is required.
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

#     _makeTTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, branch_types, branch_names)

# Create a ROOT TTree with the specified branches.

# # Arguments
# - `file`: A pointer to a ROOT file where the TTree will be stored.
# - `name`: The name of the TTree.
# - `title`: The title of the TTree.
# - `branch_types`: A collection of types for the branches.
# - `branch_names`: A collection of names for the branches.

# # Returns
# - A RootIO `TTree` object containing the ROOT TTree and its branches.
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
    TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, rowtype)

Create a ROOT TTree to store instances of a composite type, `rowtype`. Each field of the type is mapped to a TTree branch (aka column) of the same name. Each field must be annotated with its type in the declaration of `rowtype` declaration. The [`Fill`](@ref) function must be used to store the instance. Each instance will be stored in a TTree entry (aka row).

Note: for convenience, providing an instance of the row type instead of the type itself is currently supported. This support might eventually be dropped if we find that it leads to confusion. The instance is used solely to retrieve the type and is not nserted in the tree. See [`TTree(::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, ::String, ::String; columns...)`](@ref) to create and fill a tree in one go.

# Example
```julia

using CxxWrap, ROOT, RootIO
mutable struct Event
    x::Float32
    y::Float32
    z::Float32
    v::StdVector{Float32}
end
Event()  = Event(0., 0., 0., StdVector{Float32}())

# Create the tree
f = ROOT.TFile!Open("data.root", "RECREATE")
tree = RootIO.TTree(f, "mytree", "mytreetitle", Event)

# Fill the tree
e = Event()
for i in 1:10
    e.x, e.y, e.z = rand(3)
    n = rand(1:5)
    # Two next lines are an optimized version of e.v = rand(Float32)
    # by limiting time consuming memory allocation
    resize!(e.v, n)
    e.v .= rand(Float32)
    Fill(tree, e)
end

# Display tree contents
Scan(tree)
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
    TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String; columns...)

Creates a new ROOT tree and fill it with the provided data.

# Arguments
- `file`: A pointer to a ROOT file where the TTree will be stored.
- `name`: The name of the TTree.
- `title`: The title of the TTree.
- `columns...`: column definitions passed as named argument, in the form column_name = column_content or column_name = element_type

# Creation of an empty `TTree`

If the `columns` values are data types, then an empty `TTree` is created. The argument names are used for the column (aka branch) names and their value specify the type of elements to store in the column.

## Example
```julia
using ROOT, RootIO

# Create the tree
file = ROOT.TFile!Open("example.root", "RECREATE")
tree = RootIO.TTree(file, "mytree", "My tree"; col_int = Int64, col_float = Float64)

# Display the tree definition
Print(tree)
```

# Creation and filling of a `TTree`

If the `columns` values are vectors, a `TTree` is created and filled with the data provided in the vectors. A branch is created for each `columns` argument with the name of the argument and filled with each element of the vector provided as the argument value. All the vectors must be of the same length.

## Example
```julia
file = ROOT.TFile!Open("example.root", "RECREATE")
name = "example_tree"
title = "Example TTree"
data = (col_float=rand(Float64, 3), col_int=rand(Int32, 3))
tree = RootIO.TTree(file, name, title; data...)
```
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

Append one or more rows (aka entries) to the ROOT `tree`.

Single row can be provided as an instance of a composite type or of a `Tuple`.

# Example
```julia
using ROOT, RootIO

# Create the tree
file = ROOT.TFile!Open("example.root", "RECREATE")
tree = RootIO.TTree(file, "mytree", "My tree"; col_int = Int64, col_float = Float64)

# Fill the tree
for i in 1:10
    Fill(tree, (i, i*π))
end

# Display the tree contents
Scan(tree)
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
