mod cli;
mod compose_create;
mod infisical;
mod sync_config;
mod types;

use crate::cli::{Command, InfisicalCommonParams, InfisicalStoreSecretsParams};
use crate::compose_create::{
    create_boostrap_node_docker_compose, create_domain_bootstrap_node_docker_compose,
    create_domain_operator_node_docker_compose, create_domain_rpc_node_docker_compose,
    create_farmer_node_docker_compose, create_rpc_node_docker_compose,
    create_timekeeper_node_docker_compose,
};
use crate::infisical::InfisicalClient;
use crate::sync_config::sync_config;
use ::infisical::InfisicalError;
use clap::Parser;
use env_logger::Env;
use handlebars::{RenderError, TemplateError};
use hex::FromHexError;
use toml::ser::Error as TomlError;

#[tokio::main]
async fn main() -> Result<(), Error> {
    let env = Env::default().default_filter_or("info");
    env_logger::init_from_env(env);

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
        Command::InfisicalStore(params) => {
            let InfisicalStoreSecretsParams {
                common,
                file: files,
            } = params;
            let InfisicalCommonParams {
                client_id,
                client_secret,
                project_id,
                path,
            } = common;
            let infisical_client = InfisicalClient::new(client_id, client_secret).await?;
            infisical_client
                .store_secret_files(project_id, path, files)
                .await?;
            Ok(())
        }
        Command::InfisicalFetch(params) => {
            let InfisicalCommonParams {
                client_id,
                client_secret,
                project_id,
                path,
            } = params;
            let infisical_client = InfisicalClient::new(client_id, client_secret).await?;
            infisical_client.fetch_secrets(project_id, path).await?;
            Ok(())
        }
    }
}

#[derive(thiserror::Error, Debug)]
pub(crate) enum Error {
    #[error("Infisical error: {0}")]
    Infisical(InfisicalError),
    #[error("Toml error: {0}")]
    Toml(TomlError),
    #[error("IO error: {0}")]
    Io(std::io::Error),
    #[error("Missing config")]
    Config,
    #[error("Template error: {0}")]
    Template(TemplateError),
    #[error("Render error: {0}")]
    Render(RenderError),
    #[error("From Hex error: {0}")]
    FromHex(FromHexError),
}

impl From<InfisicalError> for Error {
    fn from(value: InfisicalError) -> Self {
        Self::Infisical(value)
    }
}

impl From<TomlError> for Error {
    fn from(value: TomlError) -> Self {
        Self::Toml(value)
    }
}

impl From<std::io::Error> for Error {
    fn from(value: std::io::Error) -> Self {
        Self::Io(value)
    }
}

impl From<TemplateError> for Error {
    fn from(value: TemplateError) -> Self {
        Self::Template(value)
    }
}

impl From<RenderError> for Error {
    fn from(value: RenderError) -> Self {
        Self::Render(value)
    }
}

impl From<FromHexError> for Error {
    fn from(value: FromHexError) -> Self {
        Self::FromHex(value)
    }
}
