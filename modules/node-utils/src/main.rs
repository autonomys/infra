mod cli;
mod compose_create;
mod sync_config;
mod types;

use crate::cli::Command;
use crate::compose_create::{
    create_boostrap_node_docker_compose, create_domain_bootstrap_node_docker_compose,
    create_domain_operator_node_docker_compose, create_domain_rpc_node_docker_compose,
    create_farmer_node_docker_compose, create_rpc_node_docker_compose,
    create_timekeeper_node_docker_compose,
};
use crate::sync_config::sync_config;
use clap::Parser;

fn main() {
    let command: Command = Command::parse();
    match command {
        Command::SyncConfig(params) => sync_config(params),
        Command::Bootstrap(params) => create_boostrap_node_docker_compose(params),
        Command::Farmer(params) => create_farmer_node_docker_compose(params),
        Command::Rpc(params) => create_rpc_node_docker_compose(params),
        Command::DomainBootstrap(params) => create_domain_bootstrap_node_docker_compose(params),
        Command::DomainRpc(params) => create_domain_rpc_node_docker_compose(params),
        Command::DomainOperator(params) => create_domain_operator_node_docker_compose(params),
        Command::Timekeeper(params) => create_timekeeper_node_docker_compose(params),
    }
}
