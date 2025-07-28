use clap::Parser;
use serde::{Deserialize, Serialize};
use std::error::Error;

/// Command Cli for node-utils.
#[derive(Debug, Parser)]
#[clap(about, version)]
pub enum Command {
    SyncConfig(SyncConfigParams),
    Bootstrap(CommonParams),
    Farmer(FarmerParams),
    Rpc(RpcParams),
    DomainBootstrap(DomainCommonParams),
    DomainRpc(DomainRpcParams),
    DomainOperator(DomainOperatorParams),
}

/// Params to either sync or create new Config.
#[derive(Debug, Parser)]
pub struct SyncConfigParams {
    /// Network name
    /// Ex: mainnet, devnet etc..
    #[arg(long, required = true)]
    pub network: String,
    /// Genesis hash of the network.
    #[arg(long, required = true)]
    pub genesis_hash: String,
    /// New relic API Key
    #[arg(long, required = true)]
    pub new_relic_api_key: String,
    /// Domain name.ex: subspace.network
    #[arg(long, required = true)]
    pub fqdn: String,
    /// Consensus bootstrap node count.
    #[arg(long, required = true)]
    pub bootstrap_node_count: u32,
    /// Domain bootstrap node count
    /// Format: domain_id=count
    #[arg(long, value_parser(parse_key_value))]
    pub domain_bootstrap_node_count: Vec<(u32, u32)>,
    /// Domain operator for Bundle signing key.
    /// Format: domain_id=operator_id
    #[arg(long, value_parser(parse_key_value))]
    pub domain_operators: Vec<(u32, u32)>,
}

/// Common Params to create node docker compose
#[derive(Debug, Parser)]
pub struct CommonParams {
    /// Node instance index
    #[arg(long, required = true)]
    pub node_id: String,
    /// Docker tag
    #[arg(long, required = true)]
    pub docker_tag: String,
    #[arg(long, required = true)]
    pub external_ip_v4: String,
    #[arg(long, required = true)]
    pub external_ip_v6: String,
    #[arg(long, required = true)]
    pub is_reserved: bool,
}

#[derive(Debug, Parser)]
pub struct FarmerParams {
    #[clap(flatten)]
    pub common: CommonParams,
    #[clap(flatten)]
    pub farmer_params: FarmerNodeParams,
}

#[derive(Debug, Parser)]
pub struct RpcParams {
    #[clap(flatten)]
    pub common: CommonParams,
    #[arg(long, required = true)]
    pub node_prefix: String,
}

#[derive(Debug, Parser)]
pub struct DomainCommonParams {
    #[clap(flatten)]
    pub common: CommonParams,
    #[arg(long, required = true)]
    pub domain_id: String,
    #[arg(long, required = true)]
    pub node_prefix: String,
}

#[derive(Debug, Parser)]
pub struct DomainRpcParams {
    #[clap(flatten)]
    pub common: DomainCommonParams,
    #[arg(long)]
    pub eth_cache: bool,
}

#[derive(Debug, Parser)]
pub struct DomainOperatorParams {
    #[clap(flatten)]
    pub common: DomainCommonParams,
    #[arg(long, required = true)]
    pub operator_id: String,
}

#[derive(Debug, Serialize, Deserialize, Parser)]
pub struct FarmerNodeParams {
    #[arg(long, required = true)]
    pub plot_size: String,
    #[arg(long, required = true)]
    pub reward_address: String,
    #[arg(long, required = true)]
    pub cache_percentage: String,
    #[arg(long)]
    pub faster_sector_plotting: bool,
    #[arg(long)]
    pub force_block_production: bool,
}

/// Parse a single key-value pair.
fn parse_key_value(s: &str) -> Result<(u32, u32), Box<dyn Error + Send + Sync + 'static>> {
    let pos = s
        .find('=')
        .ok_or_else(|| format!("invalid Key=Value: no `=` found in `{s}`"))?;
    Ok((s[..pos].parse()?, s[pos + 1..].parse()?))
}
