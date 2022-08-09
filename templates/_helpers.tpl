{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "docker-registry.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "docker-registry.fullname" -}}
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

{{/*
Create a livenessProbe.
Allow the default value to be completely overriden by an optional value.
Retain he original livenessProbe logic.
*/}}
{{- define "docker-registry.livenessProbe" -}}
livenessProbe:
{{- if .Values.livenessProbe }}
{{ .Values.livenessProbe | toYaml | indent 2 }}
{{- else }}
  httpGet:
{{- if .Values.tlsSecretName }}
    scheme: HTTPS
{{- end }}
    path: /
    port: 5000
{{- end -}}
{{- end -}}

{{/*
Create a readinessProbe.
Allow the default value to be completely overriden by an optional value.
Retain he original readinessProbe logic.
*/}}
{{- define "docker-registry.readinessProbe" -}}
readinessProbe:
{{- if .Values.readinessProbe }}
{{ .Values.readinessProbe | toYaml | indent 2 }}
{{- else }}
  httpGet:
{{- if .Values.tlsSecretName }}
    scheme: HTTPS
{{- end }}
    path: /
    port: 5000
{{- end -}}
{{- end -}}