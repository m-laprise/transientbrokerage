"""
    explore_staffing.jl

Run Model 1 (staffing) for T periods across parameter configurations and seeds.
Produces 4×3 time-series figures comparing staffing dynamics against the base model.
Base model data is loaded from cached JLD2 files produced by explore_base_model.jl.

Usage: julia --project --threads=auto scripts/explore_staffing.jl
       julia --project --threads=auto scripts/explore_staffing.jl --rerun --geometry=all
"""

Threads.nthreads() == 1 && @warn "Running single-threaded; start Julia with --threads=auto"

using TransientBrokerage
using CairoMakie
using DataFrames
using Statistics: mean
using JLD2

const OUTDIR = joinpath(@__DIR__, "..", "data", "figures", "exploration")
const DATADIR = joinpath(@__DIR__, "..", "data", "sims", "exploration")
const BASEDIR = DATADIR  # base model data lives in same tree

# ---------------------------------------------------------------------------
# Helpers (shared with explore_base_model.jl)
# ---------------------------------------------------------------------------

"""Run `n_seeds` simulations at `params` (overriding T, seed, and enable_staffing=true)."""
function run_ensemble(; base_params_kwargs, T::Int, n_seeds::Int)
    mdfs = Vector{DataFrame}(undef, n_seeds)
    Threads.@threads for s in 1:n_seeds
        params = default_params(; T=T, seed=s, enable_staffing=true, base_params_kwargs...)
        _, mdf = run_simulation(params)
        mdf[!, :seed] = fill(s, nrow(mdf))
        mdfs[s] = mdf
    end
    return mdfs
end

"""Compute rolling mean over a window. Uses a growing window for early periods."""
function rolling_mean(v::AbstractVector, window::Int)
    n = length(v)
    out = fill(NaN, n)
    for i in 1:n
        start = max(1, i - window + 1)
        vals = filter(!isnan, @view v[start:i])
        if !isempty(vals)
            out[i] = mean(vals)
        end
    end
    return out
end

# Consistent colors
const COL_BROKER = :crimson
const COL_INTERNAL = :steelblue
const COL_STAFFED = :darkorange
const COL_WORKER = :forestgreen

# ---------------------------------------------------------------------------
# Main plotting function: 4×3 Model 1 exploration figure
# ---------------------------------------------------------------------------

"""Generate 4×3 Model 1 (staffing) exploration figure with base model overlay."""
function plot_staffing_ensemble(mdfs::Vector{DataFrame}, mdfs_base::Vector{DataFrame},
                                suptitle::String, filename::String; window::Int=20)
    n_seeds = length(mdfs)
    periods = mdfs[1].period
    T_burn = 30

    title_fs = 12; label_fs = 10; tick_fs = 9; row_label_fs = 12
    leg_kw = (; labelsize=9, patchsize=(10, 10), padding=(3, 3, 2, 2),
                rowgap=0, patchlabelgap=3, framewidth=0.5)

    # Model 1 lines: thin per-seed + thick mean
    function plot_metric!(ax, metric_fn; label="", color=COL_INTERNAL)
        seed_vals = [rolling_mean(metric_fn(mdf), window) for mdf in mdfs]
        for sv in seed_vals
            lines!(ax, periods, sv; color=(color, 0.45), linewidth=0.8)
        end
        ensemble = [mean(filter(!isnan, [sv[t] for sv in seed_vals])) for t in eachindex(periods)]
        lines!(ax, periods, ensemble; color=color, linewidth=2.5, label=label)
    end

    # Base model overlay: dashed gray ensemble mean only
    function plot_base!(ax, metric_fn; label="Base")
        seed_vals = [rolling_mean(metric_fn(mdf), window) for mdf in mdfs_base]
        ensemble = [mean(filter(!isnan, [sv[t] for sv in seed_vals])) for t in eachindex(periods)]
        lines!(ax, periods, ensemble; color=:gray50, linewidth=2.0, linestyle=:dash, label=label)
    end

    ax_kw = (; titlesize=title_fs, ylabelsize=label_fs,
               xticklabelsize=tick_fs, yticklabelsize=tick_fs)

    fig = Figure(; size=(1100, 900), figure_padding=(5, 5, 5, 5))
    Label(fig[0, 1:3], suptitle * " — Staffing (M1)"; fontsize=16, font=:bold,
          halign=:center, tellwidth=false)

    # ── Row 1: Capture dynamics ──
    Label(fig[1, 0], "Capture\nDynamics"; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)

    ax1 = Axis(fig[1, 1]; title="Flow capture rate", ylabel="F^t",
               limits=(nothing, (0, 1)), ax_kw...)
    plot_metric!(ax1, mdf -> mdf.flow_capture_rate; color=COL_BROKER)

    ax2 = Axis(fig[1, 2]; title="Outsourcing rate", ylabel="Rate",
               limits=(nothing, (0, 1)), ax_kw...)
    plot_metric!(ax2, mdf -> mdf.outsourcing_rate; label="M1", color=COL_BROKER)
    plot_base!(ax2, mdf -> mdf.outsourcing_rate)
    axislegend(ax2; position=:rt, leg_kw...)

    ax3 = Axis(fig[1, 3]; title="Matches by channel", ylabel="Count",
               limits=(nothing, (0, nothing)), ax_kw...)
    plot_metric!(ax3, mdf -> Float64.(mdf.n_direct); label="Direct", color=COL_INTERNAL)
    plot_metric!(ax3, mdf -> Float64.(mdf.n_placed); label="Placed", color=COL_BROKER)
    plot_metric!(ax3, mdf -> Float64.(mdf.n_staffed); label="Staffed", color=COL_STAFFED)
    axislegend(ax3; position=:rt, leg_kw...)

    # ── Row 2: Lock-in mechanism ──
    Label(fig[2, 0], "Lock-in\nMechanism"; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)

    ax4 = Axis(fig[2, 1]; title="Firm holdout R²", ylabel="R²",
               limits=(nothing, (0, 1)), ax_kw...)
    plot_metric!(ax4, mdf -> mdf.firm_r_squared_holdout; label="M1 firm", color=COL_INTERNAL)
    plot_base!(ax4, mdf -> mdf.firm_r_squared_holdout; label="Base firm")
    axislegend(ax4; position=:rb, leg_kw...)

    ax5 = Axis(fig[2, 2]; title="Avg firm referral pool", ylabel="Size",
               limits=(nothing, (0, nothing)), ax_kw...)
    plot_metric!(ax5, mdf -> mdf.avg_referral_pool_size; label="M1", color=COL_INTERNAL)
    plot_base!(ax5, mdf -> mdf.avg_referral_pool_size)
    axislegend(ax5; position=:rb, leg_kw...)

    ax6 = Axis(fig[2, 3]; title="Broker holdout R²", ylabel="R²",
               limits=(nothing, (0, 1)), ax_kw...)
    plot_metric!(ax6, mdf -> mdf.broker_r_squared_holdout; label="M1 broker", color=COL_BROKER)
    plot_base!(ax6, mdf -> mdf.broker_r_squared_holdout; label="Base broker")
    axislegend(ax6; position=:rb, leg_kw...)

    # ── Row 3: Structural dynamics ──
    Label(fig[3, 0], "Structural\nDynamics"; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)

    ax7 = Axis(fig[3, 1]; title="Cross-mode betweenness", ylabel="C_B(broker)",
               limits=(nothing, (0, 1)), ax_kw...)
    plot_metric!(ax7, mdf -> mdf.betweenness; label="M1", color=COL_BROKER)
    plot_base!(ax7, mdf -> mdf.betweenness)
    axislegend(ax7; position=:rt, leg_kw...)

    ax8 = Axis(fig[3, 2]; title="Broker history & referral reach", ylabel="Count",
               ax_kw...)
    plot_metric!(ax8, mdf -> Float64.(mdf.broker_history_size); label="Broker hist", color=COL_STAFFED)
    plot_metric!(ax8, mdf -> mdf.avg_referral_pool_size; label="Avg referral", color=COL_INTERNAL)
    axislegend(ax8; position=:rb, leg_kw...)

    ax9 = Axis(fig[3, 3]; title="Access share (brokered)", ylabel="Fraction",
               limits=(nothing, (0, 1)), ax_kw...)
    plot_metric!(ax9, mdf -> begin
        total = mdf.access_count .+ mdf.assessment_count
        [t > 0 ? mdf.access_count[i] / t : NaN for (i, t) in enumerate(total)]
    end; label="M1", color=COL_STAFFED)
    plot_base!(ax9, mdf -> begin
        total = mdf.access_count .+ mdf.assessment_count
        [t > 0 ? mdf.access_count[i] / t : NaN for (i, t) in enumerate(total)]
    end)
    axislegend(ax9; position=:rt, leg_kw...)

    # ── Row 4: Surplus redistribution ──
    Label(fig[4, 0], "Surplus\nRedistrib."; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)

    ax10 = Axis(fig[4, 1]; title="Surplus shares", xlabel="Period", ylabel="Fraction",
                limits=(nothing, (0, 1)), ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax10, mdf -> begin
        tot = mdf.total_realized_surplus
        [t > 0 ? mdf.worker_surplus[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Worker", color=COL_WORKER)
    plot_metric!(ax10, mdf -> begin
        tot = mdf.total_realized_surplus
        fs = mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed
        [t > 0 ? fs[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Firm", color=COL_INTERNAL)
    plot_metric!(ax10, mdf -> begin
        tot = mdf.total_realized_surplus
        bs = mdf.broker_surplus_placement .+ mdf.broker_surplus_staffing
        [t > 0 ? bs[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Broker", color=COL_BROKER)
    axislegend(ax10; position=:rt, leg_kw...)

    ax11 = Axis(fig[4, 2]; title="Firm surplus by channel", xlabel="Period", ylabel="Fraction",
                limits=(nothing, (0, 1)), ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax11, mdf -> begin
        tot = mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed
        [t != 0 ? mdf.firm_surplus_direct[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Direct", color=COL_INTERNAL)
    plot_metric!(ax11, mdf -> begin
        tot = mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed
        [t != 0 ? mdf.firm_surplus_placed[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Placed", color=COL_BROKER)
    plot_metric!(ax11, mdf -> begin
        tot = mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed
        [t != 0 ? mdf.firm_surplus_staffed[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Staffed", color=COL_STAFFED)
    axislegend(ax11; position=:rt, leg_kw...)

    ax12 = Axis(fig[4, 3]; title="Broker revenue by channel", xlabel="Period", ylabel="Fraction",
                limits=(nothing, (0, 1)), ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax12, mdf -> begin
        tot = mdf.broker_surplus_placement .+ mdf.broker_surplus_staffing
        [t != 0 ? mdf.broker_surplus_placement[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Placement", color=COL_BROKER)
    plot_metric!(ax12, mdf -> begin
        tot = mdf.broker_surplus_placement .+ mdf.broker_surplus_staffing
        [t != 0 ? mdf.broker_surplus_staffing[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Staffing", color=COL_STAFFED)
    axislegend(ax12; position=:rt, leg_kw...)

    # Burn-in indicator
    for ax in [ax1, ax2, ax3, ax4, ax5, ax6, ax7, ax8, ax9, ax10, ax11, ax12]
        vlines!(ax, [T_burn]; color=:gray30, linestyle=:dash, linewidth=1.5)
    end

    footer = "Thin lines: individual seeds ($n_seeds). Thick: M1 ensemble mean. " *
             "Dashed gray: base model. Dashed vertical: burn-in (t=$T_burn). " *
             "Smoothing: $window-period rolling mean."
    Label(fig[5, 1:3], footer; fontsize=12, color=:black, halign=:center, tellwidth=false)

    colsize!(fig.layout, 0, Fixed(30))
    for r in 1:4; rowsize!(fig.layout, r, Auto(1)); end
    rowsize!(fig.layout, 0, Fixed(22))
    rowsize!(fig.layout, 5, Fixed(18))
    rowgap!(fig.layout, 5)
    colgap!(fig.layout, 10)

    save(joinpath(OUTDIR, filename), fig)
    println("  Saved: $filename")
    return fig
end

# ---------------------------------------------------------------------------
# Run configurations (same grid as base model)
# ---------------------------------------------------------------------------

T = 800
N_SEEDS = 5
RERUN = "--rerun" in ARGS

GEOMETRY_ARG = let
    idx = findfirst(a -> startswith(a, "--geometry="), ARGS)
    idx !== nothing ? Symbol(split(ARGS[idx], "=")[2]) : :complex
end
GEOMETRIES = GEOMETRY_ARG == :all ? [:unstructured, :simple, :complex] : [GEOMETRY_ARG]

function make_configs(geom::Symbol)
    geo_label = Dict(:complex => "complex curve", :simple => "great circle",
                     :unstructured => "unstructured")[geom]
    return [
     (tag="baseline",
      label="Baseline [$geo_label]: (d=8, ρ=0.50, η=0.05)",
      kwargs=(d=8, rho=0.50, firm_geometry=geom)),
     (tag="d04_simple",
      label="4-dim types [$geo_label]: (d=4, ρ=0.50, η=0.05)",
      kwargs=(d=4, rho=0.50, firm_geometry=geom)),
     (tag="d12_complex",
      label="12-dim types [$geo_label]: (d=12, ρ=0.50, η=0.05)",
      kwargs=(d=12, rho=0.50, firm_geometry=geom)),
     (tag="rho10_weakquality",
      label="Weak quality [$geo_label]: (d=8, ρ=0.10, η=0.05)",
      kwargs=(d=8, rho=0.10, firm_geometry=geom)),
     (tag="rho90_strongquality",
      label="Strong quality [$geo_label]: (d=8, ρ=0.90, η=0.05)",
      kwargs=(d=8, rho=0.90, firm_geometry=geom)),
     (tag="eta01_stable",
      label="Stable market [$geo_label]: (d=8, ρ=0.50, η=0.01)",
      kwargs=(d=8, rho=0.50, eta=0.01, firm_geometry=geom)),
     (tag="eta10_volatile",
      label="Volatile market [$geo_label]: (d=8, ρ=0.50, η=0.10)",
      kwargs=(d=8, rho=0.50, eta=0.10, firm_geometry=geom)),
     (tag="rho00_pureinteraction",
      label="Pure interaction [$geo_label]: (d=8, ρ=0.00, η=0.05)",
      kwargs=(d=8, rho=0.0, firm_geometry=geom)),
     (tag="rho100_purequality",
      label="Pure quality [$geo_label]: (d=8, ρ=1.00, η=0.05)",
      kwargs=(d=8, rho=1.0, firm_geometry=geom)),
    ]
end

println("Running Model 1 (staffing) exploration (T=$T, $N_SEEDS seeds, geometries=$(GEOMETRIES))")
RERUN && println("  --rerun: forcing re-simulation")
println()

for geom in GEOMETRIES
    configs = make_configs(geom)
    geo_dir = string(geom)
    outdir = joinpath(OUTDIR, geo_dir)
    staffing_datadir = joinpath(DATADIR, geo_dir, "staffing")
    base_datadir = joinpath(DATADIR, geo_dir)
    mkpath(outdir); mkpath(staffing_datadir)
    println("━━━ Geometry: $geom ($outdir) ━━━")

    for (i, c) in enumerate(configs)
        println("[$i/$(length(configs))] $(c.label)")

        # Load base model data (must exist from explore_base_model.jl)
        base_datafile = joinpath(base_datadir, "$(c.tag).jld2")
        if !isfile(base_datafile)
            println("  ⚠ Base model data not found: $base_datafile — skipping")
            println("    Run explore_base_model.jl first")
            continue
        end
        mdfs_base = JLD2.load(base_datafile, "mdfs")

        # Run or load staffing data
        datafile = joinpath(staffing_datadir, "$(c.tag).jld2")
        if !RERUN && isfile(datafile)
            println("  Loading cached staffing data: $datafile")
            mdfs = JLD2.load(datafile, "mdfs")
        else
            mdfs = run_ensemble(; base_params_kwargs=c.kwargs, T=T, n_seeds=N_SEEDS)
            JLD2.save(datafile, "mdfs", mdfs, "label", c.label,
                      "kwargs", Dict(pairs(c.kwargs)), "T", T, "n_seeds", N_SEEDS)
            println("  Saved staffing data: $datafile")
        end

        plot_staffing_ensemble(mdfs, mdfs_base, c.label,
                               joinpath(geo_dir, "$(c.tag)_staffing.png"))
    end
    println()
end

println("Figures: $OUTDIR")
println("Data: $DATADIR")
println("Done.")
