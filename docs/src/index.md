# RootIO.jl

## Introduction

The RootIO package provides an easy interface to write columnar data sets from and into [ROOT files](https://root.cern/manual/root_files) using the [`TTree`](https://root.cern/doc/master/classTTree.html) representation. A `TTree` is a columnar data representation stored on disk that supports an in-memory buffer for fast data access and automatic writing to disk. This package is based on [ROOT.jl](https://github.com/JuliaHEP/ROOT.jl), a package that provides Julia bindings to the C++ [ROOT](https://root.cern) API.

The original `TTree` API is heavily based on pointers; it does not translate well to Julia and is not easy to use. The `RootIO` module, to be used alongside the `ROOT` module, provides a higher-level and more user-friendly interface to `TTree`. `RootIO` defines its own `TTree` type to be used in place of `ROOT.TTree`.

_The development of this package was initiated in the context of the 2024 edition of the [Google Summer of Code](https://summerofcode.withgoogle.com/) program under the [CERN-HSF](https://github.com/JuliaHEP/RootIO.jl/blob/main/Introduction) organization._

Only write support is currently implemented. We recommend [UnROOT](https://github.com/JuliaHEP/UnROOT.jl) for an easy read interface to trees. Direct use of ROOT.jl is also possible but requires pointer manipulation. 

## Contents
```@contents
Pages = ["index.md", "gettingstarted.md", "typesandmethods.md", "examples.md"]
Depth = 1
```

## Supported types

`TTree` represents data in two dimensions. Elements of this matrix can be of any type that can be defined in C++, including classes. In the botanical ROOT terminology, a column is called a branch and a row a tree entry.

`RootIO` includes support for most of the standard Julia primitive types, character strings (`String`), and vectors of elements of these types. Vectors of `Any` are not supported. The supported types are summarized in the table below.

| **Type**       | **Description**                                                       | **Supported** |
|----------------|-----------------------------------------------------------------------|---------------|
| String         | A character string                                                    | ✅            |
| Int8           | An 8-bit signed integer                                               | ✅            |
| UInt8          | An 8-bit unsigned integer                                             | ✅            |
| Int16          | A 16-bit signed integer                                               | ✅            |
| UInt16         | A 16-bit unsigned integer                                             | ✅            |
| Int32          | A 32-bit signed integer                                               | ✅            |
| UInt32         | A 32-bit unsigned integer                                             | ✅            |
| Float32        | A 32-bit floating-point number                                        | ✅            |
| Float64        | A 64-bit floating-point number                                        | ✅            |
| Int64          | A long signed integer, stored as 64-bit                               | ✅            |
| UInt64         | A long unsigned integer, stored as 64-bit                             | ✅            |
| Bool           | A boolean                                                             | ✅            |
| StdVector{T}¹  | A vector of elements of any of the above types stored as std::vector  | ✅            |
| Vector{T}      | A vector of elements of any of the above types stored as a C-array²   | ✅            |

¹ `StdVector` is a subtype of `AbstractVector` provided by the CxxWrap package and reexported by `RootIO`. Use `StdVector([1, 2, 3])` to create a vector with elements 1, 2, and 3.

² with a fixed size or a size specified in another column.
