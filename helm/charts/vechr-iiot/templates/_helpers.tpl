{{- define "vechr.releasename" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
 
{{- define "vechr.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}