use clap::Parser;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::error::Error;

/// Config for node utilities.
#[derive(Serialize, Deserialize, Debug)]
pub struct Config {
    pub network: String,
    pub genesis_hash: String,
    pub bootstrap_node_keys: BTreeMap<String, NodeKey>,
    pub bootstrap_dsn_keys: BTreeMap<String, NodeKey>,
    pub domain_bootstrap_node_keys: BTreeMap<String, BTreeMap<String, NodeKey>>,
    pub domain_operator_keys: BTreeMap<String, BTreeMap<String, OperatorKeypair>>,
}

/// Config for a single boot node.
#[derive(Serialize, Deserialize, Debug)]
pub struct NodeKey {
    pub peer_id: String,
    pub key: String,
}

/// Config for a single boot node.
#[derive(Serialize, Deserialize, Debug)]
pub struct OperatorKeypair {
    pub secret: String,
    pub public_address: String,
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

/// Command Cli for node-utils.
#[derive(Debug, Parser)]
#[clap(about, version)]
pub enum Command {
    SyncConfig(SyncConfigParams),
}

/// Parse a single key-value pair.
fn parse_key_value(s: &str) -> Result<(u32, u32), Box<dyn Error + Send + Sync + 'static>> {
    let pos = s
        .find('=')
        .ok_or_else(|| format!("invalid Key=Value: no `=` found in `{s}`"))?;
    Ok((s[..pos].parse()?, s[pos + 1..].parse()?))
}
