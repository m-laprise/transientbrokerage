# Appendix A: Specifications for an ABM of Transient Brokerage in Matching Markets

This appendix details the specifications of an agent-based model of brokered matching meant to formalize and demonstrate the theory of brokerage put forward in its companion article.

## Theory Overview

The structural-hole theory of brokerage (Burt, 1992) locates the broker's value in its network position, bridging disconnected parties. Structural-hole brokerage, when performed at scale, can be self-liquidating: each successful match creates a direct tie that densifies the network and closes the holes that created bridging opportunities in the first place, unless the broker aggressively recruits new, distant clients.

I propose a complementary view of brokerage. Brokerage is outsourced relational work: the broker constructs viable matches between parties who cannot easily evaluate each other. This relational work generates an informational byproduct that the broker can leverage. The broker accumulates knowledge about heterogeneous parties and how to match them successfully. Structural position provides the access that feeds learning, but while each successful match erodes the broker's structural advantage, it also strengthens its informational position (by adding an observation to its experience of the matching function).

The broker converts structural capital into informational capital through the act of brokering. When the matching problem is sufficiently complex, the informational capital compounds faster than structural capital erodes, and this compounding advantage can support a transition from intermediation to capture, transforming the broker into a principal selling the resource it was formerly intermediating or data and analytics. This is *transient brokerage*, a process that highlights the broker's power rather than its fragility.

This project develops an agent-based model of brokered matching to formalize and demonstrate the theoretical framework. In the model, agents seeking pairwise matches either search their own network or outsource the search to a broker. Capture can take two forms: resource capture, where the broker becomes a principal and locks clients out of learning, or data capture, where the broker sells its predictions as an analytics service while clients continue matching directly. All agents use heuristic decision rules. No agent solves an optimization problem or holds beliefs about other agents' strategies.

## Questions

1. Under what conditions does the broker develop, maintain, or lose an informational advantage over its clients?

2. Under what conditions can the broker leverage its advantage for capture?

3. What form does capture take and how does capture impact the dynamics of the broker's advantage?

## Main Propositions

The simulation is designed to demonstrate the following propositions.

### Premise

**A broker provides value in a matching market because of its structural or informational advantages.** A broker helps create a match between principals who, without the broker's intervention, could not easily find each other (access; structural advantage) or were unaware that they would benefit from a match (matchmaking; informational advantage). In other words, the broker's service is valuable both because it can find counterparties that clients cannot reach and because it can assess match quality better than its clients can.

- ***The existence of a structural advantage depends purely on network topology.*** It can be measured using betweenness centrality, constraint, and effective size.

- ***The emergence of an informational advantage depends on the value of the data a broker and its clients accumulate, which in turn depends on the form and difficulty of the matching problem.*** When the matching problem is hard to solve, local or limited experience can be insufficient relative to a broker's high volume of cross-market data.

### 1. Advantage

#### Proposition 1.1

**A broker's structural and informational advantages exhibit distinct dynamics over repeated brokerage activity.**

**1.1a. Structural advantage tends to be self-liquidating.** A broker that bridges a gap between two principals, and successfully matches them, creates a direct relationship between them. With each match, the broker's network position weakens. Direct ties accumulate between principals and structural holes close. This is particularly the case when brokerage occurs at scale. A broker can counteract the self-liquidating tendency by aggressively recruiting new candidates, continuously expanding its reach into parts of the network that principals cannot yet access. However, when the broker's pool of candidates is stable or slowly evolving, placements create direct ties faster than new structural holes are bridged, and the erosion of structural advantage dominates.

**1.1b. Informational advantage tends to be self-reinforcing.** Each match generates information about what makes pairings succeed or fail in a given market. The broker's cross-market experience, whether it helps assess general counterparty quality or understand pairing complementarities, generates an informational advantage over each client's limited within-agent perspective. This advantage grows with the volume and diversity of the broker's placement history.

#### Proposition 1.2

**The broker's informational advantage arises primarily from understanding pairing complementarities (the relational channel) rather than from better assessing counterparty quality (the attributional channel), and the extent of the dominance of the relational channel depends on the structure of the data-generating process.**

The broker's advantage will be largest when the interaction component dominates (relational channel), rather than when the general quality component dominates (attributional channel). This difference is more or less pronounced depending on the structure of the data-generating process.

#### Proposition 1.3

**Network topology influences whether an active broker's structural or informational advantages dominate.**

**1.3a. In sparse or small-world networks, an active broker's value depends primarily on its structural advantage, which is correlated with its informational advantage.** Principals cannot easily find each other in such a network. Standard structural-hole measures (betweenness centrality, constraint, effective size) predict broker value well in this regime. At the same time, structural holes provide the access that feeds the broker's learning, so its structural and informational advantages are positively correlated.

**1.3b. In dense (or densifying) networks, an active broker's value depends primarily (or increasingly) on its informational advantage, which can become decoupled from its structural advantage.** Even if principals could find each other, a broker provides value if it can predict match quality better than principals can. A broker that started in a strong structural position may possess a lot of accumulated cross-market knowledge, regardless of its current structural advantage. As a broker's structural position weakens as a result of its brokerage activity, it accumulates more data, and the correlation between the two types of advantages weakens. In the limit, the broker has no structural advantage but retains its informational advantage.

### 2. Conditions for capture

#### Proposition 2.1

**A broker can leverage its informational advantage to transition from intermediary to principal (capture by the broker). The informational channel, not the structural one, drives capture.** A broker's information advantage translates into higher quality predictions of matching outputs and matches providing higher value to clients. Instead of continuing to facilitate these matches, the broker can leverage its predictive ability to capture the resource it was intermediating and become a principal.

At the point of capture, the broker's structural advantage may be declining (it has closed many of the gaps it once bridged). Standard structural-hole measures would predict that the broker is losing power exactly when it is consolidating it.

#### Proposition 2.2

**Capture requires specific conditions and does not occur universally. It is more likely when matching is complex and markets are opaque.**

High matching complexity make the principals' learning problem harder, widening and preserving the broker's advantage.

In markets with simple matching problems, principals learn fast and well enough that the broker does not accumulate a decisive informational advantage. Brokers persist as commodity intermediaries earning thin margins and may attempt capture but do not consolidate into dominant principals. This is the no-capture region of the parameter space.

Within the capture region of the parameter space, if the broker does not capture, its information advantage may start to erode over time.

### 3. Forms of capture

#### Proposition 3

**Capture can occur in two forms with qualitatively different dynamics.**

**3a. Under resource capture, the transition is abrupt, and the broker suddenly starts taking inventory risk and acting primarily as a principal.** Resource capture creates a triple lock-in: the client's information state freezes (it doesn't learn from new matches like it did when the broker acted as an intermediary), the client's network no longer grows (the broker is everyone's counterparty, so no direct ties form between principals), and the open market thins as the broker acquires counterparty positions (supply-side scarcity). The self-liquidating dynamic of structural advantage is suspended, because the broker no longer creates direct ties between clients. This produces a steep capture trajectory.

**3b. Under data capture, the transition is gradual, and the broker progressively monetizes its informational advantage by acting as a principal in subscription contracts.** Clients continue making new matches, learning from outcomes, and growing their networks. The self-liquidating dynamic of structural advantage continues operating. This produces a smooth capture trajectory.

## Illustrative Domains

The model is domain-agnostic: it formalizes brokered matching between heterogeneous agents in a single population. It represents any market in which a broker facilitates pairwise matches, and accumulates cross-market data from doing so while facing structural erosion from the direct ties it creates.

Because of its level of generality, the model can equally be taken to represent a variety of empirical domains in which real life brokers sometime transition to become principals; here I describe three of them, which I will refer to as illustrative examples throughout this section, to make things more concrete.

**Interdealer brokerage in OTC financial markets.** Dealers in over-the-counter markets (interest rate swaps, foreign exchange, corporate bonds) need counterparties for trades. Interdealer brokers (IDBs) sit between dealers, matching buy and sell interests across the market. Each successful brokered trade creates a direct relationship between two dealers who can subsequently trade bilaterally. The IDB accumulates cross-market knowledge of which dealer pairings clear efficiently. The well-documented transition from voice brokerage to electronic trading platforms (ICAP → NEX/CME, BGC → Fenics) is an instance of data capture; IDBs that became principal traders illustrate resource capture.

**Dealer networks in collectible markets.** Collectors of art, wine, rare books, or similar specialty goods seek trades or sales through dealers who know the market. Each collector has distinct tastes and holdings; match quality depends on multidimensional complementarity between what one party has and what another wants. Dealers accumulate knowledge of collector preferences across transactions. A dealer who transitions from pure intermediation to holding inventory (gallery, wine merchant) illustrates resource capture; one who builds a valuation database or subscription advisory service illustrates data capture.

**Import-export trading companies.** Producers and buyers across international markets rely on trading intermediaries to find counterparties they cannot easily reach or evaluate. Trading companies (*sōgō shōsha*, commodity brokers, Hong Kong trading houses) bridge geographically and informationally separated markets, matching exporters' goods with importers' needs. Match quality depends on multidimensional compatibility of product specifications, volumes, timing, and quality standards. Each successful brokered trade creates a direct relationship between producer and buyer who can subsequently trade bilaterally. The trading company's informational advantage lies in knowing which supplier-buyer combinations work across many markets. The transition from pure intermediation to taking principal positions (buying commodities from producers and reselling to buyers, bearing inventory and price risk) is the canonical resource capture trajectory. Some trading companies evolve further into vertically integrated conglomerates.

## Part I. Base Model

The model is a discrete-time agent-based simulation of a matching market with two participant types: *agents* and a *broker*. Agents seeking pairwise matches either search their own network or outsource the search to the broker. Each period represents one calendar quarter. All economic quantities (match output, fees, surplus) are in the same monetary units.

A single broker serves the market. This is a simplification: with multiple brokers, the data pool fragments, there is competition for informational rents, and no single broker consolidates as large an informational advantage. The model can be interpreted as a monopolistic broker or as a single broker's segment within a competitive market. Analysis of broker competition is deferred to future work.

All agents use heuristic decision rules. No agent holds beliefs about other agents' strategies, in line with the tradition of ABM agents using simple, bounded-rationality rules grounded in empirically observable behavior (Brenner, 2006).

The base model specifies agents (§0), the matching problem (§1), how agents learn to predict match quality (§2), match economics (§3), network structure and agent turnover (§4), how agents and the broker find counterparties (§5), the outsourcing decision (§6), the broker's roster (§7), the match lifecycle (§8), and the complete step ordering (§9). There is no capture in the base model. Resource capture is specified in Part III (§12).

### 0. Agents

The model has $N$ agents (default 1000) and a single broker. Agents are nodes in an undirected network $G$ that determines their search opportunities: an agent can only find counterparties among its direct connections in $G$ (§5). The network is initialized as a small-world graph with random node ordering (no built-in type assortativity). It evolves over time as matches create new edges between matched agents (§4).

Each agent $i$ is characterized by:

- **Type** $\mathbf{x}_i \in \mathbb{R}^d$: a fixed vector of observable characteristics assigned at initialization. Types determine general quality and productive compatibility with other agents through the matching function (§1). The dimensionality $d = 8$ is fixed.
- **Current-period matches** $M_i^t$: the list of matches involving $i$ that have already formed in period $t$. The same counterparty may appear multiple times (concurrent matches with the same partner are allowed). The length $|M_i^t| \leq K$ (default $K = 5$).
- **Available capacity**: $K - |M_i^t|$, the number of additional matches the agent can enter.
- **Experience history** $\mathcal{H}_{i}^t = \{(\mathbf{x}_j, q_{ij})\}$: the set of (other party's type, realized match output) pairs from all matches $i$ has participated in, regardless of whether $i$ was the demander or the counterparty (§2a). Because the matching function is symmetric (§1a), both roles produce the same prediction target.
- **Satisfaction indices** $s_{i,c}^t$: one scalar per search channel $c \in \{\text{self}, \text{broker}\}$, tracking realized match value via an EWMA (§6a). Drives the outsourcing decision (§6).
- **Outside option** $r$: the minimum match value any agent requires to participate in a match (§3). Constant across agents, calibrated at initialization.

Agents exit independently each period with probability $\eta$ (default 0.02) and are replaced by new entrants with fresh types, empty histories, self-satisfaction initialized from neighbors' opinions, and broker-satisfaction set to the current broker reputation (§6a).

#### Agent types

Agents are described by type vectors in $\mathbb{R}^d$ ($d = 8$). These types are the observable characteristics that determine productive compatibility through the matching function (§1).

Agent types lie near a smooth one-dimensional curve on the surface of the unit sphere in $\mathbb{R}^d$. The curve is parameterized by a position $t \in [0, 1]$:

$$\mathbf{x}(t) = \frac{\tilde{\mathbf{x}}(t)}{\|\tilde{\mathbf{x}}(t)\|}, \qquad \tilde{x}_k(t) = \begin{cases} \sin(2\pi f_k t + \theta_k) & k = 1, \ldots, s \\ 0 & k = s+1, \ldots, d \end{cases}$$

where $f_k \sim U\{1, 2, 3, 4, 5\}$ are random integer frequencies and $\theta_k \sim U[0, 2\pi)$ are random phases, both drawn once per simulation, and $s \leq d$ is the number of **active dimensions** (the dimensions along which the curve has nonzero variation). The remaining $d - s$ dimensions receive only noise (see below).

Each agent is drawn at a random position $t_i \sim U[0,1]$ on the curve, then perturbed:

$$\mathbf{x}_i = \frac{\mathbf{x}(t_i) + \boldsymbol{\epsilon}_i}{\|\mathbf{x}(t_i) + \boldsymbol{\epsilon}_i\|}, \qquad \boldsymbol{\epsilon}_i \sim N\!\left(\mathbf{0}, \frac{\sigma_x^2}{d} \mathbf{I}_d\right)$$

The noise $\boldsymbol{\epsilon}_i$ is applied in all $d$ dimensions (including inactive ones), so that type vectors are not exactly confined to the $s$-dimensional subspace of the curve. The per-dimension noise scale $\sigma_x / \sqrt{d}$ is chosen so that the expected Euclidean distance from an agent to its curve position is approximately $\sigma_x$ regardless of $d$. The result is then re-projected to the unit sphere.

The parameter $s$ controls the complexity of the matching problem. When $s = d$, the curve spans all $d$ dimensions: agents nearby on the curve have similar types, while agents far apart point in genuinely different directions across all of $\mathbb{R}^d$. When $s < d$, the curve is confined to a lower-dimensional subspace.

#### Broker

A single broker serves the market. The broker is a permanent node in $G$, connected to all agents on its roster. The broker is characterized by:

- **Experience history** $\mathcal{H}_b^t = \{(\mathbf{x}_i, \mathbf{x}_j, q_{ij})\}$: the set of (demander type, counterparty type, realized match output) triples from all matches the broker has mediated (§2c).
- **Roster** $\text{Roster}^t$: the set of agents the broker knows and can propose as counterparties. Grows over time as agents outsource to the broker (§7).
- **Reputation** $\text{rep}^t$: the average satisfaction of current client agents (§6).

### 1. The Matching Problem

The model's central dynamics depend on a matching problem: how valuable will the match between agents $i$ and $j$ be? No agent knows the answer in advance; all must learn it from experience.

The structure of the matching problem and how the broker and agents try to solve it determines whether and when the broker develops an informational advantage over the agents it serves.

**Match quality** (§1a) is symmetric: $f(\mathbf{x}_i, \mathbf{x}_j) = f(\mathbf{x}_j, \mathbf{x}_i)$. Match quality is a property of the pairing, not of which party initiated the match. It decomposes into two components:

- **General quality** (§1b): each party's baseline contribution to any match, independent of who the other party is.
- **Match-specific interaction** (§1c): how well this particular pairing works, depending on both parties' types.

The broker, which mediates matches across many agents, observes the same agent types producing different outcomes with different counterparties; whereas each agent only sees its own matching history.

#### 1a. Match quality

Let $q_{ij}$ represent the **per-period value of the match between agents $i$ and $j$**. It is a function of both agents' types, it is measured in monetary units, and it represents the economic value the match generates:

$$q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}, \qquad
\varepsilon_{ij} \sim N(0, \sigma_\varepsilon^2)$$

where $Q = 1.0$ is a constant offset that shifts $q$ positive for downstream economic computations (surplus, fees, satisfaction), and $\sigma_\varepsilon = 0.10$. The noise term $\varepsilon_{ij}$ represents idiosyncratic match-specific variation (unobserved characteristics, timing, context) that is irreducible even with perfect knowledge of $f$.

The matching function $f: \mathbb{R}^d \times \mathbb{R}^d \to \mathbb{R}$ is unknown to all agents and fixed for the duration of the simulation. $f$ represents the pure signal structure of the data-generating process.

The deterministic matching function has two components, the first relating to each party's general quality and the second to their pairing complementarity:

$$f(\mathbf{x}_i, \mathbf{x}_j) = \rho \cdot \frac{1}{2}\!\left[\mathbf{x}_i^\top \mathbf{c} + \mathbf{x}_j^\top \mathbf{c}\right] + (1 - \rho) \cdot g(\mathbf{x}_i, \mathbf{x}_j) \cdot \mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j$$

where $\mathbf{c} \in \mathbb{R}^d$ is an ideal type vector (§1b), $\mathbf{A} \in \mathbb{R}^{d \times d}$ is a symmetric random interaction matrix (§1c), and $g(\mathbf{x}_i, \mathbf{x}_j)$ is a **regime-dependent gain** that modulates the interaction strength (§1c). The gain $g$ depends on a second symmetric random matrix $\mathbf{B}$ that determines whether a pairing is in a high-gain or low-gain regime. Because $\mathbf{A}$ and $\mathbf{B}$ are symmetric, $\mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j = \mathbf{x}_j^\top \mathbf{A} \mathbf{x}_i$ and $g(\mathbf{x}_i, \mathbf{x}_j) = g(\mathbf{x}_j, \mathbf{x}_i)$, so $f(\mathbf{x}_i, \mathbf{x}_j) = f(\mathbf{x}_j, \mathbf{x}_i)$.

The mixing weight $\rho$ (§1d) controls how much the general quality component contributes to total match output compared to the interaction component.

#### 1b. Agent general quality

General quality captures the portable value each party brings to any match, independent of who the counterparty is. Both parties contribute quality through their dot product with an **ideal type vector** $\mathbf{c} \in \mathbb{R}^d$. Agents whose types are aligned with $\mathbf{c}$ are high-quality counterparties in any match.

The vector $\mathbf{c}$ is drawn at initialization as a perturbation of a random point on the agent type curve with the same $\sigma_x / \sqrt{d}$ per-dimension noise used for regular agents.

A match between two high-quality agents produces a high quality component; a match involving a low-quality agent is penalized regardless of the other party's quality. 

#### 1c. Match-specific interaction

The match-specific interaction combines a base interaction with a regime-dependent gain: $g(\mathbf{x}_i, \mathbf{x}_j) \cdot \mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j$.

**Base interaction.** The bilinear form $\mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j$ measures the complementarity of the pairing. The interaction matrix $\mathbf{A} \in \mathbb{R}^{d \times d}$ is symmetric positive definite (SPD), constructed as $\mathbf{A} = \mathbf{M}_A^\top \mathbf{M}_A \cdot (d / \text{tr}(\mathbf{M}_A^\top \mathbf{M}_A))$ where $\mathbf{M}_A$ has iid $N(0,1)$ entries. The trace normalization ensures $\text{tr}(\mathbf{A}) = d$, so that $E[\mathbf{x}^\top \mathbf{A} \mathbf{x}] = 1$ for random unit vectors, keeping the bilinear form at unit scale. $\mathbf{A}$ is fixed for the duration of the simulation.

Because $\mathbf{A}$ is symmetric, $\mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j = \mathbf{x}_j^\top \mathbf{A} \mathbf{x}_i$, so the base interaction is symmetric without explicit symmetrization. Positive definiteness ensures $\mathbf{A}$ has full rank and well-conditioned eigenvalues, so the interaction structure spans all $d$ dimensions without degenerate directions. The interaction depends on all $d(d+1)/2$ distinct cross-dimensional products $x_{i,k} \cdot x_{j,l}$ (for $k \leq l$).

**Regime-dependent gain.** A second SPD matrix $\mathbf{B} \in \mathbb{R}^{d \times d}$ (independent of $\mathbf{A}$, same construction including trace normalization) determines a gain that amplifies or attenuates the base interaction:

$$g(\mathbf{x}_i, \mathbf{x}_j) = 1 + \delta \cdot \text{sign}(\mathbf{x}_i^\top \mathbf{B} \mathbf{x}_j)$$

where $\delta \in (0, 1)$ (default 0.5) controls the gain strength. Because $\mathbf{B}$ is symmetric, $g(\mathbf{x}_i, \mathbf{x}_j) = g(\mathbf{x}_j, \mathbf{x}_i)$. Pairings divide into two regimes: when $\mathbf{x}_i^\top \mathbf{B} \mathbf{x}_j > 0$, the gain is $(1 + \delta)$ (high-gain regime); when $\mathbf{x}_i^\top \mathbf{B} \mathbf{x}_j < 0$, the gain is $(1 - \delta)$ (low-gain regime). At $\delta = 0.5$, the high-gain interaction is three times the low-gain interaction.

The gain modulates the *strength* of the base interaction without changing its sign. Among pairings with similar base interactions $\mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j$, those in the high-gain regime are worth substantially more than those in the low-gain regime. This difference is the source of the broker's informational advantage (§1e).

#### 1d. What controls the nature of the matching problem

- **$s$ (active dimensions).** When $s = d$, the type curve spans all $d$ dimensions, creating maximum diversity in the type space and the interaction effects that depend on it. When $s < d$, the curve is confined to a lower-dimensional subspace.

- **$\rho$ (mixing weight).** At high $\rho$, general quality dominates. At low $\rho$, the gain-modulated interaction dominates.

- **$\delta$ (gain strength).** Controls the magnitude of the regime effect. At $\delta = 0$, the gain is 1 for all pairings and the DGP reduces to a simple interaction without regimes. At $\delta > 0$, the true interaction results from a mixture of two regimes. Larger $\delta$ produces a larger gap between high-gain and low-gain pairings, making the regime more consequential for match rankings.

- **$\mathbf{A}$ and $\mathbf{B}$ (interaction and regime matrices).** $\mathbf{A}$ determines the base interaction structure; $\mathbf{B}$ determines the regime boundary. Both are symmetric positive definite $d \times d$ matrices drawn independently at initialization. For a fixed agent $i$, the base interaction $\mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j = \mathbf{a}_i^\top \mathbf{x}_j$ (where $\mathbf{a}_i = \mathbf{A} \mathbf{x}_i$) is linear in $\mathbf{x}_j$. The regime boundary ($\mathbf{b}_i^\top \mathbf{x}_j = 0$, where $\mathbf{b}_i = \mathbf{B} \mathbf{x}_i$) is along a *different direction* than the interaction.

- **$\sigma_\varepsilon$ (noise scale).** The match-level noise $\sigma_\varepsilon = 0.10$ should be interpreted relative to the actual variance of $f$, which depends on the parameter configuration. The typical magnitude of dot products on the unit sphere in $\mathbb{R}^d$ is $O(1/\sqrt{d})$. The effective signal-to-noise ratio should be measured empirically at initialization.

#### 1e. The information gap between single- and cross-agent data

The regime-dependent gain (§1c) creates an informational gap between single-agent and cross-agent data. This gap has three important characteristics:

1. The gap is inherent to the DGP, not purely model-related.

2. The gap is fundamental, not merely statistical.

    - A purely statistical advantage depends asymptotically on data volume only and erodes as agents accumulate data. A fundamental gap involve an identification problem that single-agent data cannot solve regardless of sample size.

3. The gap affects match selection.

    - Agents use predictions to select a best counterparty ($\arg\max$).
    - The gap causes single- and cross-agent data to produce *different rankings* among top candidates, not just more accurate point estimates or better predictions for candidates that would never selected.

These characteristics correspond to assumptions being made through model design.

**Why the regime creates a fundamental information gap.** For a fixed agent $i$, the gain-modulated interaction produces outcomes from a *mixture* of two linear functions of $\mathbf{x}_j$. Some partners are in the high-gain regime ($g = 1 + \delta$) and others in the low-gain regime ($g = 1 - \delta$), but it is hard for agent $i$ to determine which regime each match fell into. The regime boundary (where $\mathbf{b}_i^\top \mathbf{x}_j = 0$, with $\mathbf{b}_i = \mathbf{B}^\top \mathbf{x}_i$) is along a direction in $\mathbf{x}_j$ space that the agent does not know. 

The agent data is generated by the mixture:

$$q_{ij} \approx \begin{cases} (1 + \delta) \cdot \mathbf{a}_i^\top \mathbf{x}_j & \text{if } \mathbf{b}_i^\top \mathbf{x}_j > 0 \\ (1 - \delta) \cdot \mathbf{a}_i^\top \mathbf{x}_j & \text{if } \mathbf{b}_i^\top \mathbf{x}_j < 0 \end{cases}$$

(omitting the quality component and noise for clarity). 

A linear model $\boldsymbol{\beta}^\top \mathbf{x}_j$ fitted on this mixture learns an *average slope* that is systematically wrong for both regimes. To separate the two regimes, the agent needs to detect that the slope of the relationship between $\mathbf{x}_j$ and outcomes changes along the direction $\mathbf{b}_i$. This is an unsupervised change-point detection problem in $d$ dimensions that requires qualitatively more sophisticated analysis than simple linear regression, regardless of sample size.

**Why the broker can resolve the regime.** The broker observes $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ triples across many different pairings. The regime depends on $\mathbf{x}_i^\top \mathbf{B} \mathbf{x}_j$, which is a *bilinear* function of both types. The broker's network, taking $[\mathbf{x}_i; \mathbf{x}_j]$ as input (§2c), can learn that certain combinations of $(\mathbf{x}_i, \mathbf{x}_j)$ systematically produce higher or lower match quality, capturing the regime effect through the nonlinear interactions learned by its hidden layer. The regime boundary that is hidden from the individual agent (because it requires conditioning on $\mathbf{x}_i$, which is fixed in single-agent data) is *visible* in the broker's input (because $\mathbf{x}_i$ varies across observations in cross-agent data).

**Why the gap affects match selection.** The gain operates multiplicatively on the base interaction. Among an agent's candidates with a high true interaction component, some are in the high-gain regime and others in the low-gain regime. The agent's linear model, fitting the average slope, ranks these candidates similarly. But their true match qualities differ by a factor of $(1 + \delta) / (1 - \delta)$ (3:1 at $\delta = 0.5$). The broker, knowing the regime, can identify which top candidates are high-gain and rank them above the low-gain candidates. This produces *different selections* from the same candidate pool.

### 2. Learning

Each period, agents and the broker **fit** prediction models on their accumulated histories to learn from past outcomes, then **use** those models to rank candidates and make decisions. Models are fitted once per period (§9, Step 2.1), then used repeatedly during candidate evaluation and match formation (§9, Steps 2.2–3).

#### 2a. Architecture and fitting

Both agents and the broker use the same architecture: a fully-connected network with one hidden layer, ReLU activations, and a single linear output:

$$\hat{q}(\mathbf{z}) = \mathbf{w}_2^\top \text{ReLU}(\mathbf{W}_1 \mathbf{z} + \mathbf{b}_1) + b_2$$

where $\mathbf{z}$ is the input feature vector, $\mathbf{W}_1$ is the hidden-layer weight matrix, $\mathbf{b}_1$ is the hidden bias vector, $\mathbf{w}_2$ is the output-layer weight vector, and $b_2$ is the output bias. Neither agents nor the broker use hand-crafted features; both receive raw type vectors as input and learn the relevant structure from data.

**Fitting.** Each period, the network weights are updated by minimizing MSE using vanilla gradient descent on the full batch with a fixed learning rate $\eta_{lr}$ (default 0.03). No explicit regularization is applied: at the data scales the broker and agents accumulate, adding weight decay has no measurable effect on held-out fit, so it is omitted for simplicity.

**Initialization.** At $t = 0$ each network is trained from random weights for $E_{\text{init}}$ gradient steps (default 200) on its seed history. The output bias $b_2$ is initialized to $Q$ (the DGP offset, §1a) rather than zero so that an untrained network predicts the population-mean match quality. This avoids a large negative-bias artifact for fresh entrants whose network has not yet been trained, and is irrelevant for mature networks (the first training steps on any real data move $b_2$ to its fitted value). All other weights follow He initialization.

**Adaptive schedule.** The network is updated each period with warm start from the previous period's weights. The number of gradient steps adapts to the ratio of new observations to total history:

$$E_t = \max\!\left(50, \; \left\lceil E_{\text{init}} \cdot \frac{n_{\text{new}}}{n_{\text{total}}} \right\rceil\right)$$

where $n_{\text{new}}$ is the number of observations added this period and $n_{\text{total}} = |\mathcal{H}^t|$ is the current history size. The floor of 50 ensures that mature networks continue to receive enough gradient updates per period to converge close to the DGP's best-achievable fit, rather than stagnating far below it.

**Training window.** To avoid diluting new observations in a large full-batch gradient, each training period uses at most the $W = 500$ most recent observations from the agent's or broker's history. The warm start preserves what was learned from older data. This sliding window ensures that the gradient reflects recent experience while being large enough, after symmetry augmentation for the broker, to contain a representative cross-section of match types.

**Prediction.** Given a fitted network, the prediction for a candidate match is a single forward pass. An agent evaluates $\hat{q}_i(\mathbf{x}_j)$ for each candidate partner $\mathbf{x}_j$ and selects the candidate with the highest predicted quality ($\arg\max$). Because $f$ is symmetric, the same model serves both roles: evaluating potential counterparties (as demander) and evaluating incoming proposals (as counterparty). The broker evaluates $\hat{q}_b([\mathbf{x}_i; \mathbf{x}_j])$ for all (demander, available roster member) pairs and allocates greedily (§5b).

#### 2b. Agent $i$'s model

**History.** $\mathcal{H}_i^t = \{(\mathbf{x}_j, q_{ij})\}_{m=1}^{n_i}$ records the other party's type and the realized match output from every match $i$ has participated in, regardless of role. Because $f$ is symmetric (§1a), observations from both roles pool into a single history.

**Input and capacity.** The agent's network takes the partner's type as input: $\mathbf{z} = \mathbf{x}_j$ ($d = 8$ inputs). The hidden layer has $h_a = 16$ units. Total parameters: $h_a \cdot (d + 1) + (h_a + 1) = 161$.

**Why this architecture.** The regime-dependent gain (§1c) makes the agent's local prediction problem *piecewise linear*: for a fixed agent $i$, the target function is $f_i(\mathbf{x}_j) \approx (1 \pm \delta) \cdot \mathbf{a}_i^\top \mathbf{x}_j + \text{quality}$, with two different slopes on either side of a hyperplane boundary $\mathbf{b}_i^\top \mathbf{x}_j = 0$ that the agent does not know. A one-hidden-layer ReLU network is the natural function approximator for this structure: each ReLU unit computes a hinge function $\max(\mathbf{w}^\top \mathbf{x}_j + b, 0)$, and a small number of such units can represent piecewise linear functions with learned breakpoints.

With sufficient data, the network can in principle learn the piecewise linear structure. The ReLU units can discover the regime boundary as one of their activation thresholds. In practice, with sparse data, the network produces a smooth approximation that averages across regimes. As the agent accumulates observations, the approximation improves, but the identification problem persists: detecting a change in slope along an unknown direction in $\mathbb{R}^d$ from noisy data requires substantially more observations than fitting a single linear relationship.

#### 2c. Broker's model

**History.** $\mathcal{H}_b^t = \{(\mathbf{x}_i, \mathbf{x}_j, q_{ij})\}_{m=1}^{n_b}$ records both parties' types and the realized match output from every match the broker has mediated. Seeded at initialization from random roster member pairs (§11c).

**Input and capacity.** The broker's network takes both parties' types as input: $\mathbf{z} = [\mathbf{x}_i; \mathbf{x}_j]$ ($2d = 16$ inputs). The hidden layer has $h_b = 32$ units. Total parameters: $h_b \cdot (2d + 1) + (h_b + 1) = 577$. No hand-crafted features (such as outer products) are provided.

**Fitting.** The network must discover the bilinear interaction structure $\mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j$ and the regime boundary $\mathbf{x}_i^\top \mathbf{B} \mathbf{x}_j$ from the raw concatenated inputs. With 32 hidden ReLU units, the network has sufficient capacity to approximate these bilinear forms. Each unit computes a piecewise linear function of $[\mathbf{x}_i; \mathbf{x}_j]$ that can represent products of input components through interactions between units. 

To exploit the symmetry of $f$, the broker augments its training data by including both orderings of each observation: for each $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ in $\mathcal{H}_b$, the broker trains on both $[\mathbf{x}_i; \mathbf{x}_j]$ and $[\mathbf{x}_j; \mathbf{x}_i]$ with the same target $q_{ij}$. This doubles the effective training set and ensures the network learns that the two input slots are interchangeable.

**Data scope.** The broker learns only from matches it mediates. It does not observe outcomes of self-search matches. After a brokered match forms, the realized output $q_{ij}$ is observed by all parties involved (the two agents and the broker), and the broker adds $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$.

#### 2d. The asymmetry between agents and the broker

The broker's advantage has two components:

1. **More data.** The broker accumulates observations across all client agents, giving it far more training examples than any individual agent.

2. **Regime identification from cross-agent variation.** The regime-dependent gain (§1c) creates a mixture in each agent's data: some observations come from high-gain pairings and others from low-gain pairings. The broker, by observing the *same* partner types producing *different* outcomes with *different* agents, can detect the regime structure. The regime depends on the interaction between both parties' types ($\mathbf{x}_i^\top \mathbf{B} \mathbf{x}_j$), which is visible only when $\mathbf{x}_i$ varies across observations.

An agent learns "what kind of partner works well for me" from a small, agent-specific sample, but its model averages across regimes. The broker learns "what kind of pairings work well" from a large, cross-market sample where both parties' types vary. The broker's advantage is both informational (it can identify regimes that agents cannot) and statistical (it has more data).

### 3. Match Economics

Matches form when both parties expect positive gains from trade, following a heuristic version of the standard search-and-matching framework (Rogerson, Shimer & Wright, 2005).

#### 3a. Outside options

All agents share a common outside option $r$: the minimum per-period match value an agent requires to participate. Below this threshold, the agent prefers to remain unmatched. The outside option is calibrated at initialization:

$$r = 0.60 \cdot \bar{q}_{\text{cal}}$$

where $\bar{q}_{\text{cal}}$ is the mean match output computed from a Monte Carlo sample (§11c). The 0.60 calibration sets the outside option at 60% of average match value, producing a market where approximately 40% of match output is surplus available for gains from trade. A constant $r$ means the profitability comparison is the same for every counterparty.

#### 3b. Participation constraints

A match between demander $i$ and counterparty $j$ forms only if both parties predict positive gains:

- **Demander**: $\hat{q}_{i}(\mathbf{x}_j) > r$
- **Counterparty**: $\hat{q}_{j}(\mathbf{x}_i) > r$

When the broker proposes a match, it applies the constraint using its own prediction: $\hat{q}_b([\mathbf{x}_i; \mathbf{x}_j]) > r$. The counterparty still evaluates independently using its own model.

#### 3c. Search costs

The model includes two channel frictions with an intentional asymmetry. **Self-search** incurs a per-demand-slot search-effort cost $c_s$: each slot the agent attempts to fill through self-search bears that cost whether or not it is successfully matched. **Standard brokerage** instead incurs a contingent placement fee $\phi$: the fee is paid only on brokered matches that actually clear. Rather than calibrating the broker fee and self-search cost separately, the model uses a single **cost wedge** parameter $\Delta_c$ on the surplus scale $(\bar{q}_{\text{cal}} - r)$ and derives both channel costs from it:

$$
\phi = (0.15 + \Delta_c / 2)\cdot(\bar{q}_{\text{cal}} - r), \qquad
c_s = (0.15 - \Delta_c / 2)\cdot(\bar{q}_{\text{cal}} - r).
$$

The midpoint `0.15` is fixed, so the average channel cost is held constant while $\Delta_c$ controls the economically relevant difference $\phi - c_s$. At $\Delta_c = 0$, both frictions have the same scale. At the baseline $\Delta_c = 0.10$, the model uses $\phi = 0.20\cdot(\bar{q}_{\text{cal}} - r)$ and $c_s = 0.10\cdot(\bar{q}_{\text{cal}} - r)$. Larger $\Delta_c$ makes brokerage more expensive relative to self-search; at the upper bound $\Delta_c = 0.30$, self-search is free and the broker fee is $0.30\cdot(\bar{q}_{\text{cal}} - r)$.

The two frictions are independent of realized match quality. The self-search cost $c_s$ is charged on each demanded slot routed through self-search, whether or not that slot is filled. The broker fee $\phi$ is charged on each successful **standard** brokered placement. Under principal mode (§12), no $\phi$ is charged to the demander because the broker is no longer acting as a pure intermediary.

An economically important asymmetry in the illustrative markets is **search-risk transfer**. Self-search typically requires the agent to incur time, attention, or internal business-development costs for each sought transaction slot whether or not the search succeeds: calling dealers, screening counterparties, traveling to trade events, preparing offers, or canvassing foreign buyers. By contrast, broker compensation is often at least partly contingent on success: a broker or intermediary is usually paid when a transaction clears, not merely for having searched. In that sense, outsourcing shifts part of the risk of failed search from the agent to the intermediary. This creates a motive for brokerage that is distinct from pure informational superiority. Even when the broker and the agent were equally good at ranking counterparties, the broker could still be valuable by absorbing failed-search risk.

### 4. Network Structure and Turnover

Agents interact through a single undirected network $G$ that determines each agent's search opportunities and structural position.

#### 4a. Network initialization

$G$ is initialized as a small-world graph (Watts & Strogatz, 1998). Agents are arranged on a ring in random order, each connected to its $k = 6$ nearest neighbors on the ring, and each edge is rewired with probability $p_{\text{rewire}} = 0.1$. This produces the high clustering and short path lengths characteristic of small-world graphs. Agents are placed on the ring in random order (rather than, e.g., sorted by type) so that the initial network is not type-assortative: neighbors at $t = 0$ are representative of the broader population, which avoids inflating baseline match quality through an artificially favorable neighborhood structure. An optional PC1-sorted variant is retained for robustness checks.

The broker is a permanent node in $G$, connected to all roster members (edges added as agents join the roster, §7). The broker node has no type vector and is excluded from matching candidate pools, but is included in network measure computations (§10).

#### 4b. Match tie formation

Each realized match (whether through self-search or brokered) adds an undirected edge between the demander and counterparty in $G$, if one does not already exist. Ties persist unless one of the nodes exits, as former counterparties remain connected after their match dissolves. This is the only mechanism of network densification.

#### 4c. Agent turnover

Agents exit independently each period with probability $\eta$ (default 0.02), yielding an expected agent lifetime of 50 quarters (12.5 years).

Exiting agents are replaced by entrants with fresh types sampled from the curve at a random position $t \sim U[0,1]$ plus noise (same procedure as initialization), empty experience histories, self-satisfaction initialized from new neighbors' self-satisfaction (word-of-mouth), and broker-satisfaction set to the current broker reputation. The exiting agent's node in $G$ is removed (along with all its edges). 

The entrant is added to $G$ with $\lfloor k/2 \rfloor$ edges to agents sampled from the type neighborhood (probability $\propto \exp(-\|\mathbf{x}_{i'} - \mathbf{x}_j\|^2)$). Entrants join with fewer connections than the initial network degree $k$ to reflect the disadvantage of being new to a market: established agents have accumulated connections through prior matches, while entrants start with only a few type-similar contacts. New entrants with sparse networks are more likely to need the broker's matching service.

### 5. Search

At the start of each period, all $K$ slots are open. Each slot independently generates demand with probability $p_{\text{demand}}$ (default 0.50), so agent $i$ draws demand $d_i \sim \text{Binomial}(K,\; p_{\text{demand}})$. If $d_i > 0$, the agent chooses **one channel for the batch** of current-period demand (§6): self-search or broker. Conditional on that batch decision, the chosen channel attempts to fill up to $d_i$ slots. The same counterparty may be selected for multiple slots in the same period if it remains the highest-valued feasible candidate and both parties retain capacity.

#### 5a. Self-search

Agent $i$'s candidate pool has two components:

**Known neighbors.** Direct network neighbors in $G$ with available capacity ($K - |M_j^t| > 0$). The agent has matched with these agents before (every edge in $G$ comes from a prior match or from initialization). For each known neighbor $j$, the agent evaluates quality using the **average of realized outcomes** from prior matches with $j$: $\bar{q}_{ij} = \frac{1}{n_{ij}} \sum q_{ij}^{(m)}$, where $n_{ij}$ is the number of times $i$ and $j$ have matched. This is a direct empirical estimate, not a model prediction.

**Strangers.** $\min(n_s, |\text{eligible}|)$ agents sampled uniformly from the population (excluding current neighbors, current matches, and the broker node), where $n_s = 5$ (default) and eligible agents are those with available capacity. The agent has no prior history with these candidates and evaluates them using its **prediction model**: $\hat{q}_i(\mathbf{x}_j)$ (§2b). Strangers represent cold outreach: attending trade events, browsing listings, or following up on indirect referrals.

The candidate pool is built once per agent-period and then reused across that agent's requested slots. Within the batch, self-search tracks temporary remaining capacities for candidate counterparties: after a candidate is selected for one slot, its available capacity for that agent's remaining slots falls by one. The agent selects the feasible candidate with the highest evaluated quality (whether from history or prediction), provided the participation constraint is satisfied: the evaluation exceeds $r$ (§3b). If no feasible candidate clears the threshold, no proposal is recorded for that slot. Because this temporary capacity accounting is local to agent $i$'s batch, the agent does **not** internalize competing proposals from other agents until the global match-formation step.

The proposal enters the match formation step (§9, Step 3), where all proposals from both channels are processed sequentially in random order. The counterparty evaluates the proposal using its own model (for strangers) or historical average (for known neighbors), accepting if the evaluation exceeds $r$ (§3b) and it has not already been matched this period.

#### 5b. Broker-mediated search

When agent $i$ outsources to the broker, the broker includes agent $i$ in its allocation for the current period. Agent $i$ is also added to the broker's roster if not already a member (§7).

At the end of Step 1 (after all outsourcing decisions), the broker observes its full client list $D^t$ (the set of demanders who outsourced this period) and the available roster members $\text{Roster}^t \cap \{\text{agents with available capacity}\}$. The broker computes predicted match quality $\hat{q}_b([\mathbf{x}_i; \mathbf{x}_j])$ for every (demander, available roster member) pair and assigns matches using a greedy best-pair heuristic (§9, Step 2.3): iteratively select the highest-quality feasible pair, propose that match, and decrement the remaining demand of $i$ and the remaining capacity of $j$. If both remain positive, the same pair can be selected again on a later iteration. This continues until all outsourced demand is exhausted, the roster is exhausted, or no remaining pair has positive predicted surplus ($\hat{q}_b > r$). The broker applies the same participation constraint as self-search: it does not propose matches with non-positive predicted surplus.

Proposals enter the match formation step (§9, Step 3) alongside self-search proposals. The counterparty evaluates using its own model (§3b).

Agents whose demand is not filled (because the roster was exhausted, no candidate cleared the surplus threshold, or the counterparty rejected) receive no proposal. The agent's broker satisfaction decays toward zero (§6a).

### 6. The Outsourcing Decision

A **calibration reference** $\bar{q}_{\text{cal}} = E[q]$ is computed once at initialization from a Monte Carlo sample of random agent pairs (§11c). This is the unconditional mean match output, used to scale the reservation value $r$, broker fee $\phi$, and self-search cost $c_s$ (§11b). It is not used to initialize satisfaction indices or broker reputation; those are initialized from actual seed data (see below).

#### 6a. Satisfaction tracking

Each agent $i$ maintains a satisfaction index $s_{i,c}^t$ for each search channel $c \in \{\text{self}, \text{broker}\}$. These scores summarize past matching outcomes and drive the outsourcing decision.

The index is an exponentially weighted moving average (recency weight $\omega = 0.3$) of realized match value, net of search costs:

$$s_{i,c}^{t+1} = (1 - \omega)\,s_{i,c}^t + \omega \cdot \tilde{q}$$

where $\tilde{q}$ is the satisfaction input for the period. The averaging unit is the agent's **requested slot demand** $d_i$: realized outcomes from accepted matches are summed, unfilled slots contribute zero output, and the total is divided by $d_i$. This makes partial fill mechanically lower satisfaction relative to full fill.

| Channel | Satisfaction input $\tilde{q}$ |
|---------|-------------------------------|
| Self-search | $\dfrac{\sum q_{ij} - c_s \cdot d_i}{d_i} = \dfrac{\sum q_{ij}}{d_i} - c_s$, summing over accepted self-search slots |
| Standard brokered (base model) | $\dfrac{\sum (q_{ij} - \phi)}{d_i}$, summing over accepted brokered slots |
| Broker channel under principal mode (M1, §12) | $\dfrac{\sum_{\text{standard}} (q_{ij} - \phi) + \sum_{\text{principal}} q_{ij}}{d_i}$ |

This implies an intentional asymmetry in total-failure episodes. If a brokered batch fails completely, then $\tilde{q}=0$ and broker satisfaction decays toward zero. If a self-search batch fails completely, then $\tilde{q}=-c_s$ because the per-slot search effort was paid despite filling no slot. Satisfaction indices are not floored: they can go negative. The EWMA's recency weighting ensures recovery from negative values within a few good observations.

**Initialization from seed data.** At initialization, each agent's self-satisfaction is set to the mean of its seed match outcomes (§11c, step I.10), not to an arbitrary constant. Each agent's broker-satisfaction is set to the broker's seed-data reputation (§6c). This grounds the initial outsourcing decision in actual data: agents with good neighbors start with high self-satisfaction and are harder for the broker to recruit, while agents with poor neighbors are more open to outsourcing.

**Fresh entrants.** New agents entering via turnover (§4) initialize self-satisfaction as the mean of their new neighbors' self-satisfaction (word-of-mouth: the entrant inherits the local opinion about self-search quality). Broker-satisfaction is set to the current broker reputation (the market's current opinion). The `tried_broker` flag is false, so the entrant uses broker reputation for its first outsourcing decision.

**`tried_broker` flag semantics.** The flag flips from false to true the first time the agent chooses the broker channel for any demand in a period, regardless of whether the broker's proposal led to a successful placement. Once true, the agent uses its own $s_{i,\text{broker}}^t$ rather than the broker's reputation for subsequent decisions (§6b). The rationale is that after selecting the broker once, the agent's personal EWMA has started to absorb information about that channel, including failed broker episodes that update satisfaction through a zero realized input, so reputation stops being the better signal.

#### 6b. Decision rule

Each period, an agent with $d_i$ demand slots compares three scores:

- **$\text{score}_{\text{self}}$** $= s_{i,\text{self}}^t$: the EWMA satisfaction from past self-search outcomes.
- **$\text{score}_{\text{known}}$**: the net value of directly using the agent's best known partners under the self-search channel. Computed as: sort all neighbors $j$ in $G$ that have capacity and a known `partner_mean`, take the top $d_i$ values, average them using denominator $d_i$ (so missing slots dilute the score), and subtract the per-slot self-search cost $c_s$. This preserves the same slot-weighted scale as §6a: if the agent needs 3 slots but only knows 1 good partner, the missing slots dilute the average.
- **$\text{score}_{\text{broker}}$** $= s_{i,\text{broker}}^t$ if the agent has tried the broker, otherwise the broker's reputation $\text{rep}_b^t$.

The agent outsources if $\text{score}_{\text{broker}} > \max(\text{score}_{\text{self}}, \text{score}_{\text{known}})$; it self-searches if $\text{score}_{\text{broker}} < \max(\text{score}_{\text{self}}, \text{score}_{\text{known}})$. At the boundary $\text{score}_{\text{broker}} = \max(\text{score}_{\text{self}}, \text{score}_{\text{known}})$, the channel is chosen by a uniform coin flip between self-search and broker (a tie between $\text{score}_{\text{self}}$ and $\text{score}_{\text{known}}$ alone does not require resolution, as both map to the self-search channel).

The $\text{score}_{\text{known}}$ term ensures that agents who have discovered good partners (including through prior broker introductions) recognize they can reach those partners directly, but must still bear the per-slot cost of doing so. The broker must offer value beyond what the agent's known partners provide: either finding better counterparties, filling demand slots that known partners cannot, or absorbing failed-search risk that self-search leaves with the agent.

The search-risk-transfer asymmetry sharpens this comparison. Self-search exposes the agent to the risk of paying for effort on requested slots that yield no placement, whereas standard brokerage shifts more of that downside onto the intermediary because compensation is tied more closely to successful matching. As a result, outsourcing can be attractive not only because the broker has better information or broader access, but also because it converts some search cost from a non-contingent expenditure into a contingent payment. This mechanism is especially relevant for agents facing uncertain fill rates, sparse networks, or highly lumpy demand.

**Initial conditions.** Self-satisfaction is initialized from each agent's seed match outcomes (mean of 5 neighbor pairings). Broker-satisfaction is initialized to the broker's seed-data reputation (mean of 100 seed broker match outcomes). Both values are grounded in actual data, not an arbitrary constant. Since the broker's seed reputation and the typical agent's seed self-satisfaction are close but not identical, the first period's outsourcing decisions reflect genuine (if noisy) differences in local match quality rather than a symmetric coin flip. Agents with above-average self-satisfaction prefer self-search; those with below-average self-satisfaction are more open to outsourcing. The broker's early client base is thus self-selected rather than random.

#### 6c. Broker reputation

$$\text{rep}_b^{t+1} = \begin{cases} \frac{1}{|D_b^t|} \sum_{i \in D_b^t} s_{i,b}^{t+1} & \text{if } D_b^t \neq \emptyset \\[4pt] \text{rep}_b^{t} & \text{otherwise} \end{cases}$$

where $D_b^t$ is the set of agents who outsourced to the broker this period. When the broker has current clients, reputation is updated to the mean of their (post-update) broker satisfaction. When it has no clients, the value is held from the previous period. Reputation is initialized from the mean of the broker's seed match outcomes (§11c, step I.9).

### 7. Broker Roster

The broker maintains a **roster** of agents it knows and can propose as counterparties when mediating matches.

**Initialization.** The roster is seeded with $\lceil 0.20 \cdot N \rceil$ agents (default 200 at $N = 1000$) chosen uniformly at random from the population. This ensures the broker can serve early outsourcers without frequent no-match failures that would drive broker satisfaction down before the broker has a chance to demonstrate value. The broker's history is seeded with observations from random roster member pairs in $G$ (§11c).

**Roster membership with lag.** Each agent $i$ records $t_i^{\text{out}}$, the most recent period in which it outsourced to the broker. At the start of each period (after outsourcing decisions are taken, §9, Step 1.3), the roster is rebuilt as

$$\text{Roster}^t = \{i : t_i^{\text{out}} > 0 \text{ and } t - t_i^{\text{out}} \leq L\},$$

where $L$ is the **roster lag** (structural constant, default $L = 4$). Broker edges in $G$ are added and removed to mirror this set. An agent that outsources in period $t$ is placed on the roster immediately; an agent that last outsourced more than $L$ periods ago drops off. This rule decouples roster membership from the current-period outsourcing decision: a recent broker client remains on the roster for a few periods even if it self-searches or has no demand in the interim, smoothing "dry periods" when a known client has no new demand, and retaining recent contacts as available counterparties. Because $L$ is finite, the roster does not accumulate monotonically: inactive agents age out automatically.

**Availability.** A roster member is available as a counterparty in a given period if it has spare capacity ($|M_j^t| < K$). An agent may act as both a demander (seeking matches for its own slots) and a counterparty (being matched with other demanders) in the same period, provided it still has open slots. Self-matches are excluded: the broker never matches an agent with itself.

### 8. Match Lifecycle

Matches are transactional within a period. Once a match forms, it occupies one slot for each side for the remainder of that period, both parties observe the realized match output immediately, and all slots reopen before the next period begins.

**At match formation:**
1. Realized output is drawn: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$.
2. Both parties add the observation to their histories: the demander adds $(\mathbf{x}_j, q_{ij})$ to $\mathcal{H}_{i}$; the counterparty adds $(\mathbf{x}_i, q_{ij})$ to $\mathcal{H}_{j}$.
3. If brokered, the broker adds $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$.
4. An edge is added between $i$ and $j$ in $G$ (if not already present).

**Before the next period begins:** clear the current-period match lists $M_i^t$ and $M_j^t$. Both sides regain the slot, so all $K$ slots are open again at the start of the next period.

### 9. Base Model Pseudocode

At the start of the simulation, the state of the world must be initialized.

> **INITIALIZE**
>
> *Agent types and matching function.*
> I.1. &emsp;Generate random frequencies $f_k$ and phases $\theta_k$ for the sinusoidal curve (§0).
> I.2. &emsp;Draw $N$ agent types: each at a random position $t_i \sim U[0,1]$ on the curve, perturbed by noise, and projected to the unit sphere.
> I.3. &emsp;Draw ideal type $\mathbf{c}$ (perturbation of a random curve position).
> I.4. &emsp;Draw SPD interaction matrix $\mathbf{A} = \mathbf{M}_A^\top \mathbf{M}_A \cdot (d / \text{tr}(\mathbf{M}_A^\top \mathbf{M}_A))$ and SPD regime matrix $\mathbf{B}$ (same construction), where $\mathbf{M}_A, \mathbf{M}_B \in \mathbb{R}^{d \times d}$ have iid $N(0,1)$ entries. Trace normalization ensures unit-scale bilinear forms. Drawn independently.
>
> *Calibration.*
> I.5. &emsp;Compute $\bar{q}_{\text{cal}} = E[q]$ from 10,000 random agent pairs $(i, j)$ with $i, j$ drawn independently and uniformly from $\{1, \ldots, N\}$ (self-pairs $i = j$ are not filtered; at $N = 1000$ the resulting bias is $O(1/N)$ and negligible). Set $r \leftarrow 0.60 \cdot \bar{q}_{\text{cal}}$.
> I.6. &emsp;Set channel costs from the cost wedge $\Delta_c$: $\phi \leftarrow (0.15 + \Delta_c / 2)\cdot(\bar{q}_{\text{cal}} - r)$ and $c_s \leftarrow (0.15 - \Delta_c / 2)\cdot(\bar{q}_{\text{cal}} - r)$ (§11b).
>
> *Network.*
> I.7. &emsp;Build $G$: Watts–Strogatz with $N$ nodes, degree $k$, rewiring $p_{\text{rewire}}$. Node order is random (non-assortative initial network).
>
> *Broker.*
> I.8. &emsp;Seed broker roster with $\lceil 0.20 \cdot N \rceil$ randomly chosen agents. Set $t_i^{\text{out}} \leftarrow 1$ for each seed roster member so they are eligible for the lag-based rebuild during the first few periods (§7). Non-roster agents are initialized with a non-positive sentinel (the roster test $t_i^{\text{out}} > 0$ treats any such value as "never outsourced"; the implementation uses $-1000$ at initialization and resets to $0$ on exit). Add broker-agent edges to $G$ for each roster member.
> I.9. &emsp;Seed broker history $\mathcal{H}_b$ with 100 observations drawn from random pairs of distinct roster members (sampling from the roster directly, not from pre-existing edges in $G$). For each sampled pair $(i, j)$, realize $q_{ij}$, append $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$, and add the edge $(i, j)$ to $G$ (the broker's seed placement creates the tie, mirroring the regular match flow in §4b).
>
> *State variables.*
> I.10. &emsp;For each agent $i$: seed $\mathcal{H}_{i}$ with 5 pairings sampled from $i$'s neighbors in $G$. For each sampled neighbor $j$, realize $q_{ij}$ and record $(\mathbf{x}_j, q_{ij})$ in $\mathcal{H}_i$ along with the corresponding `partner_mean` update for $j$. Seed observations are recorded only in the sampling agent's history (so the counterparty $j$ is not credited with this draw in $\mathcal{H}_j$); agents independently seed their own histories from their own neighborhoods. $M_i^0 \leftarrow \emptyset$.
> I.11. &emsp;Broker reputation from seed data: $\text{rep}^0 \leftarrow \text{mean}(\mathcal{H}_b)$. Agent satisfaction from seed data: $s_{i,\text{self}}^0 \leftarrow \text{mean}(\mathcal{H}_i)$; $s_{i,\text{broker}}^0 \leftarrow \text{rep}^0$.
>
> *Initial model training.*
> I.12. &emsp;For each agent $i$: train neural network on $\mathcal{H}_i$ for $E_{\text{init}}$ GD steps from random weights (§2a).
> I.13. &emsp;Train broker's neural network on $\mathcal{H}_b$ (symmetry-augmented) for $E_{\text{init}}$ GD steps from random weights (§2c).

Each period proceeds through six steps (plus recording).

> **PERIOD $t$:**
>
> **0. CURRENT-PERIOD MATCH RESET**
> 0.1. &emsp;For each agent $i$: set $M_i^t \leftarrow \emptyset$, so all $K$ slots are open at the start of period $t$.
>
> **1. DEMAND GENERATION AND OUTSOURCING DECISIONS**
> 1.1. &emsp;For each agent $i$: draw demand count $d_i \sim \text{Binomial}(K,\; p_{\text{demand}})$.
> 1.2. &emsp;For each agent $i$ with $d_i > 0$:
> &emsp;&emsp;Compute $\text{score}_{\text{self}}, \text{score}_{\text{known}}, \text{score}_{\text{broker}}$ as in §6b.
> &emsp;&emsp;$\text{decision}_i \leftarrow \text{broker}$ if $\text{score}_{\text{broker}} > \max(\text{score}_{\text{self}},\; \text{score}_{\text{known}})$; else $\text{self}$. Ties broken uniformly at random. (Channel choice applies to all $d_i$ slots.)
> &emsp;&emsp;If $\text{decision}_i = \text{broker}$: set $t_i^{\text{out}} \leftarrow t$ (§7).
> 1.3. &emsp;Rebuild broker roster: $\text{Roster}^t \leftarrow \{i : t_i^{\text{out}} > 0 \text{ and } t - t_i^{\text{out}} \leq L\}$ (§7). Add broker-agent edges in $G$ for new roster members; remove edges for agents that aged out.
> &emsp;Output: for each demander, channel choice and demand count $d_i$. Broker client list $D^t$ with per-agent demand counts. Current roster $\text{Roster}^t$.
>
> **2. CANDIDATE EVALUATION**
>
> &emsp;**2.1. Fit prediction models:**
> 2.1.1. &emsp;For each agent $i$ whose parity matches the current period ($i \bmod 2 = t \bmod 2$): update neural network on $\mathcal{H}_{i}^t$ (§2b). Warm start; $E_t = \max(50, \lceil E_{\text{init}} \cdot n_{\text{new}} / n_i \rceil)$ GD steps on the sliding window of the most recent $W = 500$ observations. No regularization. Agents not selected in period $t$ keep accumulating $n_{\text{new}}$ observations and retrain the next period.
> 2.1.2. &emsp;Update broker's neural network on $\mathcal{H}_b^t$ with symmetry-augmented data (§2c). Same adaptive schedule and window. No regularization.
>
> &emsp;**2.2. Self-searches:**
> 2.2.1. &emsp;For each agent $i$ with $\text{decision}_i = \text{self}$:
> &emsp;&emsp;Build candidate pool (once per agent, shared across all $d_i$ slots):
> &emsp;&emsp;&emsp;**Known neighbors:** direct neighbors of $i$ in $G$ with available capacity. Evaluate each using average of realized outcomes: $\bar{q}_{ij}$.
> &emsp;&emsp;&emsp;**Strangers:** sample $\min(n_s, |\text{eligible}|)$ agents uniformly from non-neighbors with available capacity (excluding broker node). Evaluate each using prediction model: $\hat{q}_i(\mathbf{x}_j)$.
> &emsp;&emsp;Initialize temporary remaining capacity for each candidate from its current-period free slots.
> &emsp;&emsp;For each of $i$'s $d_i$ demand slots: select the feasible $j^* = \arg\max$ over the candidate pool (ties broken randomly); if best evaluation $\leq r$, skip this slot; else record proposed match $(i, j^*)$ and decrement $j^*$'s temporary remaining capacity by one. The same $j^*$ may be selected for multiple slots if it remains feasible and best-valued.
>
> &emsp;**2.3. Broker proposals:**
> 2.3.1. &emsp;Collect client list: $D^t = \{i : \text{decision}_i = \text{broker}\}$.
> 2.3.2. &emsp;$\text{available\_roster} \leftarrow \text{Roster}^t \cap \{\text{agents with available capacity}\}$.
> 2.3.3. &emsp;Compute quality matrix: $\hat{Q}[i,j] = \hat{q}_b([\mathbf{x}_i; \mathbf{x}_j])$ for all $i \in D^t$, $j \in \text{available\_roster}$, $i \neq j$ (self-matches excluded).
> 2.3.4. &emsp;While $D^t$ non-empty AND available\_roster non-empty:
> &emsp;&emsp;$(i^*, j^*) = \arg\max \hat{Q}[i,j]$ &ensp;(implementation sorts $(-\hat{Q}[i,j], \text{flat index})$ once and iterates in that order; ties in $\hat{Q}$ are broken deterministically by flat index to keep runs reproducible under seed)
> &emsp;&emsp;If $\hat{Q}[i^*, j^*] \leq r$: break (no remaining pair has positive surplus)
> &emsp;&emsp;Record proposed match $(i^*, j^*)$
> &emsp;&emsp;Decrement $i^*$'s remaining demand by one. Decrement $j^*$'s available capacity by one. If both remain positive, the pair may be selected again on a later iteration.
> 2.3.5. &emsp;If $D^t$ non-empty (roster exhausted or no surplus-positive pair): for each remaining $i \in D^t$, mark as no-proposal.
>
> **3. MATCH FORMATION**
>
> &emsp;**3.1. Sequential acceptance:**
> 3.1.1. &emsp;Shuffle all proposed matches (from both self-search and broker) into random order.
> 3.1.2. &emsp;For each proposed match $(i, j)$ in order:
> &emsp;&emsp;If demander $i$ has no available capacity: skip (capacity consumed by earlier accepted proposals, including proposals where $i$ was a counterparty).
> &emsp;&emsp;If counterparty $j$ has no available capacity: skip.
> &emsp;&emsp;Counterparty $j$ evaluates: $\bar{q}_{ji}$ (historical average) if $i$ is a neighbor of $j$, else $\hat{q}_{j}(\mathbf{x}_i)$ (prediction model).
> &emsp;&emsp;If evaluation $\leq r$: reject.
> &emsp;&emsp;Else: accept. Decrement both $i$'s and $j$'s available capacity by one.
>
> &emsp;**3.2. Finalization** (for each accepted match $(i, j)$):
> 3.2.1. &emsp;Realize output: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$.
> 3.2.2. &emsp;Add match to active match lists: append $j$ to $M_i^{t+1}$; append $i$ to $M_j^{t+1}$. (The same pair may appear multiple times if they have concurrent matches.)
> 3.2.3. &emsp;Add edge $(i, j)$ to $G$ if not already present.
> 3.2.4. &emsp;Record: channel (self/broker), $q_{ij}$, predictions used, whether $j$ was a direct neighbor of $i$ in $G$.
>
> **4. LEARNING AND STATE UPDATES**
> 4.1. &emsp;For each finalized match $(i, j)$:
> &emsp;&emsp;Add $(\mathbf{x}_j, q_{ij})$ to $\mathcal{H}_{i}$ (demander's history).
> &emsp;&emsp;Add $(\mathbf{x}_i, q_{ij})$ to $\mathcal{H}_{j}$ (counterparty's history).
> &emsp;&emsp;If brokered: add $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$.
>
> 4.2. &emsp;Update satisfaction indices (§6a):
> &emsp;&emsp;For each agent $i$ with $d_i > 0$, let $c$ be $i$'s chosen channel:
> &emsp;&emsp;&emsp;Sum realized outputs over $i$'s accepted matches through $c$; unfilled slots contribute zero.
> &emsp;&emsp;&emsp;If $c = \text{self}$: compute $\tilde{q} = (\sum q_{ij} - c_s \cdot d_i) / d_i = \sum q_{ij}/d_i - c_s$.
> &emsp;&emsp;&emsp;If $c = \text{broker}$ in the base model: compute $\tilde{q} = \sum (q_{ij} - \phi) / d_i$ over accepted brokered slots.
> &emsp;&emsp;&emsp;Update: $s_{i,c}^{t+1} = (1 - \omega)\, s_{i,c}^t + \omega \cdot \tilde{q}$.
>
> 4.3. &emsp;Update broker reputation (§6c):
> &emsp;&emsp;If $|D^t| > 0$: $\text{rep}^{t+1} \leftarrow \text{mean of } s_{i,\text{broker}}^{t+1} \text{ over } i \in D^t$.
> &emsp;&emsp;Else: $\text{rep}^{t+1} \leftarrow \text{rep}^{t}$ (hold previous value).
>
> **5. ENTRY AND EXIT**
> 5.1. &emsp;For each agent $i$:
> &emsp;&emsp;With probability $\eta$: agent exits.
> &emsp;&emsp;&emsp;Remove $i$ from $G$ (node and all edges).
> &emsp;&emsp;&emsp;Terminate all active matches involving $i$; counterparties regain capacity.
> &emsp;&emsp;&emsp;Remove $i$ from broker roster (if present); reset $t_i^{\text{out}} \leftarrow 0$ so the entrant will not be treated as a recent broker client.
> &emsp;&emsp;&emsp;Replace with entrant $i'$: fresh type from curve + noise; empty histories; added to $G$ with $\lfloor k/2 \rfloor$ edges to type-similar agents ($\propto \exp(-\|\mathbf{x}_{i'} - \mathbf{x}_j\|^2)$). Self-satisfaction $\leftarrow$ mean of new neighbors' self-satisfaction; broker-satisfaction $\leftarrow$ current broker reputation (§6a).
>
> **6. RECORDING AND MEASUREMENT**
> 6.1. &emsp;Record period aggregates: match quality by channel; outsourcing rate (outsourced slots / total demand slots); roster size.
> 6.2. &emsp;Record broker state: reputation $\text{rep}^t$; roster size; $|\mathcal{H}_b^t|$.
> 6.3. &emsp;Compute per-agent averaged holdout prediction quality ($R^2$, bias, rank correlation) for broker and agents (§10), excluding fresh entrants with no match history. This runs every period because the cost is small (≈4,000 NN forward passes) and finer time resolution benefits the headline figures that track the informational gap over time.
> 6.4. &emsp;Every $M$ periods (default $M = 20$): compute network measures on $G$ (§10): betweenness centrality $C_B(b)$; Burt's constraint (broker's ego network); effective size (broker's ego network). The $M$-period cadence reflects the cost of Brandes BFS on the full graph, not a conceptual alignment with holdout measurement.

#### Parallelism summary

Steps 0 and 1 are embarrassingly parallel across agents. Step 2.2 (self-searches) is parallel across agents. Step 3 requires a conflict resolution pass but per-match computations are parallel. Steps 4–5 involve writes to shared state that require synchronization, but writes are non-overlapping (each match writes to distinct agent records). Network measures are the most expensive single computation; they read the full state but write nothing and can be offloaded to a separate thread or deferred to a coarser schedule.

### 10. Performance Measures

Computed on $G$ (which includes the broker as a permanent node; §4a) each measurement period. No agent uses these measures in its decisions; they are outputs for analysis.

#### Network measures

**Betweenness centrality.** Standard Freeman betweenness (Freeman, 1977) computed on $G$ using the Brandes (2001) algorithm adapted for single-node computation on undirected unweighted graphs. Neighbor iteration uses a compressed sparse row (CSR) adjacency structure built once per measurement call, with pre-allocated per-thread BFS workspaces for allocation-free parallel execution. The broker's betweenness is the fraction of all shortest paths that pass through the broker node, with the standard undirected normalization:

$$C_B(b) = \frac{1}{(n-1)(n-2)} \sum_{s \neq b} \sum_{t \neq s} \frac{\sigma_{st}(b)}{\sigma_{st}}$$

where $n = N+1$, $\sigma_{st}$ is the number of shortest paths from $s$ to $t$, and $\sigma_{st}(b)$ is the number passing through $b$. The double sum counts each undirected pair from both directions; dividing by $(n-1)(n-2)$ rather than $\binom{n}{2}$ corrects for this double-counting (Brandes, 2001, p. 9). As matches create direct ties, shortest paths increasingly bypass the broker, reducing betweenness: the structural erosion that the theory predicts.

**Burt's constraint.** Computed on the broker's ego network (Burt, 1992):

$$C_b = \sum_j \left(p_{bj} + \sum_{h \neq b,j}
p_{bh}\, p_{hj}\right)^2$$

where $p_{bj} = 1/d_b$ is the proportion of the broker's ties invested in node $j$ (for the unweighted network), and $p_{kj} = 1/d_k$ is the proportion of intermediary $k$'s ties invested in $j$ (Everett & Borgatti, 2020). Note that the indirect term uses the intermediary's degree, not the ego's. Low constraint = broker spans structural holes. High constraint = broker's contacts are interconnected.

**Effective size.** The number of non-redundant contacts in the broker's ego network. Using the Borgatti (1997) simplification for binary undirected networks: $\text{ES}_b = d_b - 2t_b / d_b$, where $d_b$ is the broker's degree and $t_b$ is the number of ties among the broker's neighbors (not counting ties to the broker). Equivalently: $\text{ES}_b = |N(b)| - \sum_j p_{bj} \sum_{h \neq b, h \in N(b)} m_{jh}$ where $p_{bj} = 1/d_b$ and $m_{jh} = 1$ if $j$ and $h$ are connected.

#### Prediction quality

**Winner's curse / selection bias.** Both agents and the broker select the counterparty with the highest *predicted* match quality from their candidate set ($\arg\max_j \hat{q}_{ij}$). When predictions are noisy, the selected counterparty's prediction $\hat{q}_{ij^*}$ is systematically inflated relative to the true match quality $f(\mathbf{x}_i, \mathbf{x}_{j^*})$, because the selection picks up positive noise realizations. This is the classic winner's curse.

**Holdout $R^2$ (model quality).** Each period, 100 agents are sampled at random (excluding fresh entrants with no match history). For each sampled agent $i$, 40 random partners $j$ are drawn, and both agent $i$'s neural network and the broker's neural network predict the noiseless true match quality $f(\mathbf{x}_i, \mathbf{x}_j)$ for each partner. Per-agent $R^2$, bias, and rank correlation are computed for each model, then averaged across the sampled agents. Because both models are evaluated on the same agent-partner sets, the resulting metrics are directly comparable: any gap reflects the models' relative quality, not differences in evaluation samples.

**Selected-sample metrics.** Three metrics are computed each period over all matches formed through each channel (self-search or brokered) that period:

- *Selected $R^2$* $= 1 - \text{MSE}/\text{Var}(q)$. Because matched counterparties are those with the highest predictions, this sample is subject to the winner's curse: predictions are systematically inflated relative to outcomes, depressing $R^2$.

- *Bias* $= \frac{1}{n}\sum(\hat{q} - q)$. Tracks systematic over- or underprediction. Positive bias is expected in the selected sample due to the winner's curse.

- *Selected rank correlation* (Spearman's $\rho_S$). Measures whether the agent ranks matched counterparties correctly by realized output. The rank correlation is less affected by the winner's curse than $R^2$ because it is invariant to monotone transformations.

**Minimum variance threshold.** When $\text{Var}(q) < \sigma_\varepsilon^2 / 6 \approx 0.01$, the realized output variance in the sample is too small relative to the noise floor for $R^2$ to be informative. Below this threshold, all three metrics ($R^2$, bias, rank correlation) return NaN so that the row is treated uniformly as "insufficient signal" in downstream aggregation.

**Summary of prediction quality metrics:**

| Metric | What it measures | Selection bias? | Primary use |
|--------|-----------------|-----------------|-------------|
| Holdout $R^2$ | Model quality (approximation of $f$) | None (random sample, noiseless truth) | Informational advantage |
| Selected rank correlation | Matching decision quality (correct ordering) | Mild (order is more robust than level) | Allocation effectiveness |
| Selected $R^2$ | Prediction accuracy on actual matches | Strong (winner's curse) | Economic outcomes |

The broker-agent gap in holdout $R^2$ is the purest measure of the informational advantage. The gap in selected rank correlation shows whether the advantage translates into better matching decisions.

#### Other measures

**Access vs. assessment decomposition.** For each brokered match, record whether counterparty $j$ was a direct neighbor of demander $i$ in $G$ at the time of the match. If not: access value (the demander could not have found this counterparty through its own network). If yes: assessment value (the demander could have found this counterparty but the broker predicted match quality better).

**Match quality by channel.** Average realized match output $\bar{q}_c^t$ per period, where $c \in \{\text{self}, \text{brokered}\}$.

**Outsourcing rate.** Fraction of demand slots that are outsourced to the broker: outsourced slots / total demand slots. A demander-level outsourcing share (fraction of demanders choosing the broker channel) is retained as a secondary diagnostic in the code, but the slot share is the primary quantity because the model's demand object is the slot.

**Roster size.** Number of agents currently on the broker's roster (§7). Reflects the flow of recent broker clients: it rises with outsourcing activity and decays as agents age out after $L$ periods without outsourcing.

## Part II. Parameters, Calibration, and Initialization

### 11. Parameters

#### 11a. Parameter table

Parameters are organized into four categories reflecting their role in the analysis.

**Structural constants.** Define the model's mechanisms. Values are set by design rationale and not varied.

| Symbol | Meaning | Value | Notes |
|--------|---------|-------|-------|
| $d$ | Type dimensionality | 8 | Fixed |
| $k$ | Network mean degree | 6 | Watts-Strogatz ring lattice degree |
| $p_{\text{rewire}}$ | Network rewiring probability | 0.1 | Watts-Strogatz rewiring |
| $\omega$ | Satisfaction recency weight (§6a) | 0.3 | EWMA weight |
| $p_{\text{demand}}$ | Per-slot demand probability | 0.50 | All $K$ slots are open at period start; $d_i \sim \text{Binomial}(K, p_{\text{demand}})$ |
| $n_s$ | Max strangers in self-search | 5 | Sampled uniformly from non-neighbors with capacity |
| $\sigma_x$ | Type noise scale | 0.5 | Expected distance from agent to curve position |
| $L$ | Roster lag (§7) | 4 | Agent stays on broker roster this many periods after last outsourcing |

**Calibration parameters.** Set during model development. Constant in production runs.

| Symbol | Meaning | Default | Notes |
|--------|---------|---------|-------|
| $r$ | Outside option | $0.60 \cdot \bar{q}_{\text{cal}}$ | Constant for all agents; calibrated at initialization |
| $\eta_{lr}$ | Learning rate | 0.03 | Vanilla gradient descent, full-batch, no weight decay |
| $E_{\text{init}}$ | Initial training steps | 200 | Full convergence at initialization; in production periods each agent retrains every other period on a deterministic parity schedule, with steps $\max(50, \lceil E_{\text{init}} \cdot n_{\text{new}} / n_{\text{total}} \rceil)$ |
| $W$ | Training window | 500 | Train on at most $W$ most recent observations (sliding window) |
| $h_a$ | Agent hidden width | 16 | One hidden layer, ReLU activations |
| $h_b$ | Broker hidden width | 32 | One hidden layer, ReLU activations |
| $b_2^{(0)}$ | Initial output bias | $Q$ | Untrained networks predict population-mean quality rather than zero |
| $\sigma_\varepsilon$ | Match output noise SD | 0.10 | |
| $\delta$ | Regime gain strength (§1c) | 0.5 | $\delta = 0$: no regime effect; $\delta = 1$: maximum gain contrast |
| $\Delta_c$ | Broker-minus-self cost wedge | 0.10 | $\phi = (0.15 + \Delta_c/2)\cdot(\bar{q}_{\text{cal}} - r)$, $c_s = (0.15 - \Delta_c/2)\cdot(\bar{q}_{\text{cal}} - r)$; $c_s$ is a self-search cost per demanded slot, $\phi$ a successful standard-placement fee; §11b |

**Phase diagram axes.** Primary parameters of interest.

| Symbol | Meaning | Default | Sweep |
|--------|---------|---------|-------|
| $s$ | Active dimensions | 8 | {2, 4, 6, 8} |
| $\rho$ | Quality-interaction mixing weight | 0.50 | {0, 0.10, 0.30, 0.50, 0.70, 0.90, 1.0} |

**Model 1 parameters.** Apply only under resource capture (§12).

| Symbol | Meaning | Default | Notes |
|--------|---------|---------|-------|
| `enable_principal` | Resource capture toggle | false | When true, the broker can operate in principal mode using the smooth post-pairing threshold (§12c) |

**OAT sensitivity parameters.** Varied one at a time while holding all others at defaults.

| Symbol | Meaning | Default | Sweep | Notes |
|--------|---------|---------|-------|-------|
| $K$ | Match capacity | 5 | {1, 2, 5, 10, 20, 50} | Exclusive at $K = 1$; concurrent at $K > 1$ |
| $p_{\text{demand}}$ | Per-slot demand probability | 0.50 | {0.10, 0.25, 0.50, 0.75, 0.90} | Higher values produce a thicker, faster-moving market |
| $\eta$ | Agent entry/exit rate | 0.02 | {0.01, 0.02, 0.05, 0.10} | |
| $\delta$ | Regime gain strength | 0.5 | {0, 0.25, 0.50, 0.75} | $\delta = 0$: no regime effect (pure statistical advantage) |

The activity parameters $p_{\text{demand}}$ and $K$ jointly determine the market regime. Because demand is per-slot, the expected demand volume scales with $K \cdot p_{\text{demand}}$: high-capacity agents in high-demand environments generate more opportunities per period, reflecting a thicker, faster-moving market. Different combinations map to the illustrative domains:

| Domain | $p_{\text{demand}}$ | $K$ | Rationale |
|--------|---------------------|-----|-----------|
| Interdealer brokerage | High | 10–50 | Frequent opportunities; many concurrent positions |
| Collector networks | Moderate | 2–5 | Episodic transactions; moderate concurrency |
| Import-export trading | Low to moderate | 2–5 | Slower opportunity flow; moderate concurrency |

**Implementation parameters.** Control simulation scale.

| Symbol | Meaning | Default | Scale check |
|--------|---------|---------|-------------|
| $N$ | Agent population | 1000 | {500, 1000, 2000} |
| $T$ | Simulation length (periods) | 200 | {100, 200, 400} |
| $T_{\text{burn}}$ | Burn-in periods (discarded) | 30 | — |
| $M$ | Network measure interval | 20 | — |

#### 11b. Search-cost calibration

The two channel costs are calibrated jointly from the average match surplus scale $(\bar{q}_{\text{cal}} - r)$ using a single cost-wedge parameter $\Delta_c$:

$$
\phi = (0.15 + \Delta_c / 2)\cdot(\bar{q}_{\text{cal}} - r), \qquad
c_s = (0.15 - \Delta_c / 2)\cdot(\bar{q}_{\text{cal}} - r).
$$

This keeps the average friction scale fixed at $0.15\cdot(\bar{q}_{\text{cal}} - r)$ while letting the model vary the difference $\phi - c_s$ that matters directly for the outsourcing decision. In the default $\Delta_c = 0.10$, brokered search is more expensive than self-search but not prohibitively so. The two quantities are computed once at initialization and held constant thereafter, but they enter realized payoffs asymmetrically: $c_s$ is charged on each self-search demand slot regardless of fill, whereas $\phi$ is charged only on successful standard brokered placements.

#### 11c. Initial conditions

The initialization procedure is specified in the pseudocode (§9, steps I.1–I.13). The key design choices are:

- Agent types are drawn at random positions on the sinusoidal curve with noise, then projected to the unit sphere (§0).
- The matching function parameters ($\mathbf{c}$, $\mathbf{A}$, $\mathbf{B}$) are drawn once and held fixed (§1).
- Calibration quantities ($\bar{q}_{\text{cal}}$, $r$, $\phi$, $c_s$) are computed from 10,000 random agent pairs (§11b).
- Each agent's history is seeded with 5 pairings from its neighbors in $G$, ensuring initial predictions reflect the local network.
- The broker's roster is seeded at $\lceil 0.20 \cdot N \rceil$ agents, and its history is seeded from 100 random roster member pairs.
- All neural networks are trained from random weights for $E_{\text{init}}$ steps on their seed histories before the first period (§2a). These seed histories initialize predictive capability, but under Model 1 they do **not** initialize principal-mode confidence: principal mode is disabled until the broker has observed live brokered outcomes in the simulation (§12c).

#### 11d. Reproducibility

All randomness flows from a single integer seed. The seed determines: type draws, the realization of $G$, matching function parameters ($\mathbf{c}$, $\mathbf{A}$, $\mathbf{B}$), broker seed roster, and all subsequent random events. Simulations are fully reproducible given (parameter dictionary, seed).

## Part III. Model Variant: Resource Capture

All base model mechanisms (§§0–10) operate unchanged. The difference: the broker can additionally act as a **principal**, acquiring a counterparty's position or resource and presenting itself as the counterparty to the demander. Rather than connecting two agents, the broker takes one side of the match. This implements the resource capture mode of Proposition 3a.

### 12. Resource Capture

#### 12a. Setup

Under resource capture, the broker transitions from intermediary to principal. Instead of connecting a demander with a counterparty, the broker acquires the counterparty's position (paying the counterparty for its resource or service) and then matches directly with the demander. The demander deals with the broker, not with the original counterparty. The broker earns the spread between what it charges the demander and what it pays the counterparty, bearing inventory risk if the match output falls short.

**Agent state additions.** Matches gain a flag: *standard* (brokerage as in the base model) or *principal* (broker takes one side). No new agent-level state variables are needed. On the broker side, Model 1 additionally tracks a scalar confidence state $\kappa_b^t$ and counterparty support counts $\{s_j^t\}$ used in the principal-mode decision (§12c).

#### 12b. Mechanism

When the broker operates in principal mode for demander $i$:

1. The broker identifies the best counterparty $j$ using its model (same allocation as the base model, §9 Step 2.3).
2. **The broker acquires $j$'s position** against an acquisition reservation $\bar{q}_j$ (the mean of all outputs in $j$'s history, or $\bar{q}_{\text{cal}}$ if $j$ has no history). This reservation is $j$'s self-assessed value of its position based on its own experience and serves as the broker's ex-ante benchmark. Agent $j$'s capacity slot is consumed for the period, but $j$'s history and satisfaction are unaffected (satisfaction is updated only for the demander role, §6a); $j$ does not observe who the end-use counterparty is.
3. **The broker matches with demander $i$** as the counterparty, stepping into $j$'s role. Match output is realized: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$, determined by the underlying pairing $(i, j)$ even though $i$ deals only with the broker.
4. **Both the demander and the broker experience $q_{ij}$** (the joint match output, as in any match). The **capture surplus** of the match is $\Delta q_{ij} = q_{ij} - \bar{q}_j$: the realized match output net of the counterparty's reservation. $\Delta q_{ij}$ can be negative when the acquired position underperforms the reservation; this is the broker's **capture risk**.
5. **Neither party observes the other's type.** The demander observes $q_{ij}$ (it experiences the match outcome) but not $\mathbf{x}_j$ (it does not know whose position the broker acquired). The counterparty does not observe $\mathbf{x}_i$ or $q_{ij}$ (it released its position without knowing the end use). Neither party can update its prediction history, because histories require (type, outcome) pairs (§2a).
6. **No edge is added to $G$ between $i$ and $j$.** The parties are unaware of each other's existence. The structural hole between them remains open.
7. **The broker adds $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$.** The broker is the only agent that learns from principal-mode matches.

Counterparty acceptance is automatic by construction: $j$ does not evaluate the match and has no participation constraint in principal mode (the broker, not $j$, is now the counterparty). The broker absorbs capture risk: it has acquired at reservation $\bar{q}_j$ a position whose realized output $q_{ij}$ may be higher or lower. Bearing this risk is a defining property of capture.

As the market evolves and counterparties accumulate better match histories (including from broker-mediated matches), their reservations $\bar{q}_j$ rise, naturally narrowing the pool of pairings with positive expected capture surplus. The broker sustains positive capture surplus only for counterparties whose self-assessed value is substantially below its predicted match output for the specific pairing.

If the broker repeatedly acquires positions from the same high-value agents, those agents are effectively monopolized, available to the market only through the broker. Self-searchers are left with a thinner, lower-quality pool.

#### 12c. Broker's decision: standard vs. principal

Each time the broker fills a match for demander $i$ with counterparty $j$, it first identifies the specific pairing $(i, j)$ using the same broker-allocation logic as in the base model (§9 Step 2.3), and then chooses between standard placement and principal mode using the smooth threshold

$$
\hat{q}_b([\mathbf{x}_i; \mathbf{x}_j]) - \bar{q}_j > \phi + \frac{\kappa_b^t}{\sqrt{1 + s_j^t / K}}.
$$

The left-hand side is the broker's expected capture surplus on the specific pairing. The right-hand side is the standard placement benchmark $\phi$ plus a confidence penalty that is high when the broker's recent forecasting errors are large and low when counterparty $j$ has broad prior broker placement support. Support is scaled by match capacity $K$, so the caution term relaxes only after support has built up relative to the market's per-period slot volume.

The objects in the rule are:

- $\hat{q}_b([\mathbf{x}_i; \mathbf{x}_j])$: the broker's predicted match output for the specific pairing.
- $\bar{q}_j$: agent $j$'s acquisition reservation, equal to the mean of all outputs in $j$'s history, or $\bar{q}_{\text{cal}}$ if $j$ has no history.
- $\phi$: the standard brokered-placement friction (§3c). Under standard placement the demander incurs $\phi$ and the broker has no output-level stake. Under principal mode no $\phi$ is charged to the demander; instead the broker bears capture risk and records realized capture surplus $\Delta q_{ij}$.
- $s_j^t$: **counterparty support**, defined as the number of distinct demanders previously matched with counterparty $j$ through accepted broker matches, whether those matches were standard or principal. Support starts at zero at $t = 0$ and grows only from realized broker activity.
- $K$: match capacity (§4a), used here as a scale factor so support lowers the caution term only after breadth has built up relative to the number of possible slots an agent can carry.
- $\kappa_b^t$: the broker's current **confidence MAE**, an exponentially weighted moving average of realized broker-match absolute forecast errors, initialized only from live brokered matches observed in the simulation.

Principal mode is disabled in period 1 by construction. More generally, principal mode remains disabled until the broker has observed at least one period with realized broker matches, so seed history trains the broker's model but does not by itself authorize capture.

Formally, if $B_t$ is the set of all realized broker matches in period $t$ (standard and principal), the current-period broker MAE is

$$
\tilde{\kappa}_b^t =
\begin{cases}
\dfrac{1}{|B_t|}\sum_{m \in B_t} |q_m - \hat{q}_{b,m}| & \text{if } |B_t| > 0 \\
\text{undefined} & \text{if } |B_t| = 0,
\end{cases}
$$

and the broker updates its confidence state as

$$
\kappa_b^{t+1} =
\begin{cases}
\tilde{\kappa}_b^t & \text{if } \kappa_b^t \text{ is not yet available and } |B_t| > 0 \\
(1-\omega)\kappa_b^t + \omega \tilde{\kappa}_b^t & \text{if } \kappa_b^t \text{ is available and } |B_t| > 0 \\
\kappa_b^t & \text{if } \kappa_b^t \text{ is available and } |B_t| = 0,
\end{cases}
$$

If $\kappa_b^t$ is not yet available and $|B_t| = 0$, it remains unavailable and principal mode stays disabled. The broker uses $\kappa_b^t$ during period $t$ mode selection and updates it only after period-$t$ outcomes are realized. This confidence term depends only on information the broker plausibly observes about its own activity: its own ex-ante predictions and realized outcomes on brokered matches.

**Design motivation.** The decision remains after pairing because the broker's informational advantage in the model is primarily about evaluating **specific pairings**, not generic counterparty quality in isolation. The confidence penalty is anchored in the broker's own realized forecast errors because that is the most natural observable summary of how reliable its predictions have recently been. Seed history is used only for learning, not for immediate capture, so the broker must first operate as an intermediary in the modeled market before principal mode becomes available. Counterparty support is defined by distinct demander breadth because repeated successful placement of $j$ across multiple demanders is a natural reduced-form signal that $j$ is marketable even when the broker has not previously captured that exact pairing. Scaling support by $K$ makes this signal build gradually with market volume instead of relaxing caution too sharply after one or two placements. The smooth threshold preserves a gradual buildup of confidence and support while keeping the model parsimonious.

Early in the simulation, principal mode is unavailable at first, then becomes rare because newly initialized $\kappa_b^t$ is based on live broker errors and most counterparties have little or no support. As the broker's realized forecasting errors fall and more counterparties accumulate broader demander support, the effective hurdle declines for well-understood, marketable counterparties, making principal mode increasingly frequent.

The capture dynamic relies on informational dependency and supply scarcity rather than long-duration lock-in (see §12e for the full feedback mechanism).

#### 12d. Principal-mode outcomes for each party

In principal mode the broker acts as the counterparty; no placement friction $\phi$ is charged, since the broker is no longer intermediating.

**Demander's perspective.** The demander experiences $q_{ij}$ with no friction deduction (no $\phi$ in principal mode). Its satisfaction input is $q_{ij}$, better than standard brokered matches (where $\phi$ is deducted) or self-search (where $c_s$ is deducted); demanders therefore *prefer* principal-mode matches, which reinforces the capture dynamic. The demander cannot update its prediction model, however (it observes $q_{ij}$ but lacks the counterparty type $\mathbf{x}_j$ needed for a history entry), so its informational position is frozen.

**Broker's perspective.** The broker experiences $q_{ij}$ as the counterparty, against the counterparty's acquisition reservation $\bar{q}_j$. The **capture surplus** $\Delta q_{ij} = q_{ij} - \bar{q}_j$ is the broker's realized outcome from the match. When the broker's predictions are accurate it selects high-output pairings with $q_{ij} \gg \bar{q}_j$ and captures positive surplus; when predictions are poor $\Delta q_{ij}$ may be negative, which is the realized capture risk. Whether or not the match is profitable to the broker after the fact, the broker adds $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$ and continues to learn.

**Counterparty's perspective.** The counterparty's capacity slot is consumed for the period. Because the counterparty does not observe the match outcome or the demander's type (§12b.5), its history $\mathcal{H}_j$ is not updated; because satisfaction is updated only for the demander role (§6a), its satisfaction tracking is unaffected by this match. Its reservation $\bar{q}_j$ rises over time as it accumulates outputs from standard matches where it does observe outcomes, narrowing the pool of pairings where capture surplus is likely positive.

#### 12e. Lock-in dynamics

Resource capture produces a **triple lock-in**:

**Informational lock-in.** Neither party observes the other's type. Prediction histories do not grow. The agent's neural network cannot be refitted on new data. Prediction quality stagnates at whatever level it had reached before entering principal-mode matching.

**Structural lock-in.** No direct tie forms between $i$ and $j$ in $G$. The network does not densify from principal-mode matches. Structural holes between agents remain open. The broker's betweenness centrality does not decline from these matches.

**Supply-side lock-in.** Agents whose positions are repeatedly acquired by the broker are effectively removed from the open market during those periods. Self-searchers face a thinner candidate pool, degrading the quality of self-search outcomes and pushing more agents toward the broker. This supply scarcity reinforces the information lock-in.

**Positive feedback loop.** Principal-mode matching prevents agent learning and thins the open market → agent's self-search quality stagnates or declines → agent's self-search satisfaction falls below broker satisfaction → agent continues outsourcing → broker captures surplus on each principal-mode match, continues learning, and acquires from more counterparties → recent successful broker forecasting lowers the effective caution term $\kappa_b^t$, while repeated broker placement of a counterparty raises its support $s_j^t$ and lowers the support penalty on future capture of that counterparty on the slower $s_j^t / K$ scale → more pairings clear the principal-mode decision rule in §12c → more agents locked in, more positions acquired.

This feedback loop is self-reinforcing once initiated, producing the abrupt capture trajectory predicted by Proposition 3a. The self-liquidating dynamic of structural advantage is suspended: because principal-mode matches create no direct ties between agents, the broker's structural position stops eroding.

#### 12f. Illustrative domains

Under resource capture, the broker transitions from connecting agents to taking one side of the match: acquiring a counterparty's position or resource and reselling it, with the broker bearing inventory risk. The mapping below shows how each v0.2 quantity corresponds to real-world analogs in the three illustrative domains.

**Interdealer brokerage (IDBs).** The broker transitions from voice intermediation to principal trading. Instead of finding a counterparty for a dealer's trade, the broker takes the other side itself, buying a position from one dealer and selling it to another. The broker warehouses the position and bears price risk until the offsetting trade clears. Neither dealer knows who is on the other side; both deal with the broker.
- $q_{ij}$ (match output): the joint value realized by the two-sided trade once both legs are placed.
- $\bar{q}_j$ (acquisition reservation): the counterparty dealer's ask price — the price level at which that dealer would normally clear the trade with a conventional counterparty.
- $\Delta q_{ij}$ (capture surplus): the realized bid-ask spread, net of position risk taken on during warehousing.
- Capture risk ($\Delta q_{ij} < 0$): the warehoused position moves against the broker before the offsetting leg is placed.
- $\phi$ (placement threshold): the traditional voice-broker commission the broker would otherwise collect as a pure intermediary.

**Collector networks.** The dealer transitions from pure intermediation to holding inventory. Instead of connecting a seller with a buyer, the dealer buys the piece outright (acquiring the seller's holding) and later sells it to a buyer. The dealer bears the risk that the piece may not find a suitable buyer at a profitable price. This is the standard transition from consignment dealer to gallery or wine merchant.
- $q_{ij}$ (match output): the realized buyer-seller joint value once the piece finds its end buyer.
- $\bar{q}_j$ (acquisition reservation): the seller's expected consignment price based on its own sale history.
- $\Delta q_{ij}$ (capture surplus): the dealer's margin — retail price minus the consignment reservation.
- Capture risk ($\Delta q_{ij} < 0$): the piece sells for less than the consignment reservation, or sits unsold and is eventually marked down.
- $\phi$ (placement threshold): the consignment dealer fee under pure intermediation.

**Import-export trading companies.** The trading company transitions from pure intermediation to taking principal positions. Instead of connecting a producer with a buyer, the company buys goods from the producer (acquiring the supply position) and resells to the buyer. The company bears inventory and price risk between acquisition and resale. This is the canonical trajectory of trading houses that evolve from brokers to merchants to vertically integrated conglomerates.
- $q_{ij}$ (match output): the joint value realized by producer-and-buyer once the shipment reaches the buyer.
- $\bar{q}_j$ (acquisition reservation): the producer's selling price based on its past export history.
- $\Delta q_{ij}$ (capture surplus): the trading margin — resale value minus procurement price.
- Capture risk ($\Delta q_{ij} < 0$): demand-side price drops, currency moves, or spoilage/delay reduce realized value below procurement cost.
- $\phi$ (placement threshold): the trading company's commission under pure intermediation.

#### 12g. Channel comparison

| | Base (no capture) | Resource capture (principal) | Data capture (§13a) |
|---|---|---|---|
| Who matches? | Agent matches directly | Broker takes one side | Agent matches directly |
| Agent observes counterparty type? | Yes | No (deals with broker) | Yes |
| Agent's prediction model improves? | Yes | No | Yes |
| Whose predictions guide selection? | Agent's own | Broker's | Broker's (sold to agent) |
| Direct tie forms? | Yes | No | Yes |
| Structural erosion? | Continues | Suspended | Continues |
| Supply scarcity? | No | Yes (broker acquires positions) | No |
| Broker bears capture risk? | No | Yes ($\Delta q_{ij}$ can be negative) | No |
| Quantity associated with placement | Successful standard-placement fee $\phi$ on demander; broker has no output-level stake | Capture surplus $\Delta q_{ij} = q_{ij} - \bar{q}_j$ accrues to broker's ledger of realized outcomes; no $\phi$ on demander | Friction $\mu$ on subscriber; broker has no output-level stake |
| Broker learns from match? | Yes | Yes | No (agent matched directly) |
| Predicted trajectory | Self-liquidating | Abrupt capture (Prop 3a) | Gradual capture (Prop 3b) |

The two capture modes differ on every dimension. Under resource capture, the broker becomes a principal, acquiring positions, bearing capture risk, and preventing clients from learning or forming direct ties. Under data capture, the broker *licenses* its informational advantage, selling predictions while clients continue matching directly, learning, and forming ties. These are two ways of monetizing the same informational asset: by exploiting it privately or by licensing it.

A subtle asymmetry in learning dynamics: under resource capture, the broker keeps learning (it observes both types in every principal-mode match). Under data capture, the broker's learning *slows* because agents match directly and the broker does not observe those outcomes unless a reporting mechanism exists. This creates a natural ceiling on data capture that resource capture does not face, and may contribute to the gradual-vs-abrupt distinction.

#### 12h. Pseudocode modifications

Steps not listed are identical to the base model pseudocode (§9).

<small>

> **2. CANDIDATE EVALUATION** (principal-mode branch added)
>
> &emsp;**2.3. Broker proposals** (unchanged from base):
> 2.3.1–2.3.5: as in §9.
>
> &emsp;**2.4. Broker mode selection** (new):
> 2.4.1. &emsp;for each proposed brokered match $(i, j)$:
> &emsp;&emsp;If $\kappa_b^t$ is not yet available: mark match as standard
> &emsp;&emsp;Compute acquisition reservation: $\bar{q}_j$ = mean of agent $j$'s realized match history (or $\bar{q}_{\text{cal}}$ if empty)
> &emsp;&emsp;Read current counterparty support: $s_j^t$ = number of distinct demanders previously matched with $j$ through accepted broker matches
> &emsp;&emsp;Read current broker confidence state: $\kappa_b^t$
> &emsp;&emsp;Compute smooth caution term: $\kappa_b^t / \sqrt{1 + s_j^t / K}$
> &emsp;&emsp;Compute standard-placement benchmark: $\Pi^{\text{standard}} = \phi + \kappa_b^t / \sqrt{1 + s_j^t / K}$
> &emsp;&emsp;Compute expected principal surplus: $\Pi^{\text{principal}} = \hat{q}_b([\mathbf{x}_i; \mathbf{x}_j]) - \bar{q}_j$
> &emsp;&emsp;If $\Pi^{\text{principal}} > \Pi^{\text{standard}}$: mark match as principal
> &emsp;&emsp;Else: mark match as standard
>
> **3. MATCH FORMATION** (principal-mode branch added)
>
> &emsp;**3.1. Sequential acceptance** (as in base, §9 Step 3, with principal-mode additions):
> 3.1.1. &emsp;Shuffle all proposals (standard and principal-mode) into random order.
> 3.1.2. &emsp;For each proposed match $(i, j)$ in order:
> &emsp;&emsp;If demander $i$ has no available capacity: skip.
> &emsp;&emsp;If counterparty $j$ has no available capacity: skip.
> &emsp;&emsp;**If standard:** counterparty $j$ evaluates as in base (§9 Step 3.1.2).
> &emsp;&emsp;**If principal mode:** broker acquires $j$'s position at price $\bar{q}_j$ (automatic acceptance). Demander's participation constraint was applied by the broker during allocation ($\hat{q}_b > r$, §9 Step 2.3.4).
> &emsp;&emsp;If accepted: decrement both $i$'s and $j$'s available capacity by one.

> **4. OUTCOME REALIZATION AND LEARNING** (principal-mode branch added)
>
> 4.1. &emsp;for each accepted match $(i, j)$:
> &emsp;&emsp;Realize output: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$
> &emsp;&emsp;Increment $n_{\text{matches},i}$ and $n_{\text{matches},j}$ (cumulative match counters, any role, any channel — used for broker dependency $D_j$, §12i).
> &emsp;&emsp;If brokered and demander $i$ has not previously been broker-matched with counterparty $j$: mark that support link and increment $s_j$
> &emsp;&emsp;**If standard** (self-search or standard brokered):
> &emsp;&emsp;&emsp;Add $(\mathbf{x}_j, q_{ij})$ to $\mathcal{H}_i$ (demander's history)
> &emsp;&emsp;&emsp;Add $(\mathbf{x}_i, q_{ij})$ to $\mathcal{H}_j$ (counterparty's history)
> &emsp;&emsp;&emsp;If brokered: add $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$
> &emsp;&emsp;&emsp;Add edge $(i, j)$ to $G$
> &emsp;&emsp;**If principal mode:**
> &emsp;&emsp;&emsp;Agent histories $\mathcal{H}_i$ and $\mathcal{H}_j$ are **not** updated (neither party observes the other's type; demander dealt with broker, counterparty released position to broker)
> &emsp;&emsp;&emsp;Add $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$ (broker observes both types)
> &emsp;&emsp;&emsp;**No edge** added to $G$ between $i$ and $j$
> &emsp;&emsp;&emsp;Increment $n_{\text{principal-acquired},j}$ (agent $j$ was the acquired counterparty)
>
> 4.2. &emsp;Update satisfaction indices (as in base §9 Step 4.2, with principal-mode addition):
> &emsp;&emsp;For each agent $i$ with $d_i > 0$, let $c$ be $i$'s chosen channel:
> &emsp;&emsp;&emsp;Sum realized outputs across $i$'s accepted broker-channel slots; unfilled slots contribute zero.
> &emsp;&emsp;&emsp;Compute $\tilde{q} = \big[\sum_{\text{standard}} (q_{ij} - \phi) + \sum_{\text{principal}} q_{ij}\big] / d_i$.
> &emsp;&emsp;&emsp;Update: $s_{i,\text{broker}}^{t+1} = (1 - \omega)\, s_{i,\text{broker}}^t + \omega \cdot \tilde{q}$.
>
> 4.3. &emsp;Capture surplus recording (principal-mode matches):
> &emsp;&emsp;for each accepted principal-mode match $(i, j)$, record the triple $(q_{ij}, \bar{q}_j, \hat{q}_b)$ in the period's principal-mode ledger, where $\bar{q}_j$ is the acquisition reservation used at mode-selection time (§2.4) and $\hat{q}_b$ is the broker's ex-ante predicted match output. The capture surplus is $\Delta q_{ij} = q_{ij} - \bar{q}_j$; the broker's ex-ante expected surplus was $\hat{q}_b - \bar{q}_j$. These per-match quantities feed the capture measures in §12i.
>
> 4.4. &emsp;Broker confidence update:
> &emsp;&emsp;Collect all accepted broker matches in period $t$ (standard and principal)
> &emsp;&emsp;If at least one exists: compute $\tilde{\kappa}_b^t = \frac{1}{|B_t|}\sum_{m \in B_t}|q_m - \hat{q}_{b,m}|$
> &emsp;&emsp;If $\kappa_b^t$ is not yet available: set $\kappa_b^{t+1} = \tilde{\kappa}_b^t$
> &emsp;&emsp;If $\kappa_b^t$ is available: update $\kappa_b^{t+1} = (1-\omega)\kappa_b^t + \omega \tilde{\kappa}_b^t$
> &emsp;&emsp;If no broker matches and $\kappa_b^t$ is available: leave $\kappa_b^{t+1} = \kappa_b^t$
> &emsp;&emsp;If no broker matches and $\kappa_b^t$ is not yet available: leave $\kappa_b^{t+1}$ unavailable

</small>

#### 12i. Model 1 performance measures

**Principal-mode share** $P^t$: the fraction of brokered matches in period $t$ that are principal-mode (versus standard placement). This is the primary capture metric. Proposition 3a predicts an abrupt tipping point: $P^t$ should remain near zero while the broker builds its informational advantage, then jump sharply once the smooth decision rule in §12c clears for a broad set of pairings. Under the current timing, $P^1 = 0$ by construction because principal mode is disabled until live broker confidence is available.

**Broker confidence state.**

- **Broker selected-match MAE** $= \frac{1}{|B_t|}\sum_{m \in B_t}|q_m - \hat{q}_{b,m}|$ over all realized broker matches in period $t$ (standard and principal). This is the broker-observable period statistic feeding the confidence update.
- **Broker confidence MAE** $\kappa_b^t$: the broker's state variable carried into period $t$ and used in principal-mode decisions. Before the first live broker period with realized matches, this quantity is unavailable. A declining $\kappa_b^t$ indicates that the broker's recent realized forecasts have become more reliable, lowering the effective caution term in §12c.

**Agent prediction quality by principal-mode exposure.** Average holdout $R^2$ stratified by agents' cumulative principal-mode match fraction. Agents with high exposure should show stagnating prediction quality (informational lock-in), while agents who primarily self-search or receive standard placements should continue improving.

**Capture outcome.** Over principal-mode matches accepted in period $t$:

- **Mean capture surplus** $\overline{\Delta q}^t = \frac{1}{|P^t|} \sum_{(i,j) \in P^t} \Delta q_{ij}$: the typical per-match capture surplus (where $\Delta q_{ij} = q_{ij} - \bar{q}_j$).
- **Capture loss rate** $= |\{(i,j) \in P^t : \Delta q_{ij} < 0\}| / |P^t|$: the share of principal-mode matches whose realized output falls below the counterparty's acquisition reservation.
- **Capture loss magnitude** $= \mathrm{mean}(|\Delta q_{ij}| \mid \Delta q_{ij} < 0)$: the typical size of losses when they occur.

Early in the capture transition, when the broker's predictions are less accurate, losses should be more frequent and larger. As predictions improve, both loss rate and loss magnitude should decline. Persistent losses would indicate that the broker is going principal too early.

**Capture decision quality.** On the principal-mode subset in each period, we measure whether the broker's ex-ante basis $\hat{q}_b - \bar{q}_j$ correlates with the realized surplus $q_{ij} - \bar{q}_j$. If the subset has fewer than 5 matches, both metrics return NaN.

- **Capture decision rank correlation** $= $ Spearman $\rho$ between $\hat{q}_b - \bar{q}_j$ and $q_{ij} - \bar{q}_j$. A high value means the broker reliably ranks matches by realized surplus; a low value means it goes principal somewhat blindly.
- **Capture decision RMSE** $= \sqrt{\mathrm{mean}((\hat{q}_b - q_{ij})^2)}$ on principal-mode matches. Calibration of the broker's output prediction on captured pairings.

**Supply scarcity.** The per-period fraction of agents whose positions are acquired by the broker in principal mode, and the resulting impact on self-search candidate pool sizes. Under capture, self-searchers face a shrinking pool of available counterparties.

**Broker dependency.** For each agent $j$ with at least one match, the cumulative dependency ratio
$$D_j^t = \frac{n_{\text{principal-acquired},j}^t}{n_{\text{matches},j}^t},$$
where $n_{\text{principal-acquired},j}^t$ is the cumulative count of principal-mode matches in which $j$ was the acquired counterparty and $n_{\text{matches},j}^t$ is the cumulative count of all matches $j$ has participated in (any role, any channel). At $D_j = 0$, the agent participates only in direct or standard-brokered matches; at $D_j = 1$, every match it has ever been in has been a principal-mode acquisition from it. The distribution of $\{D_j^t\}$ across eligible agents characterizes the extent and concentration of monopolization. Summary statistics:

- **Mean $D_j$**: overall dependency level.
- **$D_j$ 90th percentile**: the heavy-use tail.
- **Fraction of agents with $D_j > 0.5$**: effectively monopolized agents.
- **Gini coefficient of $\{D_j\}$**: concentration of capture across agents.

---

## Part IV. Outstanding Design Choices

### 13. Deferred Design Choices

The following design choices are deferred for future work. They are described at a conceptual level to guide subsequent development.

#### 13a. Data Capture (Model 2)

Under data capture (Proposition 3b), the broker sells access to its prediction model as a per-period subscription service. Subscribing agents use the broker's model when evaluating strangers during self-search (§5a), while continuing to match directly, learn from outcomes, and form ties. For known neighbors, subscribers still use their own historical averages. The broker earns per-period subscription revenue $\mu$ rather than per-match fees.

Data capture produces the gradual trajectory of Proposition 3b: agents keep learning and forming ties, structural erosion continues, and the broker's advantage narrows as subscribers improve their own predictions. The channel comparison table in §12g summarizes the contrast with resource capture.

**Open design questions:**

**Does the broker observe outcomes of subscriber-directed matches?** If not, the broker's learning slows under data capture: subscribers use the broker's model to find better matches with strangers, but the broker doesn't see the outcomes. This creates a natural ceiling on the broker's model quality. If the broker does observe outcomes (e.g., through a reporting requirement in the subscription contract), the ceiling disappears and data capture dynamics change.

**Does subscription replace or supplement the agent's own model for stranger evaluation?** If the subscription replaces the agent's neural network entirely (the agent uses the broker's predictions for all strangers), the agent becomes dependent and its own model atrophies. If the subscription supplements (e.g., the agent uses the better of its own prediction and the broker's for each stranger), the agent's model continues to improve alongside the broker's. The replacement version is simpler and produces stronger capture dynamics; the supplement version is more realistic.

**Can subscribers also use the broker for standard placement simultaneously?** If yes, the broker can earn revenue from both subscription fees and placement fees, and subscribers benefit from both better predictions and access to the broker's roster. If no, subscription and brokerage are mutually exclusive channels.

#### 13b. Alternative Resource Capture Mechanisms

Two alternatives to the principal-mode mechanism (§12) are noted for future exploration.

**Exclusive contracts without information lock-in.**

Agents sign exclusive contracts with the broker for $L$ periods but still observe counterparty types and form direct ties. Lock-in is contractual, not informational: the agent's prediction model and network continue to improve, but it cannot switch to self-search during the contract.

This variant serves as a **comparison case**: if capture is weaker without information lock-in, it demonstrates that the informational channel (not the contractual restriction) drives the abrupt capture dynamics of Proposition 3a.

**Partial obfuscation.**

The broker reveals noisy or partial type information: $\tilde{\mathbf{x}}_j = \mathbf{x}_j + \boldsymbol{\zeta}$, where $\boldsymbol{\zeta} \sim N(0, \sigma_{\text{obf}}^2 \mathbf{I}_d)$. The agent can update its history with $(\tilde{\mathbf{x}}_j, q_{ij})$, but the noisy type degrades the quality of its learned model. At $\sigma_{\text{obf}} = 0$, this is standard brokerage; at $\sigma_{\text{obf}} \to \infty$, this approaches the full information lock-in of principal mode.

This variant provides a continuous lock-in parameter that can be swept, serving as a **robustness check**: does the capture result survive when the information freeze is partial rather than total? The theoretical prediction is that capture requires sufficiently strong obfuscation but is not knife-edge: there should be a threshold $\sigma_{\text{obf}}^*$ above which capture dynamics emerge.

#### 13c. Prediction Confidence and Uncertainty

The current model does not track per-prediction posterior uncertainty. All match predictions are still point estimates. It does, however, track a reduced-form broker confidence state, $\kappa_b^t$, defined from live realized broker-match absolute forecast errors and used as a scalar caution term in the principal-mode decision (§12c). This captures recent realized forecasting reliability without requiring a full predictive distribution.

**Bayesian last layer.** A natural extension of the current neural network architecture (§2a): the hidden layer remains a deterministic feature extractor trained by gradient descent, but the output layer is replaced with Bayesian linear regression. Given hidden features $\mathbf{h} = \text{ReLU}(\mathbf{W}_1 \mathbf{z} + \mathbf{b}_1)$ from the training data, the posterior over output weights $\mathbf{w}_2$ is available in closed form (conjugate Gaussian). For a new input $\mathbf{z}^*$, the predictive distribution is $N(\boldsymbol{\mu}_{\text{post}}^\top \mathbf{h}^*, \; \sigma_\varepsilon^2 + \mathbf{h}^{*\top} \boldsymbol{\Sigma}_{\text{post}} \mathbf{h}^*)$, where the second variance term $\mathbf{h}^{*\top} \boldsymbol{\Sigma}_{\text{post}} \mathbf{h}^*$ is the *epistemic* uncertainty (large when the input is far from training data in feature space, small when it is well-covered). Implementation cost is minimal: one $h \times h$ matrix inversion per agent per period (at $h = 16$, this is trivial).

**Uses of per-prediction uncertainty:**
- *Match selection.* An upper confidence bound (UCB) rule (select the partner with the highest $\hat{q} + \kappa \cdot \hat{\sigma}$) would balance exploitation (high predicted quality) with exploration (high uncertainty), generating more informative data and accelerating learning.
- *Principal-mode decision.* The broker could replace the current global MAE-based caution term with pair-specific prediction uncertainty, avoiding principal positions where $q_{ij}$ is highly uncertain and inventory risk is greatest.
- *Outsourcing decision.* An agent whose average predictive uncertainty is high might rationally prefer the broker even when satisfaction scores are comparable.
- *Measuring the informational advantage.* The epistemic uncertainty gap between agent and broker (the broker's $\Sigma_{\text{post}}$ is smaller because it has more diverse training data) directly quantifies the informational advantage at the prediction level.

Deferred because the current reduced-form MAE-based confidence state is sufficient to demonstrate the core propositions while keeping the model parsimonious. A Bayesian last layer would enrich the dynamics by replacing the global caution term with pair-specific epistemic uncertainty, and could be added without changing the hidden-layer training procedure.

#### 13d. Pricing Alternatives

The base model uses a fixed successful-placement fee $\phi$ on standard brokered matches. Under Model 1 (principal mode), the broker's compensation is the spread $q_{ij} - \bar{q}_j$ with no additional fee. Two alternative pricing mechanisms are noted for future exploration.

**Surplus-proportional fee.** $\phi = \alpha \cdot \hat{q}_b([\mathbf{x}_i; \mathbf{x}_j])$. The broker charges a fraction of its predicted match quality. This creates a recognition gap: the broker's revenue depends on its own prediction, while the agent's satisfaction depends on realized quality. Better predictions increase broker revenue, strengthening the incentive to invest in prediction accuracy.

**Prediction-based fee.** $\phi = \alpha \cdot (\hat{q}_b - \hat{q}_i)$. The broker charges for the prediction improvement it provides over the agent's own model. This directly prices the informational advantage but requires the broker to know (or estimate) the agent's prediction quality.

Both alternatives create richer dynamics but add parameters and complicate the satisfaction comparison between channels. The fixed-fee design isolates the informational channel by removing price as a margin of competition.

#### 13e. Other Design Choices

**Before-pairing capture decision.**

The current Model 1 makes the capture decision **after** the broker has already selected a specific pairing $(i, j)$, so the decision object is the predicted pair surplus $\hat{q}_b(i, j) - \bar{q}_j$ adjusted by the smooth caution term in §12c. A future variant could instead let the broker first acquire counterparty $j$ and only then assign that acquired position to a demander. In that design, the natural decision object would no longer be pair surplus itself, but a **resale-option value** for counterparty $j$, for example the best predicted current outsourced demander for $j$ or an expected future resale value. This would likely require explicit inventory and assignment timing. If acquisition can precede placement across periods, the model would also need holding-cost, depreciation, or expiry assumptions for unplaced inventory. This alternative is conceptually interesting but is not implemented here.

**Fixed acquisition price at outside option.** The current model sets the counterparty's ask price at $\bar{q}_j$ (average realized match quality from its history). A simpler alternative: the counterparty always accepts at the fixed outside option $r$, regardless of its match history. This makes acceptance truly automatic and the acquisition cost constant across counterparties, producing a clean regime shift in the broker's principal-mode decision. The tradeoff is that the broker acquires all positions at the same low price, which may make capture too easy and remove the natural margin compression from rising counterparty experience.

**Exclusivity under principal mode.** The base Model 1 uses per-slot independence: principal-mode matches consume one capacity slot, and other slots remain available for self-search. An alternative is full exclusivity ($\xi = 1$): an agent with any principal-mode match cannot self-search at all during that period, routing all demand through the broker. This produces total information freeze (the agent gains no new observations from any source) and stronger lock-in. With per-slot demand, an agent at $K = 5$ generates ~2.5 demands per period; under per-slot independence, some of these could go through self-search even if one slot is filled by a principal-mode match. Full exclusivity would block all self-search, significantly strengthening the lock-in. Comparing dynamics under per-slot independence and full exclusivity would test whether the full information freeze is necessary for the abrupt capture trajectory of Proposition 3a.

#### 13f. Interpreting $K$ as Counterparty Capacity

The current specification interprets $K$ as a per-period capacity in transactional slots: each accepted match consumes one slot for the demander and one slot for the counterparty for the remainder of the period, and repeated matches with the same partner in the same period are allowed if both parties retain capacity. A deferred alternative is to reinterpret $K$ as the maximum number of **concurrent counterparties** or active bilateral relationships an agent can maintain within a period.

Under that alternative, an accepted match would no longer represent a single transaction-level placement, but the formation of a period-level commercial relationship. Repeated transactions between the same two parties within the period would be bundled into that relationship rather than modeled individually. This interpretation is closer to settings such as labor-market intermediation, where a match is naturally read as a filled bilateral position rather than a sequence of repeated trades.

This reinterpretation has several conceptual advantages. The network edge created by an accepted match aligns more naturally with the object being modeled, since one accepted match would correspond to one active relationship. The support term in principal mode, $s_j^t / K$, would also become easier to read: breadth of prior demander relationships relative to the number of concurrent counterparties an agent can sustain. Likewise, supply scarcity under resource capture would become more relationship-based and easier to interpret.

The tradeoff is that the model would change meaning, not just notation. Match output $q_{ij}$, search costs, broker fees, satisfaction updates, and capture surplus would all need to be reinterpreted at the relationship level rather than the transaction level. Principal-mode acquisition would become a stronger form of exclusivity, because occupying one of an agent's $K$ counterparty positions would block an entire relationship for the period rather than a single transaction slot. Repeated within-period trade volume between the same pair would no longer be observed directly. This could be a useful extension for domains where relationship formation is the relevant matching object, but it is not part of the current base model.

## Figures

**Fig. 1.** The informational mechanism.
- *Purpose:* Establishes the core mechanism: the broker learns faster than individual agents, the gap widens with matching complexity, and this drives increasing outsourcing (Propositions 1.1, 1.2, 1.3).
- *Content:* All panels at default parameters ($s = 8$, $\rho = 0.50$). Each panel includes a **base model** series (dashed grey) as a no-capture reference line, plus Model 1 series.
  - Panel A: time on the horizontal axis, prediction quality (holdout $R^2$) on the vertical axis. One line for the broker, one for the average agent. The broker-agent gap reflects the informational advantage and its dynamics over time. An inset shows the effect of varying $s$.
  - Panel B: time on the horizontal axis, outsourcing rate on the vertical axis. The base model establishes the reference trajectory. Model 1 diverges.
  - Panel C: time on the horizontal axis, average realized match output by channel (self-search, standard brokered, principal mode).

**Fig. 2.** Decoupling of structural position from informational advantage.
- *Purpose:* The central empirical implication. Shows that betweenness centrality declines while the broker's informational advantage grows, and that resource capture suspends the structural erosion (Propositions 2.1, 3a).
- *Content:* Time on the horizontal axis, dual vertical axes for broker betweenness centrality and broker prediction quality. Under Model 1, betweenness plateaus or recovers once principal mode dominates.

**Fig. 3.** Access vs. assessment decomposition over time.
- *Purpose:* Traces the shift from network access to information assessment as the dominant source of broker value (Propositions 1.3a, 1.3b).
- *Content:* Time on the horizontal axis, fraction of brokered matches on the vertical axis, decomposed into access value (counterparty was not in demander's network) and assessment value (counterparty was reachable but broker predicted better).

**Fig. 4.** Capture dynamics and the lock-in mechanism.
- *Purpose:* Shows that capture occurs and the lock-in mechanism explains why resource capture is abrupt and self-reinforcing (Proposition 3a).
- *Content:*
  - Panel A: time on the horizontal axis, principal-mode share $P^t$ on the vertical axis. Shows the abrupt tipping point as the broker shifts from standard placement to principal mode.
  - Panel B: time on the horizontal axis, average agent prediction quality on the vertical axis, stratified by principal-mode exposure (high vs. low). Broker-dependent agents stagnate; others continue improving. Panel A shows the outcome; Panel B shows the mechanism.

**Fig. 5.** Phase diagram.
- *Purpose:* Maps the conditions under which capture occurs, identifying regions of no capture, partial capture, and full capture as a function of matching complexity (Proposition 2.2).
- *Content:* Main axes TBD. Heatmap or contour plot showing the broker-agent prediction quality gap (or principal-mode share at steady state) across the parameter space.

#### SI figures

**Fig. S1.** Prediction quality decomposition.
- *Content:* Three sub-panels: $R^2$, bias, and rank correlation over time (broker and average agent). Under Model 1, agent lines stratified by principal-mode exposure.

**Fig. S2.** Attributional vs. relational channel (Proposition 1.2).
- *Content:* $\rho$ on horizontal axis; broker-agent gap in holdout $R^2$; outsourcing rate at steady state.

**Fig. S3.** OAT parameter sweeps.
- *Content:* Grid of panels varying $\eta$, $\delta$, $p_{\text{demand}}$, $K$ while holding others at defaults.

**Fig. S4.** Network visualization snapshots.
- *Content:* The network $G$ at early, middle, and late periods. Broker node positioned centrally. Under Model 1, late-period graph should show persistent structural holes between agents matched through the broker's principal mode.

**Fig. S5.** Broker risk profile.
- *Purpose:* Shows the frequency and magnitude of inventory losses the broker absorbs in principal mode.
- *Content:* Time on the horizontal axis, distribution of $q_{ij} - r$ for principal-mode matches. Early: wider distribution with more losses. Late: concentrated in positive territory as predictions improve.

## References

Bethune, Z., Sultanum, B., & Trachter, N. (2024). An information-based theory of financial intermediation. *Review of Economic Studies*, *91*(3), 1424–1454.

Brandes, U. (2001). A faster algorithm for betweenness centrality. *Journal of Mathematical Sociology*, *25*(2), 163–177.

Borgatti, S. P. (1997). Structural holes: Unpacking Burt's redundancy measures. *Connections*, *20*(1), 35–38.

Brenner, T. (2006). Agent learning representation: Advice on modelling economic learning. In K. Judd & L. Tesfatsion (Eds.), *Handbook of computational economics* (Vol. 2, pp. 895–947). North-Holland.

Burt, R. S. (1992). *Structural holes: The social structure of competition*. Harvard University Press.

Burt, R. S. (2005). *Brokerage and closure: An introduction to social capital*. Oxford University Press.

Duffie, D., Gârleanu, N., & Pedersen, L. H. (2005). Over-the-counter markets. *Econometrica*, *73*(6), 1815–1847.

Everett, M. G., & Borgatti, S. P. (2020). Unpacking Burt's constraint measure. *Social Networks*, *62*, 50–57.

Freeman, L. C. (1977). A set of measures of centrality based on betweenness. *Sociometry*, *40*(1), 35–41.

Li, D. D. (1998). Middlemen and private information. *Journal of Monetary Economics*, *42*(1), 131–159.

Muscillo, A. (2021). A note on matricial ways to compute Burt's structural holes in networks. *arXiv preprint arXiv:2102.05114*.

Rogerson, R., Shimer, R., & Wright, R. (2005). Search-theoretic models of the labor market: A survey. *Journal of Economic Literature*, *43*(4), 959–988.

Watts, D. J., & Strogatz, S. H. (1998). Collective dynamics of 'small-world' networks. *Nature*, *393*(6684), 440–442.
