use crate::Error;
use hex::{decode, encode};
use infisical::secrets::{CreateSecretRequest, ListSecretsRequest, Secret, UpdateSecretRequest};
use infisical::{AuthMethod, Client};
use log::info;
use std::collections::BTreeSet;
use std::fs;

const DEFAULT_INFISICAL_PROJECT_ENV: &str = "prod";

pub(crate) struct InfisicalClient {
    client: Client,
}

impl InfisicalClient {
    pub(crate) async fn new(client_id: String, client_secret: String) -> Result<Self, Error> {
        let mut client = Client::builder().build().await?;
        let auth_method = AuthMethod::new_universal_auth(client_id, client_secret);
        client.login(auth_method).await?;
        Ok(Self { client })
    }

    pub(crate) async fn store_secret_files(
        &self,
        project_id: String,
        path: String,
        files: Vec<String>,
    ) -> Result<(), Error> {
        let secrets = self
            .get_secrets(&project_id, &path)
            .await?
            .into_iter()
            .map(|s| s.secret_key)
            .collect::<BTreeSet<_>>();

        for file in files {
            if secrets.contains(&file) {
                self.update_secret(&project_id, &path, &file).await?;
            } else {
                self.store_secret(&project_id, &path, &file).await?;
            }
        }

        Ok(())
    }

    async fn store_secret(&self, project_id: &str, path: &str, file: &str) -> Result<(), Error> {
        info!("Creating secret file: {file}...");
        let file_data = fs::read(format!("data/{file}"))?;
        let encoded_data = encode(&file_data);
        let req = CreateSecretRequest::builder(
            file,
            encoded_data,
            project_id,
            DEFAULT_INFISICAL_PROJECT_ENV,
        )
        .path(path)
        .build();
        self.client.secrets().create(req).await?;
        info!("Created secret file: {file}");
        Ok(())
    }

    async fn update_secret(&self, project_id: &str, path: &str, file: &str) -> Result<(), Error> {
        info!("Updating secret file: {file}...");
        let file_data = fs::read(format!("data/{file}"))?;
        let encoded_data = encode(&file_data);
        let req = UpdateSecretRequest::builder(file, project_id, DEFAULT_INFISICAL_PROJECT_ENV)
            .path(path)
            .secret_value(encoded_data)
            .build();
        self.client.secrets().update(req).await?;
        info!("Updated secret file: {file}");
        Ok(())
    }

    async fn get_secrets(&self, project_id: &str, path: &str) -> Result<Vec<Secret>, Error> {
        let request = ListSecretsRequest::builder(project_id, DEFAULT_INFISICAL_PROJECT_ENV)
            .path(path)
            .build();
        self.client
            .secrets()
            .list(request)
            .await
            .map_err(Into::into)
    }

    pub(crate) async fn fetch_secrets(
        &self,
        project_id: String,
        path: String,
    ) -> Result<(), Error> {
        info!("Fetching secret files...");
        let secrets = self.get_secrets(&project_id, &path).await?;
        for secret in secrets {
            let file = secret.secret_key;
            let secret_data = secret.secret_value;
            let decoded_secret = decode(&secret_data)?;
            fs::write(format!("data/{file}"), decoded_secret)?;
            info!("Fetched secret {file}");
        }

        Ok(())
    }
}
