{{/*
    Expand the name of the chart.
    */}}
    {{- define "rewards-squid.name" -}}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
    {{- end }}

    {{/*
    Create a default fully qualified app name.
    */}}
    {{- define "rewards-squid.fullname" -}}
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
    {{- define "rewards-squid.chart" -}}
    {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    {{- end }}

    {{/*
    Common labels
    */}}
    {{- define "rewards-squid.labels" -}}
    helm.sh/chart: {{ include "rewards-squid.chart" . }}
    {{ include "rewards-squid.selectorLabels" . }}
    {{- if .Chart.AppVersion }}
    app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
    {{- end }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    {{- end }}

    {{/*
    Selector labels
    */}}
    {{- define "rewards-squid.selectorLabels" -}}
    app.kubernetes.io/name: {{ include "rewards-squid.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    {{- end }}

    {{/*
    Create the name of the service account to use
    */}}
    {{- define "rewards-squid.serviceAccountName" -}}
    {{- if .Values.serviceAccount.create }}
    {{- default (include "rewards-squid.fullname" .) .Values.serviceAccount.name }}
    {{- else }}
    {{- default "default" .Values.serviceAccount.name }}
    {{- end }}
    {{- end }}
