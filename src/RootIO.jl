module RootIO

import ROOT, Tables, CxxWrap
import ROOT.Write, ROOT.Fill, ROOT.Scan, ROOT.Print, ROOT.GetEntries, CxxWrap.StdVector, CxxWrap.StdValArray, CxxWrap.StdString

export TTree, Write, Fill, Print, Scan, GetEntries, StdVector, StdValArray, StdString

"""
    `TTree`

Type representing a `ROOT` tree. It must be used in place of the `TTree` type of the `ROOT` module.
"""
struct TTree
    _ROOT_ttree::ROOT.TTree                             # The ROOT TTree object.
    _branch_array::Vector{Union{CxxWrap.CxxPtr{ROOT.TBranch}, ROOT.TBranchPtr}} # Branches associated with the TTree.
    _branch_names::Vector{Symbol}                       # Names of the branches associated with the TTree
    _branch_types::Vector{DataType}                     # Expected Julia types for branch associated with the TTree
    _size_branches::Vector{Union{Integer, Symbol}}      # Name of the branch containing the size of a c-array,
                                                        # size if it is fixed, or 0 if i-th branch is not a c-array
    _file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}       # A pointer to the ROOT file where the TTree is stored.
    _rowbuffer::Vector{Any}                             # Current row, scalars are put in a zero-length array

    TTree(tree, branches, names, types, sizebranches, file) = new(tree, branches, names, types, sizebranches,
                                                                  file, Vector{DenseArray}(undef, length(branches)))
end

Base.convert(t::Type{StdVector{T}}, x::Array{T}) where {T} = StdVector(x)

# Helper function to retrieve the branch type from the provided type or type instance
# returns StdVector{T} for StdVector{T} and its subtypes
_branchtype(data::Type{T})  where {T <: StdVector{U}} where {U} = (StdVector{U}, 0)
_branchtype(data::Type{T})  where {T <: DenseArray{U}} where {U} = (StdVector{U}, 0)
_branchtype(data::Tuple{T,S})  where {T <: Type, S <: Union{Symbol, Integer}} = (Vector{data[1]}, data[2])
_branchtype(type::Type) = (type, 0)
_branchtype(data) = invoke(_branchtype, [Type], typeof(data)) #use invoke to be 100% sure to not call the same method recursively

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
function _makeTTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, branch_names, branch_types)
    tree = ROOT.TTree(name, title)
    current_branches = Union{CxxWrap.CxxPtr{ROOT.TBranch}, ROOT.TBranchPtr}[]

    (branch_datatypes, sizebranches) = tuple.(_branchtype.(branch_types)...)
    
    for i in eachindex(branch_datatypes)
        if sizebranches[i] !== 0 #c-array
            type_identifier = _getTypeCharacter(eltype(branch_datatypes[i]))
            isnothing(type_identifier) && throw(ArgumentError("Element type $(eltype(branch_datatypes[i])) is not supported for a c-array storage. You can use StdVector storage mode instead."))
            if isa(sizebranches[i], Symbol)
                curr_branch = ROOT.Branch(tree, string(branch_names[i]), Ptr{Nothing}(), "$(branch_names[i])[$(string(sizebranches[i]))]/$(type_identifier)")
                push!(current_branches, curr_branch)
            elseif isa(sizebranches[i], Number) && sizebranches[i] > 0
                curr_branch = ROOT.Branch(tree, string(branch_names[i]), Ptr{Nothing}(), "$(branch_names[i])[$(sizebranches[i])]/$(type_identifier)")
                push!(current_branches, curr_branch)
            else
                throw(ArgumentError("Bad c-array specification, $(branch_types[i]). Second element needs to be either a symbol or a strictly positive number."))
            end
        else
            if branch_datatypes[i] <: CxxWrap.StdVector
                ptr = (branch_datatypes[i])()
                curr_branch = ROOT.Branch(tree, string(branch_names[i]), ptr, 3200, 99)
                push!(current_branches, curr_branch)
            elseif branch_datatypes[i] == String
                curr_branch = ROOT.Branch(tree, string(branch_names[i]), Ptr{Nothing}(), "$(branch_names[i])/C")
                push!(current_branches, curr_branch)
            elseif branch_datatypes[i] == Bool
                curr_branch = ROOT.Branch(tree, string(branch_names[i]), Ptr{Nothing}(), "$(branch_names[i])/O")
                push!(current_branches, curr_branch)
            elseif branch_datatypes[i] <: Union{ROOT.TObject, ROOT.TString}
                classname = replace(string(branch_datatypes[i]), "ROOT." => "")
                curr_branch = ROOT.Branch(tree, string(branch_names[i]), classname, Ptr{Nothing}(), 3200, 99)
                push!(current_branches, curr_branch)
            else
                curr_branch = ROOT.Branch(tree, string(branch_names[i]), Ref{branch_datatypes[i]}(), 3200, 99)
                push!(current_branches, curr_branch)
            end
        end
    end

    return TTree(tree, current_branches, collect(branch_names), collect(branch_datatypes), collect(sizebranches), file)
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
function TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, rowtype::DataType)
    branchnames = fieldnames.(rowtype)
    branchtypes = fieldtypes.(rowtype)
    return _makeTTree(file, name, title, branchnames, branchtypes)
end

# no stringdoc here, as it is shared with the previous method declaration
function TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, table)
    if Tables.istable(table)
        sch = Tables.schema(table)
        isnothing(sch) && error("Failed to retrieve the schema of the provided table")
        tree = _makeTTree(file, name, title, sch.names, sch.types)
        Fill(tree, table)
        tree
    else #handle the case where the 4th argument is an instance of a single row
        type = typeof(rowtype)
        isa(type, DataType) || throw(ArgumentError("The rowtype argument needs to be a DataType."))
        TTree(file, name, title, type)
    end
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
function TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String; columns...)
    branch_types = []
    branch_names = Symbol[]

    nrowdata = 0
    for (key, value) in columns
        push!(branch_names, key)
        if isa(value, Union{DataType, Tuple{DataType, Any}})
            nrowdata > 0 && throw(ArgumentError("Mix of keyword argument specifying column type and contents"))
            push!(branch_types, value)                            
        elseif isa(value, Union{Vector, Tuple})
            push!(branch_types, eltype(value))
            if nrowdata == 0
                nrowdata = length(value)
            else
                nrowdata == length(value) || throw(ArgumentError("Column size mimatch"))
            end
        else
            throw(ArgumentError("Invalid value for keyword argument $key."))
        end
    end

    tree =  _makeTTree(file, name, title, branch_names, branch_types)

    if nrowdata > 0
        data = last(zip(columns...))
        for row in zip(data...)
            Fill(tree, row)
        end
    end

    return tree
end

_SupportedStdContainers = Union{StdVector, StdValArray, StdString}

#wrap data to reference them in the _rowbuffer.
#everything is put in a mutable as we need a pointer to the data to pass to the C++ library
_wrap(a) = fill(a)
_wrap(a::DenseArray) = a
#_wrap(a::StdVector) = a
_wrap(a::_SupportedStdContainers) = a
_wrap(a::String) = a

# Set address of data to store in a branch

_SetColAddress(tree::RootIO.TTree, icol, x::Union{StdVector, ROOT.TObject}) = ROOT.SetObject(tree._branch_array[icol], x)

@inline function _SetColAddress(tree::RootIO.TTree, icol, x::DenseArray)
    #FIXME handle nested std::vector, used for multidimensionnal arrays
    if tree._branch_types[icol] <: _SupportedStdContainers
        ROOT.SetObject(tree._branch_array[icol], x)
    elseif tree._branch_types[icol] <: Union{String, Bool, Vector}
        ROOT.SetAddress(tree._branch_array[icol], convert(Ptr{Nothing}, pointer(x)))
    elseif tree._branch_types[icol] <: Union{ROOT.TObject, ROOT.TString}
        ROOT.SetAddress(tree._branch_array[icol], convert(Ptr{Nothing}, pointer(x)))       
    else
        ROOT.SetAddress(tree._branch_array[icol], x)
    end
end

_SetColAddress(tree::RootIO.TTree, icol, x::Union{Bool, String}) = ROOT.SetAddress(tree._branch_array[icol], convert(Ptr{Nothing}, pointer(x)))


function _UpdateAddresses(tree)
    for (icol, data) in enumerate(tree._rowbuffer)
        _SetColAddress(tree, icol, data)
    end
    nothing
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
function Fill(tree::TTree, data; unsafe = false)
    if Tables.istable(data)
        _fillFromTable(tree, data, unsafe = unsafe)
    elseif(applicable(fieldnames, typeof(data))
           && !isa(data, Tuple) #Exclude Tuples which have fieldnames :1, :2,...
           && length(fieldnames(typeof(data))) > 0)
        #a composite type or a NamedTuple
        _fillOneRowFromStructOrNamedTuple(tree, data)
    else
        _fillOneRowFromIterable(tree, data)
    end
end

function _fillOneRowFromStructOrNamedTuple(tree, data)
    for (icol, nm) in enumerate(tree._branch_names)
        _set(tree, icol, getfield(data, nm))
    end
    _fill(tree)
end

function _fillOneRowFromIterable(tree, data)
    nfilled = 0
    for (icol, val) in enumerate(data)
        icol > length(tree._branch_array) && throw(ArgumentError("Provided data contains two many columns, expected $(length(tree._branch_array))."))
        _set(tree, icol, val)
        nfilled += 1
    end
    nfilled == length(tree._branch_array) || throw(ArgumentError("Provided data does not contain enough columns, expected $(length(tree._branch_array))."))
    _fill(tree)
end

function _fillFromTable(tree::TTree, data; unsafe = false)
    sch = Tables.schema(data)
    if !unsafe
        all(sch.names .== tree._branch_names) || throw(ArgumentError("Column name or order mismatch, Got $(sch.names), expected $(tree._branch_names)"))
    end
    for row in Tables.rows(data)
        Tables.eachcolumn(sch, row) do val, icol, colname
            _set(tree, icol, val)
        end
        _fill(tree)
    end
end


function _fill(tree)
    rowbuffer = tree._rowbuffer
    GC.@preserve rowbuffer begin
        _UpdateAddresses(tree)
        ROOT.Fill(tree._ROOT_ttree)
    end
end

# Set value of a column in the row buffer.
function _set(tree, icol, val)
    tree._rowbuffer[icol] = _wrap(convert(tree._branch_types[icol], val))
end

end # module RootIO
