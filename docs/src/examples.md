# Examples

## Writing primitive types

All the primitive types and structs can be written to the TTree using the RootIO.jl library. By convention, a data type or an instance of the column can be used to create the columns. 

A complete list of supported Julia and ROOT custom types can be found in the [introduction page](@ref Introduction).

!!! tip "Creating TTree with columns instances"
    Creating a TTree with row instance only infers the types from the instance, and doesn't write it to the TTree

### Writing to a TTree using keyword-argument and instance of row

Keyword-arguments can be used to pass instance of a column to the tree. The types and names are inferred from the arguments.

```julia
import RootIO, ROOT
using DataFrames
file = ROOT.TFile!Open("example.root", "RECREATE")
name = "example_tree"
title = "Example TTree"
data = (col_float=rand(Float64, 3), col_int=rand(Int32, 3))
tree = RootIO.TTree(file, name, title; data...)
RootIO.Write(tree)
ROOT.Close(file)
```

### Writing a struct to a TTree

The fieldnames and field types of the struct are used to create the branches of the TTree.

```julia
import RootIO, ROOT
using CxxWrap
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
RootIO.Write(tree)
ROOT.Close(f)
```

## Writing vectors

RootIO.jl supports writing of the ```CxxWrap.StdVector``` that wraps the ```std::vector``` from C/C++.

```julia
import RootIO, ROOT, CxxWrap
# Create and open the ROOT file
file = ROOT.TFile!Open("example.root", "RECREATE")
name = "example_tree"
title = "Example TTree"
v = StdVector{Float32}()
# Create a columns for CxxWrap.StdVector data type
tree = RootIO.TTree(file, name, title; my_arr = CxxWrap.StdVector)
# Write the CxxWrap.Std vector to the TTree
v .= rand(Float32, 5)
RootIO.Fill(tree, [v])
RootIO.Write(tree)
ROOT.Close(file)
```

## C-style arrays

The syntax for creating a C-style array is ```array_name = (element_type, array_size)```, where:

1. ```array_name``` is the name of column containing the array
2. ```element_type``` is a data type or an instance of array element
2. ```array_size``` is the symbol for variable having size of the array for fixed size array, or identifier of the branch that contains the length of the array in case of variable length array 

### Fixed size C-style arrays

```julia
import RootIO, ROOT
# Create and open the ROOT file
file = ROOT.TFile!Open("example.root", "RECREATE")
name = "example_tree"
title = "Example TTree"
# Store the size of array as variable
my_arr_fixed_length = 3
# Create the column for C-style array
tree = RootIO.TTree(file, name, title; my_arr = (Int64, my_arr_fixed_length))
# Write the C-style array to the TTree
RootIO.Fill(tree, [[1,2,3]])
RootIO.Write(tree)
ROOT.Close(file)
```

### Variable size C-style arrays

```julia
import RootIO, ROOT
# Create and open the the ROOT file
file = ROOT.TFile!Open("example.root", "RECREATE")
name = "example_tree"
title = "Example TTree"
# Create the column for array-size and the C-style array
tree = RootIO.TTree(file, name, title; arr_size = Int64, my_arr = (Int64, :arr_size))
# Write the C-style array along with its size to the TTree
RootIO.Fill(tree, [3, [1,10,100]])
RootIO.Fill(tree, [2, [2,20]])
RootIO.Write(tree)
ROOT.Close(file)
```