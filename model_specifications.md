# Model Specification: Transient Brokerage in Matching Markets

This document details the specifications of an agent-based model of labor intermediation meant to formalize and demonstrate the theory of brokerage put forward in the project titled "Transient Brokerage."

## Theory Overview

Dominant theories of brokerage (see e.g. Stovel, Golub, and Milgrom, *PNAS* 2011) describe brokerage as a fragile position at the intersection of social groups, a position that requires stabilizing to avoid collapsing. This view of brokerage fails to explain or predict how so many actors that started in position of brokerage, from Randstad, Amazon, and Visa to Bloomberg and Elsevier, have managed to rise in market power, profit, and prominence even as networks transformed around them and their structural advantage eroded.

The structural-hole theory of brokerage (Burt, 1992) locates the broker's value in its network position, bridging disconnected parties. Structural-hole brokerage, when performed at scale, is self-liquidating: each successful match creates a direct tie that densifies the network and closes the holes that created bridging opportunities in the first place.

I propose a complementary mechanism. Brokerage is outsourced relational work: the broker constructs viable matches between parties who cannot easily evaluate each other. This relational work generates an informational byproduct that the broker can leverage. The broker accumulates knowledge of how to match heterogeneous parties. Structural position provides the access that feeds learning, but while each successful match erodes the broker's structural advantage, it also strengthens its informational position (by adding an observation to its experience of the matching function).

The broker converts structural capital into informational capital through the act of brokering. When the matching problem is sufficiently complex, the informational capital compounds faster than structural capital erodes, and this compounding advantage can support a transition from intermediation to capture, transforming the broker into a principal selling the resource it was formerly intermediating or data and analytics. This is *transient brokerage*, a process that highlights the broker's power rather than its fragility.

This project develops an agent-based model of the labor intermediation industry (in which many headhunting and matchmaking firms have undergone this transition) to formalize and demonstrate the theoretical framework.

In the model, firms with vacancies either search for workers directly or outsource the search to the broker. Capture can take two forms: worker capture, where staffing locks firms out of learning and freezes their referral networks, or data capture, where the broker sells its predictions as an analytics service while firms continue hiring directly. All agents use heuristic decision rules. No agent solves an optimization problem or holds beliefs about other agents' strategies.

Two model variants build on a shared base (agents, matching process, learning, search, and step ordering, §§1–8) and differ only in the capture mode: worker capture through staffing (§9) and data capture through analytics (§10).

## Questions

1. Under what conditions does the broker develop, maintain, or lose an informational advantage over firms?

2. Under what conditions can the broker leverage its advantage for capture?

3. What form does capture take and how does capture impact the dynamics of the broker's advantage?

## Main Propositions

The simulation is designed to demonstrate the following propositions.

### Premise

**1. A broker provides value in a matching market because of its structural or informational advantages.** A broker helps create a match between principals who, without the broker's intervention, could not easily find each other (structural advantage) or were unaware that they would benefit from a match (informational advantage). In other words, the broker's service is valuable both because it can find counterparties that clients cannot reach and because it can assess match quality better than its clients can.

- ***The existence of a structural advantage depends purely on network topology.*** It can be measured using traditional measures of betweenness centrality, constraint, and effective size.

- ***The emergence of an informational advantage depends on the value of the data a broker and its clients accumulate, which in turn depends on the form and difficulty of the matching problem.*** When the matching problem is hard to solve, local or limited experience can be insufficient relative to a broker's high volume of cross-market data.

**2. A broker's informational advantage is mainly relational, not attributional.** Assessing match quality involves two components: assessing the general quality of each good or counterparty involved, and assessing the quality of the specific pairing or relational package being considered.

The broker observes outcomes from many different pairings across principals, while each principal observes outcomes only from its own matches. This gives the broker two potential channels of informational advantage: (1) better estimation of counterparty quality from cross-market data (the attributional channel), and (2) better understanding of pairing complementarities from observing the same counterparties matched with different principals (the relational channel).

Important models in the economics literature have characterized the broker's role as quality certification (Li, 1998) or expert screening (Bethune, Sultanum, and Trachter, 2024): the broker identifies which goods or counterparties are high quality. He is an appraiser whose cross-market experience helps it assess the general quality of counterparties more accurately than individual principals can.

The relational-work view of brokerage rather suggests that the broker's value lies in understanding complementarities between counterparties and shaping relational packages accordingly. The broker is a relational worker and a matchmaker whose advantage comes from knowing which pairings will succeed.

### 1. Advantage

#### Proposition 1.1

**A broker's structural and informational advantages exhibit distinct dynamics over repeated brokerage activity.**

**1.1a. Structural advantage tends to be self-liquidating.** A broker that bridges a gap between two principals, and successfully matches them, creates a direct relationship between them. With each match, the broker's network position weakens. Direct ties accumulate between principals and structural holes close. This is particularly the case when brokerage occurs at scale. A broker can counteract the self-liquidating tendency by aggressively recruiting new candidates, continuously expanding its reach into parts of the network that principals cannot yet access. However, when the broker's pool of candidates is stable or slowly evolving, placements create direct ties faster than new structural holes are bridged, and the erosion of structural advantage dominates.

**1.1b. Informational advantage tends to be self-reinforcing.** Each match generates information about what makes pairings succeed or fail in a given market. The broker's cross-market experience, whether it helps assess general worker quality or understand worker-firm complementarities, generates an informational advantage over each client's limited within-firm perspective. This advantage grows with the volume and diversity of the broker's placement history.

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

High matching complexity and low transparency make the principals' learning problem harder, widening and preserving the broker's advantage.

In transparent markets with simple matching problems, principals learn fast and well enough that the broker does not accumulate a decisive informational advantage. Brokers persist as commodity intermediaries earning thin margins and may attempt capture but do not consolidate into dominant principals. This is the no-capture region of the parameter space.

Within the capture region of the parameter space, if the broker does not capture, its information advantage may start to erode over time.

### 3. Forms of capture

#### Proposition 3

**Capture can occur in two forms with qualitatively different dynamics.**

**3a. Under resource capture, the transition is abrupt, and the broker suddenly starts taking inventory risk and acting primarily as a principal.** Resource capture creates a double lock-in: the client's information state freezes (it doesn't learn from new matches like it did when the broker acted as an intermediary) and the client's network no longer grows (the broker is everyone's counterparty). The self-liquidating dynamic of structural advantage is suspended, because the broker no longer creates direct ties between clients. This produces a steep capture trajectory.

**3b. Under data capture, the transition is gradual, and the broker progressively monetizes its informational advantage by acting as a principal in subscription contracts.** Clients continue making new matches, learning from outcomes, and growing their networks. The self-liquidating dynamic of structural advantage continues operating. This produces a smooth capture trajectory.

## Part I. Base Model

The model is a discrete-time agent-based simulation of a labor matching market with three agent types: *workers*, *firms*, and a *broker*. Firms with vacancies either search for workers directly or outsource the search to the broker. All agents operate within a single industry. Each period represents one calendar quarter. All economic quantities (output, wages, fees, bill rates, profits) are in the same monetary units.

A single broker serves the market. This is a simplification: with multiple brokers, the data pool fragments, there is competition for informational rents, and no single broker consolidates as large an informational advantage. The model can be interpreted as a monopolistic broker or as a single broker's segment within a competitive market. Analysis of broker competition is deferred to future work.

All agents use heuristic decision rules. No agent solves an optimization problem or holds beliefs about other agents' strategies, in line with the tradition of ABM agents using simple, bounded-rationality rules grounded in empirically observable behavior (Brenner, 2006; Neugart & Richiardi, 2018).

The base model specifies agents (§0), the matching problem (§1), how agents learn to predict match quality (§2), wage determination (§3), network structure and agent turnover (§4), how firms and the broker find candidates (§5), the firm's outsourcing decision (§6), broker pricing (§7), and the complete step ordering (§8). There is no capture in the base model.

Two model variants (§§9–10) build on this base and differ in how the broker captures value once its informational advantage is large enough: through worker capture, where staffing locks firms out of learning and freezes their referral networks (§9), or through data capture, where the broker sells its predictions as an analytics subscription service while firms continue hiring directly (§10).

### 0. Agents

The model has three agent types: workers, firms, and a broker. This section describes their attributes and possible states.

#### Workers

There are $N_W$ workers (default 1000). The worker population is fixed: workers change status but never enter or leave the simulation. Workers are connected through a fixed social network $G_S$ (§4) that channels referrals.

Each worker $i$ is characterized by:

- **Type** $w_i \in \mathbb{R}^d$: a fixed vector of observable characteristics assigned at initialization. Types determine general worker quality and productive compatibility with firms through the matching function (§1).
- **Reservation wage** $r_i$: the minimum compensation the worker requires to accept employment (§3b). Fixed at initialization.
- **State**: one of two discrete states in the base model:
  - *Available*: not employed by any firm; can be proposed for new matches.
  - *Employed*: in a firm's workforce via direct hire (internal search or brokered placement). The worker appears in the firm's employee set $E_j^t$, and the worker's social ties contribute to the firm's referral reach.

#### Firms

There are $N_F$ firms (default 50). Each firm $j$ is characterized by:

- **Type** $x_j \in \mathbb{R}^d$: a fixed vector of observable characteristics assigned at initialization. Types determine productive compatibility with workers through the matching function (§1).
- **Employee set** $E_j^t$: the set of workers currently employed by the firm.
  - **Referral reach** $R_j^t = \bigcup_{i \in E_j^t} N_S(i) \setminus E_j^t$, where $N_S(i)$ denotes the neighbors of worker $i$ in the social network $G_S$ (§4): the set of workers reachable through the social-network neighbors of the firm's current employees, excluding current employees. This is a network property; candidates are drawn from the available subset $R_j^t \cap \{\text{available workers}\}$ at hiring time (§5a). Grows as the employee set grows.
- **Experience history** $\mathcal{H}_j^t = \{(w_m, q_{mj})\}$: the set of (worker type, realized match output) pairs from all workers the firm has directly employed (§2a).
- **Satisfaction indices** $s_{j,c}^t$: one scalar per hiring channel $c \in \{\text{internal}, \text{broker}\}$, tracking realized output minus the firm's per-period cost above $r_i$ via an EWMA (§6a). Drives the outsourcing decision (§6b).
- **Vacancy status**: at most one open vacancy per firm per period. Vacancies arise stochastically (probability $p_{\text{vac}}$ per period) and persist if unfilled (§5).

Firms exit independently each period with probability $\eta$ (default 0.05) and are replaced by new entrants with fresh types, a small initial workforce (6-10), and histories seeded from the initial hires (§4).

#### Worker and firm types

Workers and firms are described by type vectors in $\mathbb{R}^d$ (default $d = 8$). These types are the observable characteristics that determine productive compatibility through the matching function (§1).

**Firm types.** All firm types lie on the surface of the unit sphere in $\mathbb{R}^d$. How they are distributed on the sphere determines the structure of the matching problem and the value of cross-firm data to the broker. Three firm geometries are defined, varying in the dimensionality and regularity of the firm type manifold.

*Complex geometry* (main specification). Firms lie along a smooth one-dimensional curve that spans all $d$ dimensions. The curve is parameterized by a position $t \in [0, 1]$:

$$\mathbf{x}(t) = \frac{\tilde{\mathbf{x}}(t)}{\|\tilde{\mathbf{x}}(t)\|}, \qquad \tilde{x}_k(t) = \sin(2\pi f_k t + \phi_k), \quad k = 1, \ldots, d$$

where $f_k$ and $\phi_k$ are random parameters drawn once per simulation. The $N_F$ firms are evenly spaced along this curve. Because each dimension has its own independent frequency, the curve spans all $d$ dimensions: firms nearby on the curve have similar types, while firms far apart point in genuinely different directions across all of $\mathbb{R}^d$. This full-dimensional diversity is what makes the interaction (§1c) vary in fundamentally different ways across firms, and what makes cross-firm data valuable to the broker (§1d).

*Simple geometry.* Firms lie along a great circle, the intersection of the unit sphere with a two-dimensional plane through the origin. The circle is defined by two orthonormal vectors $\mathbf{a}, \mathbf{b} \in \mathbb{R}^d$:

$$\mathbf{x}(t) = \cos(\theta t) \, \mathbf{a} + \sin(\theta t) \, \mathbf{b}$$

where $\theta$ is calibrated so that the spacing between adjacent firms matches the complex geometry. Firms are evenly spaced. Because the great circle spans only a two-dimensional subspace of $\mathbb{R}^d$, the firm type variation is low-dimensional regardless of $d$.

*Unstructured geometry.* Firm types are drawn independently from an anisotropic distribution on the sphere. Each firm type is generated as

$$\mathbf{x} = \frac{\mathbf{z}}{\|\mathbf{z}\|}, \qquad \mathbf{z} = \mathbf{m} + \mathbf{Q} \boldsymbol{\Lambda}^{1/2} \boldsymbol{\xi}, \qquad \boldsymbol{\xi} \sim N(\mathbf{0}, \mathbf{I}_d)$$

where $\mathbf{m}$ is a random unit vector (the center of the distribution), $\mathbf{Q}$ is a random orthonormal matrix, and $\boldsymbol{\Lambda}$ is a diagonal matrix of anisotropic scales drawn once at initialization. The scales decay so that the distribution is elongated along some directions and compressed along others. Unlike the structured geometries, firms have no ordering: there is no notion of "adjacent" or "distant" firms, and pairwise distances are approximately uniform.

The three geometries test whether the model's dynamics depend on the structure of the firm type manifold (§13c). Entrant firms replacing exiting ones (§4) are drawn from the same geometry: at a random position on the curve for structured geometries, or as a fresh draw from the same distribution for unstructured.

**Worker types.** Each worker is a noisy version of a randomly chosen firm type:

$$\mathbf{w}_i = \mathbf{x}_{j(i)} + \boldsymbol{\epsilon}_i, \qquad j(i) \sim U\{1, \ldots, N_F\}, \qquad \boldsymbol{\epsilon}_i \sim N\!\left(\mathbf{0}, \frac{\sigma_w^2}{d} \mathbf{I}_d\right)$$

where all quantities are $d$-vectors.

The reference firm $j(i)$ is drawn uniformly at random. The per-dimension noise scale $\sigma_w / \sqrt{d}$ is chosen so that the expected Euclidean distance from a worker to its reference firm is approximately $\sigma_w$ regardless of the dimensionality $d$.

At the default $\sigma_w = 0.5$, this distance is comparable to the spacing between adjacent firms on the curve. Each worker is therefore close to its reference firm and a few of that firm's neighbors, but far from most other firms. A worker who is a good match for one firm may be a poor match for a firm on the other side of the curve, and determining which firms a given worker fits requires data.

#### Broker

A single broker serves the market. The broker is characterized by:

- **Experience history** $\mathcal{H}_b^t = \{(w_m, x_m, q_m)\}$: the set of (worker type, firm type, realized match output) triples from all placements the broker has mediated (§2b).
- **Pool** $\text{Pool}^t$: the set of workers the broker can propose for matching. Maintained at a fixed target size $P$ through periodic recruitment to replace placed and staffed workers (§4).
- **Reputation** $\text{rep}^t$: the average satisfaction of current client firms (§6b).

### 1. The Matching Problem

The model's central dynamics depend on a matching problem: how productive will worker $i$ be at firm $j$? No agent knows the answer in advance; all must learn it from experience.

The structure of the matching problem and how the broker and firms try to solve it determines whether and when the broker develops an informational advantage over the firms it serves.

**Match quality** (§1a) decomposes into two components:

- **General worker quality** (§1b): a worker's baseline productivity that does not depend on which firm they work for.
- **Match-specific interaction** (§1c): how well a particular worker-firm pairing works.

The broker, which places workers at many firms, observes the same worker characteristics producing different outcomes at different firms; whereas firms only see their own hiring history.

#### 1a. Match quality

Workers and firms are characterized by multi-dimensional types, respectively $w_i$ and $x_j$, that determine their productive compatibility through a matching function. Types are fixed and known only to their owner.

Let $q_{ij}$ represent the **per-period productive output of match $(i, j)$**. It is a function of worker type and firm type, it is measured in monetary units, and it represents the economic value the firm derives from the worker:

$$q_{ij} = f(w_i, x_j) + \varepsilon_{ij}, \qquad
\varepsilon_{ij} \sim N(0, \sigma_\varepsilon^2)$$

where $\sigma_\varepsilon = 0.25$. The noise term $\varepsilon_{ij}$ represents idiosyncratic match-specific variation (interpersonal chemistry, unobserved characteristics, and other factors not captured by observable types) that is irreducible even with perfect knowledge of $f$.

The matching function $f: \mathbb{R}^d \times \mathbb{R}^d \to \mathbb{R}$ is unknown to all agents and fixed for the duration of the simulation.

The deterministic portion of match quality has two components, the first relating to worker quality (portable across firms) and the second to worker-firm pairings:

$$f(\mathbf{w}, \mathbf{x}) = Q + \rho \cdot \text{sim}(\mathbf{w}, \mathbf{c}) + (1 - \rho) \cdot \text{sim}(\mathbf{w}, \mathbf{A}\mathbf{x})$$

where $\text{sim}(\mathbf{a}, \mathbf{b}) = \mathbf{a}^\top \mathbf{b} / (\|\mathbf{a}\| \|\mathbf{b}\|)$ denotes cosine similarity between two vectors, $Q = 1.0$ is a constant offset, and $\mathbf{A}$ is a $d \times d$ random matrix with iid $N(0, 1)$ entries drawn once at initialization (see §1c).

Worker quality is defined by the cosine similarity between worker types and an ideal worker type vector $c$, while worker-firm pairing quality is defined by the cosine similarity between worker types and a linear transformation of firm types, $\mathbf{A}\mathbf{x}$.

The offset $Q = 1.0$ shifts the output to be nonnegative (both signal components are bounded in $[-1, 1]$, so $f \in [-1, 3]$ in principle but concentrates near $[0, 2]$).

Both components are bounded and $\rho$ is a mixing weight that controls how much of match quality depends on each component.

At **low $\rho$**, the broker's cross-firm data is most valuable because the interaction $\text{sim}(w, Ax)$ can only be disentangled by observing the same workers at different firms. Individual firms see only their own slice $\text{sim}(w, Ax_j)$ and cannot separate worker quality from interaction effects. The broker's advantage is large.

At **high $\rho$**, firms can learn general quality from their own hires; the broker's advantage shrinks. Since $\text{sim}(w, c)$ depends only on the worker, each firm can estimate it from its own hiring history. The broker's cross-firm data adds little.

#### 1b. General worker quality

General worker quality is the analogue of the "worker effect" in the AKM decomposition of observed wages (Abowd, Kramarz & Margolis, 1999). It captures portable human capital such as general ability, conscientiousness, reliability.

Here, general quality is $\text{sim}(w, c)$, where $c \in \mathbb{R}^d$ is an **ideal worker type vector** drawn at initialization like an $(N_W + 1)$th worker: a perturbation of a random firm type with the same $\sigma_w / \sqrt{d}$ per-dimension noise used for regular workers (§12c).

The vector $c$ represents a quality archetype. Workers whose types are aligned with $c$ (high cosine similarity) have higher general quality. The $\text{sim}(w, c)$ term is a signed quality measure in $[-1, 1]$: workers aligned with $c$ have positive quality, anti-aligned workers have negative quality.

This is analogous to the AKM worker effect: some workers are universally better, some universally worse. The quality component depends only on the worker type, not on the firm, so it is portable across firms.

Because $\text{sim}(w, c) = w^\top c / (\|w\| \|c\|)$ is a cosine similarity (not a dot product), ridge regression on features including $w$ and $w^2$ can partially learn it but cannot capture the normalization exactly. The parameter $\rho$ (§1d) controls how much the general quality component contributes to total match output.

#### 1c. Match-specific interaction

The match-specific interaction is $\text{sim}(\mathbf{w}, \mathbf{A}\mathbf{x}) = \mathbf{w}^\top (\mathbf{A}\mathbf{x}) / (\|\mathbf{w}\| \|\mathbf{A}\mathbf{x}\|)$, the cosine similarity between the worker type vector and a linear transformation of the firm type vector. The matrix $\mathbf{A} \in \mathbb{R}^{d \times d}$ has iid $N(0, 1)$ entries and is drawn once at initialization. Because $\mathbf{A}$ mixes all $d$ dimensions of $x$, the interaction $\text{sim}(w, Ax)$ introduces cross-dimensional interactions: the match-specific quality of worker $i$ at firm $j$ depends on all $d^2$ products $w_k \cdot x_l$ (for $k, l = 1, \ldots, d$), not just the $d$ diagonal products $w_k \cdot x_k$.

Bounded in $[-1, 1]$. For a fixed firm $j$, $\text{sim}(w, Ax_j)$ varies smoothly with $w$ and is approximately learnable by ridge regression from the firm's hiring history. The diagonal elementwise products $w \odot x$ capture only $d$ of the $d^2$ interaction terms induced by $\mathbf{A}$, while the full outer product $w \otimes x$ (a $d \times d$ matrix reshaped into $d^2$ features) captures all of them.

#### 1d. What controls the difficulty of the matching problem

- **Worker-firm geometry.** Two aspects interact: (1) how workers are distributed around firms ($\sigma_w$ relative to inter-firm spacing), and (2) how much of type space the firm curve spans.

  - Workers are drawn as perturbations of firm types with dispersion $\sigma_w$ (§0). When $\sigma_w$ is comparable to inter-firm spacing (the default $\sigma_w = 0.5$), workers overlap with multiple firms' neighborhoods, creating meaningful variation in match quality that requires data to learn.

  - Firms must point in different directions across all $d$ dimensions. The sinusoidal firm curve (§0, complex geometry) achieves this by assigning each dimension an independent random frequency and phase. Because firm types span the full $d$-dimensional space, the interaction $\text{sim}(\mathbf{w}, \mathbf{A}\mathbf{x})$ varies in fundamentally different ways across firms, and a firm observing $\text{sim}(\mathbf{w}, \mathbf{A}\mathbf{x}_j)$ for its own fixed $\mathbf{x}_j$ cannot infer how the same workers would match at firms pointing in other directions. The simple geometry (great circle spanning only 2 dimensions) makes the interaction lower-dimensional, reducing the broker's advantage. The unstructured geometry (anisotropic distribution on the sphere) removes curve structure entirely.

- **$\rho$ (mixing weight).** At low $\rho$, the interaction dominates and cross-firm data is essential; the broker's advantage is large. At high $\rho$, general quality dominates and firms can learn from their own hires; the broker's advantage shrinks.

- **$\mathbf{A}$ (interaction matrix).** The random matrix $\mathbf{A}$ creates $d^2$ cross-dimensional interaction terms $w_k \cdot x_l$ that contribute to match quality. A firm observing only its own hires sees a fixed projection $Ax_j$ and can learn the interaction from the $d$ features in $w$ alone. The broker, observing workers at many firms with varying $Ax_j$, benefits from representing all $d^2$ cross-terms via the outer product $w \otimes x$. This is the primary source of the broker's feature advantage.

- **$d$ (type dimensionality).** Higher $d$ increases the number of regression features ($2d$ for firms, $d^2 + 3d$ for the broker) and, because $\mathbf{A}$ is $d \times d$, also increases the number of cross-dimensional interaction terms quadratically. However, under cosine normalization the interaction remains a bounded scalar regardless of $d$, so the effect of $d$ is secondary to the effect of the interaction structure.

- **$\sigma_\varepsilon$ (noise scale).** With $\sigma_\varepsilon = 0.25$ and signal in $[-1, 1]$, the signal-to-noise ratio is approximately 4:1.

### 2. Learning

Firms and the broker use predicted match quality $\hat{q}_{ij}$ in every core decision: which candidates to hire (§5), what wage to offer (§3), and whether to outsource hiring (§6).

Both firms and the broker learn from experience using ridge regression, fitted each period on their accumulated history.

#### 2a. Firm $j$'s prediction

A firm's history $\mathcal{H}_j^t = \{(w_m, q_{mj})\}_{m=1}^{n_j}$ records the workers the firm has directly employed and their realized match outputs. Histories are seeded at initialization: each firm's 6-10 initial employees produce observed match outputs that are recorded immediately (§12c). Firms therefore always have at least 6 observations.

Firm $j$ knows its own type $x_j$. For a fixed firm, $f(w, x_j) = Q + \rho \cdot \text{sim}(w, c) + (1 - \rho) \cdot \text{sim}(w, Ax_j) + \varepsilon$ combines a quality term and a cosine interaction term. The firm fits a ridge regression model on its history using $2d$ features:

$$\hat{q}_j(\mathbf{w}) = \hat{\boldsymbol{\beta}}_j^\top [\mathbf{w}; \mathbf{w} \odot \mathbf{w}] + \hat{\alpha}_j$$

where $\hat{\boldsymbol{\beta}}_j, \hat{\alpha}_j$ are the ridge regression coefficients fitted on $\{([\mathbf{w}_m; \mathbf{w}_m \odot \mathbf{w}_m], q_{mj})\}$ with regularization parameter $\lambda$ (default 1.0). The model is refitted each period on the firm's full history. The firm uses $2d$ features: the worker type $w$ and its elementwise square $w^2$. The quadratic features $w^2$ help approximate the cosine normalization in the quality component.

The cosine-normalized interaction $\text{sim}(w, Ax_j)$ is approximately linear for nearby workers but not exactly linear. The firm captures both the quality and interaction components imperfectly.

#### 2b. Broker's prediction

The broker's history $\mathcal{H}_b^t = \{(w_m, x_m, q_m)\}_{m=1}^{n_b}$ records all placements the broker has mediated across all client firms and their realized match outputs. The broker's history is seeded at initialization with 20 random observations from existing worker-firm matches (§12c).

Unlike a firm, the broker observes the same worker types producing different outcomes at different firms, and different worker types at the same firm. The broker fits a single pooled ridge regression on concatenated worker type, firm type, full outer-product interaction, and quadratic worker features:

$$\hat{q}_b(\mathbf{w}, \mathbf{x}) = \hat{\boldsymbol{\beta}}_w^\top \mathbf{w} + \hat{\boldsymbol{\beta}}_x^\top \mathbf{x} + \hat{\boldsymbol{\beta}}_{wx}^\top \text{vec}(\mathbf{w} \otimes \mathbf{x}) + \hat{\boldsymbol{\beta}}_{w^2}^\top (\mathbf{w} \odot \mathbf{w}) + \hat{\alpha}_b$$

where $[\hat{\boldsymbol{\beta}}_w; \hat{\boldsymbol{\beta}}_x; \hat{\boldsymbol{\beta}}_{wx}; \hat{\boldsymbol{\beta}}_{w^2}; \hat{\alpha}_b]$ are fitted on $\{([w_m; x_m; \text{vec}(w_m \otimes x_m); w_m^2], q_m)\}$ with regularization $\lambda$. The feature vector is $[w; x; \text{vec}(w \otimes x); w^2]$, where $w \otimes x$ denotes the full outer product (a $d \times d$ matrix reshaped into $d^2$ features), giving $d^2 + 3d$ features total. The outer-product features $w \otimes x$ capture all $d^2$ cross-dimensional interactions $w_k \cdot x_l$ induced by the matrix $\mathbf{A}$ in the matching function (§1c), while the separate $w$ and $x$ blocks capture linear main effects and $w^2$ helps approximate the cosine normalization. Refitted each period.

The broker's pooled model has three advantages over the firm's model:

1. **More data.** The broker accumulates observations across all client firms, giving it far more data points than any individual firm. With $n_b \gg n_j$, the broker's coefficient estimates have lower variance.

2. **Richer features.** By including both $w$ and $x$ as features, the broker's model captures how worker-firm interactions vary across firms. The coefficient $\hat{\beta}_x$ estimates how firm characteristics affect match output, information no individual firm can learn from its own-hire data alone.

3. **Outer-product interaction features.** The full outer product $w \otimes x$ gives the broker's linear model $d^2$ features that capture all cross-dimensional interactions $w_k \cdot x_l$ for every pair $(k, l)$. The matrix $\mathbf{A}$ in the matching function creates these cross-dimensional terms: $\text{sim}(w, Ax)$ depends on all $d^2$ products, not just the $d$ diagonal products $w_k \cdot x_k$. A firm does not need these features (its type $x_j$ is fixed, so $\text{sim}(w, Ax_j)$ is already a function of $w$ alone), but the broker, fitting across firms with varying $x$, benefits from explicitly representing the full interaction structure.

#### 2c. The asymmetry between firms and the broker

The firm learns "what kind of worker works well here" from a small, firm-specific sample. It cannot distinguish general quality from firm-specific fit.

The broker learns "what kind of worker works well, and at which kind of firm" from a large cross-market sample. Its richer feature set ($[w; x; \text{vec}(w \otimes x); w^2]$, with $d^2 + 3d$ features) and larger data volume produce better predictions, especially at higher $d$ where the $d^2$ outer-product features capture the full cross-dimensional interaction structure induced by $\mathbf{A}$. The outer product matters because $\mathbf{A}$ creates $d^2$ cross-terms $w_k \cdot x_l$ for all pairs $(k, l)$, not just the $d$ diagonal terms $w_k \cdot x_k$. Individual firms cannot estimate their $2d+1$ regression parameters from their sparse histories, and they do not need the outer product (their $x_j$ is fixed).

As firm $j$ accumulates more hires, its regression estimates improve and the broker's data advantage narrows. The broker's advantage is largest when firms have few observations and $d$ is high (more parameters to estimate from limited data).

#### 2d. Public information

A constant, scalar **public benchmark** $\bar{q}_{\text{pub}} = E[f(w,x)]$ is computed once at initialization from a Monte Carlo sample of clustered worker-firm pairs (matching the initialization distribution; §12c). This is the unconditional mean match output.

The benchmark initializes satisfaction indices (§6a) and broker reputation (§6b).

### 3. Wage Determination

#### 3a. Wages under direct hire and placement

Following search-and-matching models of labor markets, in which workers and firms must find each other before they can produce or negotiate terms (Mortensen & Pissarides, 1994; Pissarides, 2000; Rogerson et al., 2005), wages are negotiated at hiring and set by splitting the predicted match surplus (the gain from the match above the worker's outside option, i.e., the value of remaining unemployed) between worker and firm.

The predicted surplus is:

$$\hat{S}_{ij} = \max(\hat{q}_{ij} - r_i, \ 0)$$

where $\hat{q}_{ij}$ is the predicted match output (the hiring agent's prediction of match quality, or how productive the worker will be at the firm) and $r_i$ is the worker's reservation wage (§3b).

The surplus is split at a fixed ratio. The worker receives:

$$\text{wage}_{ij} = r_i + \beta_W \hat{S}_{ij}$$

and the firm expects to retain:

$$\text{expected profit}_{ij} = (1 - \beta_W) \hat{S}_{ij}$$

where $\beta_W \in (0, 1)$ is the worker's share of match surplus (default 0.5). This is a heuristic version of Nash bargaining (a game-theoretic model in which two parties split the gains from trade): agents split at a fixed ratio without computing equilibrium values or outside options dynamically (cf. Neugart & Richiardi, 2018, on heuristic wage rules in labor market ABMs).

This wage formula applies identically to internal hires and brokered placements. In both cases, the firm evaluates the candidate and sets the wage using its own prediction $\hat{q}_j​$. The broker's informational advantage under placement therefore operates through candidate selection, not price-setting (§7a).

#### 3b. Reservation wages

Workers have a reservation wage reflecting their outside options (Mortensen, 1986; Rogerson, Shimer, & Wright, 2005):

$$r_i = \max\!\left(r_{\text{base}},\;
r_{\text{base}} \cdot \left(1 + 0.20 \cdot
\frac{\deg_S(i)}{\max_k \deg_S(k)}\right) + \epsilon_r\right)$$

where:

- $r_{\text{base}}$ is the reservation wage floor (calibrated at initialization as $0.60 \cdot \bar{f}$, where $\bar{f} = E[f(w,x)]$ is the mean match output; §12c),
- the coefficient $0.20$ is the network wage premium, reflecting the finding that better-connected workers have more outside options and earn higher wages (Montgomery, 1991; Calvo-Armengol & Jackson, 2004, 2007),
- $\deg_S(i)$ is worker $i$'s degree in $G_S$ (§4),
- $\epsilon_r \sim N(0, (0.05 \cdot r_{\text{base}})^2)$ adds individual variation beyond network position.

The floor at $r_{\text{base}}$ prevents negative noise draws from pushing reservation wages below the baseline outside option. The 0.60 calibration sets the outside option at 60% of average productivity, producing a labor market where approximately 40% of match output is surplus available for splitting between workers and firms.

### 4. Network Structure

Agents interact through three types of relationships that jointly determine each agent's information set and matching opportunities.

A fixed **social network** $G_S$ among workers channels referrals. $G_S$ is an undirected small-world graph (Watts & Strogatz, 1998), starting from a ring lattice where each worker is connected to its $k_S = 6$ nearest neighbors in the type space, with rewiring probability $p_{\text{rewire}} = 0.1$. Produces high clustering, short path lengths, and moderate type assortativity. The degree and rewiring probability are structural constants of the network topology, not free parameters. This follows the labor market ABM tradition of using small-world referral networks (Tassier & Menczer, 2001; Calvo-Armengol & Jackson, 2004).

A dynamic bipartite **employment graph** $G_E^t$ connects each firm to its current employees and changes every period; let $E_j^t$ denote firm $j$'s current workforce.

From these, each firm $j$'s **referral reach** is the set of workers reachable through employees' social ties but not already employed by the firm:

$$R_j^t = \bigcup_{i \in E_j^t} N_S(i) \setminus E_j^t$$

The broker maintains a **pool** $\text{Pool}^t$ of workers it can propose for matching. The pool has a fixed target size $P$ (default $\lceil 0.20 \cdot N_W \rceil = 200$ at $N_W = 1000$), representing the broker's operational capacity for sourcing, vetting, and maintaining candidate relationships. Each period, workers who were placed or staffed in the previous period leave the pool (they are no longer available candidates), and the broker recruits replacement workers drawn uniformly at random from available workers not already in the pool, topping the pool back up to $\min(P, |\text{available} \setminus \text{Pool}^t|)$. The pool thus remains at or near its target size throughout the simulation, turning over as candidates are placed and replaced. Each period, the broker evaluates available pool members against its current clients and proposes matches using a greedy best-pair heuristic (§5b).

**Combined graph for network measures**. Each measurement period, all three relationship types are assembled into a single graph: $N_W + N_F + 1$ nodes (workers, firms, and the broker), with edges from $G_S$, $G_E^t$, and the broker's pool. Network measures computed on this graph (§8; betweenness centrality, Burt's constraint, effective size) are standard and directly comparable to the published structural holes literature (Burt, 1992, 2005).

**Firm turnover**. Firms exit independently each period with probability $\eta$ (the entry/exit rate; default 0.05), yielding an expected firm lifetime of 20 quarters (5 years), consistent with U.S. establishment survival rates (Knaup, 2005; Bureau of Labor Statistics, 2024b).

Exiting firms are replaced by entrants with fresh types sampled from the firm curve at a random position $t \sim U[0,1]$, an initial workforce of 6–10 employees sampled by type-proximity (seeding their referral network), and empty experience histories.

The worker population $N_W$ is fixed for the duration of the simulation: workers change status (available or employed) but never enter or leave the population. When a firm exits, its workers return to the available pool, retaining their positions in $G_S$.

### 5. Search

Each firm without an open vacancy generates one with probability $p_{\text{vac}}$ per period. A vacancy that goes unfilled persists to the next period; the firm does not draw a new vacancy while one is already open. This keeps firm history growth tractable and ensures the outsourcing decision is made at most once per firm per period. The default $p_{\text{vac}} = 0.50$ produces approximately 25 vacancies per period across 50 firms, ensuring sufficient hiring activity for regression learning.

A firm with a vacancy fills it either through internal search (§5a) or by outsourcing to the broker (§5b); the choice between the two channels is governed by a satisfaction-based decision rule described in §6. 

#### 5a. Internal search

Firm $j$ generates $n = \lceil 0.01 \cdot N_W \rceil$ candidates per period (1% of the worker population; baseline 10 with $N_W = 1000$). Half the candidates are drawn uniformly from available workers in $R_j^t$ (or all available workers in $R_j^t$ if fewer than $\lfloor n/2 \rfloor$); the remainder are drawn uniformly from available workers outside $R_j^t$. The even split matches the empirical finding that approximately half of jobs are found through informal contacts (Ioannides & Loury, 2004).

For each candidate $i$, the firm observes $w_i$ and predicts match output using its experience (§2a). The firm hires the candidate with the highest predicted output, provided the predicted surplus is positive: $\hat{q}_{ij} > r_i$ (§3a). The firm will not hire a worker whose predicted output does not exceed the worker's reservation wage, because the match would generate no value for the firm. If multiple candidates achieve the same maximum predicted output, one is selected uniformly at random. If no candidate yields positive predicted surplus, the vacancy persists to the next period.

#### 5b. Broker-mediated search

When firm $j$ outsources to the broker, the broker includes firm $j$ in its allocation for the current period. At the end of Step 1 (after all outsourcing decisions), the broker observes its full client list $J^t$ and available pool $\text{Pool}^t \cap \{\text{available workers}\}$. The broker computes predicted match quality $\hat{q}_b(w_i, x_j)$ for every (worker, vacancy) pair and assigns matches using a greedy best-pair heuristic (§8, Step 2b): iteratively select the highest-quality pair, propose that match, and remove both worker and vacancy from consideration. This continues until all vacancies are filled, the pool is exhausted, or no remaining pair has positive predicted surplus ($\hat{q}_b > r_i$). The broker applies the same surplus threshold as internal search: it does not propose matches with non-positive predicted surplus.

The firm does not apply a separate surplus threshold to the broker's proposal; the outsourcing decision reflects cumulative experience with the broker, not a per-match evaluation. Poor realized output reduces the firm's satisfaction, making future outsourcing less likely (§6a).

Firms whose vacancy is not filled (because the pool was exhausted or no candidate cleared the surplus threshold) receive no proposal. The firm's broker satisfaction updates toward its internal satisfaction: $s_{j,b}^{t+1} = (1 - \omega)\, s_{j,b}^t + \omega \cdot s_{j,\text{int}}^t$ (§6a). The broker's proposals may conflict with internal search (the same worker could be selected by both channels). These conflicts are resolved in Step 3.2.

After any match forms (whether via internal search or brokered placement), the realized match output $q_{ij}$ is observed by all parties. The broker adds the observation to its experience history for future predictions (§2).

### 6. The outsourcing decision

The outsourcing decision and broker pricing form a feedback loop that operates across periods: firms track realized output minus their per-period cost above $r_i$ (§6a), and these scores determine whether firms outsource or search internally (§6b).

#### 6a. Satisfaction tracking

Each firm $j$ maintains a satisfaction index $s_{j,c}^t$ for each hiring channel $c$ (internal search and the broker). These scores summarize past hiring outcomes and drive the outsourcing decision (§6b).

The index is an exponentially weighted moving average (recency weight $\omega = 0.3$) of realized output minus the firm's per-period cost above $r_i$:

$$s_{j,c}^{t+1} = (1 - \omega)\,s_{j,c}^t + \omega\!\left(q_{ij} - \text{cost}_{c}\right)$$

where $\text{cost}_{c}$ is the firm's per-period expenditure above the baseline labor cost $r_i$:

| Channel | $\text{cost}_{c}$ | Components |
|---------|-------------------|------------|
| Internal hire | $\beta_W \max(\hat{q}_j - r_i, 0)$ | Surplus share paid to worker |
| Brokered placement | $\beta_W \max(\hat{q}_j - r_i, 0) + \alpha \cdot \text{wage}_{ij} / L$ | Surplus share + amortized placement fee |
| Staffing (§9c) | $\mu_b \cdot \hat{q}_b$ | Value premium in the bill rate |

Since every channel pays $r_i$ as baseline labor cost, it cancels in cross-channel comparisons. The placement fee is amortized over $L$ periods (the expected useful duration of a hire) so that per-period costs are comparable across channels. M1 reuses $L$ as the staffing assignment length (§9). For subscribers under data capture (§10b), the prediction $\hat{q}_b$ replaces $\hat{q}_j$ in the wage formula, so the deduction uses $\hat{q}_b$ as well.

**No-proposal penalty.** When the broker makes no proposal for firm $j$ (either because the pool is exhausted or no candidate clears the surplus threshold; §5b), the firm's broker satisfaction updates toward its internal satisfaction:

$$s_{j,b}^{t+1} = (1 - \omega)\, s_{j,b}^t + \omega \cdot s_{j,\text{int}}^t$$

The penalty is the opportunity cost of outsourcing: the firm delegated its search to the broker and received nothing, forgoing the outcome it would have gotten from internal search. Repeated non-delivery pulls $s_{j,b}$ toward $s_{j,\text{int}}$, at which point the firm stops outsourcing. A single bad match (which can produce negative satisfaction input when costs exceed output) is strictly worse than non-delivery, so the broker is never incentivized to propose low-quality matches to avoid the penalty.

Satisfaction indices are not floored: they can go negative when costs persistently exceed output, which is informative for the outsourcing decision. The EWMA's recency weighting ensures recovery from negative values within a few good observations.

New firms initialize all indices at the public benchmark $\bar{q}_{\text{pub}}$ (§2d). Each index is a single scalar; only the current value and the next observation are needed for the update.

Because satisfaction tracks realized output minus the firm's cost above $r_i$, both overconfident predictions (which inflate costs through wage surplus) and excessive fees are self-correcting: either reduces the broker's satisfaction score and causes firms to revert to internal search.

#### 6b. Decision rule

Each period, a firm with a vacancy chooses between two search channels: internal search or the broker. The firm selects the channel with the higher satisfaction score. Ties are broken uniformly at random.

If the firm has not yet tried the broker, it substitutes broker reputation:

$$\text{rep}_b^t = \begin{cases} \frac{1}{|\mathcal{J}_b^t|} \sum_{j' \in \mathcal{J}_b^t} s_{j',b}^t & \text{if } \mathcal{J}_b^t \neq \emptyset \\[4pt] \text{rep}_b^{t-1} & \text{if } \mathcal{J}_b^t = \emptyset \text{ and broker } b \text{ has had clients before} \\[4pt] \bar{q}_{\text{pub}} & \text{if broker } b \text{ has never had clients} \end{cases}$$

where $\mathcal{J}_b^t$ is the set of firms currently using the broker. Reputation is **sticky**: when the broker loses all current clients, it retains the last reputation computed from actual client satisfaction. Only if the broker has *never* had any client does it default to $\bar{q}_{\text{pub}}$ (§2d).

### 7. Broker Pricing

The broker earns revenue through one-time placement fees when it matches a worker to a firm (§7a). The fee rate is fixed (§7b). Under worker capture (§9), the broker additionally earns ongoing staffing revenue.

#### 7a. Placement fee

When the broker places a worker at a firm, the firm pays a one-time fee proportional to the offered salary. This mirrors the contingency fee structure in the staffing industry, where agencies charge 15–25% of the worker's salary, a quantity determined by the firm's evaluation of the candidate and known at hiring (Autor, 2009; Bonet et al., 2013):

$$\phi_b^t = \alpha \cdot \text{wage}_{i^*j}$$

where $\alpha = 0.20$ is the placement fee rate (§7b), and $\text{wage}_{i^*j} = r_{i^*} + \beta_W \cdot \max(\hat{q}_j(w_{i^*}) - r_{i^*}, 0)$ is the salary the firm offers the placed worker (§3a). Because the wage is set by the firm using its own prediction $\hat{q}_j$, the fee reflects the firm's evaluation, not the broker's. The broker's informational advantage under placement operates through candidate selection rather than price-setting (§5b). The broker bears no post-placement risk; its incentive to predict accurately comes from the satisfaction channel (§6a).

This creates a **recognition gap**: the broker must estimate its placement revenue by substituting $\hat{q}_b$ for the firm's unknown $\hat{q}_j$. When the broker's predictions are more accurate ($\hat{q}_b > \hat{q}_j$ for high-quality matches), it overestimates placement revenue by $\alpha \cdot \beta_W \cdot (\hat{q}_b - \hat{q}_j)$. The gap narrows as firms accumulate experience and $\hat{q}_j$ converges toward $\hat{q}_b$. Under worker capture (§9d), this gap delays the broker's transition from placement to staffing.

#### 7b. Fee rate

The placement fee rate $\alpha = 0.20$ is fixed. The broker competes with firms' internal search solely on the quality of its match predictions, not on price. This isolates the informational channel: if the broker can attract and retain clients at a fixed fee, its value must derive from prediction accuracy (§6a) rather than price adjustments. This provides a more stringent test of the broker's informational advantage than adaptive pricing, under which the broker could compensate for lower match quality by reducing fees.

### 8. Base Model Pseudocode

At the start of the simulation, the state of the world must be initialized.

<small>

> **INITIALIZE (Claude generated; review required)**
>
> *Firm types and matching function.*
> I.1. &emsp;Generate firm type geometry (§0) and draw $N_F$ firm types on the unit sphere. Store geometry parameters for entrant firms.
> I.2. &emsp;Draw ideal worker $c$ as perturbation of a random firm type with $\sigma_w / \sqrt{d}$ per-dimension noise (like an $(N_W + 1)$th worker).
> I.3. &emsp;Draw interaction matrix $\mathbf{A} \in \mathbb{R}^{d \times d}$ with iid $N(0,1)$ entries.
>
> *Worker types.*
> I.5. &emsp;For each worker $i$: draw reference firm $j(i) \sim U\{1,\ldots,N_F\}$; set $w_i = x_{j(i)} + \epsilon_i$, $\epsilon_i \sim N(0, \sigma_w^2/d \cdot I_d)$.
>
> *Calibration.*
> I.9. &emsp;Compute $E[f]$ from 10,000 random (not clustered) $(w, x)$ pairs using actual firm types. Set $\bar{q}\_\text{pub} \leftarrow E[f]$; $r\_\text{base} \leftarrow 0.70 \cdot E[f]$; $c\_\text{emp} \leftarrow 0.15 \cdot r\_\text{base}$ (M1 only).
> I.10. &emsp;For each worker $i$: compute reservation wage $r_i$ per §3b using $r_\text{base}$ and $G_S$ (after I.11).
>
> *Network and employment.*
> I.11. &emsp;Build $G_S$: Watts–Strogatz with $N_W$ nodes, degree $k_S$, rewiring $p_\text{rewire}$. Node order = workers sorted by first principal component of type.
> I.12. &emsp;For each firm $j$: draw workforce size $\sim \text{Uniform}\{6, 7, 8, 9, 10\}$; sample workers without replacement with probability $\propto \exp(-\|w_i - x_j\|^2)$; add to $E_j^0$; set worker status $\leftarrow$ employed at $j$. Realize match output for each initial hire and record to $\mathcal{H}_j$ (seeding the firm's prediction model).
> I.13. &emsp;For each firm $j$: $R_j^0 \leftarrow \bigcup_{i \in E_j^0} N_S(i) \setminus E_j^0$.
> I.14. &emsp;Broker seed pool: draw $P = \lceil 0.20 \cdot N_W \rceil$ workers uniformly from available workers; add to $\text{Pool}^0$. Seed broker history $\mathcal{H}_b$ with 20 random observations from existing worker-firm matches.
>
> *State variables.*
> I.15. &emsp;For each firm $j$: $\mathcal{H}_j \leftarrow \emptyset$; $\quad s_{j,\text{int}}^0 \leftarrow \bar{q}\_\text{pub}$; $\quad s_{j,\text{broker}}^0 \leftarrow \bar{q}\_\text{pub}$; $\quad \text{vacancy} \leftarrow \text{none}$.
> I.16. &emsp;$\mathcal{H}_b \leftarrow \emptyset$; $\quad \text{rep}^0 \leftarrow \bar{q}\_\text{pub}$; $\quad \text{last\_reputation} \leftarrow \bar{q}\_\text{pub}$; $\quad \Pi_b \leftarrow 0$.

</small>

Each period proceeds through six steps. The pseudocode below specifies the exact ordering of operations within each step. Where operations are independent across agents, they can be executed in parallel; dependencies are noted.

<small>

> **PERIOD $t$:**
>
> **0. REFERRAL POOL COMPUTATION**
> 0.1. &emsp;for each firm $j$: $R_j^t \leftarrow \bigcup_{i \in E_j^t} N_S(i) \;\setminus\; E_j^t$
>
> **1. VACANCY MANAGEMENT AND OUTSOURCING DECISION**
> 1.1. &emsp;Carry forward unfilled vacancies from $t{-}1$.
> 1.2. &emsp;Each firm without an open vacancy draws one with probability $p_{\text{vac}}$.
> 1.3. &emsp;Identify firms with vacancies: $V^t \subset \{1, \ldots, N_F\}$
> 1.4. &emsp;for each firm $j \in V^t$:
> &emsp;&emsp;$\text{score}\_\text{int} \leftarrow s_{j,\text{int}}^t$
> &emsp;&emsp;$\text{score}\_\text{broker} \leftarrow s_{j,\text{broker}}^t$ &ensp;(use $\text{rep}^t$ if untried; §6b)
> &emsp;&emsp;$\text{decision}\_j \leftarrow \arg\max(\text{score}\_\text{int},\; \text{score}\_\text{broker})$
> &emsp;Output: partition of $V^t$ into internal searchers and broker client list $J^t$.
>
> **2. CANDIDATE GENERATION AND EVALUATION**
> &emsp;$n \leftarrow \lceil 0.01 \cdot N_W \rceil$ &ensp;(1% of worker population)
>
> &emsp;**2.1. Internal searches**:
> 2.1.1. &emsp;for each firm $j$ with $\text{decision}\_j = \text{internal}$:
> &emsp;&emsp;Draw $\lfloor n/2 \rfloor$ candidates from available workers $\cap\; R_j^t$ (uniform, without replacement; fewer if $|R_j^t \cap \text{available}| < \lfloor n/2 \rfloor$)
> &emsp;&emsp;Draw $\lceil n/2 \rceil$ candidates from available workers $\setminus\; R_j^t$ (uniform, without replacement)
> &emsp;&emsp;For each candidate $i$, predict: $\hat{q}_j(w_i) = \hat{\boldsymbol{\beta}}_j^\top w_i + \hat{\alpha}_j$ using firm's ridge model
> &emsp;&emsp;Select $i^* = \arg\max \hat{q}_j(w_i)$ &ensp;(ties broken uniformly at random)
> &emsp;&emsp;If $\hat{q}_j(w_{i^*}) \leq r_{i^*}$: vacancy persists (zero surplus); else: record proposed match $(j, i^*)$
>
> &emsp;**2.2. Broker proposals:**
> 2.2.1. &emsp;Collect client list: $J^t = \{j : \text{decision}\_j = \text{broker}\}$
> 2.2.2. &emsp;$\text{available\_pool} \leftarrow \text{Pool}^t \cap \{\text{available workers}\}$
> 2.2.3. &emsp;Compute quality matrix: $\hat{Q}[i,j] = \hat{q}_b(w_i, x_j)$ for all $i \in \text{available\_pool}$, $j \in J^t$, using the broker's pooled ridge model on features $[w_i; x_j; \text{vec}(w_i \otimes x_j); w_i^2]$.
> 2.2.4. &emsp;while available\_pool non-empty AND $J^t$ non-empty:
> &emsp;&emsp;$(i^*, j^*) = \arg\max \hat{Q}[i,j]$ &ensp;(ties broken uniformly at random)
> &emsp;&emsp;If $\hat{Q}[i^*, j^*] \leq r_{i^*}$: break &ensp;(no remaining pair has positive surplus)
> &emsp;&emsp;Record proposed match $(j^*, i^*)$
> &emsp;&emsp;Remove $i^*$ from available\_pool (row); remove $j^*$ from $J^t$ (column)
> 2.2.5. &emsp;If $J^t$ non-empty (pool exhausted or no surplus-positive candidate): for each remaining $j \in J^t$, mark as no-proposal
> &emsp;If available\_pool non-empty (all vacancies filled): remaining workers stay in pool
>
> **3. MATCH FORMATION AND PAYMENTS**
>
> &emsp;**3.1. Wage setting:**
> 3.1.1. &emsp;for each proposed brokered match $(j, i^*)$:
> &emsp;&emsp;Firm evaluates candidate: $\hat{q}_j(w_{i^*})$; mark match as placement
> &emsp;&emsp;$\text{wage} = r_{i^*} + \beta_W \cdot \max(\hat{q}_j(w_{i^*}) - r_{i^*},\; 0)$
> 3.1.2. &emsp;for each proposed internal match $(j, i^*)$:
> &emsp;&emsp;$\text{wage} = r_{i^*} + \beta_W \cdot \max(\hat{q}_j(w_{i^*}) - r_{i^*},\; 0)$
>
> &emsp;**3.2. Conflict resolution:**
> 3.2.1. &emsp;Collect all proposals from both channels. If a worker appears in multiple proposals, the worker accepts the highest-wage offer (ties broken randomly). Rejected proposals are discarded; the firm's vacancy persists to the next period.
>
> &emsp;**3.3. Finalization** (for each accepted match $(j, i^*)$):
> 3.3.1. &emsp;Realize output: $q_{i^*j} = f(w_{i^*}, x_j) + \varepsilon_{i^*j}$
> 3.3.2. &emsp;Compute fees: placement $\phi = \alpha \cdot \text{wage}_{i^*j}$ (§7a); internal hire: no fee.
> 3.3.3. &emsp;Record: channel ($c$), $q_{i^*j}$, $\hat{q}$ (prediction used), wage, fee, whether $i^* \in R_j^t$ (access vs. assessment).
>
> **4. LEARNING AND STATE UPDATES**
> 4.1. &emsp;for each accepted match $(j, i^*)$:
> &emsp;&emsp;If direct hire via internal search:
> &emsp;&emsp;&emsp;Add $i^*$ to $E_j^t \to E_j^{t+1}$; add $(w_{i^*}, q_{i^*j})$ to $\mathcal{H}_j$;
> &emsp;&emsp;&emsp;Worker $i^*$ status $\leftarrow$ employed at $j$
> &emsp;&emsp;If direct hire via brokered placement:
> &emsp;&emsp;&emsp;Add $i^*$ to $E_j^t \to E_j^{t+1}$; add $(w_{i^*}, q_{i^*j})$ to $\mathcal{H}_j$; add $(w_{i^*}, x_j, q_{i^*j})$ to $\mathcal{H}_b$
> &emsp;&emsp;&emsp;Worker $i^*$ status $\leftarrow$ employed at $j$ (removed from pool during maintenance at step 4.4)
> &emsp;&emsp;&emsp;$\Pi_b \leftarrow \Pi_b + \phi$ &ensp;(accumulate placement fee revenue)
>
> 4.2. &emsp;Update satisfaction indices (output minus cost above $r_i$, §6a):
> &emsp;&emsp;for each firm $j$ that made a new hire via channel $c$:
> &emsp;&emsp;&emsp;If internal: $\tilde{q} = q_{i^*j} - \beta_W \cdot \max(\hat{q}_j(w_{i^*}) - r_{i^*},\; 0)$
> &emsp;&emsp;&emsp;If brokered placement: $\tilde{q} = q_{i^*j} - \beta_W \cdot \max(\hat{q}_j(w_{i^*}) - r_{i^*},\; 0) - \alpha \cdot \text{wage}_{i^*j} / L$
> &emsp;&emsp;&emsp;$s_{j,c}^{t+1} = (1 - \omega)\, s_{j,c}^t + \omega \cdot \tilde{q}$
> &emsp;&emsp;for each firm $j$ that outsourced but received no proposal:
> &emsp;&emsp;&emsp;$s_{j,\text{broker}}^{t+1} = (1 - \omega) \cdot s_{j,\text{broker}}^t + \omega \cdot s_{j,\text{int}}^t$ &ensp;(opportunity-cost penalty, §6a)
>
> 4.3. &emsp;Update broker reputation:
> &emsp;&emsp;if $|J^t| > 0$: $\text{rep}^t \leftarrow \text{mean of } s_{j,\text{broker}}^t \text{ over } j \in J^t$; store as last\_reputation
> &emsp;&emsp;else if broker has had clients before: $\text{rep}^t \leftarrow$ last\_reputation
> &emsp;&emsp;else: $\text{rep}^t \leftarrow \bar{q}\_\text{pub}$
>
> 4.4. &emsp;Broker pool maintenance:
> &emsp;&emsp;Remove from $\text{Pool}^t$ any workers who were placed or staffed this period (they are no longer available candidates).
> &emsp;&emsp;Let $n_{\text{gap}} = P - |\text{Pool}^t|$. If $n_{\text{gap}} > 0$: draw $\min(n_{\text{gap}}, |\{\text{available}\} \setminus \text{Pool}^t|)$ workers uniformly from $\{\text{available workers}\} \setminus \text{Pool}^t$; add to $\text{Pool}^{t+1}$.
>
> **5. ENTRY AND EXIT**
> 5.1. &emsp;for each firm $j$:
> &emsp;&emsp;With probability $\eta$: firm exits
> &emsp;&emsp;&emsp;All employees of $j$ return to available pool
> &emsp;&emsp;&emsp;Firm $j$ is replaced by entrant $j'$ with: fresh type $x_{j'}$ sampled from firm curve at random $t \sim U[0,1]$; initial workforce drawn from $\{6,7,8,9,10\}$ uniformly, preferring type-proximity to $x_{j'}$; empty history $\mathcal{H}_{j'} = \emptyset$; all satisfaction indices initialized at $\bar{q}\_\text{pub}$
>
> **6. NETWORK MEASURES** (computed every $M$ periods, default $M = 10$):
> 6.1. &emsp;Construct combined graph (§4):
> &emsp;&emsp;Nodes: workers $1..N_W$, firms $N_W{+}1..N_W{+}N_F$, broker node $N_W{+}N_F{+}1$
> &emsp;&emsp;Edges: $G_S$ edges among workers + employment edges $(i, j)$ for $i \in E_j^t$ + broker-pool edges $(i, \text{broker})$ for $i \in \text{Pool}^t$
> 6.2. &emsp;Compute on combined graph: Freeman betweenness centrality (all nodes; record broker's); Burt's constraint (broker's ego network); effective size (broker's ego network)
> 6.3. &emsp;Compute prediction quality ($R^2$, bias, rank correlation; rolling window) for broker and each firm from accumulated (predicted, realized) pairs. Compute access vs. assessment (fraction of brokered placements where $i^* \in R_j^t$).
>
> **7. PERIOD RECORDING** (every period):
> 7.1. &emsp;Record period aggregates: match quality by channel ($\bar{q}_c^t$); vacancy rate by channel (unfilled / total); outsourcing rate ($|J^t| / |V^t|$); broker pool size $|\text{Pool}^t|$; mean firm referral pool size $\overline{|R_j^t|}$.
> 7.2. &emsp;Record broker state: cumulative revenue $\Pi_b$; reputation $\text{rep}^t$; pool size; $|\mathcal{H}_b^t|$.

</small>

#### Parallelism summary

Steps 0 and 1 are embarrassingly parallel across firms.
Step 2.1 (internal search) is parallel across firms.
Step 3 requires a conflict resolution pass (internal vs. broker proposals for the same worker) but the per-match computations are parallel.
Steps 4–5 involve writes to shared state (employment graph, broker pool, worker status) that require synchronization, but the writes are non-overlapping (each match writes to distinct agent records).
The network measures are the most expensive single computation; they read the full state but write nothing and can be offloaded to a separate thread or deferred to a coarser schedule.

#### Network and performance measures

Computed on the combined graph (§4) each measurement period. No agent uses these measures in its decisions; they are outputs for analysis.

**Betweenness centrality.** Standard Freeman betweenness centrality (Freeman, 1977) of the broker node in the combined graph. Measures the fraction of shortest paths between all other pairs that pass through the broker.

**Burt's constraint.** Computed on the broker's ego network in the combined graph (Burt, 1992):

$$C_b = \sum_j \left(p_{bj} + \sum_{q \neq b,j}
p_{bq}\, p_{qj}\right)^2$$

where $p_{bj}$ is the proportion of the broker's ties invested in node $j$. Low constraint = broker spans structural holes. High constraint = broker's contacts are interconnected.

**Effective size.** The number of non-redundant contacts in the broker's ego network (Burt, 1992): $\text{ES}_b = |N(b)| - \sum_j p_{bj} \sum_{q \neq b} p_{bq}\, m_{jq}$ where $m_{jq} = 1$ if $j$ and $q$ are connected.

**Prediction quality: selected-sample vs. holdout evaluation.** Prediction quality is evaluated in two distinct ways that measure different things. Understanding the distinction is important because agents select candidates based on noisy predictions, which introduces a systematic winner's curse (selection bias) into the selected-sample metrics.

**Winner's curse / selection bias.** Both firms and the broker hire the candidate with the highest *predicted* match quality from their candidate pool ($\arg\max_i \hat{q}_{ij}$). When predictions are noisy, the selected candidate's prediction $\hat{q}_{i^*j}$ is systematically inflated relative to the true match quality $f(w_{i^*}, x_j)$, because the selection picks up positive noise realizations. This is the classic winner's curse: the winning bid in an auction overestimates the item's value. In the model, this bias is economically real. Wages are set from predicted surplus (§3a), so the winner's curse inflates wages relative to realized productivity, reducing the firm's realized profit margin. It is not merely a measurement artifact: it affects the economics of every hire through the surplus-sharing wage formula.

**Holdout $R^2$ (model quality).** Each period, a sample of random available workers is evaluated against each firm (and by the broker against a random firm) using noiseless true match quality $f(w, x)$ as the target. These workers are *not* selected by the agent's model. They are drawn at random, so the evaluation is free of selection bias. Holdout $R^2$ measures pure model quality: how well the agent's regression model approximates the true matching function. It is the cleanest measure of informational advantage because it is uncontaminated by the winner's curse or by variation in candidate pool composition.

**Selected-sample metrics.** Three metrics are computed over a rolling window of the last 50 actual hires (brokered placements for the broker, direct hires for firms):

- *Selected $R^2$* $= 1 - \text{MSE}/\text{Var}(q)$, where $\text{MSE} = \frac{1}{n}\sum(\hat{q} - q)^2$ and $\text{Var}(q)$ is the variance of realized output in the window. Because hired workers are those with the highest predictions, this sample is subject to the winner's curse: predictions are systematically inflated relative to outcomes, depressing $R^2$ and inflating bias. Selected $R^2$ measures **wage accuracy**: how well the prediction used for wage-setting matches the realized outcome. It is the metric most relevant to the economics of the firm's profit margin.

- *Bias* $= \frac{1}{n}\sum(\hat{q} - q)$. Tracks systematic over- or underprediction. Positive bias is expected in the selected sample due to the winner's curse: the agent selects candidates whose predictions benefited from positive noise. This bias inflates wages (through the surplus-sharing formula, §3a) and drives the recognition gap (§7a). $R^2$ can be high while bias is large if predictions track the shape of $f$ but are shifted.

- *Selected rank correlation* (Spearman's $\rho_S$). Measures whether the agent ranks hired candidates correctly by realized output, independent of level or scale. This is the measure most relevant to **hiring decision quality**: did the agent pick the right candidates from the pool? The rank correlation is less affected by the winner's curse than $R^2$ because it is invariant to monotone transformations of the prediction scale. High rank correlation with low $R^2$ indicates good candidate selection but miscalibrated pricing.

**Summary of the three prediction quality metrics:**

| Metric | What it measures | Selection bias? | Primary use |
|--------|-----------------|-----------------|-------------|
| Holdout $R^2$ | Model quality (approximation of $f$) | None (random sample, noiseless truth) | Informational advantage |
| Selected rank correlation | Hiring decision quality (correct ordering) | Mild (order is more robust than level) | Allocation effectiveness |
| Selected $R^2$ | Wage accuracy (prediction vs. realized outcome) | Strong (winner's curse inflates predictions) | Profit margin, surplus sharing |

The broker-firm gap in holdout $R^2$ is the purest measure of the informational advantage. The gap in selected rank correlation shows whether the advantage translates into better hiring decisions. The gap in selected $R^2$ shows whether it affects wage accuracy. Under Model 1 staffing, prediction quality should stop improving for locked-in firms whose histories freeze (§9f).

**Access vs. assessment decomposition.** For each brokered placement, record whether worker $i^*$ was in $R_j^t$ (the client firm's referral pool, computed at step 0). If yes: assessment value (the firm could have found this worker but the broker predicted match output better). If no: access value (the firm could not have found this worker through its own network).

**Match quality by channel.** Average realized match output $\bar{q}_c^t$ per period, where $c \in \{\text{direct}, \text{placed}\}$. Direct hires are matches where the firm conducted its own search (§5a); placed matches are those where the broker selected the candidate (§5b). Under Model 1, a third channel (staffed) is added (§9). Under Model 2, direct hires are further split by subscription status (§10). Reported as period means with 95% confidence bands across replications. Variant-specific capture measures are defined jointly in §11.

**Vacancy rate by channel.** Fraction of openings that remain unfilled per period, broken down by search channel (internal search vs. broker-mediated) and by model. A vacancy persists when no candidate yields positive predicted surplus (§5a) or when the broker's candidate pool is depleted (§5b).

---

## Part II. Model Variants

All base model mechanisms (§§1–7) operate unchanged in the model variants 1 and 2: firms search, learn, outsource, and the broker earns placement fees exactly as before.

In Model 1, the difference is that the broker can additionally employ workers directly and supply them to client firms on an ongoing basis, an arrangement called staffing.

In Model 2, the difference is that the broker can additionally offer a data product in the form of a per-period subscription service for predictions, alongside its placement service.

### 9. Worker Capture (M1)

#### 9a. Setup

Under worker capture, the broker can employ workers directly and supply them to client firms on a recurring basis. This arrangement, called staffing, gives the broker a per-period revenue stream and creates a double lock-in that freezes the client firm's learning and referral network growth (§9f).

**Agent state additions.** Worker status (§0) gains a third state: **staffed**, employed by the broker and assigned to a firm. A staffed worker does not appear in the firm's employee set $E_j^t$, does not contribute to the firm's referral reach, and the firm does not observe the worker's type or update its history $\mathcal{H}_j^t$ from the assignment (§9f). The broker gains **active staffing assignments**: a list of current contracts, each specifying the worker, firm, bill rate, and remaining periods. The broker's experience history $\mathcal{H}_b^t$ grows from staffing assignments in the same way as from placements. Staffed workers leave the broker's pool (they are no longer available candidates) and are replaced by new recruits during pool maintenance (§4).

#### 9b. Staffing wages

Under staffing, the worker is employed by the broker, not the firm. The broker pays the worker their reservation wage:

$$\text{wage}_{i}^{\text{staff}} = r_i$$

Under direct hire, the worker would earn $r_i + \beta_W \cdot \max(\hat{q}_j - r_i, 0)$ (§3a). The forgone surplus share is captured by the broker through the bill rate's value premium (§9c). This wage differential reflects the empirically documented temporary-worker wage penalty (Autor & Houseman, 2010; Houseman, Kalleberg, & Erickcek, 2003). The firm does not pay the worker directly; it pays the broker a per-period bill rate (§9c).

#### 9c. Staffing bill rate and economics

Under staffing, the broker bills the client firm a per-period rate with two components: the worker's reservation wage (passed through at cost) and a value premium proportional to the broker's predicted match output:

$$\psi_b^t = r_i + \mu_b \cdot \hat{q}_b(w_{i^*}, x_j)$$

The parameter $\mu_b$ is the value-capture rate: the fraction of predicted match output the broker charges each period as compensation for identifying and supplying the worker. The default $\mu_b = 0.25$ produces bill rates comparable to the industry average gross margin of 25--41% reported across temporary staffing firms for matches of average output (Bonet et al., 2013; Autor, 2009), while allowing the bill rate to vary with $\hat{q}$. Higher-output matches command higher bill rates; lower-output matches command lower ones.

The broker's per-period profit on a staffed assignment is the bill rate minus the worker's wage and employment costs:

$$\pi_b^{\text{staff}} = \psi_b^t - r_i - c_{\text{emp}}
= \mu_b \cdot \hat{q} - c_{\text{emp}}$$

where $c_{\text{emp}}$ is the per-period cost of being the employer of record, covering statutory employer costs and administrative overhead (default $0.15 \cdot r_{\text{base}}$; §12c). Because the worker's wage cancels, the margin depends entirely on the predicted match output: the broker earns more from matches it predicts will generate high value.

**Assignment duration and total profit.** Each staffing assignment lasts $L$ periods (default 4; fixed per assignment). The broker's total profit is:

$$\Pi^{\text{staff}} = L \cdot (\mu_b \cdot \hat{q} - c_{\text{emp}})$$

Staffing assignments are short (default $L = 4$ quarters), so time discounting is economically immaterial and omitted. The bill rate is locked in at the $\hat{q}$ predicted at the start of the assignment and does not adjust with realized output. The broker bears risk because it commits to $L$ periods of wage payments regardless of whether realized output matches the prediction.

**Satisfaction and output realization.** Match output $q_{ij}$ is realized once at the start of the assignment. The firm's satisfaction is updated once at formation with net outcome $q_{ij} - \mu_b \cdot \hat{q}_b(w_{i^*}, x_j)$, deducting only the value premium (the reservation wage $r_i$ is a pass-through cost the firm would bear under any channel; §6a). No further satisfaction updates occur during the $L$-period assignment. The broker adds $(w_{i^*}, x_j, q_{ij})$ to $\mathcal{H}_b$ at formation.

**Vacancy reopening.** When a staffing assignment expires after $L$ periods, the worker returns to the available pool and the firm's vacancy reopens. If the firm's satisfaction with the broker remains high, it is likely to outsource again, creating recurring demand.

#### 9d. When the broker offers staffing

Each time the broker fills a vacancy, it compares expected placement profit against expected staffing profit ($\Pi^{\text{staff}}$ from §9c):

$$\Pi^{\text{place}} = \alpha \cdot (r_{i^*} + \beta_W \cdot \max(\hat{q}_b(w_{i^*}, x_j) - r_{i^*}, \; 0))$$

Both quantities use the broker's prediction $\hat{q}_b$, but only the staffing estimate is accurate: the actual placement fee depends on the firm's evaluation $\hat{q}_j$ (§7a). The recognition gap (§7a) causes the broker to overestimate placement revenue, delaying the transition to staffing until $\hat{q}_j$ converges toward $\hat{q}_b$.

If $\Pi^{\text{staff}} > \Pi^{\text{place}}$ and the firm accepts the bill rate (§9e), the broker staffs. Otherwise it places. (Workers always accept broker employment at their reservation wage; §9b.)

No minimum prediction confidence is required before the broker offers staffing. Early on, inaccurate predictions prevent the broker from reliably identifying high-output matches, so $\hat{q}_b$ for selected candidates tends to be moderate and the per-period margin $\mu_b \cdot \hat{q}_b - c_{\text{emp}}$ is too small for $\Pi^{\text{staff}}$ to exceed $\Pi^{\text{place}}$. As predictions improve (§2), the broker reliably identifies genuinely high-output matches, raising both the level and reliability of $\hat{q}_b$ for selected candidates. Because the staffing slope in $\hat{q}$ ($L \cdot \mu_b$) exceeds the placement slope ($\alpha \cdot \beta_W$), the profit comparison tips toward staffing once predictions are accurate enough to consistently identify high-quality candidates. The broker does not account for premature termination due to firm exit; this makes the staffing threshold marginally too low but does not affect the qualitative dynamics.

The two channels embed different rent-capture mechanisms. Under placement, the fee is set by the firm's evaluation, so the broker captures rents indirectly through candidate quality. Under staffing, the broker sets the bill rate from $\hat{q}_b$ directly (§9c), encoding its private information in the price.

#### 9e. Firm's perspective on staffing

The firm compares the per-period cost of staffing against the per-period cost of a direct hire. All quantities are known at decision time: the broker announces the bill rate (based on $\hat{q}_b$; §9c), and the firm knows its own evaluation of the candidate $\hat{q}_j$ (which determines the wage and placement fee; §3a, §7a). Under direct hire (via placement), the firm pays:

$$\text{cost}^{\text{direct}} = \text{wage}_{ij} +
\frac{\phi_b^t}{L}$$

where $\text{wage}_{ij} = r_i + \beta_W \max(\hat{q}_j - r_i, 0)$ is the worker's wage under surplus splitting (§3a) and the one-time placement fee $\phi = \alpha \cdot \text{wage}_{ij}$ (§7a) is amortized over $L$ periods (§6a). Both the wage and the fee are based on the firm's prediction $\hat{q}_j$. Under staffing, the firm pays the bill rate each period:

$$\text{cost}^{\text{staff}} = \psi_b^t = r_i + \mu_b \cdot \hat{q}_b$$

where $\hat{q}_b$ is the broker's prediction (§9c). The firm accepts staffing when the bill rate is competitive with the amortized direct-hire cost. When predictions have converged ($\hat{q}_b \approx \hat{q}_j$), staffing is accepted whenever $\mu_b < \beta_W \cdot (1 + \alpha / L)$ ($\approx 0.53$ at defaults). The default $\mu_b = 0.25$ satisfies this comfortably. Early in the simulation, $\hat{q}_b > \hat{q}_j$ makes the bill rate relatively higher, but the gap is moderate at defaults and does not qualitatively change the acceptance decision.

#### 9f. Lock-in and network effects

Under direct hire (internal or brokered placement), the worker joins $E_j^t$. The firm:

- Observes $(w_i, q_{ij})$ and adds the pair to $\mathcal{H}_j$, improving future predictions (§2a).
- Gains referral access to $N_S(i)$: $R_j^{t+1}$ expands.
- Creates a direct tie in $G_E^t$, closing the structural hole the broker bridged.

Under staffing, the broker employs the worker. The worker does **not** join $E_j^t$. The firm:

- Does **not** observe $w_i$, so the pair cannot enter $\mathcal{H}_j$.
- Does **not** gain referral access to $N_S(i)$.
- No tie forms in $G_E^t$; the structural hole remains open.

Staffing therefore produces a **double lock-in**: the firm's prediction function does not improve (*informational*) and its referral network does not grow (*structural*). At the network level, betweenness centrality does not decline, constraint stays low, and effective size is preserved. The self-liquidating dynamic of structural-hole brokerage is suspended.

#### 9g. Pseudocode step modifications

Steps not listed are identical to the base pseudocode (§8).

<small>

> **3. MATCH FORMATION AND PAYMENTS** (staffing branch added)
>
> &emsp;**3.1. Wage setting and staffing decisions**:
> 3.1.1. &emsp;for each proposed brokered match $(j, i^*)$:
> &emsp;&emsp;Firm evaluates candidate: $\hat{q}_j(w_{i^*})$
> &emsp;&emsp;Broker compares $\Pi^{\text{place}}$ vs $\Pi^{\text{staff}}$ (§9d)
> &emsp;&emsp;If $\Pi^{\text{staff}} > \Pi^{\text{place}}$ AND firm accepts bill rate (§9e):
> &emsp;&emsp;&emsp;Mark match as staffing; $\text{wage} = r_{i^*}$
> &emsp;&emsp;Else:
> &emsp;&emsp;&emsp;Mark match as placement; $\text{wage} = r_{i^*} + \beta_W \cdot \max(\hat{q}_j(w_{i^*}) - r_{i^*},\; 0)$
> 3.1.2. &emsp;for each proposed internal match $(j, i^*)$:
> &emsp;&emsp;$\text{wage} = r_{i^*} + \beta_W \cdot \max(\hat{q}_j(w_{i^*}) - r_{i^*},\; 0)$
>
> &emsp;**3.2. Conflict resolution:** unchanged (see base 3.2.1).
>
> &emsp;**3.3. Finalization** (for each accepted match $(j, i^*)$):
> 3.3.1. &emsp;Realize output: $q_{i^*j} = f(w_{i^*}, x_j) + \varepsilon_{i^*j}$. For staffing assignments, this output is drawn once at formation and repeated each period of the assignment (no fresh noise draw).
> 3.3.2. &emsp;Compute fees:
> &emsp;&emsp;If placement: firm pays $\phi = \alpha \cdot \text{wage}_{i^*j}$ (§7a)
> &emsp;&emsp;If staffing: firm pays $\psi = r_{i^*} + \mu_b \cdot \hat{q}_b(w_{i^*}, x_j)$ per period for $L$ periods (§9c)
> 3.3.3. &emsp;Record: channel ($c$), match type (placement/staffing/internal), $q_{i^*j}$, $\hat{q}$ (prediction used), wage, fee or bill rate, whether $i^* \in R_j^t$.
>
> **4. STATE UPDATES** (staffing branch added)
> 4.1. &emsp;for each accepted match $(j, i^*)$:
> &emsp;&emsp;If direct hire via internal search:
> &emsp;&emsp;&emsp;Add $i^*$ to $E_j^t \to E_j^{t+1}$; add $(w_{i^*}, q_{i^*j})$ to $\mathcal{H}_j$; worker $i^*$ status $\leftarrow$ employed at $j$
> &emsp;&emsp;If direct hire via brokered placement:
> &emsp;&emsp;&emsp;Add $i^*$ to $E_j^t \to E_j^{t+1}$; add $(w_{i^*}, q_{i^*j})$ to $\mathcal{H}_j$; add $(w_{i^*}, x_j, q_{i^*j})$ to $\mathcal{H}_b$; worker $i^*$ status $\leftarrow$ employed at $j$ (removed from pool during maintenance at step 4.5)
> &emsp;&emsp;&emsp;$\Pi_b \leftarrow \Pi_b + \phi$ &ensp;(accumulate placement fee revenue)
> &emsp;&emsp;If staffing:
> &emsp;&emsp;&emsp;Add $i^*$ to broker's active assignments; add $(w_{i^*}, x_j, q_{i^*j})$ to $\mathcal{H}_b$; worker $i^*$ status $\leftarrow$ staffed by broker at firm $j$ (removed from pool during maintenance at step 4.5)
> &emsp;&emsp;&emsp;Firm $j$'s history $\mathcal{H}_j$ does **not** update (§9f). Firm $j$'s employee set $E_j$ does **not** update (§9f).
>
> 4.2. &emsp;Update satisfaction indices (output minus cost above $r_i$, §6a):
> &emsp;&emsp;for each firm $j$ that received a new match via channel $c$:
> &emsp;&emsp;&emsp;If internal: $\tilde{q} = q_{i^*j} - \beta_W \cdot \max(\hat{q}_j(w_{i^*}) - r_{i^*},\; 0)$
> &emsp;&emsp;&emsp;If brokered placement: $\tilde{q} = q_{i^*j} - \beta_W \cdot \max(\hat{q}_j(w_{i^*}) - r_{i^*},\; 0) - \alpha \cdot \text{wage}_{i^*j} / L$
> &emsp;&emsp;&emsp;If staffing: $\tilde{q} = q_{i^*j} - \mu_b \cdot \hat{q}_b(w_{i^*}, x_j)$ (§9c)
> &emsp;&emsp;&emsp;$s_{j,c}^{t+1} = (1 - \omega)\, s_{j,c}^t + \omega \cdot \tilde{q}$
> &emsp;&emsp;No-proposal penalty: unchanged (§6a). Satisfaction indices are not floored.
> 4.3. &emsp;Update broker reputation (sticky, §6b):
> &emsp;&emsp;$\text{active\_clients}^t \leftarrow J^t \cup \{j : \text{firm } j \text{ has an active staffing assignment}\}$
> &emsp;&emsp;if $|\text{active\_clients}^t| > 0$: $\text{rep}^t \leftarrow \text{mean of } s_{j,\text{broker}}^t \text{ over } j \in \text{active\_clients}^t$; store as last\_reputation
> &emsp;&emsp;else if broker has had clients before: $\text{rep}^t \leftarrow$ last\_reputation
> &emsp;&emsp;else: $\text{rep}^t \leftarrow \bar{q}\_\text{pub}$
>
> 4.4. &emsp;Check staffing assignment expirations:
> &emsp;&emsp;for each active staffing assignment:
> &emsp;&emsp;&emsp;If assignment has lasted $L$ periods: worker returns to available pool (eligible for pool recruitment during next period's maintenance); assignment ends
> &emsp;&emsp;&emsp;If firm does not already have an open vacancy: firm's vacancy reopens (enters $V^{t+1}$). At most one vacancy per firm; if the firm already has an open vacancy, the expiring position closes.
> 4.5. &emsp;Broker pool recruitment: same rule as base model (see base 4.4).
>
> **5. ENTRY AND EXIT** (staffing cleanup added)
> 5.1. &emsp;Firm exit unchanged except: any active staffing assignments at firm $j$ are terminated immediately. Staffed workers return to available pool. The broker forgoes remaining periods of profit on these assignments. Terminated assignments do not reopen vacancies (the firm is exiting).

</small>

#### 9h. Channel comparison summary

| | Direct hire (internal) | Brokered placement | Staffing (M1) |
|---|---|---|---|
| **Who predicts quality** | Firm: $\hat{q}_j$ | Broker selects using $\hat{q}_b$; firm evaluates using $\hat{q}_j$ | Broker: $\hat{q}_b$ |
| **Surplus threshold** | $\hat{q}_j > r_i$ | $\hat{q}_b > r_i$ (broker, at proposal) | $\mu_b \hat{q}_b > c_{\text{emp}}$ (positive margin) |
| **Who sets wage/price** | Firm: $r_i + \beta_W \max(\hat{q}_j - r_i, 0)$ | Firm (same formula) | Broker sets bill rate: $r_i + \mu_b \hat{q}_b$; worker receives $r_i$ |
| **Firm's per-period cost** | $r_i + \beta_W \hat{S}_j$ | $r_i + \beta_W \hat{S}_j + \alpha \cdot \text{wage}/L$ | $r_i + \mu_b \hat{q}_b$ |
| **Cost above $r_i$** | $\beta_W \max(\hat{q}_j - r_i, 0)$ | $\beta_W \max(\hat{q}_j - r_i, 0) + \alpha \cdot \text{wage}/L$ | $\mu_b \hat{q}_b$ |
| **Satisfaction input** (§6a) | $q_{ij} - \beta_W \max(\hat{q}_j - r_i, 0)$ | $q_{ij} - \beta_W \max(\hat{q}_j - r_i, 0) - \alpha \cdot \text{wage}/L$ | $q_{ij} - \mu_b \hat{q}_b$ |
| **No-proposal penalty** (§6a) | None (vacancy persists, no update) | $s_{j,b} \leftarrow (1-\omega) s_{j,b} + \omega \cdot s_{j,\text{int}}$ | Same |
| **Worker joins $E_j$?** | Yes | Yes | No (lock-in, §9f) |
| **Firm learns from match?** | Yes (adds to $\mathcal{H}_j$) | Yes | No (lock-in, §9f) |
| **Referral network grows?** | Yes | Yes | No (lock-in, §9f) |
| **Broker learns?** | No | Yes (adds to $\mathcal{H}_b$) | Yes |
| **Recognition gap** (§7a) | n/a | Yes: broker estimates fee using $\hat{q}_b$, actual fee uses $\hat{q}_j$ | No: broker sets price from $\hat{q}_b$ directly |
| **Broker revenue** | None | One-time fee $\alpha \cdot \text{wage}$ | $L$ periods of $(\mu_b \hat{q}_b - c_{\text{emp}})$ |
| **Assignment duration** | Permanent (until firm exit) | Permanent (until firm exit) | $L$ periods (default 4) |

#### Variant-specific performance measures

**Flow capture rate (Model 1, primary).** $F^t$: the fraction of new brokered matches formed at time $t$ that are staffing assignments rather than placements. This flow measure directly captures the broker's period-by-period decision to staff rather than place, making the abrupt tipping point of Proposition 3a visible without the smoothing inherent in stock measures.

**Stock capture ratio (Model 1, secondary).** $C^t$: the fraction of active worker-firm matches at time $t$ that are staffing assignments rather than direct hires. This cumulative measure shows the labor market transformation resulting from the broker's staffing decisions but responds sluggishly because it mixes stocks of different durations (permanent direct hires vs. fixed-length staffing assignments). Reported in SI (Fig. S2A). Also track: average firm referral pool size $\bar{|R_j^t|}$.

### 10. Data Capture (M2)

Deferred to future work.

## Figures

#### Phase diagram

The phase diagram maps the conditions under which brokerage transitions from intermediation to capture (Proposition 2.2). Its two axes are the primary drivers of matching difficulty: $d$ (type dimensionality, §1d) (vertical) and $\rho$ (general quality share, §1d) (horizontal).

Low complexity (low $d$ and low $\rho$) corresponds to persistent brokerage without capture: firms learn quickly on their own (few type dimensions) or cross-market data has little transferable value (low $\rho$), and the broker remains a commodity intermediary earning thin margins. High complexity (high $d$, high $\rho$) defines the capture region, where many type dimensions or a large universal quality share sustain the broker's informational advantage long enough for positive feedback to produce capture.

The boundary between the regions may shift with $\eta$ (entry/exit rate), which controls how quickly firm turnover refreshes the broker's structural advantage.

#### Main figures

**Fig. 1.** The informational mechanism.
- *Purpose:* Establishes the core mechanism: the broker learns faster than individual firms, the gap widens with market opacity, this drives increasing outsourcing, and the resulting matches differ in quality by channel (Propositions 1.1, 1.2, 1.3).
- *Content:* All panels are at default parameters ($d = 4$, $\rho = 0.50$). Each panel includes a **base model** series (dashed grey) as a no-capture reference line, plus Model 1 and Model 2 series. 
  - Panel A: time on the horizontal axis, prediction quality (holdout $R^2$, rolling window) on the vertical axis. One line for the broker, one for the average firm. The broker-firm gap reflects the informational advantage and its dynamics over time. An inset or small-multiple shows the effect of varying $d$ on the base model learning gap (Proposition 1.3). 
  - Panel B: time on the horizontal axis, fraction of vacancies outsourced to the broker on the vertical axis. The base model establishes the reference trajectory for outsourcing dynamics. Model 1 and Model 2 diverge from this reference. 
  - Panel C: time on the horizontal axis, average realized match output $\bar{q}_c^t$ on the vertical axis, one line per channel (direct hire, brokered placement, staffing where applicable). Under the base model only direct-hire and placement channels appear. Model 1 and Model 2 overlaid or in separate sub-panels. 
  - Panels A–C trace the full chain: the learning gap (A) drives outsourcing (B), which produces match quality differences by channel (C). The base-model reference makes each capture mechanism's deviation from the self-liquidating baseline visually immediate.

**Fig. 2.** Decoupling of structural position from informational advantage.
- *Purpose:* The paper's central empirical implication. Shows that structural-hole measures decline while the broker's informational advantage grows, and that the two capture modes fork: staffing suspends the self-liquidating dynamic, data capture does not (Propositions 2.1, 3).
- *Content:* Time on the horizontal axis, dual vertical axes for broker betweenness centrality (or Burt's constraint) and broker prediction quality. Model 1 and Model 2 in separate panels or overlaid. Under Model 1, betweenness plateaus or recovers once staffing dominates. Under Model 2, betweenness declines monotonically while prediction quality remains high.

**Fig. 3.** Access vs. assessment decomposition over time.
- *Purpose:* Traces the micro-level shift in the source of broker value from network access (finding workers firms cannot reach) to information assessment (predicting match quality better than firms can), showing that informational advantage becomes the dominant channel as the network densifies (Propositions 1.3a, 1.3b).
- *Content:* Time on the horizontal axis, fraction of brokered placements on the vertical axis, stacked or side-by-side for access value (worker was not in the firm's referral pool) and assessment value (worker was reachable but the broker predicted better). Early periods are access-dominated; later periods shift toward assessment as referral networks expand.

**Fig. 4.** Capture dynamics and the lock-in mechanism.
- *Purpose:* Shows that capture happens, the two modes differ in trajectory, and the lock-in mechanism explains why worker capture is abrupt and self-reinforcing (Proposition 3).
- *Content:* Panel A is a dual panel. Panel A-left: time on the horizontal axis, flow capture rate $F^t$ on the vertical axis (Model 1). Shows the abrupt tipping point as the broker shifts from placement to staffing. Panel A-right: time on the horizontal axis, subscriber share $\Sigma^t$ on the vertical axis (Model 2). Shows the gradual ramp as firms adopt the data product. The two panels use separate y-axes and labels, avoiding the apples-to-oranges comparison of overlaying a labor market quantity ratio with a revenue mix ratio. Panel B: time on the horizontal axis, average firm prediction quality on the vertical axis, stratified by staffing exposure (high vs. low). Staffing clients stagnate; non-clients continue improving. Panel A shows the outcome; Panel B shows the mechanism.

**Fig. 5.** Phase diagram.
- *Purpose:* Maps the conditions under which capture occurs, identifying three qualitative regions (no capture, worker capture, data capture) as a function of matching complexity (Proposition 2.2 and its corollary).
- *Content:* A single panel: $\rho$ (general quality share) on the horizontal axis, $d$ (type dimensionality) on the vertical axis. The panel is a heatmap or contour plot with three labeled regions.

#### SI figures

**Fig. S1.** Structural lock-in: firm referral pool size over time.
- *Purpose:* Complements Fig. 4B (informational lock-in) by showing the structural side: staffing freezes the firm's referral network, not just its prediction quality. Together with Fig. 4B, provides the full double lock-in evidence (Proposition 3a, corollary).
- *Content:* Time on the horizontal axis, average referral pool size $|R_j^t|$ on the vertical axis, stratified by staffing exposure (high vs. low). Staffing clients' pools plateau; non-clients' pools continue growing. Model 1 only.

**Fig. S2.** Secondary capture metrics.
- *Purpose:* Complements Fig. 4A by reporting the secondary (stock and cumulative) capture measures that track the labor market transformation (Model 1) and revenue diversification (Model 2) at a coarser grain than the primary flow/share metrics.
- *Content:* Panel A: time on the horizontal axis, stock capture ratio $C^t$ on the vertical axis (Model 1). Shows the fraction of active worker-firm matches that are staffing assignments — a smoothed, lagged reflection of the flow capture rate in Fig. 4A-left. Panel B: time on the horizontal axis, cumulative data capture ratio $\bar{D}^t$ on the vertical axis (Model 2). Shows cumulative subscription revenue as a share of cumulative total broker revenue, smoothing the period-to-period volatility of the per-period revenue ratio.

**Fig. S3.** OAT parameter sweeps.
- *Purpose:* Demonstrates that the main results (learning gap, capture trajectories, phase boundaries) are robust to parameter choices and not artifacts of specific defaults (Proposition 2.2).
- *Content:* Grid of panels. Each panel varies one parameter ($\eta$, $\mu_b$, $c_{\text{emp}}$, $L$, $\mu_d$) while holding others at defaults, showing either learning curves (broker vs. firm prediction quality) or capture ratios ($F^t$, $\Sigma^t$) over time. The effect of $(d, s)$ is absorbed into the $d$ axis of the phase diagram (Fig. 5). Key patterns to confirm: staffing economics respond to $\mu_b$, $c_{\text{emp}}$, and $L$ as expected; data capture dynamics respond to $\mu_d$; firm turnover ($\eta$) shifts the capture boundary.

**Fig. S4.** Network visualization snapshots.
- *Purpose:* Provides intuition for how the combined graph evolves and how structural holes close over time, making the abstract network measures in Fig. 2 visually concrete.
- *Content:* Three panels showing the combined graph ($G_S \cup G_E^t \cup$ broker pools) at early, middle, and late periods. Nodes colored by type (worker, firm, broker). Broker nodes positioned centrally. Early: sparse, broker bridges disconnected clusters. Middle: denser, some direct firm-worker ties bypass broker. Late: dense, most structural holes closed. Layout algorithm held constant across panels for comparability.

**Fig. S5.** Prediction quality decomposition.
- *Purpose:* Decomposes the learning gap (Fig. 1A) into three components that map to distinct model mechanisms: overall accuracy ($R^2$), systematic bias, and ranking accuracy. Shows when the broker's ranking advantage emerges relative to its calibration, and whether the recognition gap (§7a) closes before or after firms catch up on $R^2$.
- *Content:* Three sub-panels sharing a time axis, all at default parameters. Panel A: $R^2$ over time (broker and average firm). Panel B: bias ($\bar{e} = \frac{1}{n}\sum(\hat{q} - q)$) over time (broker and average firm). Positive bias indicates overestimation; the broker's bias trajectory makes the recognition gap directly visible. Panel C: Spearman rank correlation over time (broker and average firm). Key patterns to look for: rank correlation converges faster than $R^2$ (agents learn to rank before they learn to price); broker bias starts positive and declines as firms improve (recognition gap closing); under Model 1, staffing suspends firm improvement across all three measures.

**Fig. S6.** Attributional vs. relational channel (Proposition 1.2).
- *Purpose:* Identifies which channel drives the broker's informational advantage by sweeping rho while holding other parameters fixed. Distinguishes the attributional channel (better estimation of general counterparty quality) from the relational channel (better understanding of pairing complementarities).
  - Examines how the broker-firm gap in prediction quality varies across rho. If the attributional channel dominated, the gap would be largest at high rho (where general quality matters most). If the relational channel dominates, the gap is largest at low rho (where complementarities matter most) or at intermediate rho (where both components contribute but the interaction is the harder estimation problem).
- *Content:* rho on the horizontal axis (0.0 to 1.0). Three panels. Panel A: broker-firm gap in holdout R-squared at steady state, showing how the informational advantage varies with the relative importance of general quality vs interaction. Panel B: broker holdout R-squared and firm holdout R-squared separately, showing that both improve with rho (more learnable signal) but the gap changes non-monotonically. Panel C: outsourcing rate at steady state vs rho. If the relational channel dominates, the gap is largest at low-to-moderate rho (where the interaction is the binding estimation problem) and narrows at high rho (where general quality dominates and firms can learn it). If the attributional channel dominated, the gap would grow monotonically with rho.

**Fig. S7.** Prediction confidence decomposition.
- *Purpose:* Makes the informational advantage visible at the micro level by showing how each agent's prediction uncertainty evolves. Complements Fig. S5 (which measures accuracy ex post) with an ex ante view of how much each agent "knows" when making predictions. Under Model 1, locked-in firms' epistemic uncertainty should stop declining, providing a micro-level signature of the lock-in mechanism.
- *Content:* Three sub-panels sharing a time axis: R-squared, bias, and rank correlation over time (broker and average firm). Under Model 1, a second set of firm lines stratified by staffing exposure shows locked-in firms' prediction quality plateauing while non-clients continue to improve.

## Part III. Calibration and Verification

### 12. Parameters, Initial Conditions, and Reproducibility

#### 12a. Reproducibility

All randomness flows from a single integer seed. The seed determines: type draws for workers and firms, the realization of $G_S$, initial employment assignments, broker seed pools, match noise draws, and all agent decision noise. Simulations are fully reproducible given (parameter dictionary, seed).

The parameter dictionary contains all swept quantities. The seed is part of the replication identifier, not the parameter dictionary.

#### 12b. Parameter table

Parameters are organized into five categories reflecting their role in the analysis.

**Structural constants.** Define the model's mechanisms. Values are set by design rationale and not varied.

| Symbol | Meaning | Value | Notes | Model |
|--------|---------|-------|-------|-------|
| $n$ | Candidates per vacancy | $\lceil 0.01 \cdot N_W \rceil$ | | Base |
| $\alpha$ | Placement fee rate | 0.20 | Fixed throughout the simulation. Isolates the informational channel (§7b). | Base |
| $\beta_W$ | Worker surplus share | 0.50 | | Base |
| $P$ | Broker pool target size | $\lceil 0.20 \cdot N_W \rceil$ | 200 workers at $N_W = 1000$. Pool maintained at target by replacing placed workers with new recruits each period. | Base |
| $k_S$ | Social network mean degree | 6 | Fixed network topology parameter (§4) | Base |
| $p_{\text{rewire}}$ | Social network rewiring | 0.1 | Fixed network topology parameter (§4) | Base |
| $\omega$ | Satisfaction recency weight (§6a) | 0.3 | Fixed; standard EWMA weight | Base |
| $p_{\text{vac}}$ | Per-period vacancy probability (§5) | 0.50 | ~25 vacancies/period across 50 firms | Base |
| $\sigma_w$ | Worker type dispersion | 0.5 | Expected distance from worker to reference firm, dimension-invariant (§0, §12c) | Base |
| $L$ | Fee amortization period | 4 | Expected useful duration of a hire for per-period cost comparisons (§6a). M1 reuses as staffing assignment length (§9). | Base |
| Firm geometry | Firm type distribution | Complex | Complex (sinusoidal curve, all $d$ dims), simple (great circle, 2D), or unstructured (anisotropic on sphere). See §0. | Base |

**Calibration parameters.** Set during model development to ensure the DGP is well-behaved across the parameter space. Constant in production runs.

| Symbol | Meaning | Default | Notes | Model |
|--------|---------|---------|-------|-------|
| $r_{\text{base}}$ | Reservation wage floor | $0.70 \cdot E[f]$ | Calibrated at init from Monte Carlo sample of random (not clustered) worker-firm pairs. Network premium (0.20) and noise scale (0.05) hardcoded in §3b. | Base |
| $\lambda$ | Ridge regression regularization | 1.0 | Regularization for firm and broker regression models (§2a, §2b) | Base |
| $\sigma_\varepsilon$ | Match output noise SD | 0.25 | Signal bounded in $[-1,1]$; SNR $\approx$ 4:1 | Base |
| $\mathbf{A}$ | Interaction matrix | $d \times d$, iid $N(0,1)$ | Drawn once at initialization. Introduces cross-dimensional interactions in $\text{sim}(\mathbf{w}, \mathbf{A}\mathbf{x})$ (§1c). | Base |

In the table, $\bar{f}$ denotes the mean absolute match output $E[|f(w,x)|]$, computed from a Monte Carlo sample at initialization. Parameters expressed as multiples of $r_{\text{base}}$ scale automatically with the output distribution, ensuring that the economic logic (surplus margins, fee incentives, staffing profitability) is stable across different $d$ and $A$ specifications.

**Phase diagram axes.** The primary parameter of interest is $\rho$ (quality-interaction mixing weight). Lower $\rho$ increases the broker's informational advantage by making cross-firm interaction data essential. $d$ is a secondary axis: higher $d$ increases the number of regression features but does not fundamentally change the difficulty of the cosine-normalized matching problem.

| Symbol | Meaning | Default | Sweep | Model |
|--------|---------|---------|-------|-------|
| $d$ | Type dimensionality | 8 | {4, 8, 12} | Base |
| $\rho$ | Quality-interaction mixing weight (§1d) | 0.50 | {0, 0.10, 0.50, 0.90, 1.0} | Base |

**OAT sensitivity parameters.** Varied one at a time while holding all others at defaults. Confirms that qualitative dynamics are robust (Fig. S3).

| Symbol | Meaning | Default | Sweep | Model |
|--------|---------|---------|-------|-------|
| $\eta$ | Firm entry/exit rate | 0.05 | {0.02, 0.05, 0.10, 0.20} | Base |
| $\mu_b$ | Staffing value-capture rate | 0.25 | {0.15, 0.25, 0.35, 0.50} | M1 |
| $c_{\text{emp}}$ | Per-period employment cost | $0.15 \cdot r_{\text{base}}$ | {0.10, 0.15, 0.20, 0.25} $\cdot r_{\text{base}}$ | M1 |
| $L$ | Fee amortization period / staffing assignment duration | 4 | {1, 2, 4, 8} | Base |

**Implementation parameters.** Control simulation scale and mechanics. Scale checks confirm results are not artifacts of population size or run length.

| Symbol | Meaning | Default | Scale check | Model |
|--------|---------|---------|-------------|-------|
| $N_W$ | Worker population | 1000 | {500, 1000, 2000} | Base |
| $N_F$ | Firm population | 50 | {25, 50, 100} | Base |
| $T$ | Simulation length (periods) | 200 | {100, 200, 400} | Base |
| $T_{\text{burn}}$ | Burn-in periods (discarded) | 20 | — | Base |
| $M$ | Network measure interval | 10 | — | Base |


**Professional staffing specification.** The baseline defaults ($\mu_b = 0.25$) reflect a general labor market. For an alternative specification representing professional or specialized staffing markets (IT, engineering, executive search), use $\mu_b = 0.35$, reflecting higher value-capture rates for specialized screening. This value is included in the OAT sweep above.

**Simulation length.** The default $T = 200$ periods (50 years at quarterly periodicity) is long enough for capture dynamics to emerge and stabilize in the baseline specification. The first $T_{\text{burn}} = 30$ periods are discarded from analysis; during the burn-in, agents are still accumulating initial experience and regression models are noisy. An OAT check at $T = 400$ verifies that dynamics have reached a qualitative steady state by $T = 200$.

#### 12c. Initial conditions

The initialization procedure generates the matching environment, agents, and network in the following order. Definitions of types, the matching function, and learning are in §§0-2; this section specifies only the procedural steps and calibration choices.

1. **Firm geometry and types** (§0). Generate firm types on the unit sphere according to the chosen geometry. Store geometry parameters for entrant firms.
2. **Matching function** (§1). Draw ideal worker $\mathbf{c}$ and interaction matrix $\mathbf{A}$.
3. **Calibration.** Compute $E[f]$ from 10,000 random worker-firm pairs (workers drawn near random firm types, evaluated against independently drawn firms). Set $\bar{q}_{\text{pub}} = E[f]$ and $r_{\text{base}} = 0.70 \cdot E[f]$.
4. **Worker types** (§0). Each worker drawn as perturbation of a random firm type with noise $\sigma_w / \sqrt{d}$ per dimension. Workers sorted by first principal component for network construction.
5. **Social network $G_S$** (§4). Watts-Strogatz with $N_W$ nodes, degree $k_S$, rewiring $p_{\text{rewire}}$. Node ordering from step 4.
6. **Reservation wages** (§3b). Set using calibrated $r_{\text{base}}$ and degree in $G_S$. Fixed thereafter.
7. **Initial employment.** Each firm hires 6-10 workers by type proximity (softmax weighting). Match outputs are realized and recorded to firm histories, seeding the prediction model.
8. **Broker.** Pool of $P = \lceil 0.20 \cdot N_W \rceil$ available workers. History seeded with 20 observations from random existing worker-firm matches.
9. **State variables.** Satisfaction indices and broker reputation initialized at $\bar{q}_{\text{pub}}$. Referral pools computed from initial employment.

**Employment cost $c_{\text{emp}}$.** Set at $0.15 \cdot r_{\text{base}}$ for Model 1 (statutory employer costs plus administrative overhead). For Model 2, $c_{\text{emp}} = 0$.

### 13. Verification and Robustness

#### 13a. Verifying the no-capture region

The model must produce parameter combinations where capture does not occur, where the broker remains a commodity intermediary earning thin margins. If capture occurs for every parameter setting, the model is not a theory of transient brokerage; it is a theory of inevitable capture.

Different parameters may affect the firm-broker asymmetry differently, and the no-capture boundary may sit at different thresholds along different axes.

The key verification concern is that the positive feedback loop (more outsourcing → more broker data → better predictions → more outsourcing) produces capture in some regimes and not in others. The goal is a phase diagram where the no-capture region is large enough to be empirically plausible.

#### 13b. Analytic benchmark for the broker's advantage

Closed-form scaling predictions can provide an analytic benchmark against which the simulation's ridge regression learning dynamics can be compared.

All agents use ridge regression. For a linear target with Gaussian noise, ridge regression MSE scales as $\text{MSE} \sim p / n + \lambda \|\beta^*\|^2$, where $p$ is the number of features, the first term is estimation error (decreasing in $n$), and the second is regularization bias (decreasing in $\lambda$). The key scaling is that firms need $n \gg 2d$ observations to estimate $2d+1$ parameters accurately, while the broker needs $n \gg d^2 + 3d$ but has far more data.

**Firm.** Firm $j$ fits $q \approx \beta^\top [w; w^2] + c$ from $n_j$ own-hire observations ($2d+1$ parameters). The true function $f(w, x_j) = Q + \rho \cdot \text{sim}(w, c) + (1-\rho) \cdot \text{sim}(w, Ax_j)$ has components that are approximately linear in $w$ for nearby workers but involve cosine normalization that the linear model cannot capture exactly. The firm's MSE decomposes as:

$$\text{MSE}_{\text{firm}} \approx \frac{2d \cdot \sigma_{\text{eff}}^2}{n_j} + \text{misspecification}$$

where $\sigma_{\text{eff}}^2 = \sigma_\varepsilon^2 + \text{Var(nonlinear residual)}$ is the effective noise (match noise plus the variance of the components the linear model cannot capture). The first term is estimation error (decreasing in $n_j$); the second is model misspecification (irreducible for a linear model).

**Broker.** The broker fits $q \approx \beta_w^\top w + \beta_x^\top x + \beta_{wx}^\top \text{vec}(w \otimes x) + \beta_{w^2}^\top w^2 + c$ from $n_b$ pooled observations ($d^2 + 3d + 1$ parameters). Its MSE is:

$$\text{MSE}_{\text{broker}} \approx \frac{(d^2 + 3d) \cdot \sigma_{\text{eff}}^2}{n_b} + \text{misspecification}$$

Both agents face misspecification from the cosine normalization. The difference is estimation error: the broker has far more parameters ($d^2 + 3d$ vs $2d$) but far more data ($n_b \gg n_j$). The broker's outer-product features $w \otimes x$ can represent the full cross-dimensional interaction structure induced by $\mathbf{A}$, reducing its misspecification floor relative to the firm's.

**Advantage condition.** The broker outperforms the firm when its estimation error is smaller:

$$\frac{d^2 + 3d}{n_b} < \frac{2d}{n_j} \quad \Longrightarrow \quad n_b > \frac{d + 3}{2} \cdot n_j$$

Since the broker pools observations across all client firms, this condition is easily satisfied after a few periods. The advantage grows with $d$ (the broker's parameter count scales as $d^2$ while the firm's scales as $d$, but the broker's data volume scales with the number of client firms). Higher $\rho$ makes the quality component dominate, which firms can learn from their own data, shrinking the broker's advantage.

Higher $d$ increases the number of parameters for both agents but hurts differently: firms go from $2d$ to $2d$ features (linear in $d$), while the broker goes from $d^2 + 3d$ features (quadratic in $d$). At $d = 4$, a firm with $n_j = 5$ observations estimates 9 parameters from 5 data points (underdetermined). At $d = 8$, it needs 17 parameters from the same 5 observations (severely underdetermined). The broker at $d = 8$ needs $n_b \gg 88$ observations, which it accumulates quickly from cross-firm placements.

### References (cited in model specification)

Abowd, J. M., Kramarz, F., & Margolis, D. N. (1999). High wage workers and high wage firms. *Econometrica*, *67*(2), 251–333.

American Staffing Association. (2019). *Staffing industry statistics*. americanstaffing.net.

Autor, D. H. (2001). Why do temporary help firms provide free general skills training? *Quarterly Journal of Economics*, *116*(4), 1409–1448.

Autor, D. H. (2009). Studies of labor market intermediation: Introduction. In D. H. Autor (Ed.), *Studies of labor market intermediation* (pp. 1–23). University of Chicago Press.

Bonet, R., Cappelli, P., & Hamori, M. (2013). Labor market intermediaries and the new paradigm for human resources. *Academy of Management Annals*, *7*(1), 341–392.

Brenner, T. (2006). Agent learning representation: Advice on modelling economic learning. In K. Judd & L. Tesfatsion (Eds.), *Handbook of computational economics* (Vol. 2, pp. 895–947). North-Holland.

Bureau of Labor Statistics. (2024a). *Employer costs for employee compensation* (ECEC). U.S. Department of Labor.

Bureau of Labor Statistics. (2024b). *Establishment age and survival data*. Business Employment Dynamics, U.S. Department of Labor. https://www.bls.gov/bdm/bdmage.htm

Bureau of Labor Statistics. (2024c). *Job Openings and Labor Turnover Survey* (JOLTS). U.S. Department of Labor. https://www.bls.gov/jlt/

Burt, R. S. (1992). *Structural holes: The social structure of competition*. Harvard University Press.

Burt, R. S. (2005). *Brokerage and closure: An introduction to social capital*. Oxford University Press.

Calvo-Armengol, A., & Jackson, M. O. (2004). The effects of social networks on employment and inequality. *American Economic Review*, *94*(3), 426–454.

Calvo-Armengol, A., & Jackson, M. O. (2007). Networks in labor markets: Wage and employment dynamics and inequality. *Journal of Economic Theory*, *132*(1), 27–46.

Card, D., Heining, J., & Kline, P. (2013). Workplace heterogeneity and the rise of West German wage inequality. *Quarterly Journal of Economics*, *128*(3), 967–1015.

Finlay, W., & Coverdill, J. E. (2002). *Headhunters: Matchmaking in the labor market*. Cornell University Press.

Freeman, L. C. (1977). A set of measures of centrality based on betweenness. *Sociometry*, *40*(1), 35–41.

Hagedorn, M., & Manovskii, I. (2008). The cyclical behavior of equilibrium unemployment and vacancies revisited. *American Economic Review*, *98*(4), 1692–1706.

Hamersma, S., Heinrich, C. J., & Mueser, P. R. (2014). Temporary help work: Compensating differentials and multiple job holding. *Industrial Relations*, *53*(1), 72–100.

Ioannides, Y. M., & Loury, L. D. (2004). Job information networks, neighborhood effects, and inequality. *Journal of Economic Literature*, *42*(4), 1056–1093.

Knaup, A. E. (2005). Survival and longevity in the Business Employment Dynamics data. *Monthly Labor Review*, *128*(5), 50–56.

Montgomery, J. D. (1991). Social networks and labor-market outcomes: Toward an economic analysis. *American Economic Review*, *81*(5), 1408–1418.

Mortensen, D. T. (1986). Job search and labor market analysis. In O. Ashenfelter & R. Layard (Eds.), *Handbook of labor economics* (Vol. 2, pp. 849–919). Elsevier.

Mortensen, D. T., & Pissarides, C. A. (1994). Job creation and job destruction in the theory of unemployment. *Review of Economic Studies*, *61*(3), 397–415.

Neugart, M., & Richiardi, M. (2018). Agent-based models of the labor market. In S.-H. Chen, M. Kaboudan, & Y.-R. Du (Eds.), *The Oxford handbook of computational economics and finance*. Oxford University Press.

Pissarides, C. A. (2000). *Equilibrium unemployment theory* (2nd ed.). MIT Press.

Pissarides, C. A. (2009). The unemployment volatility puzzle: Is wage stickiness the answer? *Econometrica*, *77*(5), 1339–1369.

Rogerson, R., Shimer, R., & Wright, R. (2005). Search-theoretic models of the labor market: A survey. *Journal of Economic Literature*, *43*(4), 959–988.

Segal, L. M., & Sullivan, D. G. (1997). The growth of temporary services work. *Journal of Economic Perspectives*, *11*(2), 117–136.

Shimer, R. (2005). The cyclical behavior of equilibrium unemployment and vacancies. *American Economic Review*, *95*(1), 25–49.

Stone, C. J. (1982). Optimal global rates of convergence for nonparametric regression. *Annals of Statistics*, *10*(4), 1040–1053.

Tassier, T., & Menczer, F. (2001). Emerging small-world referral networks in evolutionary labor markets. *IEEE Transactions on Evolutionary Computation*, *5*(5), 482–492.

Watts, D. J., & Strogatz, S. H. (1998). Collective dynamics of 'small-world' networks. *Nature*, *393*(6684), 440–442.
