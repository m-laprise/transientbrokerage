"""
    explore_base_model.jl

Run the base model (no capture) across parameter configurations that control
matching difficulty (rho, delta, s, eta) with multiple seeds per config.
Produces per-config dynamics panels and DGP visualization (matrix, SVD).

Data is cached as JLD2; pass --rerun to force re-simulation.

Usage: julia --project --threads=auto scripts/explore_base_model.jl
       julia --project --threads=auto scripts/explore_base_model.jl --rerun
"""

Threads.nthreads() == 1 && @warn "Running single-threaded; start Julia with --threads=auto"

using TransientBrokerage
using TransientBrokerage: generate_matching_env, generate_curve_geometry,
                          generate_agent_types, match_signal, Q_OFFSET, regime_gain
using CairoMakie
using DataFrames
using Statistics: mean
using LinearAlgebra: svdvals
using MultivariateStats: fit, predict, PCA
using StableRNGs: StableRNG
using JLD2

const OUTDIR = joinpath(@__DIR__, "..", "data", "figures", "exploration")
const DATADIR = joinpath(@__DIR__, "..", "data", "sims", "exploration")
mkpath(OUTDIR)
mkpath(DATADIR)

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

"""Run n_seeds simulations, return vector of DataFrames."""
function run_ensemble(; base_kwargs, T::Int, n_seeds::Int)
    mdfs = Vector{DataFrame}(undef, n_seeds)
    for s in 1:n_seeds
        p = default_params(; N=N_SIM, T=T, seed=s, base_kwargs...)
        _, mdf = run_simulation(p)
        mdf[!, :seed] .= s
        mdfs[s] = mdf
    end
    return mdfs
end

"""Rolling mean with window. NaN-safe: skips NaN values in window."""
function rolling_mean(v::AbstractVector, window::Int)
    n = length(v)
    out = fill(NaN, n)
    for i in 1:n
        isnan(v[i]) && continue
        lo = max(1, i - window + 1)
        vals = filter(!isnan, @view v[lo:i])
        !isempty(vals) && (out[i] = mean(vals))
    end
    return out
end

"""Access fraction: access / (access + assessment), or NaN."""
function access_fraction(mdf::DataFrame)
    total = mdf.access_count .+ mdf.assessment_count
    return [t > 0 ? mdf.access_count[i] / t : NaN for (i, t) in enumerate(total)]
end

const COL_BROKER = :crimson
const COL_AGENT = :steelblue

# ─────────────────────────────────────────────────────────────────────────────
# Dynamics figure (5x3 panel)
# ─────────────────────────────────────────────────────────────────────────────

function plot_ensemble(mdfs::Vector{DataFrame}, suptitle::String, filename::String;
                       window::Int=20)
    n_seeds = length(mdfs)
    periods = mdfs[1].period

    function plot_metric!(ax, metric_fn; label="", color=COL_AGENT)
        seed_vals = [rolling_mean(metric_fn(mdf), window) for mdf in mdfs]
        for sv in seed_vals
            lines!(ax, periods, sv; color=(color, 0.4), linewidth=0.8)
        end
        ensemble = [let vs = [sv[t] for sv in seed_vals]
            nv = count(!isnan, vs)
            nv > n_seeds / 2 ? mean(v for v in vs if !isnan(v)) : NaN
        end for t in eachindex(periods)]
        lines!(ax, periods, ensemble; color=color, linewidth=2.5, label=label)
    end

    leg_kw = (; labelsize=9, patchsize=(10, 10), padding=(3, 3, 2, 2),
                rowgap=0, patchlabelgap=3, framewidth=0.5)

    fig = Figure(; size=(1400, 1800), figure_padding=(10, 15, 5, 5))
    Label(fig[0, 1:3], suptitle; fontsize=14, font=:bold, halign=:center, tellwidth=false)

    # Row labels
    row_labels = ["Outsourcing &\nMatches", "Prediction\nQuality", "Match\nOutput",
                  "Network\nStructure", "Satisfaction"]
    for (r, lbl) in enumerate(row_labels)
        Label(fig[r, 0], lbl; fontsize=11, rotation=pi/2, tellheight=false, halign=:center)
    end

    # Row 1: Outsourcing rate, matches by channel, total matches
    ax = Axis(fig[1, 1]; title="Outsourcing Rate", ylabel="Rate")
    plot_metric!(ax, mdf -> mdf.outsourcing_rate; color=COL_AGENT)

    ax = Axis(fig[1, 2]; title="Matches by Channel")
    plot_metric!(ax, mdf -> Float64.(mdf.n_self_matches); label="Self", color=COL_AGENT)
    plot_metric!(ax, mdf -> Float64.(mdf.n_broker_standard); label="Broker", color=COL_BROKER)
    axislegend(ax; leg_kw..., position=:rt)

    ax = Axis(fig[1, 3]; title="Total Matches / Period")
    plot_metric!(ax, mdf -> Float64.(mdf.n_total_matches); color=COL_AGENT)

    # Row 2: Holdout R2, rank correlation, R2 gap
    ax = Axis(fig[2, 1]; title="Holdout R\u00b2", ylabel="R\u00b2")
    plot_metric!(ax, mdf -> mdf.broker_holdout_r2; label="Broker", color=COL_BROKER)
    plot_metric!(ax, mdf -> mdf.agent_holdout_r2; label="Agent", color=COL_AGENT)
    hlines!(ax, [0.0]; color=:gray, linestyle=:dash)
    axislegend(ax; leg_kw..., position=:rb)

    ax = Axis(fig[2, 2]; title="Holdout Rank Correlation")
    plot_metric!(ax, mdf -> mdf.broker_holdout_rank; label="Broker", color=COL_BROKER)
    plot_metric!(ax, mdf -> mdf.agent_holdout_rank; label="Agent", color=COL_AGENT)
    axislegend(ax; leg_kw..., position=:rb)

    ax = Axis(fig[2, 3]; title="R\u00b2 Gap (Broker - Agent)")
    plot_metric!(ax, mdf -> mdf.r2_gap; color=:purple)
    hlines!(ax, [0.0]; color=:gray, linestyle=:dash)

    # Row 3: Mean output by channel, broker reputation, access fraction
    ax = Axis(fig[3, 1]; title="Mean Output by Channel", ylabel="q")
    plot_metric!(ax, mdf -> mdf.q_self_mean; label="Self", color=COL_AGENT)
    plot_metric!(ax, mdf -> mdf.q_broker_standard_mean; label="Broker", color=COL_BROKER)
    axislegend(ax; leg_kw..., position=:rb)

    ax = Axis(fig[3, 2]; title="Broker Reputation")
    plot_metric!(ax, mdf -> mdf.broker_reputation; color=COL_BROKER)

    ax = Axis(fig[3, 3]; title="Access Fraction (Brokered)")
    plot_metric!(ax, mdf -> access_fraction(mdf); color=:darkorange)

    # Row 4: Betweenness, effective size, roster size
    ax = Axis(fig[4, 1]; title="Broker Betweenness", ylabel="C_B")
    plot_metric!(ax, mdf -> mdf.betweenness; color=COL_AGENT)

    ax = Axis(fig[4, 2]; title="Effective Size")
    plot_metric!(ax, mdf -> mdf.effective_size; color=COL_AGENT)

    ax = Axis(fig[4, 3]; title="Roster Size & History")
    plot_metric!(ax, mdf -> Float64.(mdf.roster_size); label="Roster", color=COL_AGENT)
    plot_metric!(ax, mdf -> Float64.(mdf.broker_history_size) ./ 100; label="History/100", color=COL_BROKER)
    axislegend(ax; leg_kw..., position=:rb)

    # Row 5: Satisfaction self, satisfaction broker, n_available
    ax = Axis(fig[5, 1]; title="Satisfaction (Self-Search)", ylabel="S", xlabel="Period")
    plot_metric!(ax, mdf -> mdf.mean_satisfaction_self; color=COL_AGENT)

    ax = Axis(fig[5, 2]; title="Satisfaction (Broker)", xlabel="Period")
    plot_metric!(ax, mdf -> mdf.mean_satisfaction_broker; color=COL_BROKER)

    ax = Axis(fig[5, 3]; title="Available Agents", xlabel="Period")
    plot_metric!(ax, mdf -> Float64.(mdf.n_available); color=COL_AGENT)

    # Layout
    rowsize!(fig.layout, 0, Fixed(22))
    colsize!(fig.layout, 0, Fixed(30))
    for r in 1:5; rowsize!(fig.layout, r, Auto(1)); end
    rowgap!(fig.layout, 5)
    colgap!(fig.layout, 10)

    save(joinpath(OUTDIR, filename), fig)
    println("  Saved dynamics: $filename")
end

# ─────────────────────────────────────────────────────────────────────────────
# DGP figures (matrix heatmap + histogram, SVD spectrum)
# ─────────────────────────────────────────────────────────────────────────────

function build_ordered_output_matrix(types, env)
    N = length(types)
    type_matrix = reduce(hcat, types)
    pca = fit(PCA, type_matrix; maxoutdim=1)
    pc1 = vec(predict(pca, type_matrix))
    order = sortperm(pc1)
    sorted = types[order]
    F = Matrix{Float64}(undef, N, N)
    @inbounds for j in 1:N
        xj = sorted[j]
        for i in 1:N
            F[i, j] = Q_OFFSET + match_signal(sorted[i], xj, env)
        end
    end
    return F, pc1[order]
end

function plot_dgp_matrix(F; tag, rho, delta, s, N)
    crange = let m = maximum(abs, F .- mean(F)); (mean(F) - m, mean(F) + m) end
    fig = Figure(; size=(800, 650))
    Label(fig[0, 1:2], "Output matrix (N=$N, rho=$rho, delta=$delta, s=$s)";
          fontsize=13, font=:bold, halign=:center, tellwidth=false)

    ax1 = Axis(fig[1, 1]; xlabel="Agent j (PC1)", ylabel="Agent i (PC1)", aspect=1)
    hm = heatmap!(ax1, 1:N, 1:N, F; colormap=:RdBu, colorrange=crange)
    Colorbar(fig[1, 2], hm; label="q")

    vals = [F[i, j] for j in 2:N for i in 1:(j-1)]
    ax2 = Axis(fig[2, 1]; xlabel="q", ylabel="Count")
    hist!(ax2, vals; bins=80, color=(:steelblue, 0.7), strokewidth=0.5, strokecolor=:gray40)
    vlines!(ax2, [mean(vals)]; color=:crimson, linestyle=:dash)

    rowsize!(fig.layout, 0, Fixed(22))
    rowsize!(fig.layout, 1, Relative(0.65))
    colsize!(fig.layout, 2, Fixed(30))
    save(joinpath(OUTDIR, "$(tag)_matrix.png"), fig)
    println("  Saved: $(tag)_matrix.png")
end

function plot_dgp_svd(F; tag, rho, delta, s, N)
    svals = svdvals(F)
    cumvar = cumsum(svals .^ 2) ./ sum(svals .^ 2)
    n_show = min(50, length(svals))

    fig = Figure(; size=(700, 280))
    Label(fig[0, 1:2], "SVD of output matrix (rho=$rho, delta=$delta, s=$s)";
          fontsize=13, font=:bold, halign=:center, tellwidth=false)

    ax1 = Axis(fig[1, 1]; title="Singular values (normalized)", xlabel="Component", ylabel="sigma/sigma_1")
    sn = svals ./ svals[1]
    scatterlines!(ax1, 1:n_show, sn[1:n_show]; markersize=4, color=:steelblue)

    ax2 = Axis(fig[1, 2]; title="Cumulative variance explained", xlabel="Components", ylabel="Fraction",
               limits=(nothing, (0, 1.05)))
    scatterlines!(ax2, 0:n_show, vcat(0.0, cumvar[1:n_show]); markersize=4, color=:steelblue)
    hlines!(ax2, [0.90, 0.95]; color=:gray60, linestyle=:dash, linewidth=0.8)

    rowsize!(fig.layout, 0, Fixed(22))
    save(joinpath(OUTDIR, "$(tag)_svd.png"), fig)
    println("  Saved: $(tag)_svd.png")
end

# ─────────────────────────────────────────────────────────────────────────────
# Configurations
# ─────────────────────────────────────────────────────────────────────────────

configs = [
    # Baseline
    (tag="baseline",
     label="Baseline (rho=0.50, delta=0.50, s=8, eta=0.02)",
     kwargs=(;)),
    # rho sweep
    (tag="rho00_pureinteraction",
     label="Pure interaction (rho=0.0)",
     kwargs=(rho=0.0,)),
    (tag="rho10_weakquality",
     label="Weak quality (rho=0.10)",
     kwargs=(rho=0.10,)),
    (tag="rho30_mildinteraction",
     label="Mild interaction (rho=0.30)",
     kwargs=(rho=0.30,)),
    (tag="rho70_mildquality",
     label="Mild quality (rho=0.70)",
     kwargs=(rho=0.70,)),
    (tag="rho90_strongquality",
     label="Strong quality (rho=0.90)",
     kwargs=(rho=0.90,)),
    (tag="rho100_purequality",
     label="Pure quality (rho=1.0)",
     kwargs=(rho=1.0,)),
    # delta sweep
    (tag="delta00_noregime",
     label="No regime effect (delta=0.0)",
     kwargs=(delta=0.0,)),
    (tag="delta25_weakregime",
     label="Weak regime (delta=0.25)",
     kwargs=(delta=0.25,)),
    (tag="delta75_strongregime",
     label="Strong regime (delta=0.75)",
     kwargs=(delta=0.75,)),
    # s sweep
    (tag="s2_lowdim",
     label="Low-dim curve (s=2)",
     kwargs=(s=2,)),
    (tag="s4_middim",
     label="Mid-dim curve (s=4)",
     kwargs=(s=4,)),
    # eta sweep
    (tag="eta01_stable",
     label="Stable market (eta=0.01)",
     kwargs=(eta=0.01,)),
    (tag="eta05_volatile",
     label="Volatile market (eta=0.05)",
     kwargs=(eta=0.05,)),
]

# ─────────────────────────────────────────────────────────────────────────────
# Run
# ─────────────────────────────────────────────────────────────────────────────

T = 200
N_SIM = 1000
N_SEEDS = 5
RERUN = "--rerun" in ARGS

println("Base model exploration: $(length(configs)) configs, $N_SEEDS seeds, N=$N_SIM, T=$T")
RERUN && println("  --rerun: forcing re-simulation")
println()

for (idx, c) in enumerate(configs)
    println("[$idx/$(length(configs))] $(c.label)")
    datafile = joinpath(DATADIR, "$(c.tag).jld2")

    if !RERUN && isfile(datafile)
        println("  Loading cached data: $datafile")
        saved = JLD2.load(datafile)
        mdfs = saved["mdfs"]
    else
        mdfs = run_ensemble(; base_kwargs=c.kwargs, T=T, n_seeds=N_SEEDS)
        jldsave(datafile; mdfs=mdfs)
        println("  Saved data: $datafile")
    end

    # Dynamics panel
    plot_ensemble(mdfs, c.label, "$(c.tag)_dynamics.png")

    # DGP figures (matrix + SVD) for configs that vary rho, delta, or s
    p = default_params(; N=N_SIM, seed=42, c.kwargs...)
    rng = StableRNG(p.seed)
    geo = generate_curve_geometry(p.d, p.s, rng)
    types, _ = generate_agent_types(p.N, geo, p.sigma_x, rng)
    env = generate_matching_env(p.d, p.rho, p.delta, p.sigma_eps, types, rng; sigma_x=p.sigma_x)
    F, _ = build_ordered_output_matrix(types, env)
    plot_dgp_matrix(F; tag=c.tag, rho=p.rho, delta=p.delta, s=p.s, N=p.N)
    plot_dgp_svd(F; tag=c.tag, rho=p.rho, delta=p.delta, s=p.s, N=p.N)

    # Summary stats
    tail_dfs = [mdf[max(1, end-49):end, :] for mdf in mdfs]
    combined = vcat(tail_dfs...)
    println("  Summary (last 50 periods, pooled):")
    println("    Outsourcing: $(round(mean(combined.outsourcing_rate), digits=3))")
    println("    Broker R2: $(round(mean(filter(!isnan, combined.broker_holdout_r2)), digits=3))")
    println("    Agent R2: $(round(mean(filter(!isnan, combined.agent_holdout_r2)), digits=3))")
    println("    R2 gap: $(round(mean(filter(!isnan, combined.r2_gap)), digits=3))")
    println("    Betweenness: $(round(mean(combined.betweenness), digits=4))")
    println()
end

println("Figures: $OUTDIR")
println("Data: $DATADIR")
println("Done.")
