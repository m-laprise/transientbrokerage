"""
    explore_capture.jl

Run Model 1 (principal mode / resource capture) across parameter configurations,
with the base model as a dashed-gray reference. Produces dense dynamics panels.

Data cached as JLD2; pass --rerun to force re-simulation.

Usage: julia --project --threads=auto scripts/explore_capture.jl
       julia --project --threads=auto scripts/explore_capture.jl --rerun
"""

Threads.nthreads() == 1 && @warn "Running single-threaded; start Julia with --threads=auto"

using TransientBrokerage
using CairoMakie
using DataFrames
using Statistics: mean
using JLD2

const OUTDIR = joinpath(@__DIR__, "..", "data", "figures", "capture")
const DATADIR = joinpath(@__DIR__, "..", "data", "sims", "capture")
const BASE_DATADIR = joinpath(@__DIR__, "..", "data", "sims", "exploration")
mkpath(OUTDIR)
mkpath(DATADIR)

# ─────────────────────────────────────────────────────────────────────────────
# Helpers (same as explore_base_model.jl)
# ─────────────────────────────────────────────────────────────────────────────

function run_ensemble(; base_kwargs, T::Int, n_seeds::Int)
    mdfs = Vector{DataFrame}(undef, n_seeds)
    for s in 1:n_seeds
        p = default_params(; N=N_SIM, T=T, seed=s, enable_principal=true, base_kwargs...)
        _, mdf = run_simulation(p)
        mdf[!, :seed] .= s
        mdfs[s] = mdf
    end
    return mdfs
end

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

function access_fraction(mdf::DataFrame)
    total = mdf.access_count .+ mdf.assessment_count
    return [t > 0 ? mdf.access_count[i] / t : NaN for (i, t) in enumerate(total)]
end

const COL_M1 = :crimson
const COL_BASE = :gray60

# ─────────────────────────────────────────────────────────────────────────────
# Dynamics figure: M1 (solid) + base (dashed gray reference)
# ─────────────────────────────────────────────────────────────────────────────

function plot_capture_ensemble(m1_mdfs::Vector{DataFrame},
                               base_mdfs::Union{Vector{DataFrame}, Nothing},
                               suptitle::String, filename::String;
                               window::Int=20)
    n_seeds = length(m1_mdfs)
    periods = m1_mdfs[1].period

    function ensemble_mean(mdfs, metric_fn)
        seed_vals = [rolling_mean(metric_fn(mdf), window) for mdf in mdfs]
        return [let vs = [sv[t] for sv in seed_vals]
            nv = count(!isnan, vs)
            nv > n_seeds / 2 ? mean(v for v in vs if !isnan(v)) : NaN
        end for t in eachindex(periods)]
    end

    function plot_m1_vs_base!(ax, metric_fn; m1_label="", m1_color=COL_M1)
        # M1 ensemble mean
        m1 = ensemble_mean(m1_mdfs, metric_fn)
        lines!(ax, periods, m1; color=m1_color, linewidth=2.5, label=m1_label)
        # Base reference
        if base_mdfs !== nothing
            base = ensemble_mean(base_mdfs, metric_fn)
            lines!(ax, periods, base; color=COL_BASE, linewidth=1.5, linestyle=:dash, label="Base")
        end
    end

    leg_kw = (; labelsize=9, patchsize=(10, 10), padding=(3, 3, 2, 2),
                rowgap=0, patchlabelgap=3, framewidth=0.5)

    fig = Figure(; size=(1400, 1800), figure_padding=(10, 15, 5, 5))
    Label(fig[0, 1:3], suptitle; fontsize=14, font=:bold, halign=:center, tellwidth=false)

    # Row 1: Principal-mode share, outsourcing rate, matches by channel
    ax = Axis(fig[1, 1]; title="Principal-Mode Share", ylabel="P^t")
    plot_m1_vs_base!(ax, mdf -> mdf.principal_mode_share; m1_label="M1")
    hlines!(ax, [0.0, 1.0]; color=:gray, linestyle=:dot)

    ax = Axis(fig[1, 2]; title="Outsourcing Rate")
    plot_m1_vs_base!(ax, mdf -> mdf.outsourcing_rate; m1_label="M1")
    axislegend(ax; leg_kw..., position=:rb)

    ax = Axis(fig[1, 3]; title="Total Matches / Period")
    plot_m1_vs_base!(ax, mdf -> Float64.(mdf.n_total_matches); m1_label="M1")
    axislegend(ax; leg_kw..., position=:rb)

    # Row 2: Holdout R2 (broker + agent), rank correlation, R2 gap
    ax = Axis(fig[2, 1]; title="Holdout R\u00b2", ylabel="R\u00b2")
    m1_broker = ensemble_mean(m1_mdfs, mdf -> mdf.broker_holdout_r2)
    m1_agent = ensemble_mean(m1_mdfs, mdf -> mdf.agent_holdout_r2)
    lines!(ax, periods, m1_broker; color=COL_M1, linewidth=2.5, label="Broker (M1)")
    lines!(ax, periods, m1_agent; color=:steelblue, linewidth=2.5, label="Agent (M1)")
    if base_mdfs !== nothing
        b_broker = ensemble_mean(base_mdfs, mdf -> mdf.broker_holdout_r2)
        b_agent = ensemble_mean(base_mdfs, mdf -> mdf.agent_holdout_r2)
        lines!(ax, periods, b_broker; color=COL_BASE, linewidth=1.5, linestyle=:dash, label="Broker (base)")
        lines!(ax, periods, b_agent; color=(:steelblue, 0.4), linewidth=1.5, linestyle=:dash, label="Agent (base)")
    end
    hlines!(ax, [0.0]; color=:gray, linestyle=:dot)
    axislegend(ax; leg_kw..., position=:rb)

    ax = Axis(fig[2, 2]; title="Holdout Rank Correlation")
    m1_br = ensemble_mean(m1_mdfs, mdf -> mdf.broker_holdout_rank)
    m1_ar = ensemble_mean(m1_mdfs, mdf -> mdf.agent_holdout_rank)
    lines!(ax, periods, m1_br; color=COL_M1, linewidth=2.5, label="Broker (M1)")
    lines!(ax, periods, m1_ar; color=:steelblue, linewidth=2.5, label="Agent (M1)")
    axislegend(ax; leg_kw..., position=:rb)

    ax = Axis(fig[2, 3]; title="R\u00b2 Gap (Broker - Agent)")
    plot_m1_vs_base!(ax, mdf -> mdf.r2_gap; m1_label="M1")
    hlines!(ax, [0.0]; color=:gray, linestyle=:dot)
    axislegend(ax; leg_kw..., position=:rb)

    # Row 3: Match quality by channel, broker reputation, access fraction
    ax = Axis(fig[3, 1]; title="Mean Output by Channel", ylabel="q")
    m1_self = ensemble_mean(m1_mdfs, mdf -> mdf.q_self_mean)
    m1_std = ensemble_mean(m1_mdfs, mdf -> mdf.q_broker_standard_mean)
    m1_pri = ensemble_mean(m1_mdfs, mdf -> mdf.q_broker_principal_mean)
    lines!(ax, periods, m1_self; color=:steelblue, linewidth=2.5, label="Self")
    lines!(ax, periods, m1_std; color=COL_M1, linewidth=2.5, label="Broker (std)")
    lines!(ax, periods, m1_pri; color=:darkorange, linewidth=2.5, label="Principal")
    axislegend(ax; leg_kw..., position=:rb)

    ax = Axis(fig[3, 2]; title="Broker Reputation")
    plot_m1_vs_base!(ax, mdf -> mdf.broker_reputation; m1_label="M1")
    axislegend(ax; leg_kw..., position=:rb)

    ax = Axis(fig[3, 3]; title="Access Fraction (Brokered)")
    plot_m1_vs_base!(ax, mdf -> access_fraction(mdf); m1_label="M1")
    axislegend(ax; leg_kw..., position=:rb)

    # Row 4: Betweenness, effective size, roster
    ax = Axis(fig[4, 1]; title="Broker Betweenness", ylabel="C_B")
    plot_m1_vs_base!(ax, mdf -> mdf.betweenness; m1_label="M1")
    axislegend(ax; leg_kw..., position=:rt)

    ax = Axis(fig[4, 2]; title="Effective Size")
    plot_m1_vs_base!(ax, mdf -> mdf.effective_size; m1_label="M1")
    axislegend(ax; leg_kw..., position=:rt)

    ax = Axis(fig[4, 3]; title="Broker Cumulative Revenue")
    plot_m1_vs_base!(ax, mdf -> mdf.broker_cumulative_revenue; m1_label="M1")
    axislegend(ax; leg_kw..., position=:lt)

    # Row 5: Satisfaction, principal revenue, available agents
    ax = Axis(fig[5, 1]; title="Satisfaction (Self)", ylabel="S", xlabel="Period")
    plot_m1_vs_base!(ax, mdf -> mdf.mean_satisfaction_self; m1_label="M1")
    axislegend(ax; leg_kw..., position=:rb)

    ax = Axis(fig[5, 2]; title="Satisfaction (Broker)", xlabel="Period")
    plot_m1_vs_base!(ax, mdf -> mdf.mean_satisfaction_broker; m1_label="M1")
    axislegend(ax; leg_kw..., position=:rb)

    ax = Axis(fig[5, 3]; title="Principal Revenue / Period", xlabel="Period")
    m1_prev = ensemble_mean(m1_mdfs, mdf -> mdf.broker_principal_revenue)
    lines!(ax, periods, m1_prev; color=COL_M1, linewidth=2.5)

    # Layout
    rowsize!(fig.layout, 0, Fixed(22))
    for r in 1:5; rowsize!(fig.layout, r, Auto(1)); end
    rowgap!(fig.layout, 5)
    colgap!(fig.layout, 10)

    save(joinpath(OUTDIR, filename), fig)
    println("  Saved: $filename")
end

# ─────────────────────────────────────────────────────────────────────────────
# Configs (same sweep dims as explore_base_model.jl)
# ─────────────────────────────────────────────────────────────────────────────

configs = [
    (tag="baseline",               label="Baseline (M1)", kwargs=(;)),
    (tag="rho00_pureinteraction",  label="Pure interaction (M1, rho=0.0)", kwargs=(rho=0.0,)),
    (tag="rho30_mildinteraction",  label="Mild interaction (M1, rho=0.30)", kwargs=(rho=0.30,)),
    (tag="rho70_mildquality",      label="Mild quality (M1, rho=0.70)", kwargs=(rho=0.70,)),
    (tag="rho100_purequality",     label="Pure quality (M1, rho=1.0)", kwargs=(rho=1.0,)),
    (tag="delta00_noregime",       label="No regime (M1, delta=0.0)", kwargs=(delta=0.0,)),
    (tag="delta75_strongregime",   label="Strong regime (M1, delta=0.75)", kwargs=(delta=0.75,)),
    (tag="s2_lowdim",              label="Low-dim curve (M1, s=2)", kwargs=(s=2,)),
    (tag="eta01_stable",           label="Stable market (M1, eta=0.01)", kwargs=(eta=0.01,)),
    (tag="eta05_volatile",         label="Volatile market (M1, eta=0.05)", kwargs=(eta=0.05,)),
]

# ─────────────────────────────────────────────────────────────────────────────
# Run
# ─────────────────────────────────────────────────────────────────────────────

T = 200
N_SIM = 1000
N_SEEDS = 5
RERUN = "--rerun" in ARGS

println("Capture exploration: $(length(configs)) configs, $N_SEEDS seeds, N=$N_SIM, T=$T")
RERUN && println("  --rerun: forcing re-simulation")
println()

for (idx, c) in enumerate(configs)
    println("[$idx/$(length(configs))] $(c.label)")
    datafile = joinpath(DATADIR, "$(c.tag).jld2")

    if !RERUN && isfile(datafile)
        println("  Loading cached M1 data")
        saved = JLD2.load(datafile)
        m1_mdfs = saved["mdfs"]
    else
        m1_mdfs = run_ensemble(; base_kwargs=c.kwargs, T=T, n_seeds=N_SEEDS)
        jldsave(datafile; mdfs=m1_mdfs)
        println("  Saved M1 data")
    end

    # Load base model reference if available
    base_file = joinpath(BASE_DATADIR, "$(c.tag).jld2")
    base_mdfs = if isfile(base_file)
        println("  Loading base reference from $base_file")
        JLD2.load(base_file)["mdfs"]
    else
        println("  No base reference found (run explore_base_model.jl first for full comparison)")
        nothing
    end

    plot_capture_ensemble(m1_mdfs, base_mdfs, c.label, "$(c.tag)_capture.png")

    # Summary
    tails = [mdf[max(1, end-49):end, :] for mdf in m1_mdfs]
    combined = vcat(tails...)
    println("  Summary (last 50 periods):")
    println("    Principal share: $(round(mean(combined.principal_mode_share), digits=3))")
    println("    Outsourcing: $(round(mean(combined.outsourcing_rate), digits=3))")
    println("    R2 gap: $(round(mean(filter(!isnan, combined.r2_gap)), digits=3))")
    println("    Cumulative revenue: $(round(combined.broker_cumulative_revenue[end], digits=1))")
    println()
end

println("Figures: $OUTDIR")
println("Data: $DATADIR")
println("Done.")
