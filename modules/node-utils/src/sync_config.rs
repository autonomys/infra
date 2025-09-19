use crate::Error;
use crate::cli::SyncConfigParams;
use crate::types::{Config, NodeKey, OperatorKeypair};
use bip39::Mnemonic;
use ed25519_dalek::SigningKey;
use libp2p_identity::Keypair;
use rand::RngCore;
use sp_core::Pair as PairT;
use sp_core::sr25519::Pair;
use std::collections::BTreeMap;
use std::fs;

pub(crate) fn sync_config(config_params: SyncConfigParams) -> Result<(), Error> {
    let SyncConfigParams {
        bootstrap_node_count,
        domain_bootstrap_node_count,
        domain_operators,
    } = config_params;

    let mut config = load_config().unwrap_or_else(|| Config {
        bootstrap_node_keys: BTreeMap::new(),
        bootstrap_dsn_keys: BTreeMap::new(),
        domain_bootstrap_node_keys: BTreeMap::new(),
        domain_operator_keys: BTreeMap::new(),
    });

    (0..bootstrap_node_count).for_each(|idx| {
        let idx = idx.to_string();
        config
            .bootstrap_node_keys
            .entry(idx)
            .or_insert_with(generate_node_key);
    });

    (0..bootstrap_node_count).for_each(|idx| {
        let idx = idx.to_string();
        config
            .bootstrap_dsn_keys
            .entry(idx)
            .or_insert_with(generate_dsn_node_key);
    });

    domain_bootstrap_node_count
        .into_iter()
        .for_each(|(domain_id, count)| {
            let domain_id = domain_id.to_string();
            let domain_config = config
                .domain_bootstrap_node_keys
                .entry(domain_id)
                .or_default();
            (0..count).for_each(|idx| {
                let idx = idx.to_string();
                domain_config.entry(idx).or_insert_with(generate_node_key);
            })
        });

    domain_operators
        .into_iter()
        .for_each(|(domain_id, operator_id)| {
            let domain_id = domain_id.to_string();
            let operator_id = operator_id.to_string();
            let domain_config = config.domain_operator_keys.entry(domain_id).or_default();
            domain_config
                .entry(operator_id)
                .or_insert_with(generate_mnemonic);
        });

    fs::write("data/config.toml", toml::to_string(&config)?)?;
    Ok(())
}

pub(crate) fn load_config() -> Option<Config> {
    let config = fs::read_to_string("data/config.toml").ok()?;
    toml::from_str::<Config>(&config).ok()
}

fn generate_node_key() -> NodeKey {
    let keypair = Keypair::generate_ed25519();
    let peer_id = keypair.public().to_peer_id().to_string();
    let secret = keypair
        .try_into_ed25519()
        .expect("Keypair to ed25519")
        .secret();
    NodeKey {
        peer_id,
        key: hex::encode(secret),
        multiaddr: None,
    }
}

fn generate_dsn_node_key() -> NodeKey {
    let secret = {
        let mut secret = ed25519_dalek::SecretKey::default();
        rand::rngs::ThreadRng::default().fill_bytes(&mut secret);
        secret
    };
    let signing_key = SigningKey::from_bytes(&secret);
    let keypair_bytes = hex::encode(signing_key.to_keypair_bytes());
    let keypair = Keypair::ed25519_from_bytes(secret).expect("Should fit to [u8; 32]");
    let peer_id = keypair.public().to_peer_id().to_string();
    NodeKey {
        peer_id,
        key: keypair_bytes,
        multiaddr: None,
    }
}

fn generate_mnemonic() -> OperatorKeypair {
    let secret = Mnemonic::generate(12).expect("Failed to generate MNEMONIC");
    let keypair = Pair::from_string(&secret.to_string(), None).expect("Failed to create keypair");

    OperatorKeypair {
        secret: secret.to_string(),
        public_address: hex::encode(keypair.public()),
    }
}
