#!/usr/bin/env julia
# Compare simulation dynamics before and after dual-vacancy change.

using JLD2, DataFrames, Statistics, Printf

const OLD_DIR = joinpath(@__DIR__, "..", "data", "sims", "exploration_pre_coworker_ties")
const NEW_DIR = joinpath(@__DIR__, "..", "data", "sims", "exploration")

const GEOMETRIES = ["complex", "simple", "unstructured"]
const CONFIGS = [
    "baseline", "d04_simple", "d12_complex",
    "rho00_pureinteraction", "rho10_weakquality", "rho90_strongquality", "rho100_purequality",
    "eta01_stable", "eta10_volatile",
]
const T_BURN = 30

function load_mdfs(dir, geo, config; staffing=false)
    subdir = staffing ? joinpath(dir, geo, "staffing") : joinpath(dir, geo)
    path = joinpath(subdir, "$(config).jld2")
    isfile(path) || return nothing
    JLD2.load(path)["mdfs"]::Vector{DataFrame}
end

"""Ensemble mean of column col, last 50 post-burn-in periods, across seeds."""
function emean_last50(mdfs::Vector{DataFrame}, col::Symbol)
    vals = Float64[]
    for df in mdfs
        hasproperty(df, col) || continue
        rows = df[df.period .> T_BURN, :]
        nrow(rows) == 0 && continue
        v = collect(skipmissing(rows[!, col]))
        isempty(v) && continue
        window = v[max(1, end-49):end]
        push!(vals, mean(window))
    end
    isempty(vals) ? NaN : mean(vals)
end

"""Ensemble mean of column col, all post-burn-in periods."""
function emean_all(mdfs::Vector{DataFrame}, col::Symbol)
    vals = Float64[]
    for df in mdfs
        hasproperty(df, col) || continue
        rows = df[df.period .> T_BURN, :]
        nrow(rows) == 0 && continue
        v = collect(skipmissing(rows[!, col]))
        isempty(v) && continue
        push!(vals, mean(v))
    end
    isempty(vals) ? NaN : mean(vals)
end

function delta_str(old_v, new_v; pct=false)
    if isnan(old_v) && isnan(new_v)
        return "—"
    end
    ov = pct ? 100*old_v : old_v
    nv = pct ? 100*new_v : new_v
    d = nv - ov
    sign = d >= 0 ? "+" : ""
    if pct
        @sprintf("%.1f → %.1f (%s%.1f pp)", ov, nv, sign, d)
    else
        rel = abs(ov) > 1e-6 ? @sprintf(" %s%.0f%%", sign, 100*d/abs(ov)) : ""
        @sprintf("%.2f → %.2f%s", ov, nv, rel)
    end
end

function main()
    if !isdir(joinpath(NEW_DIR, "complex"))
        println("New data not found.")
        return
    end

    for staffing in [false, true]
        model = staffing ? "MODEL 1 (STAFFING)" : "BASE MODEL"
        println("\n", "=" ^ 100)
        println("  $model")
        println("=" ^ 100)

        for geo in GEOMETRIES
            println("\n  ── $geo ──\n")
            @printf("  %-24s %24s %24s %24s %24s\n",
                "Config", "Matches/period", "Outsourcing rate", "Broker holdout R²", "Firm holdout R²")
            @printf("  %-24s %24s %24s %24s %24s\n",
                "", "R² gap (B-F)", "Total surplus", "Betweenness", staffing ? "Flow capture rate" : "Avg referral pool")
            println("  ", "-" ^ 120)

            for config in CONFIGS
                old = load_mdfs(OLD_DIR, geo, config; staffing)
                new = load_mdfs(NEW_DIR, geo, config; staffing)
                (old === nothing && new === nothing) && continue

                # Row 1: activity & prediction
                om = old !== nothing ? emean_all(old, :matches) : NaN
                nm = new !== nothing ? emean_all(new, :matches) : NaN
                oo = old !== nothing ? emean_all(old, :outsourcing_rate) : NaN
                no_ = new !== nothing ? emean_all(new, :outsourcing_rate) : NaN
                obr = old !== nothing ? emean_last50(old, :broker_r_squared_holdout) : NaN
                nbr = new !== nothing ? emean_last50(new, :broker_r_squared_holdout) : NaN
                ofr = old !== nothing ? emean_last50(old, :firm_r_squared_holdout) : NaN
                nfr = new !== nothing ? emean_last50(new, :firm_r_squared_holdout) : NaN

                @printf("  %-24s %24s %24s %24s %24s\n",
                    config,
                    delta_str(om, nm),
                    delta_str(oo, no_; pct=true),
                    delta_str(obr, nbr),
                    delta_str(ofr, nfr))

                # Row 2: gap, surplus, structure
                og = old !== nothing ? emean_last50(old, :gap_r_squared_holdout) : NaN
                ng = new !== nothing ? emean_last50(new, :gap_r_squared_holdout) : NaN
                ots = old !== nothing ? emean_all(old, :total_realized_surplus) : NaN
                nts = new !== nothing ? emean_all(new, :total_realized_surplus) : NaN
                obt = old !== nothing ? emean_all(old, :betweenness) : NaN
                nbt = new !== nothing ? emean_all(new, :betweenness) : NaN

                last_col_old = NaN; last_col_new = NaN
                if staffing
                    last_col_old = old !== nothing ? emean_last50(old, :flow_capture_rate) : NaN
                    last_col_new = new !== nothing ? emean_last50(new, :flow_capture_rate) : NaN
                else
                    last_col_old = old !== nothing ? emean_all(old, :avg_referral_pool_size) : NaN
                    last_col_new = new !== nothing ? emean_all(new, :avg_referral_pool_size) : NaN
                end

                @printf("  %-24s %24s %24s %24s %24s\n",
                    "",
                    delta_str(og, ng),
                    delta_str(ots, nts),
                    delta_str(obt, nbt),
                    staffing ? delta_str(last_col_old, last_col_new; pct=true) : delta_str(last_col_old, last_col_new))
                println()
            end
        end
    end
end

main()
