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

{{- define "docker-registry.secretName" -}}
{{- if .Values.secrets.existingSecret }}
{{- .Values.secrets.existingSecret }}
{{- else }}
{{- template "docker-registry.fullname" . }}-secret
{{- end }}
{{- end }}

{{- define "docker-registry.azureSecretName" -}}
{{- if .Values.secrets.azure.existingSecret }}
{{- .Values.secrets.azure.secretRef }}
{{- else }}
{{- template "docker-registry.fullname" . }}-secret
{{- end }}
{{- end }}

{{- define "docker-registry.swiftSecretName" -}}
{{- if .Values.secrets.swift.existingSecret }}
{{- .Values.secrets.swift.secretRef }}
{{- else }}
{{- template "docker-registry.fullname" . }}-secret
{{- end }}
{{- end }}

{{- define "docker-registry.envs" -}}
- name: REGISTRY_HTTP_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ template "docker-registry.secretName" . }}
      {{- if and .Values.secrets.haSharedSecretKey .Values.secrets.existingSecret }}
      key: {{ .Values.secrets.haSharedSecretKey }}
      {{- else }}
      key: haSharedSecret
      {{- end }}

{{- if .Values.secrets.htpasswd }}
- name: REGISTRY_AUTH
  value: "htpasswd"
- name: REGISTRY_AUTH_HTPASSWD_REALM
  value: "Registry Realm"
- name: REGISTRY_AUTH_HTPASSWD_PATH
  value: "/auth/htpasswd"
{{- end }}

{{- if .Values.tlsSecretName }}
- name: REGISTRY_HTTP_TLS_CERTIFICATE
  value: /etc/ssl/docker/tls.crt
- name: REGISTRY_HTTP_TLS_KEY
  value: /etc/ssl/docker/tls.key
{{- end -}}

{{- if eq .Values.storage "filesystem" }}
- name: REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY
  value: "/var/lib/registry"
{{- else if eq .Values.storage "azure" }}
- name: REGISTRY_STORAGE_AZURE_ACCOUNTNAME
  valueFrom:
    secretKeyRef:
      name: {{ template "docker-registry.azureSecretName" . }}
      {{- if and .Values.secrets.azure.azureAccountNameKey .Values.secrets.azure.existingSecret }}
      key: {{- .Values.secrets.azure.accountNameKey }}
      {{- else }}
      key: azureAccountName
      {{- end }}
- name: REGISTRY_STORAGE_AZURE_ACCOUNTKEY
  valueFrom:
    secretKeyRef:
      name: {{ template "docker-registry.azureSecretName" . }}
      {{- if and .Values.secrets.azure.azureAccountNameKey .Values.secrets.azure.existingSecret }}
      key: {{- .Values.secrets.azure.accountKeyKey }}
      {{- else }}
      key: azureAccountKey
      {{- end }}
- name: REGISTRY_STORAGE_AZURE_CONTAINER
  valueFrom:
    secretKeyRef:
      name: {{ template "docker-registry.azureSecretName" . }}
      {{- if and .Values.secrets.azure.containerKey .Values.secrets.azure.existingSecret }}
      key: {{- .Values.secrets.azure.containerKey }}
      {{- else }}
      key: azureContainer
      {{- end }}
{{- else if eq .Values.storage "s3" }}
- name: REGISTRY_STORAGE_S3_REGION
  value: {{ required ".Values.s3.region is required" .Values.s3.region }}
- name: REGISTRY_STORAGE_S3_BUCKET
  value: {{ required ".Values.s3.bucket is required" .Values.s3.bucket }}
{{- if or (and .Values.secrets.s3.secretKey .Values.secrets.s3.accessKey) .Values.secrets.s3.secretRef }}
- name: REGISTRY_STORAGE_S3_ACCESSKEY
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.secrets.s3.secretRef }}{{ .Values.secrets.s3.secretRef }}{{ else }}{{ template "docker-registry.secretName" . }}{{ end }}
      key: s3AccessKey
- name: REGISTRY_STORAGE_S3_SECRETKEY
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.secrets.s3.secretRef }}{{ .Values.secrets.s3.secretRef }}{{ else }}{{ template "docker-registry.secretName" . }}{{ end }}
      key: s3SecretKey
{{- end -}}

{{- if .Values.s3.regionEndpoint }}
- name: REGISTRY_STORAGE_S3_REGIONENDPOINT
  value: {{ .Values.s3.regionEndpoint }}
{{- end -}}

{{- if .Values.s3.rootdirectory }}
- name: REGISTRY_STORAGE_S3_ROOTDIRECTORY
  value: {{ .Values.s3.rootdirectory | quote }}
{{- end -}}

{{- if .Values.s3.encrypt }}
- name: REGISTRY_STORAGE_S3_ENCRYPT
  value: {{ .Values.s3.encrypt | quote }}
{{- end -}}

{{- if .Values.s3.secure }}
- name: REGISTRY_STORAGE_S3_SECURE
  value: {{ .Values.s3.secure | quote }}
{{- end -}}

{{- if .Values.s3.forcepathstyle }}
- name: REGISTRY_STORAGE_S3_FORCEPATHSTYLE
  value: {{ .Values.s3.forcepathstyle | quote }}
{{- end -}}

{{- if .Values.s3.skipverify }}
- name: REGISTRY_STORAGE_S3_SKIPVERIFY
  value: {{ .Values.s3.skipverify | quote }}
{{- end -}}

{{- else if eq .Values.storage "swift" }}
- name: REGISTRY_STORAGE_SWIFT_AUTHURL
  value: {{ required ".Values.swift.authurl is required" .Values.swift.authurl }}
- name: REGISTRY_STORAGE_SWIFT_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ template "docker-registry.swiftSecretName" . }}
      {{- if and .Values.secrets.swift.usernameKey .Values.secrets.swift.secretRef }}
      key: {{ .Values.secrets.swift.usernameKey }}
      {{- else }}
      key: swiftUsername
      {{- end }}
- name: REGISTRY_STORAGE_SWIFT_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "docker-registry.swiftSecretName" . }}
      {{- if and .Values.secrets.swift.passwordKey .Values.secrets.swift.secretRef }}
      key: {{ .Values.secrets.swift.passwordKey }}
      {{- else }}
      key: swiftPassword
      {{- end }}
- name: REGISTRY_STORAGE_SWIFT_CONTAINER
  value: {{ required ".Values.swift.container is required" .Values.swift.container }}
{{- end -}}

{{- if .Values.proxy.enabled }}
- name: REGISTRY_PROXY_REMOTEURL
  value: {{ required ".Values.proxy.remoteurl is required" .Values.proxy.remoteurl }}
- name: REGISTRY_PROXY_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.proxy.secretRef }}{{ .Values.proxy.secretRef }}{{ else }}{{ template "docker-registry.secretName" . }}{{ end }}
      {{- if and .Values.proxy.proxyUsernameKey .Values.proxy.secretRef }}
      key: {{ .Values.proxy.proxyUsernameKey }}
      {{- else }}
      key: proxyUsername
      {{- end }}
- name: REGISTRY_PROXY_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.proxy.secretRef }}{{ .Values.proxy.secretRef }}{{ else }}{{ template "docker-registry.secretName" . }}{{ end }}
      {{- if and .Values.proxy.proxyPasswordKey .Values.proxy.secretRef }}
      key: {{ .Values.proxy.proxyPasswordKey }}
      {{- else }}
      key: proxyPassword
      {{- end }}
{{- end -}}

{{- if .Values.persistence.deleteEnabled }}
- name: REGISTRY_STORAGE_DELETE_ENABLED
  value: "true"
{{- end -}}

{{- with .Values.extraEnvVars }}
{{ toYaml . }}
{{- end -}}

{{- end }}

{{- define "docker-registry.volumeMounts" -}}
- name: "{{ template "docker-registry.fullname" . }}-config"
  mountPath: {{ .Values.configPath }}

{{- if or .Values.secrets.htpasswd .Values.secrets.existingSecret }}
- name: auth
  mountPath: /auth
  readOnly: true
{{- end }}

{{- if eq .Values.storage "filesystem" }}
- name: data
  mountPath: /var/lib/registry/
{{- end }}

{{- if .Values.tlsSecretName }}
- mountPath: /etc/ssl/docker
  name: tls-cert
  readOnly: true
{{- end }}

{{- with .Values.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}

{{- end -}}

{{- define "docker-registry.volumes" -}}
- name: {{ template "docker-registry.fullname" . }}-config
  configMap:
    name: {{ template "docker-registry.fullname" . }}-config

{{- if or .Values.secrets.htpasswd .Values.secrets.existingSecret }}
- name: auth
  secret:
    secretName: {{ template "docker-registry.secretName" . }}
    items:
    {{- if and .Values.secrets.htpasswdKey .Values.secrets.existingSecret }}
    - key: {{ .Values.secrets.htpasswdKey }}
      path: htpasswd
    {{- else }}
    - key: htpasswd
      path: htpasswd
    {{- end }}
{{- end }}

{{- if eq .Values.storage "filesystem" }}
- name: data
  {{- if .Values.persistence.enabled }}
  persistentVolumeClaim:
    claimName: {{ if .Values.persistence.existingClaim }}{{ .Values.persistence.existingClaim }}{{- else }}{{ template "docker-registry.fullname" . }}{{- end }}
  {{- else }}
  emptyDir: {}
  {{- end -}}
{{- end }}

{{- if .Values.tlsSecretName }}
- name: tls-cert
  secret:
    secretName: {{ .Values.tlsSecretName }}
{{- end }}

{{- with .Values.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end -}}
