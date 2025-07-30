use crate::cli::{
    CommonParams, DomainCommonParams, DomainOperatorParams, DomainRpcParams, FarmerNodeParams,
    FarmerParams, RpcParams,
};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

/// Config for node utilities.
#[derive(Serialize, Deserialize, Debug)]
pub struct Config {
    pub network: String,
    pub genesis_hash: String,
    pub new_relic_api_key: String,
    pub fqdn: String,
    pub bootstrap_node_keys: BTreeMap<String, NodeKey>,
    pub bootstrap_dsn_keys: BTreeMap<String, NodeKey>,
    pub domain_bootstrap_node_keys: BTreeMap<String, BTreeMap<String, NodeKey>>,
    pub domain_operator_keys: BTreeMap<String, BTreeMap<String, OperatorKeypair>>,
}

/// Config for a single boot node.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct NodeKey {
    pub peer_id: String,
    pub key: String,
}

impl NodeKey {
    fn multiaddress(
        &self,
        network: String,
        fqdn: String,
        node_id: String,
        port: String,
        maybe_prefix: Option<String>,
    ) -> String {
        if let Some(prefix) = maybe_prefix {
            format!(
                "/dns/bootstrap-{}.{}.{}.{}/tcp/{}/p2p/{}",
                node_id, prefix, network, fqdn, port, self.peer_id
            )
        } else {
            format!(
                "/dns/bootstrap-{}.{}.{}/tcp/{}/p2p/{}",
                node_id, network, fqdn, port, self.peer_id
            )
        }
    }
}

/// Config for a single boot node.
#[derive(Serialize, Deserialize, Debug)]
pub struct OperatorKeypair {
    pub secret: String,
    pub public_address: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RpcNode {
    pub port: String,
    pub is_consensus: bool,
    pub is_domain: bool,
    pub enable_reverse_proxy: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DsnNode {
    pub key: String,
    pub genesis_hash: String,
    pub multi_address: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DomainNode {
    pub domain_id: String,
    pub operator_id: Option<String>,
    pub domain_bootstrap_nodes: Vec<String>,
    pub eth_cache: bool,
}

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct PrometheusNodeData {
    pub job_name: String,
    pub node: String,
    pub port: String,
}

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct PrometheusTemplateData {
    pub nodes: Vec<PrometheusNodeData>,
}

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct ComposeTemplateData {
    pub network_name: String,
    pub node_prefix: String,
    pub node_id: String,
    pub new_relic_api_key: String,
    pub docker_tag: String,
    pub external_ip_v4: String,
    pub external_ip_v6: String,
    pub bootstrap_nodes: Vec<String>,
    pub dsn_bootstrap_nodes: Vec<String>,
    pub is_reserved: bool,
    pub sync_mode: String,
    pub fqdn: String,
    pub node_key: Option<String>,
    pub farmer_node: Option<FarmerNodeParams>,
    pub rpc_node: Option<RpcNode>,
    pub dsn_node: Option<DsnNode>,
    pub domain_node: Option<DomainNode>,
}

impl ComposeTemplateData {
    fn new_base_common(
        config: &Config,
        node_type: String,
        node_params: CommonParams,
        include_all_bootstrap_nodes: bool,
    ) -> ComposeTemplateData {
        let CommonParams {
            node_id,
            docker_tag,
            external_ip_v4,
            external_ip_v6,
            sync_mode,
            is_reserved,
        } = node_params;
        ComposeTemplateData {
            network_name: config.network.clone(),
            node_prefix: node_type,
            node_id: node_id.clone(),
            new_relic_api_key: config.new_relic_api_key.clone(),
            docker_tag,
            external_ip_v4,
            external_ip_v6,
            bootstrap_nodes: config
                .bootstrap_node_keys
                .iter()
                .filter_map(|(idx, node_key)| {
                    if *idx == node_id && !include_all_bootstrap_nodes {
                        None
                    } else {
                        Some(node_key.multiaddress(
                            config.network.clone(),
                            config.fqdn.clone(),
                            idx.clone(),
                            "30333".to_string(),
                            None,
                        ))
                    }
                })
                .collect(),
            dsn_bootstrap_nodes: config
                .bootstrap_dsn_keys
                .iter()
                .filter_map(|(idx, node_key)| {
                    if *idx == node_id && !include_all_bootstrap_nodes {
                        None
                    } else {
                        Some(node_key.multiaddress(
                            config.network.clone(),
                            config.fqdn.clone(),
                            idx.clone(),
                            "30533".to_string(),
                            None,
                        ))
                    }
                })
                .collect(),
            is_reserved,
            fqdn: config.fqdn.clone(),
            sync_mode,
            ..Default::default()
        }
    }

    pub fn new_boostrap(config: Config, node_params: CommonParams) -> ComposeTemplateData {
        let node_id = node_params.node_id.clone();
        let mut data = Self::new_base_common(&config, "bootstrap".to_string(), node_params, false);
        data.node_key = config
            .bootstrap_node_keys
            .get(&node_id)
            .cloned()
            .map(|node_key| node_key.key);
        data.dsn_node = Some(DsnNode {
            key: config
                .bootstrap_dsn_keys
                .get(&node_id)
                .cloned()
                .map(|node_key| node_key.key)
                .expect("DSN Node key not found"),
            genesis_hash: config.genesis_hash,
            multi_address: config
                .bootstrap_dsn_keys
                .get(&node_id)
                .cloned()
                .map(|node_key| {
                    node_key.multiaddress(
                        config.network.clone(),
                        config.fqdn.clone(),
                        node_id.clone(),
                        "30533".to_string(),
                        None,
                    )
                })
                .unwrap(),
        });
        data
    }

    pub fn new_farmer(config: Config, farmer_params: FarmerParams) -> ComposeTemplateData {
        let mut data =
            Self::new_base_common(&config, "farmer".to_string(), farmer_params.common, true);
        data.farmer_node = Some(farmer_params.farmer_params);
        data
    }

    pub fn new_rpc(config: Config, node_params: RpcParams) -> ComposeTemplateData {
        let mut data =
            Self::new_base_common(&config, node_params.node_prefix, node_params.common, true);
        data.rpc_node = Some(RpcNode {
            port: "9944".to_string(),
            is_consensus: true,
            is_domain: false,
            enable_reverse_proxy: node_params.enable_reverse_proxy,
        });
        data
    }

    fn new_domain_common(
        config: &Config,
        node_params: DomainCommonParams,
        include_all_bootstrap_nodes: bool,
    ) -> ComposeTemplateData {
        let domain_id = node_params.domain_id;
        let node_id = node_params.common.node_id.clone();
        let node_prefix = node_params.node_prefix;
        let mut data =
            Self::new_base_common(&config, node_prefix.clone(), node_params.common, true);
        data.domain_node = Some(DomainNode {
            domain_id: domain_id.clone(),
            operator_id: None,
            domain_bootstrap_nodes: config
                .domain_bootstrap_node_keys
                .get(&domain_id)
                .unwrap()
                .iter()
                .filter_map(|(idx, node_key)| {
                    if idx == &node_id && !include_all_bootstrap_nodes {
                        None
                    } else {
                        Some(node_key.multiaddress(
                            config.network.clone(),
                            config.fqdn.clone(),
                            idx.clone(),
                            "30334".to_string(),
                            Some(node_prefix.clone()),
                        ))
                    }
                })
                .collect(),
            eth_cache: false,
        });
        data
    }

    pub fn new_domain_bootstrap(
        config: Config,
        node_params: DomainCommonParams,
    ) -> ComposeTemplateData {
        let domain_id = node_params.domain_id.clone();
        let node_id = node_params.common.node_id.clone();
        let mut data = Self::new_domain_common(&config, node_params, false);
        data.node_key = config
            .domain_bootstrap_node_keys
            .get(&domain_id)
            .unwrap()
            .get(&node_id)
            .cloned()
            .map(|node_key| node_key.key);
        data
    }

    pub fn new_domain_rpc(config: Config, node_params: DomainRpcParams) -> ComposeTemplateData {
        let mut data = Self::new_domain_common(&config, node_params.common, true);
        data.rpc_node = Some(RpcNode {
            port: "9945".to_string(),
            is_consensus: false,
            is_domain: true,
            enable_reverse_proxy: node_params.enable_reverse_proxy,
        });
        let mut domain_data = data.domain_node.take().unwrap();
        domain_data.eth_cache = node_params.eth_cache;
        data.domain_node = Some(domain_data);
        data
    }

    pub fn new_domain_operator(
        config: Config,
        node_params: DomainOperatorParams,
    ) -> ComposeTemplateData {
        let mut data = Self::new_domain_common(&config, node_params.common, true);
        let mut domain_data = data.domain_node.take().unwrap();
        domain_data.operator_id = Some(node_params.operator_id);
        data.domain_node = Some(domain_data);
        data
    }
}
