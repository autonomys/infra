{{/*
    Expand the name of the chart.
    */}}
    {{- define "account-squid.name" -}}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
    {{- end }}

    {{/*
    Create a default fully qualified app name.
    */}}
    {{- define "account-squid.fullname" -}}
    {{- if .Values.fullnameOverride }}
    {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
    {{- else }}
    {{- $name := default .Chart.Name .Values.nameOverride }}
    {{- if contains $name .Release.Name }}
    {{- .Release.Name | trunc 63 | trimSuffix "-" }}
    {{- else }}
    {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
    {{- end }}
    {{- end }}
    {{- end }}

    {{/*
    Create chart name and version as used by the chart label.
    */}}
    {{- define "account-squid.chart" -}}
    {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    {{- end }}

    {{/*
    Common labels
    */}}
    {{- define "account-squid.labels" -}}
    helm.sh/chart: {{ include "account-squid.chart" . }}
    {{ include "account-squid.selectorLabels" . }}
    {{- if .Chart.AppVersion }}
    app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
    {{- end }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    {{- end }}

    {{/*
    Selector labels
    */}}
    {{- define "account-squid.selectorLabels" -}}
    app.kubernetes.io/name: {{ include "account-squid.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    {{- end }}

    {{/*
    Create the name of the service account to use
    */}}
    {{- define "account-squid.serviceAccountName" -}}
    {{- if .Values.serviceAccount.create }}
    {{- default (include "account-squid.fullname" .) .Values.serviceAccount.name }}
    {{- else }}
    {{- default "default" .Values.serviceAccount.name }}
    {{- end }}
    {{- end }}
