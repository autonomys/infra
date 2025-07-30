use crate::cli::{
    CommonParams, DomainCommonParams, DomainOperatorParams, DomainRpcParams, FarmerParams,
    RpcParams,
};
use crate::sync_config::load_config;
use crate::types::{ComposeTemplateData, PrometheusNodeData, PrometheusTemplateData};
use handlebars::Handlebars;
use std::fs::File;
use std::io::Write;

const COMPOSE_TEMPLATE: &str = include_str!("templates/docker-compose.hbs");
const PROMETHEUS_CONFIG_TEMPLATE: &str = include_str!("templates/prometheus.hbs");

pub(crate) fn create_boostrap_node_docker_compose(node_params: CommonParams) {
    let config = load_config().unwrap();
    let network_name = config.network.clone();
    let node_id = node_params.node_id.clone();
    let template_data = ComposeTemplateData::new_boostrap(config, node_params);
    create_compose_file(template_data);
    create_prometheus_config(PrometheusTemplateData {
        nodes: vec![
            PrometheusNodeData {
                job_name: format!(
                    "{}-bootstrap-{}-node",
                    network_name.clone(),
                    node_id.clone(),
                ),
                node: "node".to_string(),
                port: "9615".to_string(),
            },
            PrometheusNodeData {
                job_name: format!("{}-dsn-bootstrap-{}-node", network_name, node_id,),
                node: "dsn-bootstrap-node".to_string(),
                port: "9616".to_string(),
            },
        ],
    });
}

pub(crate) fn create_rpc_node_docker_compose(rpc_params: RpcParams) {
    let config = load_config().unwrap();
    let network_name = config.network.clone();
    let node_id = rpc_params.common.node_id.clone();
    let template_data = ComposeTemplateData::new_rpc(config, rpc_params);
    create_compose_file(template_data);
    create_prometheus_config(PrometheusTemplateData {
        nodes: vec![PrometheusNodeData {
            job_name: format!("{}-rpc-{}-node", network_name, node_id,),
            node: "node".to_string(),
            port: "9615".to_string(),
        }],
    });
}

pub(crate) fn create_farmer_node_docker_compose(farmer_params: FarmerParams) {
    let config = load_config().unwrap();
    let network_name = config.network.clone();
    let node_id = farmer_params.common.node_id.clone();
    let template_data = ComposeTemplateData::new_farmer(config, farmer_params);
    create_compose_file(template_data);
    create_prometheus_config(PrometheusTemplateData {
        nodes: vec![
            PrometheusNodeData {
                job_name: format!(
                    "{}-farmer-node-{}-node",
                    network_name.clone(),
                    node_id.clone(),
                ),
                node: "node".to_string(),
                port: "9615".to_string(),
            },
            PrometheusNodeData {
                job_name: format!("{}-farmer-{}-node", network_name, node_id,),
                node: "farmer".to_string(),
                port: "9616".to_string(),
            },
        ],
    });
}

pub(crate) fn create_domain_bootstrap_node_docker_compose(domain_params: DomainCommonParams) {
    let config = load_config().unwrap();
    let network_name = config.network.clone();
    let domain_id = domain_params.domain_id.clone();
    let node_id = domain_params.common.node_id.clone();
    let template_data = ComposeTemplateData::new_domain_bootstrap(config, domain_params);
    create_compose_file(template_data);
    create_prometheus_config(PrometheusTemplateData {
        nodes: vec![PrometheusNodeData {
            job_name: format!(
                "{}-domain-{}-bootstrap-{}-node",
                network_name, domain_id, node_id,
            ),
            node: "node".to_string(),
            port: "9615".to_string(),
        }],
    });
}

pub(crate) fn create_domain_rpc_node_docker_compose(domain_params: DomainRpcParams) {
    let config = load_config().unwrap();
    let network_name = config.network.clone();
    let domain_id = domain_params.common.domain_id.clone();
    let node_id = domain_params.common.common.node_id.clone();
    let template_data = ComposeTemplateData::new_domain_rpc(config, domain_params);
    create_compose_file(template_data);
    create_prometheus_config(PrometheusTemplateData {
        nodes: vec![PrometheusNodeData {
            job_name: format!("{}-domain-{}-rpc-{}-node", network_name, domain_id, node_id,),
            node: "node".to_string(),
            port: "9615".to_string(),
        }],
    });
}

pub(crate) fn create_domain_operator_node_docker_compose(domain_params: DomainOperatorParams) {
    let config = load_config().unwrap();
    let domain_id = domain_params.common.domain_id.clone();
    let operator_id = domain_params.operator_id.clone();
    let network_name = config.network.clone();
    let operator_suri = config
        .domain_operator_keys
        .get(&domain_id)
        .unwrap()
        .get(&operator_id)
        .unwrap()
        .secret
        .clone();
    let template_data = ComposeTemplateData::new_domain_operator(config, domain_params);
    create_compose_file(template_data);
    let mut file = File::create("data/node.key").unwrap();
    file.write_all(operator_suri.as_ref()).unwrap();
    create_prometheus_config(PrometheusTemplateData {
        nodes: vec![PrometheusNodeData {
            job_name: format!(
                "{}-domain-{}-operator-{}-node",
                network_name, domain_id, operator_id,
            ),
            node: "node".to_string(),
            port: "9615".to_string(),
        }],
    });
}

fn create_compose_file(template_data: ComposeTemplateData) {
    let mut handlebars = Handlebars::new();
    handlebars
        .register_template_string("compose_template", COMPOSE_TEMPLATE)
        .unwrap();
    let mut output_file = File::create("data/docker-compose.yml").unwrap();
    handlebars
        .render_to_write("compose_template", &template_data, &mut output_file)
        .unwrap();
}

fn create_prometheus_config(template_data: PrometheusTemplateData) {
    let mut handlebars = Handlebars::new();
    handlebars
        .register_template_string("prometheus_template", PROMETHEUS_CONFIG_TEMPLATE)
        .unwrap();
    let mut output_file = File::create("data/prometheus.yml").unwrap();
    handlebars
        .render_to_write("prometheus_template", &template_data, &mut output_file)
        .unwrap();
}
