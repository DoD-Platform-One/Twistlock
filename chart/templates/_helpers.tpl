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

{{/* SSO specific name */}}
{{- define "twistlock-sso.name" -}}
{{- printf "%s-sso" (include "twistlock.name" .) | trunc 63 | trimSuffix "-" -}}
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

{{/* Kiali Pod Labels */}}
{{- define "twistlock.kiali-pod-labels" -}}
{{- with .Values.podLabels }}
{{ tpl (toYaml .) $ }}
{{- end }}
{{- end -}}

{{/* Helm required labels */}}
{{- define "base.labels" -}}
{{- $podLabels := include "twistlock.kiali-pod-labels" . | fromYaml }}
{{- $helmLabels := dict "app.kubernetes.io/instance" .Release.Name }}
{{- $_ := set $helmLabels "app.kubernetes.io/version" .Chart.AppVersion }}
{{- $_ := set $helmLabels "app.kubernetes.io/managed-by" .Release.Service }}
{{- $_ := set $helmLabels "helm.sh/chart" (include "twistlock.chart" .) }}
{{- $podLabels := mustMergeOverwrite $helmLabels $podLabels }}
{{- $podLabels := mustMergeOverwrite $podLabels (include "base.selector" . | fromYaml) }}
{{- if .Values.customLabels }}
{{- $podLabels := mustMergeOverwrite $podLabels .Values.customLabels }}
{{- end }}
{{- toYaml $podLabels }}
{{- end -}}

{{/* Defender specific labels */}}
{{- define "twistlock-defender.labels" -}}
{{- $podLabels := include "base.labels" . | fromYaml }}
{{- $podLabels := mustMergeOverwrite $podLabels (include "twistlock-defender.selector" . | fromYaml) }}
{{- toYaml $podLabels }}
{{- end -}}


{{/* Init specific labels */}}
{{- define "twistlock-init.labels" -}}
{{- $podLabels := include "base.labels" . | fromYaml }}
{{- $podLabels := mustMergeOverwrite $podLabels (include "twistlock-init.selector" . | fromYaml) }}
{{- toYaml $podLabels }}
{{- end -}}

{{/* Console specific labels */}}
{{- define "twistlock-console.labels" -}}
{{- $podLabels := include "base.labels" . | fromYaml }}
{{- $podLabels := mustMergeOverwrite $podLabels (include "twistlock-console.selector" . | fromYaml) }}
{{- toYaml $podLabels }}
{{- end -}}

{{/* Base Selector */}}
{{- define "base.selector" -}}
{{- $podLabels := include "twistlock.kiali-pod-labels" . | fromYaml }}
{{- $newPodLabels :=  dict "" "" }}
{{- range $key, $value := $podLabels }}
{{- if not (or (eq $key "app.kubernetes.io/version") (eq $key "version")) }}
{{- $_ := set $newPodLabels $key $value }}
{{- end -}}
{{- end -}}
{{- $_ := unset $newPodLabels ""}}
{{- toYaml $newPodLabels }}
{{- end -}}

{{/* Defender selector labels */}}
{{- define "twistlock-defender.selector" -}}
{{- $podLabels := include "base.selector" . | fromYaml }}
{{- $additionalLabels := dict "name" "twistlock-defender" }}
{{- $_ := set $additionalLabels "app.kubernetes.io/name" "twistlock-defender" }}
{{- $_ := set $additionalLabels "app.kubernetes.io/app" "twistlock-defender" }}
{{- $podLabels := mustMergeOverwrite $additionalLabels $podLabels }}
{{/* selector isn't configurable and is app - https://pan.dev/prisma-cloud/api/cwpp/post-defenders-daemonset-yaml/ */}}
{{- $additionalLabels = dict "app" "twistlock-defender" }}
{{- $podLabels := mustMergeOverwrite $podLabels $additionalLabels }}
{{- toYaml $podLabels }}
{{- end -}}

{{/* Init selector labels */}}
{{- define "twistlock-init.selector" -}}
{{- $podLabels := include "base.selector" . | fromYaml }}
{{- $additionalLabels := dict "name" "twistlock-init" }}
{{- $_ := set $additionalLabels "app.kubernetes.io/name" "twistlock-init" }}
{{- $_ := set $additionalLabels "app.kubernetes.io/app" "twistlock-init" }}
{{- $_ := set $additionalLabels "app" "twistlock-init" }}
{{- $podLabels := mustMergeOverwrite $additionalLabels $podLabels }}
{{- toYaml $podLabels }}
{{- end -}}

{{/* Console selector labels */}}
{{- define "twistlock-console.selector" -}}
{{- $podLabels := include "base.selector" . | fromYaml }}
{{- $additionalLabels := dict "name" "twistlock-console" }}
{{- $_ := set $additionalLabels "app.kubernetes.io/name" "twistlock-console" }}
{{- $_ := set $additionalLabels "app.kubernetes.io/app" "twistlock-console" }}
{{- $_ := set $additionalLabels "app" "twistlock-console" }}
{{- $podLabels := mustMergeOverwrite $additionalLabels $podLabels }}
{{- toYaml $podLabels }}
{{- end -}}

{{/* Return twistlock default admin password */}}
{{- define "twistlock.defaultAdminPassword" -}}
{{- if .Values.twistlock.defaultAdminPassword }}
{{- .Values.twistlock.defaultAdminPassword -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}
