use serde::Serialize;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

const MAX_LOGS: usize = 50;

#[derive(Debug, Clone, Serialize)]
pub struct TradeLog {
    pub time: String,
    pub tag: String,
    pub side: String,
    pub outcome: String,
    pub size: String,
    pub price: String,
    pub slug: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub target_address: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub copy_status: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
pub struct PositionSummary {
    pub slug: String,
    pub outcome: String,
    pub size: f64,
    pub cur_price: f64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub delta: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub delta_at: Option<String>,
    /// "open" or "closed"
    #[serde(default = "default_open")]
    pub status: String,
    /// When the position was closed (ISO timestamp)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub closed_at: Option<String>,
    /// Last known price when position closed (for P&L display)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub close_price: Option<f64>,
}

fn default_open() -> String {
    "open".to_string()
}

#[derive(Debug, Clone, Serialize)]
pub struct Status {
    pub mode: String,
    pub targets: u32,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub wallet: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub eoa_wallet: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub target_addresses: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize)]
pub struct UiConfig {
    pub delta_highlight_sec: u64,
    pub delta_animation_sec: u64,
}

#[derive(Debug, Clone, Serialize)]
pub struct WalletBalances {
    pub usdc: Option<f64>,
    pub pol: Option<f64>,
}

#[derive(Debug, Clone, Serialize)]
pub struct BotState {
    pub logs: Vec<TradeLog>,
    pub status: Status,
    pub positions: HashMap<String, Vec<PositionSummary>>,
    pub ui: UiConfig,
    pub balances: WalletBalances,
}

impl Default for BotState {
    fn default() -> Self {
        Self {
            logs: Vec::new(),
            status: Status {
                mode: String::new(),
                targets: 0,
                wallet: None,
                eoa_wallet: None,
                target_addresses: None,
            },
            positions: HashMap::new(),
            ui: UiConfig {
                delta_highlight_sec: 10,
                delta_animation_sec: 2,
            },
            balances: WalletBalances {
                usdc: None,
                pol: None,
            },
        }
    }
}

pub type SharedState = Arc<RwLock<BotState>>;

pub fn new_shared_state() -> SharedState {
    Arc::new(RwLock::new(BotState::default()))
}

pub async fn get_state(state: SharedState) -> BotState {
    state.read().await.clone()
}

pub async fn set_status(
    state: SharedState,
    mode: String,
    targets: u32,
    wallet: Option<String>,
    eoa_wallet: Option<String>,
    target_addresses: Option<Vec<String>>,
) {
    let mut s = state.write().await;
    s.status = Status {
        mode,
        targets,
        wallet,
        eoa_wallet,
        target_addresses,
    };
}

pub async fn set_ui_config(state: SharedState, delta_highlight_sec: u64, delta_animation_sec: u64) {
    let mut s = state.write().await;
    s.ui = UiConfig {
        delta_highlight_sec,
        delta_animation_sec,
    };
}

pub async fn push_trade(
    state: SharedState,
    tag: &str,
    side: &str,
    outcome: &str,
    size: &str,
    price: &str,
    slug: &str,
    target_address: Option<&str>,
    copy_status: Option<&str>,
) {
    let mut s = state.write().await;
    s.logs.push(TradeLog {
        time: chrono::Utc::now().to_rfc3339(),
        tag: tag.to_string(),
        side: side.to_string(),
        outcome: outcome.to_string(),
        size: size.to_string(),
        price: price.to_string(),
        slug: slug.to_string(),
        target_address: target_address.map(String::from),
        copy_status: copy_status.map(String::from),
    });
    if s.logs.len() > MAX_LOGS {
        s.logs.remove(0);
    }
}

pub async fn set_positions(
    state: SharedState,
    user: &str,
    positions: Vec<(String, String, f64, f64)>, // (slug, outcome, size, cur_price)
) {
    let user = user.to_string();
    let mut prev: HashMap<String, f64> = HashMap::new();
    let mut prev_positions: HashMap<String, PositionSummary> = HashMap::new();
    {
        let s = state.read().await;
        if let Some(existing) = s.positions.get(&user) {
            for p in existing {
                let key = format!("{}|{}", p.slug, p.outcome);
                prev.insert(key.clone(), p.size);
                prev_positions.insert(key, p.clone());
            }
        }
    }
    let now = chrono::Utc::now().to_rfc3339();
    // Build set of currently-open position keys
    let mut open_keys: std::collections::HashSet<String> = std::collections::HashSet::new();
    let mut list = Vec::with_capacity(positions.len());
    for (slug, outcome, size, cur_price) in positions {
        let key = format!("{}|{}", slug, outcome);
        open_keys.insert(key.clone());
        let prev_size = prev.get(&key).copied();
        prev.insert(key, size);
        let (delta, delta_at) = prev_size
            .map(|ps| {
                let d = size - ps;
                (Some(d), if d != 0.0 { Some(now.clone()) } else { None })
            })
            .unwrap_or((None, None));
        list.push(PositionSummary {
            slug,
            outcome,
            size,
            cur_price,
            delta: if delta.map(|d| d != 0.0).unwrap_or(false) {
                delta
            } else {
                None
            },
            delta_at,
            status: "open".to_string(),
            closed_at: None,
            close_price: None,
        });
    }
    // Detect positions that disappeared (closed/resolved) and mark them
    for (key, old_pos) in &prev_positions {
        if old_pos.status == "open" && !open_keys.contains(key) {
            list.push(PositionSummary {
                slug: old_pos.slug.clone(),
                outcome: old_pos.outcome.clone(),
                size: old_pos.size,
                cur_price: old_pos.cur_price,
                delta: None,
                delta_at: None,
                status: "closed".to_string(),
                closed_at: Some(now.clone()),
                close_price: Some(old_pos.cur_price),
            });
        }
    }
    // Keep previously-closed positions
    for old_pos in prev_positions.values() {
        if old_pos.status == "closed" {
            list.push(old_pos.clone());
        }
    }
    let mut s = state.write().await;
    s.positions.insert(user, list);
}

pub async fn set_balances(state: SharedState, usdc: Option<f64>, pol: Option<f64>) {
    let mut s = state.write().await;
    s.balances = WalletBalances { usdc, pol };
}
