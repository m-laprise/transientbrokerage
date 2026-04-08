"""
    explore_staffing.jl

Run Model 1 (staffing) for T=300 periods across parameter configurations
(d, rho, eta sweeps) and 5 seeds per config, for each firm geometry.
Produces per config: a 5×3 dynamics figure and a 2×3 surplus figure,
overlaying staffing dynamics against base model reference (dashed grey).
Requires base model data from explore_base_model.jl (loaded from cache).
Data cached as JLD2; figures saved as PNG.

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

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

"""Run `n_seeds` simulations with enable_staffing=true."""
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

"""Rolling mean with window. NaN if current value is NaN; otherwise average
non-NaN values in [i-window+1, i]. Growing window for early periods."""
function rolling_mean(v::AbstractVector, window::Int)
    n = length(v)
    out = fill(NaN, n)
    for i in 1:n
        isnan(v[i]) && continue
        start = max(1, i - window + 1)
        vals = filter(!isnan, @view v[start:i])
        !isempty(vals) && (out[i] = mean(vals))
    end
    return out
end

# Consistent colors
const COL_BROKER = :crimson
const COL_INTERNAL = :steelblue
const COL_STAFFED = :darkorange
const COL_WORKER = :mediumseagreen

"""Shade contiguous regions where the majority of seeds have no brokered matches."""
function shade_no_broker!(ax, mdfs::Vector{DataFrame})
    n_seeds = length(mdfs)
    periods = mdfs[1].period
    inactive = [count(mdf -> mdf.n_placed[t] + mdf.n_staffing_new[t] == 0, mdfs) > n_seeds / 2
                for t in eachindex(periods)]
    i = 1
    while i <= length(periods)
        if inactive[i]
            j = i
            while j < length(periods) && inactive[j + 1]; j += 1; end
            vspan!(ax, [periods[i] - 0.5], [periods[j] + 0.5]; color=(:gray80, 0.4))
            i = j + 1
        else
            i += 1
        end
    end
end

# ---------------------------------------------------------------------------
# 5x3 dynamics figure (mirrors base model layout)
# ---------------------------------------------------------------------------

function plot_staffing_ensemble(mdfs::Vector{DataFrame}, mdfs_base::Vector{DataFrame},
                                suptitle::String, filename::String; N_W::Int, window::Int=20)
    n_seeds = length(mdfs)
    periods = mdfs[1].period
    T_burn = 30

    title_fs = 12; label_fs = 10; tick_fs = 9; row_label_fs = 12
    leg_kw = (; labelsize=9, patchsize=(10, 10), padding=(3, 3, 2, 2),
                rowgap=0, patchlabelgap=3, framewidth=0.5)

    function plot_metric!(ax, metric_fn; label="", color=COL_INTERNAL)
        seed_vals = [rolling_mean(metric_fn(mdf), window) for mdf in mdfs]
        for sv in seed_vals
            lines!(ax, periods, sv; color=(color, 0.45), linewidth=0.8)
        end
        ensemble = [let vs = [sv[t] for sv in seed_vals]
            n_valid = count(!isnan, vs)
            n_valid > n_seeds / 2 ? mean(v for v in vs if !isnan(v)) : NaN
        end for t in eachindex(periods)]
        lines!(ax, periods, ensemble; color=color, linewidth=2.5, label=label)
    end

    function plot_base!(ax, metric_fn; label="Base")
        seed_vals = [rolling_mean(metric_fn(mdf), window) for mdf in mdfs_base]
        n_base = length(mdfs_base)
        ensemble = [let vs = [sv[t] for sv in seed_vals]
            n_valid = count(!isnan, vs)
            n_valid > n_base / 2 ? mean(v for v in vs if !isnan(v)) : NaN
        end for t in eachindex(periods)]
        lines!(ax, periods, ensemble; color=:gray50, linewidth=2.0, linestyle=:dash, label=label)
    end

    xlims = (first(periods), last(periods))
    ax_kw = (; titlesize=title_fs, ylabelsize=label_fs,
               xticklabelsize=tick_fs, yticklabelsize=tick_fs,
               xticks=0:100:last(periods))

    fig = Figure(; size=(1150, 1100), figure_padding=(5, 15, 5, 5))
    Label(fig[0, 1:3], suptitle * " — Staffing (M1)"; fontsize=16, font=:bold,
          halign=:center, tellwidth=false)

    # ── Row 1: Market Activity ──
    Label(fig[1, 0], "Market\nActivity"; fontsize=row_label_fs, font=:bold, rotation=pi/2,
          tellheight=false)

    ax1 = Axis(fig[1, 1]; title="Outsourcing rate", ylabel="Rate",
               limits=(xlims, (-0.02, 1.02)), ax_kw...)
    plot_metric!(ax1, mdf -> mdf.outsourcing_rate; label="M1", color=COL_BROKER)
    plot_base!(ax1, mdf -> mdf.outsourcing_rate)
    axislegend(ax1; position=:rt, leg_kw...)

    ax2 = Axis(fig[1, 2]; title="Matches per period", ylabel="Count",
               limits=(xlims, (-0.02, nothing)), ax_kw...)
    plot_metric!(ax2, mdf -> Float64.(mdf.n_direct); label="Direct", color=COL_INTERNAL)
    plot_metric!(ax2, mdf -> Float64.(mdf.n_placed); label="Placed", color=COL_BROKER)
    plot_metric!(ax2, mdf -> Float64.(mdf.n_staffed); label="Staffed", color=COL_STAFFED)
    axislegend(ax2; position=:rt, leg_kw...)

    ax3 = Axis(fig[1, 3]; title="Flow capture rate", ylabel="F^t",
               limits=(xlims, (-0.02, 1.02)), ax_kw...)
    shade_no_broker!(ax3, mdfs)
    plot_metric!(ax3, mdf -> mdf.flow_capture_rate; color=COL_STAFFED)

    # ── Row 2: Prediction Quality ──
    Label(fig[2, 0], "Prediction\nQuality"; fontsize=row_label_fs, font=:bold, rotation=pi/2,
          tellheight=false)

    ax4 = Axis(fig[2, 1]; title="Model quality: holdout R\u00b2", ylabel="R\u00b2",
               limits=(xlims, (-0.02, 1.02)), ax_kw...)
    plot_metric!(ax4, mdf -> mdf.firm_r_squared_holdout; label="M1 firm", color=COL_INTERNAL)
    plot_metric!(ax4, mdf -> mdf.broker_r_squared_holdout; label="M1 broker", color=COL_BROKER)
    plot_base!(ax4, mdf -> mdf.firm_r_squared_holdout; label="Base firm")
    plot_base!(ax4, mdf -> mdf.broker_r_squared_holdout; label="Base broker")
    axislegend(ax4; position=:rb, leg_kw...)

    ax5 = Axis(fig[2, 2]; title="Rank correlation (selected)", ylabel="Spearman rho",
               limits=(xlims, (-0.52, 1.02)), ax_kw...)
    plot_metric!(ax5, mdf -> mdf.firm_rank_corr_selected; label="Firm", color=COL_INTERNAL)
    plot_metric!(ax5, mdf -> mdf.broker_rank_corr_selected; label="Broker", color=COL_BROKER)
    plot_base!(ax5, mdf -> mdf.firm_rank_corr_selected; label="Base firm")
    plot_base!(ax5, mdf -> mdf.broker_rank_corr_selected; label="Base broker")
    axislegend(ax5; position=:rb, leg_kw...)

    ax6 = Axis(fig[2, 3]; title="Prediction bias (selected)", ylabel="Bias",
               limits=(xlims, (-0.32, 0.32)), ax_kw...)
    plot_metric!(ax6, mdf -> mdf.firm_bias_selected; label="Firm", color=COL_INTERNAL)
    plot_metric!(ax6, mdf -> mdf.broker_bias_selected; label="Broker", color=COL_BROKER)
    hlines!(ax6, [0.0]; color=:gray50, linewidth=0.8)
    axislegend(ax6; position=:rt, leg_kw...)

    # ── Row 3: Broker Advantage ──
    Label(fig[3, 0], "Broker\nAdvantage"; fontsize=row_label_fs, font=:bold, rotation=pi/2,
          tellheight=false)
    COL_GAP = :purple

    ax7 = Axis(fig[3, 1]; title="Holdout R\u00b2 gap", ylabel="Delta R\u00b2",
               limits=(xlims, (-1.02, 1.02)), ax_kw...)
    shade_no_broker!(ax7, mdfs)
    plot_metric!(ax7, mdf -> mdf.gap_r_squared_holdout; label="M1", color=COL_GAP)
    plot_base!(ax7, mdf -> mdf.gap_r_squared_holdout)
    hlines!(ax7, [0.0]; color=:gray50, linewidth=0.8)
    axislegend(ax7; position=:rt, leg_kw...)

    ax8 = Axis(fig[3, 2]; title="Rank corr. gap (selected)", ylabel="Delta rho",
               limits=(xlims, (-1.02, 1.02)), ax_kw...)
    shade_no_broker!(ax8, mdfs)
    plot_metric!(ax8, mdf -> mdf.gap_rank_corr_selected; label="M1", color=COL_GAP)
    plot_base!(ax8, mdf -> mdf.gap_rank_corr_selected)
    hlines!(ax8, [0.0]; color=:gray50, linewidth=0.8)
    axislegend(ax8; position=:rt, leg_kw...)

    ax9 = Axis(fig[3, 3]; title="R\u00b2 gap (selected)", ylabel="Delta R\u00b2",
               limits=(xlims, (-1.02, 1.02)), ax_kw...)
    shade_no_broker!(ax9, mdfs)
    plot_metric!(ax9, mdf -> mdf.gap_r_squared_selected; label="M1", color=COL_GAP)
    plot_base!(ax9, mdf -> mdf.gap_r_squared_selected)
    hlines!(ax9, [0.0]; color=:gray50, linewidth=0.8)
    axislegend(ax9; position=:rt, leg_kw...)

    # ── Row 4: Structural Dynamics ──
    Label(fig[4, 0], "Structural\nDynamics"; fontsize=row_label_fs, font=:bold, rotation=pi/2,
          tellheight=false)

    ax10 = Axis(fig[4, 1]; title="Mean match output", ylabel="Output",
                limits=(xlims, (-0.02, 2)), ax_kw...)
    plot_metric!(ax10, mdf -> mdf.q_direct_mean; label="Direct", color=COL_INTERNAL)
    plot_metric!(ax10, mdf -> mdf.q_placed_mean; label="Placed", color=COL_BROKER)
    plot_metric!(ax10, mdf -> mdf.q_staffed_mean; label="Staffed", color=COL_STAFFED)
    axislegend(ax10; position=:rb, leg_kw...)

    ax11 = Axis(fig[4, 2]; title="Cross-mode betweenness", ylabel="C_B(broker)",
                limits=(xlims, (-0.02, 0.62)), ax_kw...)
    plot_metric!(ax11, mdf -> mdf.betweenness; label="M1", color=COL_BROKER)
    plot_base!(ax11, mdf -> mdf.betweenness)
    axislegend(ax11; position=:rt, leg_kw...)

    ax12 = Axis(fig[4, 3]; title="Access share (brokered)", ylabel="Fraction",
                limits=(xlims, (-0.02, 1.02)), ax_kw...)
    shade_no_broker!(ax12, mdfs)
    plot_metric!(ax12, mdf -> begin
        total = mdf.access_count .+ mdf.assessment_count
        [t > 0 ? mdf.access_count[i] / t : NaN for (i, t) in enumerate(total)]
    end; label="M1", color=:goldenrod)
    plot_base!(ax12, mdf -> begin
        total = mdf.access_count .+ mdf.assessment_count
        [t > 0 ? mdf.access_count[i] / t : NaN for (i, t) in enumerate(total)]
    end)
    axislegend(ax12; position=:rt, leg_kw...)

    # ── Row 5: Diagnostics ──
    Label(fig[5, 0], "Diagnostics"; fontsize=row_label_fs, font=:bold, rotation=pi/2,
          tellheight=false)

    ax13 = Axis(fig[5, 1]; title="Broker history & firm referral reach", xlabel="Period",
                ylabel="Count", ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax13, mdf -> Float64.(mdf.broker_history_size); label="Broker history", color=:sienna)
    plot_metric!(ax13, mdf -> mdf.avg_referral_pool_size; label="Avg referral pool", color=COL_INTERNAL)
    axislegend(ax13; position=:rb, leg_kw...)

    ax14 = Axis(fig[5, 2]; title="Mean satisfaction by channel", xlabel="Period", ylabel="Satisfaction",
                limits=(xlims, nothing), ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax14, mdf -> mdf.mean_satisfaction_internal; label="Internal", color=COL_INTERNAL)
    plot_metric!(ax14, mdf -> mdf.mean_satisfaction_broker; label="Broker", color=COL_BROKER)
    plot_metric!(ax14, mdf -> mdf.broker_reputation; label="Reputation", color=:gray50)
    axislegend(ax14; position=:rb, leg_kw...)

    ax15 = Axis(fig[5, 3]; title="Unemployment rate, broker pool & firm size",
                xlabel="Period", ylabel="Count / %",
                limits=(xlims, (-0.02, nothing)), ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax15, mdf -> Float64.(mdf.n_available) ./ N_W .* 100; label="Unemp. rate (%)", color=:teal)
    plot_metric!(ax15, mdf -> Float64.(mdf.broker_pool_size); label="Broker pool", color=COL_BROKER)
    plot_metric!(ax15, mdf -> mdf.avg_firm_size; label="Firm size", color=:gray50)
    axislegend(ax15; position=:rt, leg_kw...)

    for ax in [ax1, ax2, ax3, ax4, ax5, ax6, ax7, ax8, ax9, ax10, ax11, ax12, ax13, ax14, ax15]
        vlines!(ax, [T_burn]; color=:gray30, linestyle=:dash, linewidth=1.5)
    end

    footer = "Thin lines: individual seeds ($n_seeds). Thick: ensemble mean (shown when majority of seeds have data). Dashed gray: base model.\n" *
             "Gray shading: majority of seeds have no brokered matches. Dashed vertical: burn-in (t=$T_burn). Smoothing: $window-period rolling mean."
    Label(fig[6, 1:3], footer; fontsize=10, color=:black, halign=:center, tellwidth=false)

    colsize!(fig.layout, 0, Fixed(30))
    for r in 1:5; rowsize!(fig.layout, r, Auto(1)); end
    rowsize!(fig.layout, 0, Fixed(22))
    rowsize!(fig.layout, 6, Fixed(30))
    rowgap!(fig.layout, 5)
    colgap!(fig.layout, 10)

    save(joinpath(OUTDIR, filename), fig)
    println("  Saved: $filename")
end

# ---------------------------------------------------------------------------
# 2x3 surplus figure
# ---------------------------------------------------------------------------

function plot_staffing_surplus(mdfs::Vector{DataFrame}, suptitle::String, filename::String;
                               window::Int=20)
    n_seeds = length(mdfs)
    periods = mdfs[1].period
    T_burn = 30

    title_fs = 12; label_fs = 10; tick_fs = 9; row_label_fs = 12
    leg_kw = (; labelsize=9, patchsize=(10, 10), padding=(3, 3, 2, 2),
                rowgap=0, patchlabelgap=3, framewidth=0.5)

    function plot_metric!(ax, metric_fn; label="", color=COL_INTERNAL)
        seed_vals = [rolling_mean(metric_fn(mdf), window) for mdf in mdfs]
        for sv in seed_vals
            lines!(ax, periods, sv; color=(color, 0.45), linewidth=0.8)
        end
        ensemble = [let vs = [sv[t] for sv in seed_vals]
            n_valid = count(!isnan, vs)
            n_valid > n_seeds / 2 ? mean(v for v in vs if !isnan(v)) : NaN
        end for t in eachindex(periods)]
        lines!(ax, periods, ensemble; color=color, linewidth=2.5, label=label)
    end

    xlims = (first(periods), last(periods))
    ax_kw = (; titlesize=title_fs, ylabelsize=label_fs,
               xticklabelsize=tick_fs, yticklabelsize=tick_fs,
               xticks=0:100:last(periods))

    COL_DIRECT = :royalblue
    COL_PLACED = :darkorchid

    fig = Figure(; size=(1150, 500), figure_padding=(5, 15, 5, 5))
    Label(fig[0, 1:3], suptitle * " — Surplus (M1)"; fontsize=16, font=:bold,
          halign=:center, tellwidth=false)

    # ── Row 1: Three-way split ──
    Label(fig[1, 0], "Three-way\nSplit"; fontsize=row_label_fs, font=:bold, rotation=pi/2,
          tellheight=false)

    ax1 = Axis(fig[1, 1]; title="Surplus by party", ylabel="Surplus", ax_kw...)
    plot_metric!(ax1, mdf -> mdf.total_realized_surplus; label="Total", color=:gray40)
    plot_metric!(ax1, mdf -> mdf.worker_surplus; label="Worker", color=COL_WORKER)
    plot_metric!(ax1, mdf -> mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed;
                 label="Firm", color=COL_INTERNAL)
    plot_metric!(ax1, mdf -> mdf.broker_surplus_placement .+ mdf.broker_surplus_staffing;
                 label="Broker", color=COL_BROKER)
    axislegend(ax1; position=:rt, leg_kw...)

    ax2 = Axis(fig[1, 2]; title="Cumulative surplus shares", ylabel="Fraction",
               limits=(xlims, (-0.02, 1.02)), ax_kw...)
    plot_metric!(ax2, mdf -> begin
        cum_w = cumsum(mdf.worker_surplus)
        cum_t = cumsum(mdf.total_realized_surplus)
        [cum_t[i] > 0 ? cum_w[i] / cum_t[i] : 0.0 for i in eachindex(cum_t)]
    end; label="Worker", color=COL_WORKER)
    plot_metric!(ax2, mdf -> begin
        cum_f = cumsum(mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed)
        cum_t = cumsum(mdf.total_realized_surplus)
        [cum_t[i] > 0 ? cum_f[i] / cum_t[i] : 0.0 for i in eachindex(cum_t)]
    end; label="Firm", color=COL_INTERNAL)
    plot_metric!(ax2, mdf -> begin
        cum_b = cumsum(mdf.broker_surplus_placement .+ mdf.broker_surplus_staffing)
        cum_t = cumsum(mdf.total_realized_surplus)
        [cum_t[i] > 0 ? cum_b[i] / cum_t[i] : 0.0 for i in eachindex(cum_t)]
    end; label="Broker", color=COL_BROKER)
    axislegend(ax2; position=:rt, leg_kw...)

    ax3 = Axis(fig[1, 3]; title="Outsourcing rate", ylabel="Rate",
               limits=(xlims, (-0.02, 1.02)), ax_kw...)
    plot_metric!(ax3, mdf -> mdf.outsourcing_rate; color=COL_BROKER)

    # ── Row 2: Channel decomposition ──
    Label(fig[2, 0], "Channel\nDecomp."; fontsize=row_label_fs, font=:bold, rotation=pi/2,
          tellheight=false)

    ax4 = Axis(fig[2, 1]; title="Firm surplus share by channel", xlabel="Period",
               ylabel="Fraction", limits=(xlims, (-0.02, 1.02)), ax_kw..., xlabelsize=label_fs)
    shade_no_broker!(ax4, mdfs)
    plot_metric!(ax4, mdf -> begin
        tot = mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed
        [t != 0 ? mdf.firm_surplus_direct[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Direct", color=COL_DIRECT)
    plot_metric!(ax4, mdf -> begin
        tot = mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed
        [t != 0 ? mdf.firm_surplus_placed[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Placed", color=COL_PLACED)
    plot_metric!(ax4, mdf -> begin
        tot = mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed
        [t != 0 ? mdf.firm_surplus_staffed[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Staffed", color=COL_STAFFED)
    axislegend(ax4; position=:rt, leg_kw...)

    ax5 = Axis(fig[2, 2]; title="Broker revenue share by channel", xlabel="Period",
               ylabel="Fraction", limits=(xlims, (-0.02, 1.02)), ax_kw..., xlabelsize=label_fs)
    shade_no_broker!(ax5, mdfs)
    plot_metric!(ax5, mdf -> begin
        tot = mdf.broker_surplus_placement .+ mdf.broker_surplus_staffing
        [t != 0 ? mdf.broker_surplus_placement[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Placement", color=COL_PLACED)
    plot_metric!(ax5, mdf -> begin
        tot = mdf.broker_surplus_placement .+ mdf.broker_surplus_staffing
        [t != 0 ? mdf.broker_surplus_staffing[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Staffing", color=COL_STAFFED)
    axislegend(ax5; position=:rt, leg_kw...)

    ax6 = Axis(fig[2, 3]; title="Mean output by channel", xlabel="Period",
               ylabel="Mean q", ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax6, mdf -> mdf.q_direct_mean; label="Direct", color=COL_DIRECT)
    plot_metric!(ax6, mdf -> mdf.q_placed_mean; label="Placed", color=COL_PLACED)
    plot_metric!(ax6, mdf -> mdf.q_staffed_mean; label="Staffed", color=COL_STAFFED)
    axislegend(ax6; position=:rb, leg_kw...)

    for ax in [ax1, ax2, ax3, ax4, ax5, ax6]
        vlines!(ax, [T_burn]; color=:gray30, linestyle=:dash, linewidth=1.5)
    end

    footer = "Thin lines: individual seeds ($n_seeds). Thick: ensemble mean (shown when majority of seeds have data).\n" *
             "Gray shading: majority of seeds have no brokered matches. Dashed vertical: burn-in (t=$T_burn). Smoothing: $window-period rolling mean."
    Label(fig[3, 1:3], footer; fontsize=10, color=:black, halign=:center, tellwidth=false)

    colsize!(fig.layout, 0, Fixed(30))
    for r in 1:2; rowsize!(fig.layout, r, Auto(1)); end
    rowsize!(fig.layout, 0, Fixed(22))
    rowsize!(fig.layout, 3, Fixed(30))
    rowgap!(fig.layout, 5)
    colgap!(fig.layout, 10)

    save(joinpath(OUTDIR, filename), fig)
    println("  Saved: $filename")
end

# ---------------------------------------------------------------------------
# Run configurations (same grid as base model)
# ---------------------------------------------------------------------------

T = 300
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
      label="Baseline [$geo_label]: (d=8, rho=0.50, eta=0.05)",
      kwargs=(d=8, rho=0.50, firm_geometry=geom)),
     (tag="d04_simple",
      label="4-dim types [$geo_label]: (d=4, rho=0.50, eta=0.05)",
      kwargs=(d=4, rho=0.50, firm_geometry=geom)),
     (tag="d12_complex",
      label="12-dim types [$geo_label]: (d=12, rho=0.50, eta=0.05)",
      kwargs=(d=12, rho=0.50, firm_geometry=geom)),
     (tag="rho10_weakquality",
      label="Weak quality [$geo_label]: (d=8, rho=0.10, eta=0.05)",
      kwargs=(d=8, rho=0.10, firm_geometry=geom)),
     (tag="rho30_mildinteraction",
      label="Mild interaction [$geo_label]: (d=8, rho=0.30, eta=0.05)",
      kwargs=(d=8, rho=0.30, firm_geometry=geom)),
     (tag="rho70_mildquality",
      label="Mild quality [$geo_label]: (d=8, rho=0.70, eta=0.05)",
      kwargs=(d=8, rho=0.70, firm_geometry=geom)),
     (tag="rho90_strongquality",
      label="Strong quality [$geo_label]: (d=8, rho=0.90, eta=0.05)",
      kwargs=(d=8, rho=0.90, firm_geometry=geom)),
     (tag="eta01_stable",
      label="Stable market [$geo_label]: (d=8, rho=0.50, eta=0.01)",
      kwargs=(d=8, rho=0.50, eta=0.01, firm_geometry=geom)),
     (tag="eta10_volatile",
      label="Volatile market [$geo_label]: (d=8, rho=0.50, eta=0.10)",
      kwargs=(d=8, rho=0.50, eta=0.10, firm_geometry=geom)),
     (tag="rho00_pureinteraction",
      label="Pure interaction [$geo_label]: (d=8, rho=0.00, eta=0.05)",
      kwargs=(d=8, rho=0.0, firm_geometry=geom)),
     (tag="rho100_purequality",
      label="Pure quality [$geo_label]: (d=8, rho=1.00, eta=0.05)",
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

        base_datafile = joinpath(base_datadir, "$(c.tag).jld2")
        if !isfile(base_datafile)
            println("  Base model data not found: $base_datafile -- skipping")
            println("    Run explore_base_model.jl first")
            continue
        end
        base_saved = JLD2.load(base_datafile)
        mdfs_base = base_saved["mdfs"]
        cfg_N_W = base_saved["N_W"]::Int

        datafile = joinpath(staffing_datadir, "$(c.tag).jld2")
        if !RERUN && isfile(datafile)
            println("  Loading cached staffing data: $datafile")
            mdfs = JLD2.load(datafile, "mdfs")
        else
            cfg_params = default_params(; c.kwargs..., enable_staffing=true)
            mdfs = run_ensemble(; base_params_kwargs=c.kwargs, T=T, n_seeds=N_SEEDS)
            JLD2.save(datafile, "mdfs", mdfs, "label", c.label,
                      "kwargs", Dict(pairs(c.kwargs)), "T", T, "n_seeds", N_SEEDS,
                      "N_W", cfg_params.N_W)
            println("  Saved staffing data: $datafile")
        end

        plot_staffing_ensemble(mdfs, mdfs_base, c.label,
                               joinpath(geo_dir, "$(c.tag)_staffing.png"); N_W=cfg_N_W)
        plot_staffing_surplus(mdfs, c.label,
                              joinpath(geo_dir, "$(c.tag)_staffing_surplus.png"))
    end
    println()
end

println("Figures: $OUTDIR")
println("Data: $DATADIR")
println("Done.")
