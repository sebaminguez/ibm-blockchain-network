{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "ibm-blockchain-network.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "ibm-blockchain-network.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the shared volume.
*/}}
{{- define "ibm-blockchain-shared.name" -}}
{{- default "ibm-blockchain-shared" .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the composer volume.
*/}}
{{- define "ibm-blockchain-composer.name" -}}
{{- default "ibm-blockchain-composer" .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

