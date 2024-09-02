# RootIO.jl

## Introduction

Interface to ROOT file format with read/write support based on the C++ ROOT libraries.

It uses a Julia interface to the official [ROOT](http://root.cern/) C++ libraries written using [WrapIt](https://github.com/grasph/wrapit) and [CxxWrap](https://github.com/JuliaInterop/CxxWrap.jl). It extends this interface to provide a user-friendly and Julia-like interface.

This project is initiated in the context of the 2024 edition of the [Google Summer of Code](https://summerofcode.withgoogle.com/) program under the [CERN-HSF](https://github.com/JuliaHEP/RootIO.jl/blob/main/Introduction) organization.

## Contents
```@contents
Pages = ["index.md", "gettingstarted.md", "typesandmethods.md", "examples.md"]
Depth = 1
```

## Supported types

| **Type**                 | **Description**                                   | **Supported** |
|--------------------------|---------------------------------------------------|---------------|
| String                   | A character string                                | ✅            |
| Int8                     | An 8-bit signed integer                           | ✅            |
| UInt8                    | An 8-bit unsigned integer                         | ✅            |
| Int16                    | A 16-bit signed integer                           | ✅            |
| UInt16                   | A 16-bit unsigned integer                         | ✅            |
| Int32                    | A 32-bit signed integer                           | ✅            |
| UInt32                   | A 32-bit unsigned integer                         | ✅            |
| Float32                  | A 32-bit floating-point number                    | ✅            |
| Half32b                  | 32 bits in memory, 16 bits on disk                | ❌            |
| Float64                  | A 64-bit floating-point number                    | ✅            |
| Double32c                | 64 bits in memory, 32 bits on disk                | ❌            |
| Int64                    | A long signed integer, stored as 64-bit           | ✅            |
| UInt64                   | A long unsigned integer, stored as 64-bit         | ✅            |
| Bool                     | A boolean                                         | ✅            |
| StdVector{T}             | A vector of elements of any of the above types    | ✅            |
| C-array                  | A C-array of elements of any of the above types   | ✅            |
| Simple structs           | A simple sturcts without any struct field         | ✅            |
| Nested structs           | A sturcts with another struct as its field        | ❌            |
| RNTuple                  | ROOT's experimental tuple data type               | ❌            |

## For contributors

1. Add support for ROOT classes in [ROOT.jl](https://github.com/JuliaHEP/ROOT.jl)
2. Add support for writing new classes and objects
3. Translate [ROOT Tutorials](https://root.cern/doc/master/group__Tutorials.html) into equivalent Julia tutorials