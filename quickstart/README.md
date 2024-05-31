# Quickstart

This is a 1-2 hour tutorial intended to get people swimming on day 1, assuming no prior Julia or Oceananigans experience.

# Install Julia

Copy into a terminal:


```bash
curl -fsSL https://install.julialang.org | sh
```

You will be prompted a few times and usually you can just accept the defaults.
See also https://julialang.org/downloads/.

# Install Oceananigans

```julia
julia> using Pkg; Pkg.add("Oceananigans")
```

Tip: another way is to press `]` (to enter package manager mode) and then type `pkg> add Oceananigans`.

Note: in this tutorial we are "installing" Oceananigans into your global Julia environment.
This is great for playing around!
If you start working with Julia, however, its strongly recommended that you create project-specific
[environments](https://pkgdocs.julialang.org/v1/environments/).
But we don't need to worry about that yet.

## Very Important Resources for learning Julia

* [Julia's Documentation](https://docs.julialang.org/en/v1/)
* [Official resources for learning Julia](https://julialang.org/learning/)

In this tutorial we also make extensive use of one of Julia's most powerful plotting libraries,
[Makie](https://docs.makie.org/v0.21/).

# A first example (it's supposed to impress you): two-dimensional turbulence

```julia
using Oceananigans

grid = RectilinearGrid(CPU(),
                       size = (128, 128),
                       x = (0, 2π),
                       y = (0, 2π),
                       topology = (Periodic, Periodic, Flat))

model = NonhydrostaticModel(; grid, advection=WENO())

ϵ(x, y) = 2rand() - 1
set!(model, u=ϵ, v=ϵ)

simulation = Simulation(model; Δt=0.01, stop_time=4)
run!(simulation)
```

then type

```julia
using GLMakie
heatmap(interior(model.velocities.u, :, :, 1))
```

This should create a visualization of the turbulence you just simulated.

# Again with more explanation

```julia
using Oceananigans
```

This "loads" Oceananigans.
Specifically, this brings a bunch of "names" (functions and constructors for objects, like `RectilinearGrid`)
into our namespace so that we can use them.

```julia
grid = RectilinearGrid(CPU(),
                       size = (128, 128),
                       x = (0, 2π),
                       y = (0, 2π),
                       topology = (Periodic, Periodic, Flat))
```

This builds a rectilinear grid (eg, a rectangle).
Oceananigans also supports `LatitudeLongitudeGrid` for hydrostatic simulations in a spherical shell,
and a few other grid types are in various stages of development.
The first argument, which is not "named" (this is called a "positional" argument) is `CPU()`.
`CPU()` indicates that we'll allocate memory and do all our computations on the CPU.
Some other options are

* `GPU()` to allocate memory and perform computations on an NVidia GPU, if one is available.
* `Distributed(arch)`, where `arch=CPU()` or `arch=GPU()` to distributed computations across nodes, using MPI for communication.

The second argument is `size`, which sets the resolution.
Because this grid is two-dimensional, `size` is a "tuple" with 2 elements.
We're using a grid with 128 cells in the x- and y-directions.
Note, this argument is named and is called a "keyword" argument, or "kwarg".

The arguments `x` and `y` specify the domain extend in `x` and `y`.
A tuple builds a grid with equal spacing.
An array or function specifying the cell _interfaces_ can be used to build a stretched grid.

The argument `topology` dictates the nature of each dimension.
The possibilities are `Periodic`, `Bounded`, and `Flat`.
Here the z-dimension is `Flat` which means our grid is two-dimensional in `x, y`.

```julia
model = NonhydrostaticModel(; grid, advection=WENO())
```

This builds a nonhydrostatic model.
By default, `NonhydrostaticModel` has no tracers.
We've also specified an advection scheme called `WENO`, which stands for "Weighted Essentially Non-Oscillatory."

