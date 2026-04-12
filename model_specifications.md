# Model Specification: Transient Brokerage in Matching Markets

This document details the specifications of an agent-based model of brokered matching meant to formalize and demonstrate the theory of brokerage put forward in the project titled "Transient Brokerage."

## Theory Overview

The structural-hole theory of brokerage (Burt, 1992) locates the broker's value in its network position, bridging disconnected parties. Structural-hole brokerage, when performed at scale, can be self-liquidating: each successful match creates a direct tie that densifies the network and closes the holes that created bridging opportunities in the first place, unless the broker aggressively recruits new, distant clients.

I propose a complementary view of brokerage. Brokerage is outsourced relational work: the broker constructs viable matches between parties who cannot easily evaluate each other. This relational work generates an informational byproduct that the broker can leverage. The broker accumulates knowledge of how to match heterogeneous parties. Structural position provides the access that feeds learning, but while each successful match erodes the broker's structural advantage, it also strengthens its informational position (by adding an observation to its experience of the matching function).

The broker converts structural capital into informational capital through the act of brokering. When the matching problem is sufficiently complex, the informational capital compounds faster than structural capital erodes, and this compounding advantage can support a transition from intermediation to capture, transforming the broker into a principal selling the resource it was formerly intermediating or data and analytics. This is *transient brokerage*, a process that highlights the broker's power rather than its fragility.

This project develops an agent-based model of brokered matching to formalize and demonstrate the theoretical framework. In the model, agents seeking pairwise matches either search their own network or outsource the search to a broker. Capture can take two forms: resource capture, where the broker becomes a principal and locks clients out of learning, or data capture, where the broker sells its predictions as an analytics service while clients continue matching directly. All agents use heuristic decision rules. No agent solves an optimization problem or holds beliefs about other agents' strategies.

## Questions

1. Under what conditions does the broker develop, maintain, or lose an informational advantage over its clients?

2. Under what conditions can the broker leverage its advantage for capture?

3. What form does capture take and how does capture impact the dynamics of the broker's advantage?

## Main Propositions

The simulation is designed to demonstrate the following propositions.

### Premise

**1. A broker provides value in a matching market because of its structural or informational advantages.** A broker helps create a match between principals who, without the broker's intervention, could not easily find each other (access; structural advantage) or were unaware that they would benefit from a match (matchmaking; informational advantage). In other words, the broker's service is valuable both because it can find counterparties that clients cannot reach and because it can assess match quality better than its clients can.

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

Assessing match quality involves two components: assessing the general quality of each good or counterparty involved, and assessing the quality of the specific pairing or relational package being considered.

The broker observes outcomes from many different pairings across principals, while each principal observes outcomes only from its own matches. This gives the broker two potential channels of informational advantage: (1) better estimation of counterparty quality from cross-market data (the attributional channel), and (2) better understanding of pairing complementarities from observing the same counterparties matched with different principals (the relational channel).

Important models in the economics literature have characterized the broker's role as quality certification (Li, 1998) or expert screening (Bethune, Sultanum, and Trachter, 2024): the broker identifies which goods or counterparties are high quality. He is an appraiser whose cross-market experience helps it assess the general quality of counterparties more accurately than individual principals can.

The relational-work view of brokerage rather suggests that the broker's value lies in understanding complementarities between counterparties and shaping relational packages accordingly. The broker is a relational worker and a matchmaker whose advantage comes from knowing which pairings will succeed.

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

High matching complexity and low transparency make the principals' learning problem harder, widening and preserving the broker's advantage.

In transparent markets with simple matching problems, principals learn fast and well enough that the broker does not accumulate a decisive informational advantage. Brokers persist as commodity intermediaries earning thin margins and may attempt capture but do not consolidate into dominant principals. This is the no-capture region of the parameter space.

Within the capture region of the parameter space, if the broker does not capture, its information advantage may start to erode over time.

### 3. Forms of capture

#### Proposition 3

**Capture can occur in two forms with qualitatively different dynamics.**

**3a. Under resource capture, the transition is abrupt, and the broker suddenly starts taking inventory risk and acting primarily as a principal.** Resource capture creates a double lock-in: the client's information state freezes (it doesn't learn from new matches like it did when the broker acted as an intermediary) and the client's network no longer grows (the broker is everyone's counterparty). The self-liquidating dynamic of structural advantage is suspended, because the broker no longer creates direct ties between clients. This produces a steep capture trajectory.

**3b. Under data capture, the transition is gradual, and the broker progressively monetizes its informational advantage by acting as a principal in subscription contracts.** Clients continue making new matches, learning from outcomes, and growing their networks. The self-liquidating dynamic of structural advantage continues operating. This produces a smooth capture trajectory.

## Illustrative Domains

The model is domain-agnostic: it formalizes brokered matching between heterogeneous agents in a single population. The theoretical propositions apply wherever a broker facilitates pairwise matches, accumulates cross-market data, and faces structural erosion from the direct ties it creates. Three empirical domains illustrate the framework.

**Interdealer brokerage in OTC financial markets.** Dealers in over-the-counter markets (interest rate swaps, foreign exchange, corporate bonds) need counterparties for trades. Interdealer brokers (IDBs) sit between dealers, matching buy and sell interests across the market. Each successful brokered trade creates a direct relationship between two dealers who can subsequently trade bilaterally. The IDB accumulates cross-market knowledge of which dealer pairings clear efficiently. The well-documented transition from voice brokerage to electronic trading platforms (ICAP → NEX/CME, BGC → Fenics) is an instance of data capture; IDBs that became principal traders illustrate resource capture.

**Strategic alliance and joint venture brokerage.** Firms seeking partners for joint ventures, technology licensing, or co-development rely on intermediaries — management consultancies, investment banks, or specialized alliance brokers — to identify compatible partners. Match quality depends on capability complementarity: the best alliances combine partners with non-overlapping strengths. After a successful partnership, firms know each other and can pursue follow-on deals directly. The broker's informational advantage lies in knowing which capability combinations produce value across different market segments.

**Dealer networks in collectible markets.** Collectors of art, wine, rare books, or similar specialty goods seek trades or sales through dealers who know the market. Each collector has distinct tastes and holdings; match quality depends on multidimensional complementarity between what one party has and what another wants. Dealers accumulate knowledge of collector preferences across transactions. A dealer who transitions from pure intermediation to holding inventory (gallery, wine merchant) illustrates resource capture; one who builds a valuation database or subscription advisory service illustrates data capture.

## Part I. Base Model

The model is a discrete-time agent-based simulation of a matching market with two participant types: *agents* and a *broker*. Agents seeking pairwise matches either search their own network or outsource the search to the broker. Each period represents one calendar quarter. All economic quantities (match output, fees, surplus) are in the same monetary units.

A single broker serves the market. This is a simplification: with multiple brokers, the data pool fragments, there is competition for informational rents, and no single broker consolidates as large an informational advantage. The model can be interpreted as a monopolistic broker or as a single broker's segment within a competitive market. Analysis of broker competition is deferred to future work.

All agents use heuristic decision rules. No agent solves an optimization problem or holds beliefs about other agents' strategies, in line with the tradition of ABM agents using simple, bounded-rationality rules grounded in empirically observable behavior (Brenner, 2006).

The base model specifies agents (§0), the matching problem (§1), how agents learn to predict match quality (§2), match economics (§3), network structure and agent turnover (§4), how agents and the broker find counterparties (§5), the outsourcing decision (§6), the broker's roster (§7), the match lifecycle (§8), and the complete step ordering (§9). There is no capture in the base model. Capture mechanisms are described as outstanding design choices (§13).

### 0. Agents

The model has $N$ agents (default 500) and a single broker. Agents are connected through a network $G$ (§4) that channels search.

Each agent $i$ is characterized by:

- **Type** $\mathbf{x}_i \in \mathbb{R}^d$: a fixed vector of observable characteristics assigned at initialization. Types determine general quality and productive compatibility with other agents through the matching function (§1). The dimensionality $d = 8$ is fixed.
- **Active matches** $M_i^t$: the set of agents currently matched with $i$. Each agent can sustain at most $K$ simultaneous active matches (default $K = 5$).
- **Available capacity**: $K - |M_i^t|$, the number of additional matches the agent can enter.
- **Experience history** $\mathcal{H}_{i}^t = \{(\mathbf{x}_j, q_{ij})\}$: the set of (other party's type, realized match output) pairs from all matches $i$ has participated in, regardless of whether $i$ was the demander or the counterparty (§2a). Because the matching function is symmetric (§1a), both roles produce the same prediction target.
- **Satisfaction indices** $s_{i,c}^t$: one scalar per search channel $c \in \{\text{self}, \text{broker}\}$, tracking realized match value via an EWMA (§6a). Drives the outsourcing decision (§6).
- **Outside option** $r$: the minimum match value any agent requires to participate in a match (§3). Constant across agents, calibrated at initialization.

Agents exit independently each period with probability $\eta$ (default 0.02) and are replaced by new entrants with fresh types, empty histories, and satisfaction initialized at the public benchmark (§4).

#### Agent types

Agents are described by type vectors in $\mathbb{R}^d$ ($d = 8$). These types are the observable characteristics that determine productive compatibility through the matching function (§1).

Agent types lie near a smooth one-dimensional curve on the surface of the unit sphere in $\mathbb{R}^d$. The curve is parameterized by a position $t \in [0, 1]$:

$$\mathbf{x}(t) = \frac{\tilde{\mathbf{x}}(t)}{\|\tilde{\mathbf{x}}(t)\|}, \qquad \tilde{x}_k(t) = \begin{cases} \sin(2\pi f_k t + \theta_k) & k = 1, \ldots, s \\ 0 & k = s+1, \ldots, d \end{cases}$$

where $f_k$ and $\theta_k$ are random frequency and phase parameters drawn once per simulation, and $s \leq d$ is the number of **active dimensions** — the dimensions along which the curve has nonzero variation. The remaining $d - s$ dimensions receive only noise (see below).

Each agent is drawn at a random position $t_i \sim U[0,1]$ on the curve, then perturbed:

$$\mathbf{x}_i = \frac{\mathbf{x}(t_i) + \boldsymbol{\epsilon}_i}{\|\mathbf{x}(t_i) + \boldsymbol{\epsilon}_i\|}, \qquad \boldsymbol{\epsilon}_i \sim N\!\left(\mathbf{0}, \frac{\sigma_x^2}{d} \mathbf{I}_d\right)$$

The noise $\boldsymbol{\epsilon}_i$ is applied in all $d$ dimensions (including inactive ones), so that type vectors are not exactly confined to the $s$-dimensional subspace of the curve. The per-dimension noise scale $\sigma_x / \sqrt{d}$ is chosen so that the expected Euclidean distance from an agent to its curve position is approximately $\sigma_x$ regardless of $d$. The result is then re-projected to the unit sphere.

The parameter $s$ controls the complexity of the matching problem. When $s = d$, the curve spans all $d$ dimensions: agents nearby on the curve have similar types, while agents far apart point in genuinely different directions across all of $\mathbb{R}^d$. This full-dimensional diversity is what makes the interaction (§1c) vary in fundamentally different ways across agents, and what makes cross-agent data valuable to the broker (§1d). When $s < d$, the curve is confined to a lower-dimensional subspace, reducing the effective complexity of the matching problem and narrowing the broker's informational advantage.

#### Broker

A single broker serves the market. The broker is characterized by:

- **Experience history** $\mathcal{H}_b^t = \{(\mathbf{x}_i, \mathbf{x}_j, q_{ij})\}$: the set of (demander type, counterparty type, realized match output) triples from all matches the broker has mediated (§2b).
- **Roster** $\text{Roster}^t$: the set of agents the broker knows and can propose as counterparties. Grows over time as agents outsource to the broker (§7).
- **Reputation** $\text{rep}^t$: the average satisfaction of current client agents (§6).

### 1. The Matching Problem

The model's central dynamics depend on a matching problem: how valuable will the match between agents $i$ and $j$ be? No agent knows the answer in advance; all must learn it from experience.

The structure of the matching problem and how the broker and agents try to solve it determines whether and when the broker develops an informational advantage over the agents it serves.

**Match quality** (§1a) is symmetric — it is a property of the pairing, not of which party initiated the match — and decomposes into two components:

- **General quality** (§1b): each party's baseline contribution to any match, independent of who the other party is.
- **Match-specific interaction** (§1c): how well this particular pairing works, depending on both parties' types.

The broker, which mediates matches across many agents, observes the same agent types producing different outcomes with different counterparties; whereas each agent only sees its own matching history.

The matching function is symmetric: $f(\mathbf{x}_i, \mathbf{x}_j) = f(\mathbf{x}_j, \mathbf{x}_i)$. Match quality is a property of the pairing, not of which party initiated the match. This is a natural assumption for the illustrative domains. In interdealer brokerage, a trade's value depends on the complementarity of two dealers' positions — both sides benefit from a well-matched trade. In strategic alliances, a partnership's value depends on the complementarity of capabilities — both partners benefit from a good fit. In collector networks, a transaction's value depends on the alignment of tastes and holdings — both sides gain from a well-matched exchange.

#### 1a. Match quality

Let $q_{ij}$ represent the **per-period value of the match between agents $i$ and $j$**. It is a function of both agents' types, it is measured in monetary units, and it represents the economic value the match generates:

$$q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}, \qquad
\varepsilon_{ij} \sim N(0, \sigma_\varepsilon^2)$$

where $Q = 1.0$ is a constant offset that shifts $q$ positive for downstream economic computations (surplus, fees, satisfaction), and $\sigma_\varepsilon = 0.25$. The noise term $\varepsilon_{ij}$ represents idiosyncratic match-specific variation (unobserved characteristics, timing, context) that is irreducible even with perfect knowledge of $f$.

The matching function $f: \mathbb{R}^d \times \mathbb{R}^d \to \mathbb{R}$ is unknown to all agents and fixed for the duration of the simulation. The offset $Q$ is deliberately excluded from $f$ so that $f$ represents the pure signal structure of the data-generating process.

The deterministic matching function has two components, the first relating to each party's general quality and the second to their pairing complementarity:

$$f(\mathbf{x}_i, \mathbf{x}_j) = \rho \cdot \frac{1}{2}\!\left[\text{sim}(\mathbf{x}_i, \mathbf{c}) + \text{sim}(\mathbf{x}_j, \mathbf{c})\right] + (1 - \rho) \cdot \frac{1}{2}\!\left[\text{sim}(\mathbf{x}_i, \mathbf{A}\mathbf{x}_j) + \text{sim}(\mathbf{x}_j, \mathbf{A}\mathbf{x}_i)\right]$$

where $\text{sim}(\mathbf{a}, \mathbf{b}) = \mathbf{a}^\top \mathbf{b} / (\|\mathbf{a}\| \|\mathbf{b}\|)$ denotes cosine similarity between two vectors, and $\mathbf{A}$ is a $d \times d$ random matrix with iid $N(0, 1)$ entries drawn once at initialization (see §1c). Both components are symmetric under exchange of $i$ and $j$, so $f(\mathbf{x}_i, \mathbf{x}_j) = f(\mathbf{x}_j, \mathbf{x}_i)$.

#### 1b. General quality

General quality captures the portable value each party brings to any match, independent of who the counterparty is. Both parties contribute quality along the same dimension: alignment with an **ideal type vector** $\mathbf{c} \in \mathbb{R}^d$, which represents a quality archetype. Agents whose types are aligned with $\mathbf{c}$ (high cosine similarity) are high-quality counterparties in any match.

The vector $\mathbf{c}$ is drawn at initialization as a perturbation of a random point on the agent type curve with the same $\sigma_x / \sqrt{d}$ per-dimension noise used for regular agents.

The quality component is:

$$\frac{1}{2}\!\left[\text{sim}(\mathbf{x}_i, \mathbf{c}) + \text{sim}(\mathbf{x}_j, \mathbf{c})\right]$$

Each term is a cosine similarity in $[-1, 1]$, so the average is also in $[-1, 1]$. A match between two high-quality agents produces a high quality component; a match involving a low-quality agent is penalized regardless of the other party's quality.

Because $\text{sim}(\mathbf{x}, \mathbf{c})$ is a cosine similarity (not a dot product), ridge regression on features including $\mathbf{x}$ and $\mathbf{x}^2$ can partially learn it but cannot capture the normalization exactly. The parameter $\rho$ (§1d) controls how much the general quality component contributes to total match output.

#### 1c. Match-specific interaction

The match-specific interaction is the symmetrized cosine similarity between each agent's type and the $\mathbf{A}$-transformed type of the other:

$$\frac{1}{2}\!\left[\text{sim}(\mathbf{x}_i, \mathbf{A}\mathbf{x}_j) + \text{sim}(\mathbf{x}_j, \mathbf{A}\mathbf{x}_i)\right]$$

The matrix $\mathbf{A} \in \mathbb{R}^{d \times d}$ has iid $N(0, 1)$ entries and is drawn once at initialization. Because $\mathbf{A}$ mixes all $d$ dimensions, the interaction introduces cross-dimensional terms: the match-specific quality of the pairing depends on all $d^2$ products $x_{i,k} \cdot x_{j,l}$ (for $k, l = 1, \ldots, d$), not just the $d$ diagonal products $x_{i,k} \cdot x_{j,k}$.

The symmetrization averages both orderings of the $\mathbf{A}$-transformed interaction, ensuring $f(\mathbf{x}_i, \mathbf{x}_j) = f(\mathbf{x}_j, \mathbf{x}_i)$ even though $\mathbf{A}$ itself is not symmetric.

Bounded in $[-1, 1]$. For a fixed agent $i$, the interaction varies smoothly with $\mathbf{x}_j$ and is approximately learnable by ridge regression from the agent's matching history. The diagonal elementwise products $\mathbf{x}_i \odot \mathbf{x}_j$ capture only $d$ of the $d^2$ interaction terms induced by $\mathbf{A}$, while the full outer product $\mathbf{x}_i \otimes \mathbf{x}_j$ (a $d \times d$ matrix reshaped into $d^2$ features) captures all of them.

#### 1d. What controls the difficulty of the matching problem

- **$s$ (active dimensions).** When $s = d$, the type curve spans all $d$ dimensions, creating maximum diversity in interaction effects across agents. When $s < d$, the curve is confined to a lower-dimensional subspace, making the interaction structure lower-dimensional and easier for individual agents to learn from their own history. The broker's advantage is largest when $s$ is high.

- **Agent geometry.** Two aspects interact: (1) how agents are distributed around the curve ($\sigma_x$ relative to inter-agent spacing), and (2) how much of type space the curve spans (controlled by $s$). At the default $\sigma_x$, agents overlap with multiple neighbors' type regions, creating meaningful variation in match quality that requires data to learn.

- **$\rho$ (mixing weight).** At low $\rho$, the interaction dominates and cross-agent data is essential; the broker's advantage is large. At high $\rho$, general quality dominates and agents can learn from their own matches; the broker's advantage shrinks.

- **$\mathbf{A}$ (interaction matrix).** The random matrix $\mathbf{A}$ creates $d^2$ cross-dimensional interaction terms $x_{i,k} \cdot x_{j,l}$ that contribute to match quality. An agent observing only its own matches sees a fixed self-type and varying partner types, and can learn the interaction from the $d$ features in $\mathbf{x}_{\text{partner}}$ alone. The broker, observing matches across many pairs with varying types on both sides, benefits from representing all $d^2$ cross-terms via the outer product $\mathbf{x}_i \otimes \mathbf{x}_j$. This is the primary source of the broker's feature advantage.

- **$\sigma_\varepsilon$ (noise scale).** With $\sigma_\varepsilon = 0.25$ and signal in $[-1, 1]$, the signal-to-noise ratio is approximately 4:1.

### 2. Learning

Agents and the broker use predicted match quality $\hat{q}_{ij}$ in every core decision: which counterparties to select (§5), and whether to outsource matching (§6).

Both agents and the broker learn from experience using ridge regression, fitted each period on their accumulated history.

#### 2a. Agent $i$'s prediction

Agent $i$'s history $\mathcal{H}_i^t = \{(\mathbf{x}_j, q_{ij})\}_{m=1}^{n_i}$ records the other party's type and the realized match output from every match $i$ has participated in, regardless of role. Because the matching function is symmetric, a match where $i$ was the demander and a match where $i$ was the counterparty produce the same type of observation: the other party's type paired with the match output. The histories merge naturally.

Agent $i$ knows its own type $\mathbf{x}_i$. For a fixed agent, $f(\mathbf{x}_i, \mathbf{x}_j)$ combines a quality term and a symmetrized interaction term. Since $\mathbf{x}_i$ is fixed, both terms are functions of the other party's type $\mathbf{x}_j$ alone.

The agent fits a ridge regression model on its history $\mathcal{H}_i^t$ using $2d$ features:

$$\hat{q}_{i}(\mathbf{x}_j) = \hat{\boldsymbol{\beta}}_{i}^\top [\mathbf{x}_j; \mathbf{x}_j \odot \mathbf{x}_j] + \hat{\alpha}_{i}$$

where $\hat{\boldsymbol{\beta}}_{i}, \hat{\alpha}_{i}$ are the ridge regression coefficients fitted on $\{([\mathbf{x}_j; \mathbf{x}_j \odot \mathbf{x}_j], q_{ij})\}$ with regularization parameter $\lambda$ (default 1.0). The quadratic features $\mathbf{x}_j^2$ help approximate the cosine normalization in both the quality and interaction components.

The same model serves both roles: when searching for a counterparty (as demander), the agent evaluates candidates using $\hat{q}_i(\mathbf{x}_j)$; when receiving a proposal (as counterparty), the agent evaluates the proposer using $\hat{q}_i(\mathbf{x}_j)$. This is possible because $f$ is symmetric: the predicted match quality is the same regardless of which party initiated the match.

The model is refitted each period on the agent's full accumulated history.

#### 2b. Broker's prediction

The broker's history $\mathcal{H}_b^t = \{(\mathbf{x}_i, \mathbf{x}_j, q_{ij})\}_{m=1}^{n_b}$ records both parties' types and the realized match output from every match the broker has mediated. The ordering of $\mathbf{x}_i$ and $\mathbf{x}_j$ in the record is arbitrary (both orderings produce the same $q$ because $f$ is symmetric). The broker's history is seeded at initialization with observations from random pairings (§11c).

Unlike an individual agent, the broker observes the same agent types producing different outcomes with different partners. The broker fits a single pooled ridge regression on both parties' types, their full outer-product interaction, and quadratic features:

$$\hat{q}_b(\mathbf{x}_i, \mathbf{x}_j) = \hat{\boldsymbol{\beta}}_i^\top \mathbf{x}_i + \hat{\boldsymbol{\beta}}_j^\top \mathbf{x}_j + \hat{\boldsymbol{\beta}}_{ij}^\top \text{vec}(\mathbf{x}_i \otimes \mathbf{x}_j) + \hat{\boldsymbol{\beta}}_{i^2}^\top (\mathbf{x}_i \odot \mathbf{x}_i) + \hat{\boldsymbol{\beta}}_{j^2}^\top (\mathbf{x}_j \odot \mathbf{x}_j) + \hat{\alpha}_b$$

where the coefficients are fitted on $\{([\mathbf{x}_i; \mathbf{x}_j; \text{vec}(\mathbf{x}_i \otimes \mathbf{x}_j); \mathbf{x}_i^2; \mathbf{x}_j^2], q_{ij})\}$ with regularization $\lambda$. The feature vector is $[\mathbf{x}_i; \mathbf{x}_j; \text{vec}(\mathbf{x}_i \otimes \mathbf{x}_j); \mathbf{x}_i^2; \mathbf{x}_j^2]$, giving $d^2 + 4d$ features total. The outer-product features $\mathbf{x}_i \otimes \mathbf{x}_j$ capture all $d^2$ cross-dimensional interactions induced by the matrix $\mathbf{A}$ in the matching function (§1c), while the separate $\mathbf{x}_i$ and $\mathbf{x}_j$ blocks capture linear main effects and the quadratic terms help approximate cosine normalization for both parties. The broker does not enforce symmetry in its feature set; ridge regression learns the approximate symmetry from data. Refitted each period.

The broker's pooled model has three advantages over any individual agent's model:

1. **More data.** The broker accumulates observations across all client agents, giving it far more data points than any individual agent. With $n_b \gg n_i$, the broker's coefficient estimates have lower variance.

2. **Richer features.** By including both $\mathbf{x}_i$ and $\mathbf{x}_j$ as features, the broker's model captures how match quality varies across different pairings. Individual agents, with their own type fixed, cannot learn how the interaction structure varies with both parties' types.

3. **Outer-product interaction features.** The full outer product $\mathbf{x}_i \otimes \mathbf{x}_j$ gives the broker's linear model $d^2$ features that capture all cross-dimensional interactions $x_{i,k} \cdot x_{j,l}$ for every pair $(k, l)$. The matrix $\mathbf{A}$ in the matching function creates these cross-dimensional terms. An individual agent does not need these features (its own type is fixed, so the interaction is already a function of the other party's type alone), but the broker, fitting across agents with varying types on both sides, benefits from explicitly representing the full interaction structure.

#### 2c. The asymmetry between agents and the broker

An agent learns "what kind of partner works well for me" from a single, agent-specific history that pools all past matches regardless of role. It cannot distinguish general quality from agent-specific fit.

The broker learns "what kind of pairings work well" from a large cross-market sample. Its richer feature set ($[\mathbf{x}_i; \mathbf{x}_j; \text{vec}(\mathbf{x}_i \otimes \mathbf{x}_j); \mathbf{x}_i^2; \mathbf{x}_j^2]$, with $d^2 + 4d$ features) and larger data volume produce better predictions, especially when $s$ is high and the $d^2$ outer-product features capture the full cross-dimensional interaction structure induced by $\mathbf{A}$.

As agent $i$ accumulates more matches, its regression estimates improve and the broker's data advantage narrows. The broker's advantage is largest when agents have few observations and $s$ is high (more interaction structure to estimate from limited data).

#### 2d. Public information

A constant, scalar **public benchmark** $\bar{q}_{\text{pub}} = E[q]$ is computed once at initialization from a Monte Carlo sample of random agent pairs (§11c). This is the unconditional mean match output.

The benchmark initializes satisfaction indices (§6a) and broker reputation (§6).

### 3. Match Economics

Matches form when both parties expect positive gains from trade, following the standard search-and-matching framework.

#### 3a. Outside options

All agents share a common outside option $r$: the minimum per-period match value an agent requires to participate. Below this threshold, the agent prefers to remain unmatched. The outside option is calibrated at initialization:

$$r = 0.60 \cdot \bar{q}_{\text{pub}}$$

where $\bar{q}_{\text{pub}}$ is the mean match output computed from a Monte Carlo sample (§11c). The 0.60 calibration sets the outside option at 60% of average match value, producing a market where approximately 40% of match output is surplus available for gains from trade. A constant $r$ simplifies the broker's opaque intermediation decision (§13d) to a clean regime shift: the profitability comparison is the same for every counterparty.

#### 3b. Participation constraints

A match between demander $i$ and counterparty $j$ forms only if both parties predict positive gains:

- **Demander**: $\hat{q}_{i}(\mathbf{x}_j) > r$
- **Counterparty**: $\hat{q}_{j}(\mathbf{x}_i) > r$

Because the matching function is symmetric, both parties are predicting the same quantity — the match quality of the pairing — using the same type of model. Each evaluates whether the match is worth entering from its own perspective.

When the broker proposes a match, it applies the participation constraint using its own prediction: $\hat{q}_b(\mathbf{x}_i, \mathbf{x}_j) > r$. The counterparty still evaluates the proposal independently using its own model.

#### 3c. Broker fee

The broker charges a fixed per-match fee $\phi$ for each match it mediates. The fee is paid by the demander and is independent of match quality. The default $\phi$ is calibrated at initialization (§11c).

The fixed fee isolates the informational channel: the broker competes with agents' self-search solely on the quality of its match predictions, not on price. If the broker can attract and retain clients at a fixed fee, its value must derive from prediction accuracy (§6a) rather than price adjustments.

#### 3d. Satisfaction tracking

Each agent $i$ maintains a satisfaction index $s_{i,c}^t$ for each search channel $c$ (self-search and the broker). These scores summarize past matching outcomes and drive the outsourcing decision (§6).

The index is an exponentially weighted moving average (recency weight $\omega = 0.3$) of realized match value, net of broker fees when applicable:

$$s_{i,c}^{t+1} = (1 - \omega)\,s_{i,c}^t + \omega \cdot \tilde{q}$$

where $\tilde{q}$ is the satisfaction input:

| Channel | Satisfaction input $\tilde{q}$ |
|---------|-------------------------------|
| Self-search | $q_{ij}$ |
| Transparent brokered | $q_{ij} - \phi$ |
| Opaque brokered (M1, §13) | $\hat{q}_b - \psi$ (demander does not observe $q_{ij}$) |

**No-match penalty.** When a search channel fails to produce a match — either the broker makes no proposal (roster exhausted or no surplus-positive pair) or self-search yields no acceptable candidate — the corresponding satisfaction index decays toward zero:

$$s_{i,c}^{t+1} = (1 - \omega)\, s_{i,c}^t$$

Satisfaction indices are not floored: they can go negative, which is informative for the outsourcing decision. The EWMA's recency weighting ensures recovery from negative values within a few good observations.

New agents initialize all indices at the public benchmark $\bar{q}_{\text{pub}}$ (§2d).

### 4. Network Structure and Turnover

Agents interact through a single undirected network $G$ that determines each agent's search opportunities and structural position.

#### 4a. Network initialization

$G$ is initialized as a small-world graph (Watts & Strogatz, 1998), starting from a ring lattice where each agent is connected to its $k = 6$ nearest neighbors in the type space, with rewiring probability $p_{\text{rewire}} = 0.1$. Produces high clustering, short path lengths, and moderate type assortativity. Agents are ordered by first principal component of their type vectors before constructing the ring lattice, so that initial neighborhoods reflect type similarity.

#### 4b. Match tie formation

Each realized match (whether through self-search or brokered) adds an undirected edge between the demander and counterparty in $G$, if one does not already exist. Ties persist permanently — former counterparties remain connected after their match dissolves.

This is the sole mechanism of network densification. Each brokered match closes a structural hole that the broker bridged, contributing to the self-liquidating dynamic of structural-hole brokerage.

#### 4c. Agent turnover

Agents exit independently each period with probability $\eta$ (default 0.02), yielding an expected agent lifetime of 50 quarters (12.5 years).

Exiting agents are replaced by entrants with fresh types sampled from the curve at a random position $t \sim U[0,1]$ plus noise (same procedure as initialization), empty experience histories, and satisfaction indices initialized at $\bar{q}_{\text{pub}}$. The exiting agent's node in $G$ is removed (along with all its edges). The entrant is added to $G$ with $\lfloor k/2 \rfloor$ edges to agents sampled from the type neighborhood (probability $\propto \exp(-\|\mathbf{x}_{i'} - \mathbf{x}_j\|^2)$), mirroring the type-assortative structure of the initial network.

Turnover refreshes the broker's structural advantage by creating new disconnected agents who can only find counterparties through the broker or by slowly building connections through their own matches.

### 5. Search

Each period, agents with available capacity ($K - |M_i^t| > 0$) independently generate demand with probability $p_{\text{demand}}$ (default 0.50). An agent with demand either searches its own network (§5a) or outsources to the broker (§5b); the choice between the two channels is governed by the outsourcing decision rule (§6).

#### 5a. Self-search

Agent $i$ evaluates its direct network neighbors in $G$ as potential counterparties. Only neighbors with available capacity ($K - |M_j^t| > 0$) who are not already matched with $i$ are considered.

If no direct neighbor has available capacity, the agent goes unmatched this period and the no-match penalty applies (§3d).

For each candidate $j$, the agent predicts match quality using its model: $\hat{q}_{i}(\mathbf{x}_j)$. The agent selects the candidate with the highest predicted quality, provided the participation constraint is satisfied: $\hat{q}_{i}(\mathbf{x}_j) > r$ (§3b). If multiple candidates achieve the same maximum, one is selected uniformly at random. If no candidate yields positive predicted surplus, no match is proposed.

The selected counterparty $j$ then evaluates the proposal using its own model. The match forms only if $\hat{q}_{j}(\mathbf{x}_i) > r$ (§3b). If the counterparty rejects, the demander's demand persists to the next period.

#### 5b. Broker-mediated search

When agent $i$ outsources to the broker, the broker includes agent $i$ in its allocation for the current period. Agent $i$ is also added to the broker's roster if not already a member (§7).

At the end of Step 1 (after all outsourcing decisions), the broker observes its full client list $D^t$ (the set of demanders who outsourced this period) and the available roster members $\text{Roster}^t \cap \{\text{agents with available capacity}\}$. The broker computes predicted match quality $\hat{q}_b(\mathbf{x}_i, \mathbf{x}_j)$ for every (demander, available roster member) pair and assigns matches using a greedy best-pair heuristic (§9, Step 2b): iteratively select the highest-quality pair, propose that match, and remove both demander and counterparty from consideration. This continues until all demanders are matched, the roster is exhausted, or no remaining pair has positive predicted surplus ($\hat{q}_b > r_i$). The broker applies the same participation constraint as self-search: it does not propose matches with non-positive predicted surplus.

The counterparty then evaluates the proposal using its own model (§3b). If the counterparty rejects, the demander receives no proposal this period.

Agents whose demand is not filled (because the roster was exhausted, no candidate cleared the surplus threshold, or the counterparty rejected) receive no proposal. The agent's broker satisfaction decays toward zero (§3d).

After any match forms (whether via self-search or brokered), the realized match output $q_{ij}$ is observed by all parties. The broker adds the observation to its experience history for future predictions (§2).

### 6. The Outsourcing Decision

#### 6a. Decision rule

Each period, an agent with demand chooses between two search channels: self-search or the broker. The agent selects the channel with the higher satisfaction score. Ties are broken uniformly at random.

If the agent has not yet tried the broker, it substitutes broker reputation:

$$\text{rep}_b^t = \begin{cases} \frac{1}{|D_b^t|} \sum_{i \in D_b^t} s_{i,b}^t & \text{if } D_b^t \neq \emptyset \\[4pt] \text{rep}_b^{t-1} & \text{if } D_b^t = \emptyset \text{ and broker has had clients before} \\[4pt] \bar{q}_{\text{pub}} & \text{if broker has never had clients} \end{cases}$$

where $D_b^t$ is the set of agents currently using the broker. Reputation is **sticky**: when the broker loses all current clients, it retains the last reputation computed from actual client satisfaction. Only if the broker has *never* had any client does it default to $\bar{q}_{\text{pub}}$ (§2d).

### 7. Broker Roster

The broker maintains a **roster** of agents it knows and can propose as counterparties when mediating matches.

**Initialization.** The roster is seeded with a small set of agents (default 20) chosen uniformly at random from the population. The broker's history is seeded with observations from random pairings among these initial roster members (§11c).

**Growth.** Any agent who outsources to the broker in a given period is added to the roster permanently (if not already a member). The roster thus grows organically with broker usage.

**Availability.** A roster member is available for matching in a given period only if:
1. It has spare capacity: $|M_j^t| < K$.
2. It is not a demander being matched in the current period's allocation (an agent cannot be simultaneously a demander and a counterparty in the same broker allocation round).

There is no fixed roster size or target. The roster grows as the broker attracts clients, creating a network effect: a larger roster offers better matching options, which improves broker satisfaction, which attracts more outsourcing, which grows the roster further. In the early periods, when the roster is small, the broker has few counterparties to offer, naturally limiting its initial appeal.

### 8. Match Lifecycle

Matches last $\tau$ periods (default $\tau = 1$). During the match, both parties observe the realized match output. After $\tau$ periods, the match dissolves and both parties regain one unit of capacity.

**At match formation:**
1. Realized output is drawn: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$.
2. Both parties add the observation to their histories: the demander adds $(\mathbf{x}_j, q_{ij})$ to $\mathcal{H}_{i}$; the counterparty adds $(\mathbf{x}_i, q_{ij})$ to $\mathcal{H}_{j}$.
4. If brokered, the broker adds $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$.
5. An edge is added between $i$ and $j$ in $G$ (if not already present).

**At match expiration** (after $\tau$ periods): the match is removed from both parties' active match sets $M_i^t$ and $M_j^t$. Both regain one unit of capacity.

At $\tau = 1$ (the default), matches are transactional: they form and dissolve within the same period. Agents are always at full capacity at the start of each period, so the capacity constraint $K$ is effectively the maximum number of matches an agent can form per period. At $\tau > 1$, matches persist, and the capacity constraint becomes binding as agents accumulate active matches that have not yet expired.

### 9. Base Model Pseudocode

At the start of the simulation, the state of the world must be initialized.

> **INITIALIZE**
>
> *Agent types and matching function.*
> I.1. &emsp;Generate random frequencies $f_k$ and phases $\theta_k$ for the sinusoidal curve (§0).
> I.2. &emsp;Draw $N$ agent types: each at a random position $t_i \sim U[0,1]$ on the curve, perturbed by noise, and projected to the unit sphere.
> I.3. &emsp;Draw ideal type $\mathbf{c}$ (perturbation of a random curve position).
> I.4. &emsp;Draw interaction matrix $\mathbf{A} \in \mathbb{R}^{d \times d}$ with iid $N(0,1)$ entries.
>
> *Calibration.*
> I.5. &emsp;Compute $\bar{q}_{\text{pub}} = E[q]$ from 10,000 random agent pairs. Set $r \leftarrow 0.60 \cdot \bar{q}_{\text{pub}}$.
> I.6. &emsp;Set broker fee $\phi$ (§11b).
>
> *Network.*
> I.7. &emsp;Build $G$: Watts–Strogatz with $N$ nodes, degree $k$, rewiring $p_{\text{rewire}}$. Node order = agents sorted by first principal component of type.
>
> *Broker.*
> I.8. &emsp;Seed broker roster with 20 randomly chosen agents.
> I.9. &emsp;Seed broker history $\mathcal{H}_b$ with 20 observations from random pairings among roster members (realize match outputs and record).
>
> *State variables.*
> I.10. &emsp;For each agent $i$: seed $\mathcal{H}_{i}$ with 5 random pairings (sample 5 agents uniformly, realize match outputs, record); $s_{i,\text{self}}^0 \leftarrow \bar{q}_{\text{pub}}$; $s_{i,\text{broker}}^0 \leftarrow \bar{q}_{\text{pub}}$; $M_i^0 \leftarrow \emptyset$.
> I.11. &emsp;$\text{rep}^0 \leftarrow \bar{q}_{\text{pub}}$; $\Pi_b \leftarrow 0$.

Each period proceeds through seven steps.

> **PERIOD $t$:**
>
> **0. MATCH EXPIRATIONS**
> 0.1. &emsp;For each active match that has lasted $\tau$ periods: remove from both parties' active match sets. Both regain one unit of capacity.
>
> **1. DEMAND GENERATION AND OUTSOURCING DECISIONS**
> 1.1. &emsp;Carry forward unfilled demand from $t{-}1$.
> 1.2. &emsp;For each agent $i$ with available capacity ($K - |M_i^t| > 0$) and no carried-over demand: generate new demand with probability $p_{\text{demand}}$.
> 1.3. &emsp;For each agent $i$ with demand (new or carried over):
> &emsp;&emsp;$\text{score}_{\text{self}} \leftarrow s_{i,\text{self}}^t$
> &emsp;&emsp;$\text{score}_{\text{broker}} \leftarrow s_{i,\text{broker}}^t$ &ensp;(use $\text{rep}^t$ if untried; §6a)
> &emsp;&emsp;$\text{decision}_i \leftarrow \arg\max(\text{score}_{\text{self}},\; \text{score}_{\text{broker}})$
> &emsp;&emsp;If $\text{decision}_i = \text{broker}$: add $i$ to broker roster (if not already present)
> &emsp;Output: partition of demanders into self-searchers and broker client list $D^t$.
>
> **2. CANDIDATE EVALUATION**
>
> &emsp;**2.1. Fit prediction models:**
> 2.1.1. &emsp;For each agent $i$: refit ridge model on $\mathcal{H}_{i}^t$ (§2a).
> 2.1.2. &emsp;Refit broker's pooled ridge model on $\mathcal{H}_b^t$ (§2b).
>
> &emsp;**2.2. Self-searches:**
> 2.2.1. &emsp;For each agent $i$ with $\text{decision}_i = \text{self}$:
> &emsp;&emsp;Collect candidates: direct neighbors of $i$ in $G$ with available capacity, not already matched with $i$.
> &emsp;&emsp;For each candidate $j$: predict $\hat{q}_{i}(\mathbf{x}_j)$ using agent's model.
> &emsp;&emsp;Select $j^* = \arg\max \hat{q}_{i}(\mathbf{x}_j)$ &ensp;(ties broken uniformly at random)
> &emsp;&emsp;If $\hat{q}_{i}(\mathbf{x}_{j^*}) \leq r$: no proposal (demand persists to next period).
> &emsp;&emsp;Else: record proposed match $(i, j^*)$.
>
> &emsp;**2.3. Broker proposals:**
> 2.3.1. &emsp;Collect client list: $D^t = \{i : \text{decision}_i = \text{broker}\}$.
> 2.3.2. &emsp;$\text{available\_roster} \leftarrow \text{Roster}^t \cap \{\text{agents with available capacity}\} \setminus D^t$.
> 2.3.3. &emsp;Compute quality matrix: $\hat{Q}[i,j] = \hat{q}_b(\mathbf{x}_i, \mathbf{x}_j)$ for all $i \in D^t$, $j \in \text{available\_roster}$.
> 2.3.4. &emsp;While $D^t$ non-empty AND available\_roster non-empty:
> &emsp;&emsp;$(i^*, j^*) = \arg\max \hat{Q}[i,j]$ &ensp;(ties broken uniformly at random)
> &emsp;&emsp;If $\hat{Q}[i^*, j^*] \leq r$: break (no remaining pair has positive surplus)
> &emsp;&emsp;Record proposed match $(i^*, j^*)$
> &emsp;&emsp;Remove $i^*$ from $D^t$; remove $j^*$ from available\_roster.
> 2.3.5. &emsp;If $D^t$ non-empty (roster exhausted or no surplus-positive pair): for each remaining $i \in D^t$, mark as no-proposal.
>
> **3. MATCH FORMATION**
>
> &emsp;**3.1. Counterparty acceptance:**
> 3.1.1. &emsp;For each proposed match $(i, j)$:
> &emsp;&emsp;Counterparty $j$ evaluates: $\hat{q}_{j}(\mathbf{x}_i)$ using its model.
> &emsp;&emsp;If $\hat{q}_{j}(\mathbf{x}_i) \leq r$: reject. Demander's demand persists.
> &emsp;&emsp;Else: accept.
>
> &emsp;**3.2. Conflict resolution:**
> 3.2.1. &emsp;Collect all accepted proposals from both channels. If an agent appears as counterparty in multiple accepted proposals, it accepts the proposal with the highest predicted quality from its model (ties broken randomly). Rejected proposals are discarded; the demander's demand persists.
>
> &emsp;**3.3. Finalization** (for each finalized match $(i, j)$):
> 3.3.1. &emsp;Realize output: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$.
> 3.3.2. &emsp;Add match to active sets: $M_i^{t+1} \leftarrow M_i^t \cup \{j\}$; $M_j^{t+1} \leftarrow M_j^t \cup \{i\}$.
> 3.3.3. &emsp;Add edge $(i, j)$ to $G$ if not already present.
> 3.3.4. &emsp;Record: channel (self/broker), $q_{ij}$, predictions used, whether $j$ was a direct neighbor of $i$ in $G$.
>
> **4. LEARNING AND STATE UPDATES**
> 4.1. &emsp;For each finalized match $(i, j)$:
> &emsp;&emsp;Add $(\mathbf{x}_j, q_{ij})$ to $\mathcal{H}_{i}$ (demander's history).
> &emsp;&emsp;Add $(\mathbf{x}_i, q_{ij})$ to $\mathcal{H}_{j}$ (counterparty's history).
> &emsp;&emsp;If brokered: add $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$; $\Pi_b \leftarrow \Pi_b + \phi$.
>
> 4.2. &emsp;Update satisfaction indices (§3d):
> &emsp;&emsp;For each agent $i$ that formed a new match via channel $c$:
> &emsp;&emsp;&emsp;If self-search: $\tilde{q} = q_{ij}$
> &emsp;&emsp;&emsp;If brokered: $\tilde{q} = q_{ij} - \phi$
> &emsp;&emsp;&emsp;$s_{i,c}^{t+1} = (1 - \omega)\, s_{i,c}^t + \omega \cdot \tilde{q}$
> &emsp;&emsp;For each agent $i$ whose chosen channel produced no match this period:
> &emsp;&emsp;&emsp;$s_{i,c}^{t+1} = (1 - \omega) \cdot s_{i,c}^t$ &ensp;(no-match penalty; §3d)
>
> 4.3. &emsp;Update broker reputation (sticky; §6a):
> &emsp;&emsp;$\text{active\_clients}^t \leftarrow D^t$ (agents who outsourced this period)
> &emsp;&emsp;If $|\text{active\_clients}^t| > 0$: $\text{rep}^{t+1} \leftarrow \text{mean of } s_{i,\text{broker}}^{t+1} \text{ over } i \in \text{active\_clients}^t$ (uses post-update satisfaction); store as last\_reputation.
> &emsp;&emsp;Else if broker has had clients before: $\text{rep}^t \leftarrow$ last\_reputation.
> &emsp;&emsp;Else: $\text{rep}^t \leftarrow \bar{q}_{\text{pub}}$.
>
> **5. ENTRY AND EXIT**
> 5.1. &emsp;For each agent $i$:
> &emsp;&emsp;With probability $\eta$: agent exits.
> &emsp;&emsp;&emsp;Remove $i$ from $G$ (node and all edges).
> &emsp;&emsp;&emsp;Terminate all active matches involving $i$; counterparties regain capacity.
> &emsp;&emsp;&emsp;Remove $i$ from broker roster (if present).
> &emsp;&emsp;&emsp;Replace with entrant $i'$: fresh type from curve + noise; empty histories; satisfaction at $\bar{q}_{\text{pub}}$; added to $G$ with $\lfloor k/2 \rfloor$ edges to agents sampled from the type neighborhood (probability $\propto \exp(-\|\mathbf{x}_{i'} - \mathbf{x}_j\|^2)$).
>
> **6. NETWORK MEASURES** (computed every $M$ periods, default $M = 10$):
> 6.1. &emsp;Construct augmented graph: $G$ plus broker node connected to all roster members.
> 6.2. &emsp;Compute: betweenness centrality $C_B(b)$ (broker node); Burt's constraint (broker's ego network); effective size (broker's ego network).
> 6.3. &emsp;Compute prediction quality ($R^2$, bias, rank correlation) for broker and agents (§10).
>
> **7. PERIOD RECORDING** (every period):
> 7.1. &emsp;Record period aggregates: match quality by channel; outsourcing rate ($|D^t| / |\text{demanders}|$); roster size.
> 7.2. &emsp;Record broker state: cumulative revenue $\Pi_b$; reputation $\text{rep}^t$; roster size; $|\mathcal{H}_b^t|$.

#### Parallelism summary

Steps 0 and 1 are embarrassingly parallel across agents. Step 2.2 (self-searches) is parallel across agents. Step 3 requires a conflict resolution pass but per-match computations are parallel. Steps 4–5 involve writes to shared state that require synchronization, but writes are non-overlapping (each match writes to distinct agent records). Network measures are the most expensive single computation; they read the full state but write nothing and can be offloaded to a separate thread or deferred to a coarser schedule.

### 10. Performance Measures

Computed on the augmented graph (§9, Step 6) each measurement period. No agent uses these measures in its decisions; they are outputs for analysis.

#### Network measures

**Betweenness centrality.** Standard Freeman betweenness (Freeman, 1977) computed on the augmented graph (G plus broker node connected to all roster members). The broker's betweenness is the fraction of all shortest paths that pass through it, normalized by $\binom{N+1}{2}$:

$$C_B(b) = \frac{1}{\binom{N+1}{2}} \sum_{i \neq j \neq b} \frac{\sigma_{ij}(b)}{\sigma_{ij}}$$

where $\sigma_{ij}$ is the number of shortest paths from $i$ to $j$, and $\sigma_{ij}(b)$ is the number of those paths passing through broker node $b$. As matches create direct ties, shortest paths increasingly bypass the broker, reducing betweenness — the structural erosion that the theory predicts.

**Burt's constraint.** Computed on the broker's ego network (Burt, 1992):

$$C_b = \sum_j \left(p_{bj} + \sum_{q \neq b,j}
p_{bq}\, p_{qj}\right)^2$$

where $p_{bj}$ is the proportion of the broker's ties invested in node $j$. Low constraint = broker spans structural holes. High constraint = broker's contacts are interconnected.

**Effective size.** The number of non-redundant contacts in the broker's ego network (Burt, 1992): $\text{ES}_b = |N(b)| - \sum_j p_{bj} \sum_{q \neq b} p_{bq}\, m_{jq}$ where $m_{jq} = 1$ if $j$ and $q$ are connected.

#### Prediction quality

**Winner's curse / selection bias.** Both agents and the broker select the counterparty with the highest *predicted* match quality from their candidate set ($\arg\max_j \hat{q}_{ij}$). When predictions are noisy, the selected counterparty's prediction $\hat{q}_{ij^*}$ is systematically inflated relative to the true match quality $f(\mathbf{x}_i, \mathbf{x}_{j^*})$, because the selection picks up positive noise realizations. This is the classic winner's curse.

**Holdout $R^2$ (model quality).** Each period, a sample of random agent pairs is evaluated using noiseless true match quality $f(\mathbf{x}_i, \mathbf{x}_j)$ as the target. These pairs are *not* selected by any agent's model. Holdout $R^2$ measures pure model quality: how well the regression model approximates the true matching function. It is the cleanest measure of informational advantage because it is uncontaminated by the winner's curse or by variation in candidate pool composition.

**Selected-sample metrics.** Three metrics are computed over a rolling window of the last 50 actual matches:

- *Selected $R^2$* $= 1 - \text{MSE}/\text{Var}(q)$. Because matched counterparties are those with the highest predictions, this sample is subject to the winner's curse: predictions are systematically inflated relative to outcomes, depressing $R^2$.

- *Bias* $= \frac{1}{n}\sum(\hat{q} - q)$. Tracks systematic over- or underprediction. Positive bias is expected in the selected sample due to the winner's curse.

- *Selected rank correlation* (Spearman's $\rho_S$). Measures whether the agent ranks matched counterparties correctly by realized output. The rank correlation is less affected by the winner's curse than $R^2$ because it is invariant to monotone transformations.

**Minimum variance threshold for $R^2$.** When $\text{Var}(q) < \sigma_\varepsilon^2 / 6 \approx 0.01$, the realized output variance in the sample is too small relative to the noise floor for $R^2$ to be informative. Below this threshold, $R^2$ returns NaN.

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

**Outsourcing rate.** Fraction of demand that is outsourced to the broker: $|D^t| / |\text{demanders}^t|$.

**Roster size.** Number of agents in the broker's roster, tracking the growth of the broker's candidate network.

## Part II. Parameters, Calibration, and Initialization

### 11. Parameters

#### 11a. Parameter table

Parameters are organized into four categories reflecting their role in the analysis.

**Structural constants.** Define the model's mechanisms. Values are set by design rationale and not varied.

| Symbol | Meaning | Value | Notes |
|--------|---------|-------|-------|
| $d$ | Type dimensionality | 8 | Fixed |
| $K$ | Match capacity | 5 | Max simultaneous active matches per agent |
| $\tau$ | Match duration | 1 | Periods per match |
| $k$ | Network mean degree | 6 | Watts-Strogatz ring lattice degree |
| $p_{\text{rewire}}$ | Network rewiring probability | 0.1 | Watts-Strogatz rewiring |
| $\omega$ | Satisfaction recency weight (§3d) | 0.3 | EWMA weight |
| $p_{\text{demand}}$ | Per-period demand probability | 0.50 | Per agent with available capacity |
| $\sigma_x$ | Type noise scale | 0.5 | Expected distance from agent to curve position |

**Calibration parameters.** Set during model development. Constant in production runs.

| Symbol | Meaning | Default | Notes |
|--------|---------|---------|-------|
| $r$ | Outside option | $0.60 \cdot \bar{q}_{\text{pub}}$ | Constant for all agents; calibrated at initialization |
| $\lambda$ | Ridge regularization | 1.0 | For all ridge regression models |
| $\sigma_\varepsilon$ | Match output noise SD | 0.25 | SNR ≈ 4:1 |
| $\phi$ | Broker fee | See §11b | Fixed per match |

**Phase diagram axes.** Primary parameters of interest.

| Symbol | Meaning | Default | Sweep |
|--------|---------|---------|-------|
| $s$ | Active dimensions | 8 | {2, 4, 6, 8} |
| $\rho$ | Quality-interaction mixing weight | 0.50 | {0, 0.10, 0.30, 0.50, 0.70, 0.90, 1.0} |

**Model 1 parameters.** Apply only under resource capture (§13).

| Symbol | Meaning | Default | Notes |
|--------|---------|---------|-------|
| $\psi$ | Opaque intermediation fee | See §13e | Fixed per period per match; calibrated as $\alpha_\psi \cdot \bar{q}_{\text{pub}}$ |
| $\xi$ | Exclusivity flag | 1 | $\xi = 1$: full exclusivity (agent cannot self-search while in any opaque match); $\xi = 0$: per-slot independence |

**OAT sensitivity parameters.** Varied one at a time while holding all others at defaults.

| Symbol | Meaning | Default | Sweep |
|--------|---------|---------|-------|
| $\eta$ | Agent entry/exit rate | 0.02 | {0.01, 0.02, 0.05, 0.10} |
| $\psi$ | Opaque intermediation fee | See §13e | Sweep around default |
| $\xi$ | Exclusivity flag | 1 | {0, 1} |

**Implementation parameters.** Control simulation scale.

| Symbol | Meaning | Default | Scale check |
|--------|---------|---------|-------------|
| $N$ | Agent population | 500 | {250, 500, 1000} |
| $T$ | Simulation length (periods) | 200 | {100, 200, 400} |
| $T_{\text{burn}}$ | Burn-in periods (discarded) | 30 | — |
| $M$ | Network measure interval | 10 | — |

#### 11b. Broker fee calibration

The broker fee $\phi$ is set to a fraction of the average match surplus: $\phi = \alpha_\phi \cdot (\bar{q}_{\text{pub}} - r_{\text{base}})$, where $\alpha_\phi = 0.20$ (default). This ensures the fee is economically meaningful (large enough that outsourcing is a real cost) but not prohibitive (small enough that better match quality can justify the expense). The fee is computed once at initialization and held constant.

#### 11c. Initial conditions

The initialization procedure generates the matching environment, agents, and network in the following order.

1. **Agent types** (§0). Generate random frequencies and phases for the sinusoidal curve. Draw $N$ agent types at random curve positions with noise. Project to unit sphere.
2. **Matching function** (§1). Draw ideal type $\mathbf{c}$ (perturbation of a random curve position). Draw interaction matrix $\mathbf{A}$.
3. **Calibration.** Compute $\bar{q}_{\text{pub}}$ from 10,000 random agent pairs. Set $r = 0.60 \cdot \bar{q}_{\text{pub}}$. Set $\phi$ per §11b.
4. **Agent histories.** For each agent $i$: seed $\mathcal{H}_i$ with 5 random pairings (sample 5 agents uniformly, realize match outputs, record).
5. **Network** (§4a). Build Watts-Strogatz graph with agents ordered by first principal component.
6. **Broker** (§7). Seed roster with 20 random agents. Seed $\mathcal{H}_b$ with 20 random pairings among roster members (realize outputs, record).
7. **State variables.** For each agent: satisfaction at $\bar{q}_{\text{pub}}$, empty active match sets. Broker reputation at $\bar{q}_{\text{pub}}$.

#### 11d. Reproducibility

All randomness flows from a single integer seed. The seed determines: type draws, the realization of $G$, matching function parameters ($\mathbf{c}$, $\mathbf{A}$), broker seed roster, and all subsequent random events. Simulations are fully reproducible given (parameter dictionary, seed).

### 12. Verification and Robustness

#### 12a. Verifying the no-capture region

The model must produce parameter combinations where the broker remains a commodity intermediary. If capture occurs for every parameter setting, the model does not demonstrate transient brokerage but inevitable capture.

The key verification concern is that the positive feedback loop (more outsourcing → more broker data → better predictions → more outsourcing) produces capture in some regimes and not in others.

#### 12b. Analytic benchmark for the broker's advantage

All agents use ridge regression. For a linear target with Gaussian noise, ridge regression MSE scales as $\text{MSE} \sim p / n + \lambda \|\beta^*\|^2$, where $p$ is the number of features and the first term is estimation error (decreasing in $n$).

**Agent.** Agent $i$ fits $q \approx \beta^\top [\mathbf{x}_j; \mathbf{x}_j^2] + c$ from $n_i$ observations ($2d + 1$ parameters).

**Broker.** The broker fits $q \approx \beta^\top [\mathbf{x}_i; \mathbf{x}_j; \text{vec}(\mathbf{x}_i \otimes \mathbf{x}_j); \mathbf{x}_i^2; \mathbf{x}_j^2] + c$ from $n_b$ observations ($d^2 + 4d + 1$ parameters).

**Advantage condition.** The broker outperforms the agent when:

$$\frac{d^2 + 4d}{n_b} < \frac{2d}{n_i} \quad \Longrightarrow \quad n_b > \frac{d + 4}{2} \cdot n_i$$

At $d = 8$, the broker needs $n_b > 6 \cdot n_i$. Since the broker pools observations across all clients, this is easily satisfied after a few periods.

## Part III. Model Variant: Resource Capture (Opaque Intermediation)

All base model mechanisms (§§0–10) operate unchanged. The difference: the broker can additionally offer **opaque intermediation**, where it mediates a match without revealing either party's type to the other. This implements the resource capture mode of Proposition 3a.

### 13. Opaque Intermediation

#### 13a. Setup

Under opaque intermediation, the broker mediates a match between two agents while controlling the information flow between them. Neither party observes the other's type. The broker earns a per-period intermediation fee rather than a one-time placement fee, and it bears the risk of guaranteeing the counterparty's outside option.

**Agent state additions.** Matches gain a flag: *transparent* (standard brokerage, as in the base model) or *opaque* (intermediated). No new agent-level state variables are needed.

**Exclusivity parameter.** A binary parameter $\xi \in \{0, 1\}$ (default 1) controls whether opaque intermediation produces full or partial lock-in:
- $\xi = 1$ (exclusive): an agent that accepts any opaque match cannot self-search for the remainder of that period. All of the agent's demand is routed through the broker. This prevents the agent from learning on other capacity slots, producing total information freeze.
- $\xi = 0$ (per-slot): opaque matches consume one capacity slot independently. Other slots remain available for self-search. Lock-in is partial: agents with $K > 1$ can still learn from self-search on their remaining slots.

#### 13b. Mechanism

When the broker mediates a match under opaque mode between demander $i$ and counterparty $j$:

1. Match output is realized: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$.
2. **The broker receives the match output $q_{ij}$** and is the sole party that observes both types. The broker pays the counterparty $r$ (the guaranteed outside option) and charges the demander $\psi$ (the intermediation fee). The broker's per-period profit is $\psi + q_{ij} - r$, which can be negative when $q_{ij} < r - \psi$.
3. **Neither party observes the other's type.** The demander does not observe $\mathbf{x}_j$ or $q_{ij}$. The counterparty does not observe $\mathbf{x}_i$ or $q_{ij}$. Neither party can update its prediction history, because histories require (type, outcome) pairs (§2a).
4. **No edge is added to $G$.** The parties are unaware of each other's existence. The structural hole between them remains open.
5. **The broker adds $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$.** The broker is the only agent that learns from opaque matches.

#### 13c. Counterparty participation

Under opaque intermediation, the counterparty cannot evaluate the match using its own model: it does not observe the demander's type before the match forms. Instead, the broker guarantees the counterparty's outside option.

**The broker pays the counterparty $r$ per period for the duration of the match**, regardless of realized match output. This makes counterparty acceptance automatic: the counterparty receives at least its outside option and bears no risk.

The broker absorbs the match quality risk. The broker's per-period cash flow on an opaque match is $\psi + q_{ij} - r$: it receives the intermediation fee from the demander, captures the match output, and pays the counterparty's guaranteed outside option. When the broker's predictions are accurate, it selects high-quality matches and $q_{ij}$ is reliably above $r$, producing positive margins. When predictions are noisy (early in the transition), $q_{ij}$ can fall below $r$, and the broker absorbs the shortfall. This risk-bearing is a defining property of capture — the broker is acting as a principal, not a pure intermediary.

#### 13d. Broker's decision: transparent vs. opaque

Each time the broker fills a match for demander $i$ with counterparty $j$, it compares expected profit from transparent placement against opaque intermediation:

$$\Pi^{\text{transparent}} = \phi$$

$$\Pi^{\text{opaque}} = \psi + \hat{q}_b(\mathbf{x}_i, \mathbf{x}_j) - r$$

where $\phi$ is the one-time placement fee (§3c), $\psi$ is the per-period opaque intermediation fee (§13e), and $\hat{q}_b$ is the broker's predicted match quality. Under transparent placement, the broker earns only the fee. Under opaque intermediation, the broker captures the match output, pays the counterparty's outside option, and earns the intermediation fee. Both quantities are evaluated per period (at $\tau = 1$, each match lasts one period).

The broker chooses opaque intermediation when $\psi + \hat{q}_b - r > \phi$. This is a purely economic comparison with no prediction confidence threshold. Early in the simulation, the broker's predictions are inaccurate, so $\hat{q}_b$ for selected candidates tends to be moderate and the expected margin $\hat{q}_b - r$ is small or uncertain. As predictions improve, the broker reliably identifies high-output matches where $\hat{q}_b \gg r$, making opaque intermediation increasingly profitable.

The capture dynamic does not rely on long-duration lock-in. It relies on **informational dependency**: opaque intermediation prevents agents from learning, which causes their self-search quality to stagnate, which keeps them outsourcing to the broker, which generates repeat business at the intermediation fee. The ongoing revenue comes from sticky client relationships driven by informational asymmetry, not from contractual duration.

#### 13e. Intermediation fee

The opaque intermediation fee $\psi$ is fixed per period per match, parallel to the placement fee $\phi$ (§3c). The broker competes on match quality at a fixed price in both modes, isolating the informational channel.

The calibration follows the same logic as $\phi$ (§11b): $\psi = \alpha_\psi \cdot \bar{q}_{\text{pub}}$, where $\alpha_\psi$ is set so that the broker earns a positive expected margin ($\psi + \bar{q}_{\text{pub}} - r > 0$) when match quality is at or above the public benchmark.

Under opaque intermediation, the demander does not receive the match output (the broker does). The demander pays $\psi$ for the broker's matching service and observes neither $q_{ij}$ nor $\mathbf{x}_j$. The demander's satisfaction input is the broker's predicted match quality minus the fee: $\hat{q}_b - \psi$. This is what the demander can infer about the value of the service: the broker's reputation and the demander's past experience with brokered match quality. For comparison, under transparent placement the input is $q_{\text{realized}} - \phi$, and under self-search it is $q_{\text{realized}}$ (§3d).

#### 13f. Lock-in dynamics

Opaque intermediation produces a **double lock-in**:

**Informational lock-in.** Neither party observes counterparty types. Prediction histories do not grow. Ridge regression models cannot be refitted on new data. The agent's prediction quality stagnates at whatever level it had reached before entering opaque intermediation.

**Structural lock-in.** No direct tie forms in $G$. The network does not densify from opaque matches. Structural holes between agents remain open. The broker's betweenness centrality does not decline from these matches.

Under exclusivity ($\xi = 1$), lock-in extends to all of the agent's capacity slots: the agent cannot self-search on any slot while in an opaque match, so it gains no new observations from any source. This produces total information freeze.

**Positive feedback loop.** Opaque intermediation prevents agent learning → agent's self-search quality stagnates or declines relative to the broker's improving predictions → agent's self-search satisfaction falls below broker satisfaction → agent continues outsourcing → broker earns $\psi$ per period and continues learning → broker's predictions improve further → more matches are profitable under opaque mode → more agents locked in.

This feedback loop is self-reinforcing once initiated, producing the abrupt capture trajectory predicted by Proposition 3a. The self-liquidating dynamic of structural advantage is suspended: because opaque matches create no direct ties, the broker's structural position stops eroding.

#### 13g. Illustrative domains

Opaque intermediation isolates the *information-control dimension* of capture: the broker's ability to prevent clients from learning about counterparties and forming direct ties. In practice, real-world capture transitions typically bundle information control with inventory risk (the broker also becomes a principal on one side of the match). The model implements information control in isolation. Option B in §15a describes a richer variant that adds inventory risk.

**Interdealer brokerage.** Anonymous intermediation. Voice brokers and dark pools arrange trades where neither dealer knows the counterparty's identity ("name give-up" only at settlement, if at all). The broker controls information flow between dealers, preventing bilateral relationships from forming. The full real-world transition — anonymous broker to principal trader or electronic platform — combines this anonymity with inventory risk.

**JV / alliance brokerage.** The broker structures partnerships through a proprietary process, retaining control of relationship intelligence. Partners interact through the broker's framework rather than directly. The broker controls which capabilities are visible to which party and manages the interface between them. The full transition — advisor to PE firm assembling portfolio companies — adds principal risk.

**Collector networks.** Anonymous dealer intermediation. The dealer arranges transactions where buyer and seller do not know each other's identity, a standard practice in art, antiques, and wine markets to prevent disintermediation. The full transition — anonymous broker to dealer taking inventory — adds holding risk.

#### 13h. Channel comparison

| | Base (no capture) | Resource capture (opaque) | Data capture (§15b) |
|---|---|---|---|
| Who matches? | Agent matches directly | Broker mediates | Agent matches directly |
| Agent observes counterparty type? | Yes | No | Yes |
| Agent's prediction model improves? | Yes | No | Yes |
| Whose predictions guide selection? | Agent's own | Broker's | Broker's (sold to agent) |
| Direct tie forms? | Yes | No | Yes |
| Structural erosion? | Continues | Suspended | Continues |
| Broker revenue | Per-match fee $\phi$ | Per-period fee $\psi$ | Per-period subscription $\mu$ |
| Broker learns from match? | Yes | Yes | No (agent matched directly) |
| Predicted trajectory | Self-liquidating | Abrupt capture (Prop 3a) | Gradual capture (Prop 3b) |

The two capture modes differ on every dimension except the last column header. Under resource capture, the broker controls information and prevents learning. Under data capture, the broker *sells* information and learning continues. These are two ways of monetizing the same informational asset — by keeping it private or by licensing it.

A subtle asymmetry: under resource capture, the broker keeps learning (it mediates the match and observes both types). Under data capture, the broker's learning *slows* because agents match directly and the broker does not observe those outcomes unless a reporting mechanism exists. This creates a natural ceiling on data capture that resource capture does not face, and may contribute to the gradual-vs-abrupt distinction.

#### 13i. Pseudocode modifications

Steps not listed are identical to the base model pseudocode (§9).

<small>

> **2. CANDIDATE EVALUATION** (opaque branch added)
>
> &emsp;**2.3. Broker proposals** (unchanged from base):
> 2.3.1–2.3.5: as in §9.
>
> &emsp;**2.4. Broker mode selection** (new):
> 2.4.1. &emsp;for each proposed brokered match $(i, j)$:
> &emsp;&emsp;Compute $\Pi^{\text{transparent}} = \phi$
> &emsp;&emsp;Compute $\Pi^{\text{opaque}} = \psi + \hat{q}_b(\mathbf{x}_i, \mathbf{x}_j) - r$
> &emsp;&emsp;If $\Pi^{\text{opaque}} > \Pi^{\text{transparent}}$: mark match as opaque
> &emsp;&emsp;Else: mark match as transparent
>
> &emsp;**2.5. Exclusivity routing** (if $\xi = 1$):
> 2.5.1. &emsp;for each agent $i$ with any opaque match this period:
> &emsp;&emsp;Cancel any pending self-search matches for agent $i$
> &emsp;&emsp;Route all of agent $i$'s remaining demand to the broker

> **3. MATCH FORMATION** (opaque branch added)
>
> &emsp;**3.1. Acceptance:**
> 3.1.1. &emsp;for each proposed transparent match: two-sided acceptance as in base (§9, Step 3)
> 3.1.2. &emsp;for each proposed opaque match: counterparty acceptance is automatic (broker guarantees $r$). Demander's participation constraint is delegated to the broker, which applied $\hat{q}_b > r$ during allocation (§9, Step 2.3.4).
>
> &emsp;**3.2. Conflict resolution:** unchanged (§9, Step 3).

> **4. OUTCOME REALIZATION AND LEARNING** (opaque branch added)
>
> 4.1. &emsp;for each accepted match $(i, j)$:
> &emsp;&emsp;Realize output: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$
> &emsp;&emsp;**If transparent** (self-search or transparent brokered):
> &emsp;&emsp;&emsp;Add $(\mathbf{x}_j, q_{ij})$ to $\mathcal{H}_i$ (demander's history)
> &emsp;&emsp;&emsp;Add $(\mathbf{x}_i, q_{ij})$ to $\mathcal{H}_j$ (counterparty's history)
> &emsp;&emsp;&emsp;If brokered: add $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$
> &emsp;&emsp;&emsp;Add edge $(i, j)$ to $G$
> &emsp;&emsp;**If opaque:**
> &emsp;&emsp;&emsp;Agent histories $\mathcal{H}_i$ and $\mathcal{H}_j$ are **not** updated (neither party observes the other's type)
> &emsp;&emsp;&emsp;Add $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$ (broker observes both types)
> &emsp;&emsp;&emsp;**No edge** added to $G$
>
> 4.2. &emsp;Update satisfaction indices:
> &emsp;&emsp;for each agent that completed a match via channel $c$:
> &emsp;&emsp;&emsp;If self-search: $\tilde{q} = q_{ij}$
> &emsp;&emsp;&emsp;If transparent brokered: $\tilde{q} = q_{ij} - \phi$
> &emsp;&emsp;&emsp;If opaque brokered (demander): $\tilde{q} = \hat{q}_b - \psi$ &ensp;(demander does not observe $q_{ij}$; uses broker's prediction as proxy)
> &emsp;&emsp;&emsp;$s_{i,c}^{t+1} = (1 - \omega)\, s_{i,c}^t + \omega \cdot \tilde{q}$
> &emsp;&emsp;No-proposal penalty: unchanged (§3d).
>
> 4.3. &emsp;Broker accounting (opaque matches):
> &emsp;&emsp;for each accepted opaque match $(i, j)$:
> &emsp;&emsp;&emsp;Broker revenue: $\psi$ (from demander) $+ \; q_{ij}$ (match output captured by broker)
> &emsp;&emsp;&emsp;Broker cost: $r$ (guaranteed to counterparty)
> &emsp;&emsp;&emsp;Broker profit: $\psi + q_{ij} - r$

</small>

#### 13j. Model 1 performance measures

**Opaque share** $O^t$: the fraction of brokered matches in period $t$ that are opaque (versus transparent placement). This is the primary capture metric. Proposition 3a predicts an abrupt tipping point: $O^t$ should remain near zero while the broker builds its informational advantage, then jump sharply to near one as opaque intermediation becomes economically dominant.

**Agent prediction quality by opaque exposure.** Average holdout $R^2$ stratified by agents' cumulative opaque match fraction. Agents with high opaque exposure should show stagnating prediction quality (informational lock-in), while agents who primarily self-search or receive transparent placements should continue improving.

**Broker risk profile.** The frequency and magnitude of matches where $q_{ij} < r$ (the broker absorbs a loss on its guarantee to the counterparty). Early in the capture transition, when predictions are less accurate, losses should be more frequent. As predictions improve, losses should decline. Persistent losses would indicate that the broker is transitioning too early.

---

## Part IV. Outstanding Design Choices

The following design choices are deferred for future work. They are described at a conceptual level to guide subsequent development.

### 14. Data Capture (Model 2)

Under data capture (Proposition 3b), the broker sells access to its prediction model as a per-period subscription service. Subscribing agents use the broker's model for their self-search while continuing to match directly, learn from outcomes, and form ties. The broker earns per-period subscription revenue $\mu$ rather than per-match fees.

Data capture produces the gradual trajectory of Proposition 3b: agents keep learning and forming ties, structural erosion continues, and the broker's advantage narrows as subscribers improve their own predictions using the broker's model. The channel comparison table in §13h summarizes the contrast with resource capture.

**Open design questions:**

**Does the broker observe outcomes of subscriber-directed matches?** If not, the broker's learning slows under data capture — subscribers use the broker's model to find better matches, but the broker doesn't see the outcomes. This creates a natural ceiling: the broker's model improves only from its own brokered matches (which decline as subscribers self-search more effectively), while subscribers' models improve from both their own matches and the broker's predictions. If the broker does observe outcomes (e.g., through a reporting requirement in the subscription contract), the ceiling disappears and data capture dynamics change.

**Does subscription replace or supplement the agent's own model?** If the subscription replaces the agent's model entirely, the agent becomes dependent on the broker's predictions and its own model atrophies. If the subscription supplements (e.g., the agent uses the better of its own prediction and the broker's), the agent's model continues to improve alongside the broker's. The replacement version is simpler and produces stronger capture dynamics; the supplement version is more realistic.

**Can subscribers also use the broker for standard placement simultaneously?** If yes, the broker can earn revenue from both subscription fees and placement fees, and subscribers benefit from both better predictions and access to the broker's roster. If no, subscription and brokerage are mutually exclusive channels.

### 15. Alternative Resource Capture Mechanisms

Three alternatives to opaque intermediation (§13) are noted for future exploration. Each captures a different aspect of real-world capture transitions.

#### 15a. Market-making (Option B)

The broker contracts counterparties into exclusive inventory and supplies them to demanders. The broker pays contracted agents their outside option and earns a markup on each match. This creates **supply-side scarcity** in addition to information lock-in: contracted agents leave the open market, reducing the pool available for self-search and making the broker more necessary.

The richer positive feedback loop — capture reduces open-market supply, which worsens self-search outcomes, which drives more outsourcing, which enables more contracting — may produce stronger capture dynamics than opaque intermediation alone. This variant is the closest mapping to the real-world transitions in all three illustrative domains (IDB principal trading, PE portfolio assembly, dealer inventory).

The tradeoff is complexity: the broker now has two roles (matching and inventory management), with new decisions (which agents to contract, at what terms, when to release) and a new sub-model for counterparty acceptance of exclusive contracts.

#### 15b. Exclusive contracts without information lock-in (Option C2)

Agents sign exclusive contracts with the broker for $L$ periods but still observe counterparty types and form direct ties. Lock-in is contractual, not informational: the agent's prediction model and network continue to improve, but it cannot switch to self-search during the contract.

This variant serves as a **comparison case**: if capture is weaker under C2 than under opaque intermediation, it demonstrates that the informational channel (not the contractual restriction) drives the abrupt capture dynamics of Proposition 3a.

#### 15c. Partial obfuscation (Option D)

The broker reveals noisy or partial type information: $\tilde{\mathbf{x}}_j = \mathbf{x}_j + \boldsymbol{\zeta}$, where $\boldsymbol{\zeta} \sim N(0, \sigma_{\text{obf}}^2 \mathbf{I}_d)$. The agent can update its history with $(\tilde{\mathbf{x}}_j, q_{ij})$, but the noisy type degrades the quality of its ridge regression. At $\sigma_{\text{obf}} = 0$, this is standard transparent brokerage; at $\sigma_{\text{obf}} \to \infty$, this is opaque intermediation.

This variant provides a continuous lock-in parameter that can be swept, serving as a **robustness check**: does the capture result survive when the information freeze is partial rather than total? The theoretical prediction is that capture requires sufficiently strong obfuscation but is not knife-edge — there should be a threshold $\sigma_{\text{obf}}^*$ above which capture dynamics emerge.

### 16. Prediction Confidence Tracking

The current model does not track prediction confidence. The broker's decision to switch from transparent to opaque placement is purely economic (§13d): the broker offers opaque intermediation whenever $\psi + \hat{q}_b - r > \phi$, regardless of how confident it is in its match quality predictions.

A richer model could track prediction confidence — for example, posterior variance from Bayesian linear regression, or leave-one-out cross-validation error from ridge regression — and condition the transition on a confidence threshold. The broker would only offer opaque intermediation when it is confident enough in its predictions to bear the risk of guaranteeing $r$.

This would produce a more natural transition: the broker waits until it "knows enough" before assuming principal risk. It would also connect to the literature on expert confidence and market-making readiness. Deferred because it adds complexity to the learning model (§2) and requires choosing between several confidence metrics, each with different computational and interpretive properties.

### 17. Pricing Alternatives

The base model uses a fixed per-match fee $\phi$ and Model 1 uses a fixed per-period fee $\psi$. Two alternative pricing mechanisms are noted for future exploration.

**Surplus-proportional fee.** $\phi = \alpha \cdot \hat{q}_b(\mathbf{x}_i, \mathbf{x}_j)$. The broker charges a fraction of its predicted match quality. This creates a recognition gap: the broker's revenue depends on its own prediction, while the agent's satisfaction depends on realized quality. Better predictions increase broker revenue, strengthening the incentive to invest in prediction accuracy.

**Prediction-based fee.** $\phi = \alpha \cdot (\hat{q}_b - \hat{q}_i^d)$. The broker charges for the prediction improvement it provides over the agent's own model. This directly prices the informational advantage but requires the broker to know (or estimate) the agent's prediction quality.

Both alternatives create richer dynamics but add parameters and complicate the satisfaction comparison between channels. The fixed-fee design isolates the informational channel by removing price as a margin of competition.

### 18. Other Design Choices

**Turnover elimination.** Setting $\eta = 0$ (no agent turnover) simplifies the model and produces monotonic structural erosion without the refresh from new entrants. This is the cleanest setting for demonstrating the self-liquidating dynamic but may produce dynamics that converge too quickly. Could be tested as a robustness check.

**Roster decay.** Inactive roster members (agents who have not outsourced in the last $L$ periods) could be pruned from the roster. This would prevent the roster from growing indefinitely and create a more realistic model of broker-client relationships. The tradeoff is additional complexity and a new parameter $L$.

**Exclusivity sweep.** The default $\xi = 1$ (full exclusivity under opaque intermediation) produces the cleanest lock-in but is a strong assumption. Comparing dynamics under $\xi = 0$ and $\xi = 1$ would test whether the full information freeze is necessary for the abrupt capture trajectory of Proposition 3a, or whether partial lock-in (agents learn on non-opaque slots) suffices.

## Figures

#### Phase diagram

The phase diagram maps the conditions under which the broker develops a sustained informational advantage and transitions to capture. Its two axes are the primary drivers of matching difficulty: $s$ (active dimensions) on the vertical axis and $\rho$ (quality-interaction mixing weight) on the horizontal axis.

Low complexity (low $s$, high $\rho$) corresponds to markets where agents learn quickly and the broker does not develop a decisive advantage. High complexity (high $s$, low $\rho$) corresponds to markets where the broker's cross-market data provides a durable advantage, enabling capture.

#### Main figures

**Fig. 1.** The informational mechanism.
- *Purpose:* Establishes the core mechanism: the broker learns faster than individual agents, the gap widens with matching complexity, and this drives increasing outsourcing (Propositions 1.1, 1.2, 1.3).
- *Content:* All panels at default parameters ($s = 8$, $\rho = 0.50$). Each panel includes a **base model** series (dashed grey) as a no-capture reference line, plus Model 1 series.
  - Panel A: time on the horizontal axis, prediction quality (holdout $R^2$, rolling window) on the vertical axis. One line for the broker, one for the average agent. The broker-agent gap reflects the informational advantage and its dynamics over time. An inset shows the effect of varying $s$.
  - Panel B: time on the horizontal axis, outsourcing rate on the vertical axis. The base model establishes the reference trajectory. Model 1 diverges.
  - Panel C: time on the horizontal axis, average realized match output by channel (self-search, transparent brokered, opaque brokered).

**Fig. 2.** Decoupling of structural position from informational advantage.
- *Purpose:* The central empirical implication. Shows that betweenness centrality declines while the broker's informational advantage grows, and that resource capture suspends the structural erosion (Propositions 2.1, 3a).
- *Content:* Time on the horizontal axis, dual vertical axes for broker betweenness centrality and broker prediction quality. Under Model 1, betweenness plateaus or recovers once opaque intermediation dominates.

**Fig. 3.** Access vs. assessment decomposition over time.
- *Purpose:* Traces the shift from network access to information assessment as the dominant source of broker value (Propositions 1.3a, 1.3b).
- *Content:* Time on the horizontal axis, fraction of brokered matches on the vertical axis, decomposed into access value (counterparty was not in demander's network) and assessment value (counterparty was reachable but broker predicted better).

**Fig. 4.** Capture dynamics and the lock-in mechanism.
- *Purpose:* Shows that capture occurs and the lock-in mechanism explains why resource capture is abrupt and self-reinforcing (Proposition 3a).
- *Content:*
  - Panel A: time on the horizontal axis, opaque share $O^t$ on the vertical axis. Shows the abrupt tipping point as the broker shifts from transparent placement to opaque intermediation.
  - Panel B: time on the horizontal axis, average agent prediction quality on the vertical axis, stratified by opaque exposure (high vs. low). Opaque-dependent agents stagnate; others continue improving. Panel A shows the outcome; Panel B shows the mechanism.

**Fig. 5.** Phase diagram.
- *Purpose:* Maps the conditions under which capture occurs, identifying regions of no capture, partial capture, and full capture as a function of matching complexity (Proposition 2.2).
- *Content:* $\rho$ on the horizontal axis, $s$ on the vertical axis. Heatmap or contour plot showing the broker-agent prediction quality gap (or opaque share at steady state) across the parameter space.

#### SI figures

**Fig. S1.** Prediction quality decomposition.
- *Content:* Three sub-panels: $R^2$, bias, and rank correlation over time (broker and average agent). Under Model 1, agent lines stratified by opaque exposure.

**Fig. S2.** Attributional vs. relational channel (Proposition 1.2).
- *Content:* $\rho$ on horizontal axis; broker-agent gap in holdout $R^2$; outsourcing rate at steady state.

**Fig. S3.** OAT parameter sweeps.
- *Content:* Grid of panels varying $\eta$, $\psi$, $\xi$ while holding others at defaults.

**Fig. S4.** Network visualization snapshots.
- *Content:* Augmented graph at early, middle, and late periods. Broker node positioned centrally. Under Model 1, late-period graph should show persistent structural holes between opaque-intermediated agents.

**Fig. S5.** Broker risk profile.
- *Purpose:* Shows the frequency and magnitude of losses the broker absorbs on its guarantee under opaque intermediation.
- *Content:* Time on the horizontal axis, distribution of $q_{ij} - r$ for opaque matches. Early: wider distribution with more losses. Late: concentrated in positive territory as predictions improve.

## References

Bethune, Z., Sultanum, B., & Trachter, N. (2024). An information-based theory of financial intermediation. *Review of Economic Studies*, *91*(3), 1424–1454.

Brenner, T. (2006). Agent learning representation: Advice on modelling economic learning. In K. Judd & L. Tesfatsion (Eds.), *Handbook of computational economics* (Vol. 2, pp. 895–947). North-Holland.

Burt, R. S. (1992). *Structural holes: The social structure of competition*. Harvard University Press.

Burt, R. S. (2005). *Brokerage and closure: An introduction to social capital*. Oxford University Press.

Duffie, D., Gârleanu, N., & Pedersen, L. H. (2005). Over-the-counter markets. *Econometrica*, *73*(6), 1815–1847.

Freeman, L. C. (1977). A set of measures of centrality based on betweenness. *Sociometry*, *40*(1), 35–41.

Li, D. D. (1998). Middlemen and private information. *Journal of Monetary Economics*, *42*(1), 131–159.

Watts, D. J., & Strogatz, S. H. (1998). Collective dynamics of 'small-world' networks. *Nature*, *393*(6684), 440–442.
