# From large eddy simulations (LES) to general circulation modeling (GCM)

This tutorial assumes you have Julia installed.
Let's get started.

## Set up

Open up a terminal, navigate to a directory of your choice, and clone this repo:

```bash
git clone https://github.com/glwagner/SwimLessons.jl.git
cd SwimLessons/les-to-gcm
```

Now type `julia --project` and instantiate this environment

```julia
using Pkg
Pkg.instantiate()
```

Next, we're going to start downloading data that we need for a global ocean simulation.
We'll then move on to the rest of the tutorial before returning to use the downloaded data.
To download data, write

```julia
using ClimaOcean
using Oceananigans
λ★, φ★ = 35.1, 50.1
grid = RectilinearGrid(size=200, x=λ★, y=φ★, z=(-400, 0), topology=(Flat, Flat, Bounded))
ocean = ocean_simulation(grid; Δt=10minutes, coriolis=FPlane(latitude = φ★))
set!(ocean.model, T=ECCOMetadata(:temperature), S=ECCOMetadata(:salinity))
atmosphere = JRA55_prescribed_atmosphere(1:248, longitude=λ★, latitude=φ★, backend=InMemory())
```

Ok, back to the tutorial. 
For this, we will open up a second terminal to work in while the data is busy downloading.

## Warm up: 2D turbulence

Let's warm up before diving in. This code runs a 2D turbulence simulation and plots the vorticity at the final solution:

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

using GLMakie

u, v, w = model.velocities
ω = Field(∂x(v) - ∂y(u))
compute!(ω)
heatmap(ω, axis=(; aspect=1), colormap=:balance)
```

## That escalated quickly: large eddy simulation

```julia
using Oceananigans
using Oceananigans.Units

grid = RectilinearGrid(CPU(),
                       size = (48, 48, 24),
                       x = (0, 192),
                       y = (0, 192),
                       z = (0, 48),
                       topology = (Periodic, Periodic, Bounded))

b_top_bc = FluxBoundaryCondition(1e-7)
boundary_conditions = (; b=FieldBoundaryConditions(top=b_top_bc))

model = NonhydrostaticModel(; grid, boundary_conditions,
                            tracers = :b,
                            buoyancy = BuoyancyTracer(),
                            advection = WENO())

bi(x, y, z) = 1e-6 * z + 1e-8 * randn()
set!(model, b=bi)

simulation = Simulation(model; Δt=1minute, stop_time=12hours)
conjure_time_step_wizard!(simulation, cfl=0.7)
run!(simulation)

u, v, w = model.velocities
heatmap(view(w, :, :, grid.Nz), axis=(; aspect=1), colormap=:balance)
```

## Maybe slow down: single column model forced by a prescribed atmosphere

```julia
using ClimaOcean
using Oceananigans

λ★, φ★ = 35.1, 50.1
grid = RectilinearGrid(size = 200,
                       x = λ★, y = φ★, z = (-400, 0),
                       topology = (Flat, Flat, Bounded))

ocean = ocean_simulation(grid; Δt=10minutes, coriolis=FPlane(latitude = φ★))

set!(ocean.model, T=ECCOMetadata(:temperature), S=ECCOMetadata(:salinity))

simulation_days = 7
JRA55_snapshots = 8 * simulation_days # JRA55 is 3-hourly
atmosphere = JRA55_prescribed_atmosphere(1:JRA55_snapshots,
                                         longitude = λ★,
                                         latitude = φ★,
                                         backend = InMemory())

radiation = Radiation()
coupled_model = OceanSeaIceModel(ocean; atmosphere, radiation)
simulation = Simulation(coupled_model, Δt=ocean.Δt, stop_time=simulation_days*days)
run!(simulation)
```


