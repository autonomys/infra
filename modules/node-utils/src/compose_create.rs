use crate::Error;
use crate::cli::{
    BootnodeParams, DomainCommonParams, DomainOperatorParams, DomainRpcParams, FarmerParams,
    RpcParams, TimekeeperParams,
};
use crate::sync_config::load_config;
use crate::types::ComposeTemplateData;
use handlebars::Handlebars;
use std::fs::File;
use std::io::Write;

const COMPOSE_TEMPLATE: &str = include_str!("templates/docker-compose.hbs");

pub(crate) fn create_boostrap_node_docker_compose(
    node_params: BootnodeParams,
) -> Result<(), Error> {
    let config = load_config().ok_or(Error::Config)?;
    let template_data = ComposeTemplateData::new_boostrap(config, node_params);
    create_compose_file(template_data)
}

pub(crate) fn create_rpc_node_docker_compose(rpc_params: RpcParams) -> Result<(), Error> {
    let config = load_config().ok_or(Error::Config)?;
    let template_data = ComposeTemplateData::new_rpc(config, rpc_params);
    create_compose_file(template_data)
}

pub(crate) fn create_timekeeper_node_docker_compose(params: TimekeeperParams) -> Result<(), Error> {
    let config = load_config().ok_or(Error::Config)?;
    let template_data = ComposeTemplateData::new_timekeeper(config, params);
    create_compose_file(template_data)
}

pub(crate) fn create_farmer_node_docker_compose(farmer_params: FarmerParams) -> Result<(), Error> {
    let config = load_config().ok_or(Error::Config)?;
    let template_data = ComposeTemplateData::new_farmer(config, farmer_params);
    create_compose_file(template_data)
}

pub(crate) fn create_domain_bootstrap_node_docker_compose(
    domain_params: DomainCommonParams,
) -> Result<(), Error> {
    let config = load_config().ok_or(Error::Config)?;
    let template_data = ComposeTemplateData::new_domain_bootstrap(config, domain_params);
    create_compose_file(template_data)
}

pub(crate) fn create_domain_rpc_node_docker_compose(
    domain_params: DomainRpcParams,
) -> Result<(), Error> {
    let config = load_config().ok_or(Error::Config)?;
    let template_data = ComposeTemplateData::new_domain_rpc(config, domain_params);
    create_compose_file(template_data)
}

pub(crate) fn create_domain_operator_node_docker_compose(
    domain_params: DomainOperatorParams,
) -> Result<(), Error> {
    let config = load_config().ok_or(Error::Config)?;
    let domain_id = domain_params.common.domain_id.clone();
    let operator_id = domain_params.operator_id.clone();
    let operator_suri = config
        .domain_operator_keys
        .get(&domain_id)
        .unwrap()
        .get(&operator_id)
        .unwrap()
        .secret
        .clone();
    let template_data = ComposeTemplateData::new_domain_operator(config, domain_params);
    create_compose_file(template_data)?;
    let mut file = File::create("data/node.key")?;
    file.write_all(operator_suri.as_ref())?;
    Ok(())
}

fn create_compose_file(template_data: ComposeTemplateData) -> Result<(), Error> {
    let mut handlebars = Handlebars::new();
    handlebars.register_template_string("compose_template", COMPOSE_TEMPLATE)?;
    let mut output_file = File::create("data/docker-compose.yml")?;
    handlebars.render_to_write("compose_template", &template_data, &mut output_file)?;
    Ok(())
}
