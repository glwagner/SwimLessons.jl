using Oceananigans

grid = RectilinearGrid(size=128, x=(-5, 15), topology=(Periodic, Flat, Flat))
velocities = PrescribedVelocities(u=1)
model = HydrostaticFreeSurfaceModel(; grid, velocities, tracers=:c, buoyancy=nothing)
set!(model, c = x -> exp(-x^2 / 2))
simulation = Simulation(model, Δt=0.01, stop_time=2)
run!(simulation)

@show simulation

