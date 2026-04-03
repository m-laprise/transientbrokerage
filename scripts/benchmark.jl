using TransientBrokerage
using BenchmarkTools

# Warm up and benchmark a short simulation
params = default_params(; T=50, seed=42)

# Warm-up run
run_simulation(params)

# Benchmark
println("=== Simulation Benchmark (T=50) ===")
b = @benchmark run_simulation($params) samples=5 evals=1
display(b)
println()

# Also benchmark the hot-path functions individually
state = initialize_model(params)

# Benchmark step_period!
step_period!(state)  # warm up
println("\n=== step_period! Benchmark ===")
b_step = @benchmark step_period!($state) samples=10 evals=1
display(b_step)
println()

# Benchmark record_history! (called per match)
firm = state.firms[1]
w_type = state.workers[1].type
println("\n=== record_history! Benchmark ===")
b_hist = @benchmark record_history!($firm, $w_type, 1.0) samples=100 evals=100
display(b_hist)
println()

# Benchmark record_broker_history!
broker = state.broker
x_type = state.firms[1].type
println("\n=== record_broker_history! Benchmark ===")
b_bhist = @benchmark record_broker_history!($broker, $w_type, $x_type, 1, 1.0) samples=100 evals=100
display(b_bhist)
println()

# Benchmark firm_features (allocating version)
println("\n=== firm_features Benchmark ===")
b_ff = @benchmark firm_features($w_type) samples=100 evals=100
display(b_ff)
println()

# Full simulation allocation report
println("\n=== Full Simulation Allocation Report (T=50) ===")
@time run_simulation(params)
@time run_simulation(params)
@time run_simulation(params)
