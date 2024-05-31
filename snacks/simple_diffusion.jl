using Oceananigans
using GLMakie

# A one-dimensional grid
grid = RectilinearGrid(size=64, z=(-5, 5), topology=(Flat, Flat, Bounded))

# Build a model with one tracer and a constant, Laplacian (scalar) diffusivity
closure = ScalarDiffusivity(κ=1)
model = NonhydrostaticModel(; grid, closure, tracers=:c)

# Set the initial condition
set!(model, c=z -> exp(-z^2 / 2))

# Make a plot of the initial condition
c = interior(model.tracers.c, 1, 1, :)
z = znodes(model.tracers.c)
lines(c, z, label="t = 0")

# Build and run a simulation, taking care with the time step
simulation = Simulation(model; Δt=0.001, stop_time=1)
run!(simulation)

# Plot the final state
lines!(c, z, label=string("t = ", time(simulation)))
axislegend()
display(current_figure())

