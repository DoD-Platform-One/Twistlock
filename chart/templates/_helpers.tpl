{{/* vim: set filetype=mustache: */}}

{{/* Expand the name of the chart. */}}
{{- define "twistlock.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Init specific name */}}
{{- define "twistlock-init.name" -}}
{{- printf "%s-init" (include "twistlock.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Console specific name */}}
{{- define "twistlock-console.name" -}}
{{- printf "%s-console" (include "twistlock.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Defender specific name */}}
{{- define "twistlock-defender.name" -}}
{{- printf "%s-defender" (include "twistlock.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name. */}}
{{- define "twistlock.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "twistlock.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Helm required labels */}}
{{- define "base.labels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ template "twistlock.chart" . }}
{{- if .Values.customLabels }}
{{ toYaml .Values.customLabels }}
{{- end }}
{{- end -}}

{{/* Init specific labels */}}
{{- define "twistlock-init.labels" -}}
app.kubernetes.io/name: {{ template "twistlock-init.name" . }}
{{ template "base.labels" . }}
{{- end -}}

{{/* Console specific labels */}}
{{- define "twistlock-console.labels" -}}
app.kubernetes.io/name: {{ template "twistlock-console.name" . }}
{{ template "base.labels" . }}
{{- end -}}

{{/* Init selector labels */}}
{{- define "twistlock-init.selector" -}}
name: {{ template "twistlock-init.name" . }}
{{- end -}}

{{/* Console selector labels */}}
{{- define "twistlock-console.selector" -}}
name: {{ template "twistlock-console.name" . }}
{{- end -}}

{{/* Return twistlock default admin password */}}
{{- define "twistlock.defaultAdminPassword" -}}
{{- if .Values.twistlock.defaultAdminPassword }}
{{- .Values.twistlock.defaultAdminPassword -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}