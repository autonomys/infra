use crate::cli::{
    CommonParams, DomainCommonParams, DomainOperatorParams, DomainRpcParams, FarmerParams,
    RpcParams,
};
use crate::sync_config::load_config;
use crate::types::ComposeTemplateData;
use handlebars::Handlebars;
use std::fs::File;

const COMPOSE_TEMPLATE_DATA: &str = include_str!("templates/docker-compose.hbs");

pub(crate) fn create_boostrap_node_docker_compose(node_params: CommonParams) {
    let config = load_config().unwrap();
    let template_data = ComposeTemplateData::new_boostrap(config, node_params);
    create_compose_file(template_data);
}

pub(crate) fn create_rpc_node_docker_compose(rpc_params: RpcParams) {
    let config = load_config().unwrap();
    let template_data = ComposeTemplateData::new_rpc(config, rpc_params);
    create_compose_file(template_data);
}

pub(crate) fn create_farmer_node_docker_compose(farmer_params: FarmerParams) {
    let config = load_config().unwrap();
    let template_data = ComposeTemplateData::new_farmer(config, farmer_params);
    create_compose_file(template_data);
}

pub(crate) fn create_domain_bootstrap_node_docker_compose(domain_params: DomainCommonParams) {
    let config = load_config().unwrap();
    let template_data = ComposeTemplateData::new_domain_bootstrap(config, domain_params);
    create_compose_file(template_data);
}

pub(crate) fn create_domain_rpc_node_docker_compose(domain_params: DomainRpcParams) {
    let config = load_config().unwrap();
    let template_data = ComposeTemplateData::new_domain_rpc(config, domain_params);
    create_compose_file(template_data);
}

pub(crate) fn create_domain_operator_node_docker_compose(domain_params: DomainOperatorParams) {
    let config = load_config().unwrap();
    let template_data = ComposeTemplateData::new_domain_operator(config, domain_params);
    create_compose_file(template_data);
}

fn create_compose_file(template_data: ComposeTemplateData) {
    let mut handlebars = Handlebars::new();
    handlebars
        .register_template_string("template", COMPOSE_TEMPLATE_DATA)
        .unwrap();
    let mut output_file = File::create("data/docker-compose.yml").unwrap();
    handlebars
        .render_to_write("template", &template_data, &mut output_file)
        .unwrap();
}
