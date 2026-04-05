# Pseudocode: Worker Capture Through Staffing (Model 1)

This document provides a self-contained algorithmic specification of the agent-based staffing model. The model simulates a labor matching market with three agent types (workers, firms, and a broker) where the broker can transition from intermediary to principal by employing workers directly (staffing) rather than merely placing them at client firms.

## Notation

| Symbol | Description |
|--------|-------------|
| $N_W, N_F$ | Number of workers, firms |
| $d$ | Dimensionality of type vectors |
| $w_i \in \mathbb{R}^d$ | Worker $i$'s type vector |
| $x_j \in \mathbb{R}^d$ | Firm $j$'s type vector |
| $r_i$ | Worker $i$'s reservation wage |
| $E_j^t$ | Firm $j$'s employee set at time $t$ |
| $\mathcal{H}_j^t$ | Firm $j$'s experience history: $\{(w_m, q_{mj})\}$ |
| $\mathcal{H}_b^t$ | Broker's experience history: $\{(w_m, x_m, q_m)\}$ |
| $R_j^t$ | Firm $j$'s referral reach via social network |
| $G_S$ | Social network among workers (undirected) |
| $N_S(i)$ | Neighbors of worker $i$ in $G_S$ |
| $\text{Pool}^t$ | Broker's candidate pool |
| $P$ | Target pool size |
| $s_{j,c}^t$ | Firm $j$'s satisfaction index for channel $c$ |
| $\text{rep}^t$ | Broker's reputation (mean client satisfaction) |
| $\hat{q}_j(w)$ | Firm $j$'s predicted match output for worker type $w$ |
| $\hat{q}_b(w, x)$ | Broker's predicted match output for worker-firm pair |
| $f(w, x)$ | True matching function (unknown to agents) |
| $Q$ | Output offset constant |
| $\sigma_\varepsilon$ | Noise standard deviation |
| $\rho$ | Mixing weight (quality vs. interaction) |
| $\beta_W$ | Worker's share of match surplus |
| $\alpha$ | Placement fee rate |
| $L$ | Staffing assignment duration (periods) |
| $\mu_b$ | Staffing value-capture rate |
| $c_\text{emp}$ | Per-period employment overhead cost |
| $\omega$ | EWMA recency weight for satisfaction |
| $\eta$ | Firm exit probability per period |
| $p_\text{vac}$ | Vacancy arrival probability |
| $\lambda$ | Ridge regularization parameter |
| $k_S$ | Social network degree |
| $p_\text{rewire}$ | Watts-Strogatz rewiring probability |
| $\sigma_w$ | Worker type dispersion |
| $\bar{q}_\text{pub}$ | Public benchmark (mean match output) |
| $r_\text{base}$ | Reservation wage floor |

## 1. Matching Function

Match output combines a portable worker-quality component and a match-specific interaction component:

$$q_{ij} = Q + f(w_i, x_j) + \varepsilon_{ij}, \qquad \varepsilon_{ij} \sim \mathcal{N}(0, \sigma_\varepsilon^2)$$

$$f(w, x) = \rho \cdot \text{sim}(w, c) + (1 - \rho) \cdot \text{sim}(w, Ax)$$

where $\text{sim}(a, b) = a^\top b / (\|a\| \|b\|)$ is cosine similarity, $c \in \mathbb{R}^d$ is an ideal worker type vector drawn once at initialization, and $A \in \mathbb{R}^{d \times d}$ is a random interaction matrix with i.i.d. $\mathcal{N}(0,1)$ entries. The parameter $\rho \in [0,1]$ controls how much of match quality depends on portable worker quality versus match-specific complementarities.

## 2. Learning Models

**Firm $j$'s prediction model.** Ridge regression on $2d$ features fitted on $\mathcal{H}_j^t$:

$$\hat{q}_j(w) = \hat{\beta}_j^\top [w;\; w \odot w] + \hat{\alpha}_j$$

where $w \odot w$ denotes the elementwise square. The firm observes only its own hires and cannot separate worker quality from firm-specific interaction.

**Broker's prediction model.** Ridge regression on $d^2 + 3d$ features fitted on $\mathcal{H}_b^t$:

$$\hat{q}_b(w, x) = \hat{\beta}_w^\top w + \hat{\beta}_x^\top x + \hat{\beta}_{wx}^\top \text{vec}(w \otimes x) + \hat{\beta}_{w^2}^\top (w \odot w) + \hat{\alpha}_b$$

where $w \otimes x$ is the full outer product (a $d \times d$ matrix reshaped into $d^2$ features). The broker's cross-firm data and richer feature set enable it to capture all $d^2$ interaction terms induced by $A$.

Both models are refitted each period on the agent's full accumulated history with regularization $\lambda$.

## 3. Wage Determination

For direct hires and placements, the wage splits the predicted surplus:

$$\text{wage}_{ij} = r_i + \beta_W \cdot \max(\hat{q}_j(w_i) - r_i, \; 0)$$

For staffing, the worker receives only $r_i$ (the reservation wage). The broker bills the firm:

$$\psi = r_i + \mu_b \cdot \hat{q}_b(w_i, x_j)$$

## 4. Initialization

```
INITIALIZE:

  -- Firm types and matching function --
  1.  Generate firm types {x_1, ..., x_{N_F}} on the unit sphere in R^d
      according to chosen geometry (sinusoidal curve / great circle / anisotropic).
  2.  Draw ideal worker type c as perturbation of a random firm type.
  3.  Draw interaction matrix A in R^{d x d} with i.i.d. N(0,1) entries.

  -- Worker types --
  4.  for i = 1 to N_W:
        Draw reference firm j(i) ~ Uniform{1, ..., N_F}.
        Set w_i = x_{j(i)} + epsilon_i, where epsilon_i ~ N(0, (sigma_w^2 / d) I_d).

  -- Social network --
  5.  Sort workers by first principal component of their type vectors.
  6.  Build G_S as Watts-Strogatz graph: ring lattice with degree k_S,
      rewiring probability p_rewire.

  -- Calibration --
  7.  Compute E[f] from Monte Carlo sample of random (w, x) pairs.
  8.  Set q_pub := E[f];  r_base := 0.70 * E[f];  c_emp := 0.15 * r_base.
  9.  for each worker i:
        Compute reservation wage r_i using r_base and deg_S(i) per Eq. (r_i).

  -- Initial employment --
  10. for each firm j:
        Draw workforce size n_j ~ Uniform{6, ..., 10}.
        Sample n_j available workers with prob. proportional to exp(-||w_i - x_j||^2).
        Set each sampled worker's status := employed, employer := j.
        Add workers to E_j^0.
        Realize match output q for each initial hire; record (w, q) to H_j.
        Connect all initial employees pairwise in G_S.

  -- Referral pools --
  11. for each firm j:
        R_j^0 := Union_{i in E_j^0} N_S(i) \ E_j^0.

  -- Broker initialization --
  12. Draw P = ceil(pool_target_frac * N_W) available workers into Pool^0.
  13. Seed H_b with 20 random observations from existing worker-firm matches.

  -- State variables --
  14. for each firm j:
        s_{j,int}^0 := q_pub;  s_{j,broker}^0 := q_pub;  vacancies := 0.
  15. rep^0 := q_pub;  active_assignments := empty.
```

## 5. Per-Period Step Ordering

Each period $t$ executes seven steps in sequence:

```
PERIOD t:

  ============================================================
  STEP 0: BROKER POOL MAINTENANCE
  ============================================================
    Remove any non-available workers from Pool^t.
    n_gap := P - |Pool^t|.
    if n_gap > 0:
      eligible := {available workers} \ Pool^t
      n_referral := floor(n_gap / 2)
      referral_neighbors := Union_{i in Pool^t} N_S(i) intersect eligible
      Draw min(n_referral, |referral_neighbors|) from referral_neighbors.
      Draw remainder from eligible uniformly at random.
      Add recruited workers to Pool^t.


  ============================================================
  STEP 1: REFERRAL POOL COMPUTATION
  ============================================================
    for each firm j:
      R_j^t := Union_{i in E_j^t} N_S(i) \ E_j^t


  ============================================================
  STEP 2: VACANCY MANAGEMENT AND OUTSOURCING DECISIONS
  ============================================================
    -- Vacancy generation --
    for each firm j with no open vacancies:
      With probability p_vac:
        Draw n_vac in {1, 2} with equal probability.
        Open n_vac vacancies.

    -- Outsourcing decision (per firm with vacancies) --
    for each firm j with open vacancies:
      score_int := s_{j,int}^t
      if firm j has tried broker:
        score_broker := s_{j,broker}^t
      else:
        score_broker := rep^t              // broker reputation as proxy
      if score_broker > score_int:
        decision_j := broker
      else if score_int > score_broker:
        decision_j := internal
      else:
        decision_j := random choice        // tie-breaking

    Partition firms with vacancies into:
      internal searchers and broker client list J^t.


  ============================================================
  STEP 3: CANDIDATE GENERATION AND EVALUATION
  ============================================================

    -- 3a. Internal searches --
    n := ceil(n_candidates_frac * N_W)     // candidate pool size

    for each firm j with decision_j = internal, for each vacancy:
      Draw floor(n/2) candidates from available workers in R_j^t.
      Draw ceil(n/2) candidates from available workers outside R_j^t.
      for each candidate i:
        Compute q_hat_j(w_i) using firm's ridge model.
      i* := argmax_i q_hat_j(w_i)          // ties broken randomly
      if q_hat_j(w_{i*}) > r_{i*}:
        Emit ProposedMatch(j, i*, source=internal,
                           wage = r_{i*} + beta_W * max(q_hat_j - r_{i*}, 0))
      else:
        Vacancy persists (no positive-surplus candidate).

    -- 3b. Broker allocation (greedy best-pair) --
    available_pool := Pool^t intersect {available workers}
    Compute quality matrix:
      Q_hat[i, j] := q_hat_b(w_i, x_j)  for all i in available_pool, j in J^t.

    while available_pool is non-empty AND J^t is non-empty:
      (i*, j*) := argmax_{i,j} Q_hat[i, j]   // ties broken randomly
      if Q_hat[i*, j*] <= r_{i*}:
        break                                  // no remaining positive surplus

      -- Staffing decision (M1) --
      Firm j* evaluates: q_hat_j*(w_{i*}).

      staff_profit := L * (mu_b * Q_hat[i*, j*] - c_emp)
      est_wage := r_{i*} + beta_W * max(Q_hat[i*, j*] - r_{i*}, 0)
      place_profit := alpha * est_wage
      bill_rate := r_{i*} + mu_b * Q_hat[i*, j*]
      direct_cost := (r_{i*} + beta_W * max(q_hat_j* - r_{i*}, 0)) * (1 + alpha/L)

      if staff_profit > place_profit AND bill_rate <= direct_cost:
        Emit ProposedMatch(j*, i*, source=staffing, wage = r_{i*})
      else:
        Emit ProposedMatch(j*, i*, source=placement,
                           wage = r_{i*} + beta_W * max(q_hat_j* - r_{i*}, 0))

      Remove i* from available_pool; remove one vacancy of j* from J^t.

    for each remaining firm j in J^t (pool exhausted or no surplus):
      Mark as no-proposal.


  ============================================================
  STEP 4: MATCH FORMATION
  ============================================================

    -- 4a. Conflict resolution --
    Collect all ProposedMatches from Steps 3a and 3b.
    Group proposals by worker_id.
    for each worker i with multiple proposals:
      Worker accepts the proposal with the highest wage.
      Ties broken uniformly at random.
      All other proposals for worker i are rejected.

    -- 4b. Finalization of accepted matches --
    for each accepted ProposedMatch (j, i*):

      Realize output: q := Q + f(w_{i*}, x_j) + epsilon,  epsilon ~ N(0, sigma_eps^2).

      if source = internal:
        worker i* status := employed at j.
        Add i* to E_j.
        Record (w_{i*}, q) to H_j.
        Add coworker ties: connect i* to random half of E_j in G_S (up to 5 new ties).
        Close vacancy.

      else if source = placement:
        worker i* status := employed at j.
        Add i* to E_j.
        Record (w_{i*}, q) to H_j.
        Record (w_{i*}, x_j, q) to H_b.
        Add coworker ties: connect i* to random half of E_j in G_S (up to 5 new ties).
        Broker receives placement fee: phi := alpha * wage_{i*j}.
        Close vacancy.

      else if source = staffing:      // MODEL 1 ONLY
        worker i* status := staffed.
        Create StaffingAssignment:
          (worker=i*, firm=j, periods_remaining=L,
           bill_rate=r_{i*} + mu_b * q_hat_b,
           realized_q=q, predicted_q=q_hat_b).
        Record (w_{i*}, x_j, q) to H_b.
        // LOCK-IN: Do NOT add i* to E_j.
        //          Do NOT record to H_j.
        //          Do NOT form coworker ties.
        Close vacancy.


  ============================================================
  STEP 4b: STAFFING ECONOMICS (MODEL 1 ONLY)
  ============================================================
    for each active StaffingAssignment sa:
      // Per-period surplus accounting
      Firm surplus   += sa.realized_q - sa.reservation_wage - mu_b * sa.predicted_q
      Broker revenue += mu_b * sa.predicted_q - c_emp
      Worker surplus += 0   // worker receives only r_i

      sa.periods_remaining -= 1

      if sa.periods_remaining <= 0:     // Assignment expired
        Release worker: status := available, clear broker/staffing fields.
        Reopen one vacancy at firm j (if firm has fewer than 2 open).
        Remove assignment from active list.


  ============================================================
  STEP 5: SATISFACTION AND REPUTATION UPDATES
  ============================================================

    -- 5a. Satisfaction updates --
    for each firm j that made a new hire via channel c:
      if c = internal:
        net := q - beta_W * max(q_hat_j - r_{i*}, 0)
      else if c = placement:
        net := q - beta_W * max(q_hat_j - r_{i*}, 0) - alpha * wage / L
      else if c = staffing:
        net := q - mu_b * q_hat_b
      s_{j,c}^{t+1} := (1 - omega) * s_{j,c}^t + omega * net

    for each firm j that outsourced but received no proposal:
      s_{j,broker}^{t+1} := (1 - omega) * s_{j,broker}^t + omega * s_{j,int}^t

    -- 5b. Broker reputation (sticky) --
    active_clients := J^t union {firms with active staffing assignments}
    if |active_clients| > 0:
      rep^t := mean of s_{j,broker}^t over j in active_clients
      Store as last_reputation.
    else if broker has had clients before:
      rep^t := last_reputation
    else:
      rep^t := q_pub


  ============================================================
  STEP 6: ENTRY AND EXIT
  ============================================================
    for each firm j:
      With probability eta:
        -- Exit --
        for each worker i in E_j:
          i.status := available; i.employer := null.
        Terminate all active staffing assignments at firm j:
          for each such assignment:
            Release staffed worker (status := available).
            Remove assignment.
        Remove firm j.

        -- Immediate replacement (entry) --
        Create firm j' with:
          Fresh type x_{j'} sampled from firm geometry.
          Draw workforce size n_{j'} ~ Uniform{6, ..., 10}.
          Sample n_{j'} available workers by type proximity to x_{j'}.
          Set workers' status := employed at j'.
          Realize and record match outputs; seed H_{j'}.
          Connect all initial employees pairwise in G_S.
          s_{j',int} := q_pub;  s_{j',broker} := q_pub.
          No open vacancies.


  ============================================================
  STEP 7: NETWORK MEASURES (every M periods)
  ============================================================
    Construct combined graph G with N_W + N_F + 1 nodes:
      Worker-worker edges from G_S.
      Worker-firm edges from G_E (direct hires only; staffed workers excluded).
      Broker-worker edges for pool members and staffed workers.
      Broker-firm edges for broker clients and firms with active staffing.

    Compute on G:
      Cross-mode betweenness centrality C_B^x(broker).
      Burt's constraint.
      Effective size.
```

## 6. Staffing Decision Logic (Detail)

The broker's staffing-vs-placement decision and the firm's acceptance condition are the core mechanisms of Model 1.

**Broker's comparison.** For each proposed broker match $(i^*, j)$:

$$\Pi^\text{staff} = L \cdot (\mu_b \cdot \hat{q}_b - c_\text{emp})$$
$$\Pi^\text{place} = \alpha \cdot (r_{i^*} + \beta_W \cdot \max(\hat{q}_b - r_{i^*}, 0))$$

The broker prefers staffing when $\Pi^\text{staff} > \Pi^\text{place}$. Because the staffing slope in $\hat{q}$ ($L \cdot \mu_b$) exceeds the placement slope ($\alpha \cdot \beta_W$), the comparison tips toward staffing once the broker's predictions are accurate enough to identify genuinely high-output matches.

**Firm's acceptance.** The firm compares the proposed bill rate to its amortized direct-hire cost:

$$\text{bill rate} = r_i + \mu_b \cdot \hat{q}_b \qquad \text{vs.} \qquad \text{direct cost} = \hat{w}_j \cdot (1 + \alpha / L)$$

where $\hat{w}_j = r_i + \beta_W \cdot \max(\hat{q}_j - r_i, 0)$ is the wage the firm would pay under direct hire. The firm accepts staffing when the bill rate does not exceed the amortized direct-hire cost.

## 7. Lock-In Mechanism

Staffing produces a double lock-in that distinguishes it from placement:

| | Direct hire / Placement | Staffing |
|---|---|---|
| Worker joins $E_j$? | Yes | No |
| Firm updates $\mathcal{H}_j$? | Yes | No |
| Coworker ties form in $G_S$? | Yes | No |
| Referral pool $R_j$ grows? | Yes | No |
| Broker learns? | Placement only | Yes |

Under staffing, the firm's prediction model stops improving (no new data) and its referral network stops growing (no new ties). The structural holes the broker bridges remain open. The self-liquidating dynamic of structural-hole brokerage is suspended.

## 8. Conflict Resolution

When a worker receives multiple proposals (from internal search and/or broker-mediated search):
1. The worker accepts the offer with the highest wage.
2. Ties are broken uniformly at random.
3. A staffing offer (wage $= r_i$) always loses to a direct-hire offer with positive surplus (wage $> r_i$), so staffing succeeds only for workers without a competing internal offer.

## 9. Default Parameters

| Parameter | Symbol | Default | Description |
|-----------|--------|---------|-------------|
| Type dimensionality | $d$ | 8 | Dimension of worker/firm type vectors |
| Mixing weight | $\rho$ | 0.50 | Quality vs. interaction in $f$ |
| Firm geometry | -- | complex | Sinusoidal curve on unit sphere |
| Workers | $N_W$ | 1000 | Fixed population |
| Firms | $N_F$ | 50 | With entry/exit |
| Exit rate | $\eta$ | 0.05 | Per-period firm exit probability |
| Surplus share | $\beta_W$ | 0.50 | Worker's share of predicted surplus |
| Ridge regularization | $\lambda$ | 1.0 | For all prediction models |
| Network degree | $k_S$ | 6 | Watts-Strogatz degree |
| Rewiring probability | $p_\text{rewire}$ | 0.10 | Watts-Strogatz rewiring |
| Satisfaction recency | $\omega$ | 0.30 | EWMA weight |
| Placement fee rate | $\alpha$ | 0.20 | One-time, proportional to wage |
| Staffing duration | $L$ | 4 | Periods per assignment |
| Value-capture rate | $\mu_b$ | 0.25 | Bill rate markup on $\hat{q}_b$ |
| Employment overhead | $c_\text{emp}$ | $0.15 \cdot r_\text{base}$ | Per-period staffing cost |
| Vacancy probability | $p_\text{vac}$ | 0.50 | Per firm per period |
| Pool target fraction | -- | 0.10 | Broker pool as fraction of $N_W$ |
| Worker dispersion | $\sigma_w$ | 0.50 | Type noise scale |
| Candidate fraction | -- | 0.01 | Internal search candidate pool |
| Noise scale | $\sigma_\varepsilon$ | 0.25 | Match output noise |
| Output offset | $Q$ | 1.0 | Shifts $q$ positive |
| Simulation length | $T$ | 200 | Total periods |
| Burn-in | $T_\text{burn}$ | 30 | Periods before metrics collection |
