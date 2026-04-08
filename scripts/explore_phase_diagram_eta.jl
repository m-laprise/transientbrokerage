"""
    explore_phase_diagram_eta.jl

Phase diagram heatmaps over a (ρ, η) grid at d=8, complex geometry. Runs both
base model and staffing model for T=200 periods with 5 seeds per cell.
Produces three figures: dynamics, per-period surplus shares, cumulative surplus shares.

Output: data/figures/exploration/phasediagrams/eta_sweep/
Data:   data/sims/exploration/phasediagrams/data/eta_sweep/

Usage: julia --project --threads=auto scripts/explore_phase_diagram_eta.jl
       julia --project --threads=auto scripts/explore_phase_diagram_eta.jl --rerun
"""

Threads.nthreads() == 1 && @warn "Running single-threaded; start Julia with --threads=auto"

using TransientBrokerage
using CairoMakie
using DataFrames
using Statistics: mean
using JLD2

const OUTDIR = joinpath(@__DIR__, "..", "data", "figures", "exploration", "phasediagrams", "eta_sweep")
const DATADIR = joinpath(@__DIR__, "..", "data", "sims", "exploration", "phasediagrams", "data", "eta_sweep")
mkpath(OUTDIR); mkpath(DATADIR)

const RERUN = "--rerun" in ARGS

const RHOS = 0.0:0.1:1.0 |> collect       # 11 values
const ETAS = [0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.10]  # 10 values
const D = 8
const GEOM = :complex
const T = 200
const N_SEEDS = 5
const WINDOW = 181:200

# ── Simulation runner ──

function run_ensemble(; base_params_kwargs, T::Int, n_seeds::Int)
    mdfs = Vector{DataFrame}(undef, n_seeds)
    Threads.@threads for s in 1:n_seeds
        p = default_params(; base_params_kwargs..., T=T, seed=s)
        _, mdf = run_simulation(p)
        mdf[!, :seed] .= s
        mdfs[s] = mdf
    end
    return mdfs
end

# ── Metric extraction (identical to explore_phase_diagram.jl) ──

function emean(mdfs::Vector{DataFrame}, col::Symbol)
    vals = Float64[]
    for mdf in mdfs
        rows = mdf[in.(mdf.period, Ref(WINDOW)), :]
        nrow(rows) == 0 && continue
        v = collect(skipmissing(rows[!, col]))
        v = filter(!isnan, v)
        isempty(v) && continue
        push!(vals, mean(v))
    end
    isempty(vals) ? NaN : mean(vals)
end

function extract_cell(mdfs_base, mdfs_staff)
    b_outsourcing = emean(mdfs_base, :outsourcing_rate)
    b_r2_gap = emean(mdfs_base, :gap_r_squared_holdout)
    b_rank_gap = emean(mdfs_base, :gap_rank_corr_selected)
    b_sat_int = emean(mdfs_base, :mean_satisfaction_internal)
    b_sat_brk = emean(mdfs_base, :mean_satisfaction_broker)
    b_sat_gap = b_sat_brk - b_sat_int
    b_total_surplus = emean(mdfs_base, :total_realized_surplus)
    b_broker_surplus = emean(mdfs_base, :broker_surplus_placement) +
                       emean(mdfs_base, :broker_surplus_staffing)
    b_worker_surplus = emean(mdfs_base, :worker_surplus)
    b_firm_surplus = emean(mdfs_base, :firm_surplus_direct) +
                     emean(mdfs_base, :firm_surplus_placed) +
                     emean(mdfs_base, :firm_surplus_staffed)
    b_broker_share = b_total_surplus > 0 ? b_broker_surplus / b_total_surplus : NaN
    b_worker_share = b_total_surplus > 0 ? b_worker_surplus / b_total_surplus : NaN
    b_firm_share = b_total_surplus > 0 ? b_firm_surplus / b_total_surplus : NaN

    s_outsourcing = emean(mdfs_staff, :outsourcing_rate)
    s_r2_gap = emean(mdfs_staff, :gap_r_squared_holdout)
    s_rank_gap = emean(mdfs_staff, :gap_rank_corr_selected)
    s_sat_int = emean(mdfs_staff, :mean_satisfaction_internal)
    s_sat_brk = emean(mdfs_staff, :mean_satisfaction_broker)
    s_sat_gap = s_sat_brk - s_sat_int
    s_flow_capture = emean(mdfs_staff, :flow_capture_rate)
    s_total_surplus = emean(mdfs_staff, :total_realized_surplus)
    s_broker_surplus = emean(mdfs_staff, :broker_surplus_placement) +
                       emean(mdfs_staff, :broker_surplus_staffing)
    s_worker_surplus = emean(mdfs_staff, :worker_surplus)
    s_firm_surplus = emean(mdfs_staff, :firm_surplus_direct) +
                     emean(mdfs_staff, :firm_surplus_placed) +
                     emean(mdfs_staff, :firm_surplus_staffed)
    s_broker_share = s_total_surplus > 0 ? s_broker_surplus / s_total_surplus : NaN
    s_worker_share = s_total_surplus > 0 ? s_worker_surplus / s_total_surplus : NaN
    s_firm_share = s_total_surplus > 0 ? s_firm_surplus / s_total_surplus : NaN

    s_staffing_rev = emean(mdfs_staff, :broker_surplus_staffing)
    s_total_broker = s_broker_surplus
    s_staffing_share = s_total_broker > 0 ? s_staffing_rev / s_total_broker : NaN

    function cum_shares(mdfs)
        cum_broker = 0.0; cum_worker = 0.0; cum_firm = 0.0; cum_total = 0.0; n = 0
        for mdf in mdfs
            cum_total += sum(mdf.total_realized_surplus)
            cum_broker += sum(mdf.broker_surplus_placement) + sum(mdf.broker_surplus_staffing)
            cum_worker += sum(mdf.worker_surplus)
            cum_firm += sum(mdf.firm_surplus_direct) + sum(mdf.firm_surplus_placed) + sum(mdf.firm_surplus_staffed)
            n += 1
        end
        cum_total /= n; cum_broker /= n; cum_worker /= n; cum_firm /= n
        bs = cum_total > 0 ? cum_broker / cum_total : NaN
        ws = cum_total > 0 ? cum_worker / cum_total : NaN
        fs = cum_total > 0 ? cum_firm / cum_total : NaN
        return (; broker=bs, worker=ws, firm=fs)
    end
    b_cum = cum_shares(mdfs_base)
    s_cum = cum_shares(mdfs_staff)

    return (;
        b_outsourcing, s_outsourcing, diff_outsourcing = s_outsourcing - b_outsourcing,
        b_r2_gap, s_r2_gap, diff_r2_gap = s_r2_gap - b_r2_gap,
        b_rank_gap, s_rank_gap, diff_rank_gap = s_rank_gap - b_rank_gap,
        b_sat_gap, s_sat_gap, diff_sat_gap = s_sat_gap - b_sat_gap,
        s_flow_capture, s_staffing_share,
        b_bw_gap = b_broker_share - b_worker_share,
        b_bf_gap = b_broker_share - b_firm_share,
        s_bw_gap = s_broker_share - s_worker_share,
        s_bf_gap = s_broker_share - s_firm_share,
        b_cum_bw_gap = b_cum.broker - b_cum.worker,
        b_cum_bf_gap = b_cum.broker - b_cum.firm,
        s_cum_bw_gap = s_cum.broker - s_cum.worker,
        s_cum_bf_gap = s_cum.broker - s_cum.firm,
    )
end

# ── Grid ──

n_rho = length(RHOS)
n_eta = length(ETAS)
cells = Matrix{Any}(undef, n_eta, n_rho)

function field_matrix(field::Symbol)
    M = Matrix{Float64}(undef, n_eta, n_rho)
    for ri in 1:n_rho, ei in 1:n_eta
        M[ei, ri] = getfield(cells[ei, ri], field)
    end
    return M
end

# ── Plotting helpers ──

const AX_KW = (; xticklabelsize=12, yticklabelsize=12, xlabelsize=14, ylabelsize=14)

function interpolate_grid(M, rhos, etas; n_fine=200)
    rho_fine = range(first(rhos), last(rhos); length=n_fine)
    eta_fine = range(first(etas), last(etas); length=n_fine)
    Z = Matrix{Float64}(undef, n_fine, n_fine)
    for (jj, rf) in enumerate(rho_fine), (ii, ef) in enumerate(eta_fine)
        ri = searchsortedlast(rhos, rf)
        ri = clamp(ri, 1, length(rhos) - 1)
        ei = searchsortedlast(etas, ef)
        ei = clamp(ei, 1, length(etas) - 1)
        tr = (rf - rhos[ri]) / (rhos[ri+1] - rhos[ri])
        te = (ef - etas[ei]) / (etas[ei+1] - etas[ei])
        tr = clamp(tr, 0.0, 1.0)
        te = clamp(te, 0.0, 1.0)
        v00 = M[ei, ri];     v10 = M[ei+1, ri]
        v01 = M[ei, ri+1];   v11 = M[ei+1, ri+1]
        vs = [v00, v10, v01, v11]
        if any(isnan, vs)
            valid = filter(!isnan, vs)
            Z[ii, jj] = isempty(valid) ? NaN : mean(valid)
        else
            Z[ii, jj] = (1-tr)*(1-te)*v00 + (1-tr)*te*v10 + tr*(1-te)*v01 + tr*te*v11
        end
    end
    return rho_fine, eta_fine, Z
end

function make_phase_plot!(ax, cb_pos, M; colormap=Reverse(:RdBu), diverging=true,
                          zero_contour=diverging, n_levels=15,
                          shared_range::Union{Nothing, Tuple{Float64,Float64}}=nothing)
    vals = filter(!isnan, vec(M))
    if shared_range !== nothing
        crange = shared_range
    elseif isempty(vals)
        crange = (-1.0, 1.0)
    elseif diverging
        vmax = maximum(abs, vals)
        crange = (-vmax, vmax)
    else
        crange = (minimum(vals), maximum(vals))
    end

    rho_fine, eta_fine, Z = interpolate_grid(M, collect(Float64, RHOS), Float64.(ETAS))
    levels = range(crange[1], crange[2]; length=n_levels + 1)

    cf = contourf!(ax, rho_fine, eta_fine, Z; colormap, levels, extendlow=:auto, extendhigh=:auto)
    if zero_contour
        contour!(ax, rho_fine, eta_fine, Z; levels=[0.0], color=:black, linewidth=1.5)
    end
    contour!(ax, rho_fine, eta_fine, Z; levels=collect(levels), color=(:gray30, 0.4), linewidth=0.5)

    ax.xticks = 0.0:0.2:1.0
    ax.yticks = 0.02:0.02:0.10
    ax.xlabel = "ρ"
    ax.ylabel = "η"
    Colorbar(cb_pos, cf; ticklabelsize=10, width=12)
    return cf
end

function compute_shared_range(fields)
    vals = Float64[]
    for f in fields
        append!(vals, filter(!isnan, vec(field_matrix(f))))
    end
    (minimum(vals), maximum(vals))
end

# ── Run grid ──

println("Phase diagram (η sweep): $(n_rho) ρ × $(n_eta) η, d=$D, $GEOM geometry, $N_SEEDS seeds, T=$T")
RERUN && println("  --rerun: forcing re-simulation")
println()

for (ri, rho) in enumerate(RHOS)
    for (ei, eta) in enumerate(ETAS)
        tag = "rho$(lpad(round(Int, rho*100), 3, '0'))_eta$(lpad(round(Int, eta*100), 2, '0'))"
        base_file = joinpath(DATADIR, "$(tag)_base.jld2")
        staff_file = joinpath(DATADIR, "$(tag)_staffing.jld2")

        print("  ρ=$rho η=$eta ...")

        if !RERUN && isfile(base_file)
            mdfs_base = JLD2.load(base_file, "mdfs")
        else
            mdfs_base = run_ensemble(; base_params_kwargs=(d=D, rho=rho, eta=eta, firm_geometry=GEOM),
                                       T=T, n_seeds=N_SEEDS)
            N_W = default_params(; d=D, rho=rho, eta=eta, firm_geometry=GEOM).N_W
            JLD2.save(base_file, "mdfs", mdfs_base, "N_W", N_W)
        end

        if !RERUN && isfile(staff_file)
            mdfs_staff = JLD2.load(staff_file, "mdfs")
        else
            mdfs_staff = run_ensemble(; base_params_kwargs=(d=D, rho=rho, eta=eta, firm_geometry=GEOM,
                                                             enable_staffing=true),
                                        T=T, n_seeds=N_SEEDS)
            N_W = default_params(; d=D, rho=rho, eta=eta, firm_geometry=GEOM, enable_staffing=true).N_W
            JLD2.save(staff_file, "mdfs", mdfs_staff, "N_W", N_W)
        end

        cells[ei, ri] = extract_cell(mdfs_base, mdfs_staff)
        println(" done")
    end
end

# ── Figure 1: Dynamics ──

fig1 = Figure(; size=(1100, 1300), figure_padding=(5, 5, 3, 3))

Label(fig1[0, 1:6],
      "Phase diagrams: How firm turnover shapes broker advantage and capture";
      fontsize=16, font=:bold, halign=:center, tellwidth=false)
Label(fig1[1, 1:6],
      "Complex geometry, d=$D, T=$T, steady-state means (t=$(first(WINDOW))-$(last(WINDOW))) of ensemble means over $N_SEEDS seeds.";
      fontsize=14, halign=:center, tellwidth=false, color=:gray30)

Label(fig1[2, 1:2], "Base model"; fontsize=14, font=:bold, halign=:center, tellwidth=false)
Label(fig1[2, 3:4], "Staffing model (M1)"; fontsize=14, font=:bold, halign=:center, tellwidth=false)
Label(fig1[2, 5:6], "Difference (M1 − Base)"; fontsize=14, font=:bold, halign=:center, tellwidth=false)

PROW = 2

for c in [1, 3, 5]; colsize!(fig1.layout, c, Relative(0.29)); end
for c in [2, 4, 6]; colsize!(fig1.layout, c, Relative(0.04)); end
colgap!(fig1.layout, 2, 4); colgap!(fig1.layout, 3, 12)
colgap!(fig1.layout, 4, 4); colgap!(fig1.layout, 5, 12)

panels1 = [
    (1, 1, 2, :b_outsourcing, "Outsourcing rate",               :inferno, false, false),
    (2, 1, 2, :b_r2_gap,     "Broker − firm prediction R²",    Reverse(:RdBu), true, true),
    (3, 1, 2, :b_rank_gap,   "Broker − firm ranking accuracy",  Reverse(:RdBu), true, true),
    (4, 1, 2, :b_sat_gap,    "Satisfaction: broker ch. − internal ch.", Reverse(:RdBu), true, true),
    (1, 3, 4, :s_outsourcing, "Outsourcing rate",               :inferno, false, false),
    (2, 3, 4, :s_r2_gap,     "Broker − firm prediction R²",    Reverse(:RdBu), true, true),
    (3, 3, 4, :s_rank_gap,   "Broker − firm ranking accuracy",  Reverse(:RdBu), true, true),
    (4, 3, 4, :s_sat_gap,    "Satisfaction: broker ch. − internal ch.", Reverse(:RdBu), true, true),
    (1, 5, 6, :diff_outsourcing, "Δ Outsourcing rate",          Reverse(:RdBu), true, true),
    (2, 5, 6, :diff_r2_gap,     "Δ Prediction R² gap",          Reverse(:RdBu), true, true),
    (3, 5, 6, :diff_rank_gap,   "Δ Ranking accuracy gap",       Reverse(:RdBu), true, true),
    (4, 5, 6, :diff_sat_gap,    "Δ Satisfaction gap",            Reverse(:RdBu), true, true),
    (5, 3, 4, :s_flow_capture,   "Staffing share of new matches",    :inferno, false, false),
    (5, 5, 6, :s_staffing_share, "Staffing share of broker revenue", :inferno, false, false),
]

inferno_range = compute_shared_range([:b_outsourcing, :s_outsourcing, :s_flow_capture, :s_staffing_share])
r2_vals = compute_shared_range([:b_r2_gap, :s_r2_gap, :diff_r2_gap])
r2_vmax = max(abs(r2_vals[1]), abs(r2_vals[2]))
r2_range = (-r2_vmax, r2_vmax)
rank_vals = compute_shared_range([:b_rank_gap, :s_rank_gap, :diff_rank_gap])
rank_vmax = max(abs(rank_vals[1]), abs(rank_vals[2]))
rank_range = (-rank_vmax, rank_vmax)
sat_vals = compute_shared_range([:b_sat_gap, :s_sat_gap, :diff_sat_gap])
sat_vmax = max(abs(sat_vals[1]), abs(sat_vals[2]))

field_ranges = Dict{Symbol, Tuple{Float64,Float64}}()
for f in [:b_outsourcing, :s_outsourcing, :s_flow_capture, :s_staffing_share]
    field_ranges[f] = inferno_range
end
for f in [:b_r2_gap, :s_r2_gap, :diff_r2_gap]; field_ranges[f] = r2_range; end
for f in [:b_rank_gap, :s_rank_gap, :diff_rank_gap]; field_ranges[f] = rank_range; end
for f in [:b_sat_gap, :s_sat_gap, :diff_sat_gap]; field_ranges[f] = (-sat_vmax, sat_vmax); end

for (row, hcol, ccol, field, title, cmap, divg, zc) in panels1
    ax = Axis(fig1[row + PROW, hcol]; title, titlesize=13, AX_KW...)
    sr = get(field_ranges, field, nothing)
    make_phase_plot!(ax, fig1[row + PROW, ccol], field_matrix(field);
                     colormap=cmap, diverging=divg, zero_contour=zc, shared_range=sr)
end

footer_lines = join([
    "ρ (quality share) controls the share of match quality from general worker quality (high ρ) vs. worker-firm interaction (low ρ).",
    "η (firm exit rate) is the per-period probability of firm exit and replacement (higher η = more turnover, fresher firms).",
    "Row 1 — Outsourcing rate: fraction of firms with vacancies that delegate search to the broker.",
    "Row 2 — Prediction R² gap: holdout R² difference (broker minus avg firm); how much better the broker predicts match quality.",
    "Row 3 — Ranking accuracy gap: rank correlation difference on actual hires; does the broker pick better candidates than firms.",
    "Row 4 — Satisfaction gap: mean broker-channel minus internal-channel satisfaction; positive means firms prefer the broker.",
    "Row 5 — Capture: staffing share of new matches = fraction that are staffing; staffing share of revenue = staffing / total.",
], "\n")
Box(fig1[5 + PROW + 1, 1:6]; color=:transparent, strokevisible=false)
Label(fig1[5 + PROW + 1, 1:6], footer_lines;
      fontsize=14, halign=:left, valign=:top, justification=:left,
      tellwidth=false, tellheight=true,
      padding=(5, 5, 3, 3), color=:gray30)

save(joinpath(OUTDIR, "phase_dynamics.png"), fig1; px_per_unit=2)
println("Saved: phase_dynamics.png")

# ── Figure 2: Per-period surplus shares ──

fig2 = Figure(; size=(950, 580), figure_padding=(10, 10, 5, 5))
Label(fig2[0, 1:4],
      "Phase diagrams: Who captures the surplus from matching?";
      fontsize=16, font=:bold, halign=:center, tellwidth=false)
Label(fig2[1, 1:4],
      "Complex geometry, d=$D, T=$T, steady-state means (t=$(first(WINDOW))-$(last(WINDOW))) of ensemble means over $N_SEEDS seeds.";
      fontsize=11, halign=:center, tellwidth=false, color=:gray30)

colsize!(fig2.layout, 1, Relative(0.42)); colsize!(fig2.layout, 2, Relative(0.06))
colsize!(fig2.layout, 3, Relative(0.42)); colsize!(fig2.layout, 4, Relative(0.06))
colgap!(fig2.layout, 2, 5); colgap!(fig2.layout, 3, 15)

panels2 = [
    (1, 1, 2, :b_bw_gap, "Broker − worker share gap (Base)", Reverse(:RdYlGn), true),
    (1, 3, 4, :s_bw_gap, "Broker − worker share gap (M1)",   Reverse(:RdYlGn), true),
    (2, 1, 2, :b_bf_gap, "Broker − firm share gap (Base)",   Reverse(:RdBu),    true),
    (2, 3, 4, :s_bf_gap, "Broker − firm share gap (M1)",     Reverse(:RdBu),    true),
]

for (row, hcol, ccol, field, title, cmap, divg) in panels2
    ax = Axis(fig2[row + 1, hcol]; title, titlesize=13, AX_KW...)
    make_phase_plot!(ax, fig2[row + 1, ccol], field_matrix(field); colormap=cmap, diverging=divg)
end

surplus_footer = join([
    "Each panel shows broker surplus share minus counterparty surplus share of total realized surplus per period.",
    "Red = broker captures a larger share; green/blue = counterparty retains more. Zero line shown in black.",
    "Worker surplus = wage above reservation wage. Firm surplus = realized output minus wage and fees.",
    "Broker surplus = placement fees + staffing margins (bill rate minus worker wage minus employment costs).",
], "\n")
Box(fig2[4, 1:4]; color=:transparent, strokevisible=false)
Label(fig2[4, 1:4], surplus_footer;
      fontsize=12, halign=:left, valign=:top, justification=:left,
      tellwidth=false, tellheight=true, padding=(5, 5, 3, 3), color=:gray30)

save(joinpath(OUTDIR, "phase_surplus.png"), fig2; px_per_unit=2)
println("Saved: phase_surplus.png")

# ── Figure 3: Cumulative surplus shares ──

fig3 = Figure(; size=(950, 580), figure_padding=(10, 10, 5, 5))
Label(fig3[0, 1:4],
      "Phase diagrams: Cumulative surplus distribution over entire simulation";
      fontsize=16, font=:bold, halign=:center, tellwidth=false)
Label(fig3[1, 1:4],
      "Complex geometry, d=$D, T=$T, $N_SEEDS seeds. Shares computed from cumulative sums over all $T periods.";
      fontsize=11, halign=:center, tellwidth=false, color=:gray30)

colsize!(fig3.layout, 1, Relative(0.42)); colsize!(fig3.layout, 2, Relative(0.06))
colsize!(fig3.layout, 3, Relative(0.42)); colsize!(fig3.layout, 4, Relative(0.06))
colgap!(fig3.layout, 2, 5); colgap!(fig3.layout, 3, 15)

panels3 = [
    (1, 1, 2, :b_cum_bw_gap, "Broker − worker share gap (Base)", Reverse(:RdYlGn), true),
    (1, 3, 4, :s_cum_bw_gap, "Broker − worker share gap (M1)",   Reverse(:RdYlGn), true),
    (2, 1, 2, :b_cum_bf_gap, "Broker − firm share gap (Base)",   Reverse(:RdBu),    true),
    (2, 3, 4, :s_cum_bf_gap, "Broker − firm share gap (M1)",     Reverse(:RdBu),    true),
]

for (row, hcol, ccol, field, title, cmap, divg) in panels3
    ax = Axis(fig3[row + 1, hcol]; title, titlesize=13, AX_KW...)
    make_phase_plot!(ax, fig3[row + 1, ccol], field_matrix(field); colormap=cmap, diverging=divg)
end

cum_footer = join([
    "Each panel shows broker cumulative surplus share minus counterparty share, summed over all $T periods.",
    "Red = broker captures a larger share; green/blue = counterparty retains more. Zero line shown in black.",
    "Unlike the per-period figure, cumulative shares reflect the full trajectory including early transients.",
], "\n")
Box(fig3[4, 1:4]; color=:transparent, strokevisible=false)
Label(fig3[4, 1:4], cum_footer;
      fontsize=12, halign=:left, valign=:top, justification=:left,
      tellwidth=false, tellheight=true, padding=(5, 5, 3, 3), color=:gray30)

save(joinpath(OUTDIR, "phase_surplus_cumulative.png"), fig3; px_per_unit=2)
println("Saved: phase_surplus_cumulative.png")

println("\nFigures: $OUTDIR")
println("Data: $DATADIR")
println("Done.")
