{{/* Check configuration of Sidekiq - queues must be a string */}}
{{- define "gitlab.checkConfig.sidekiq.queues" -}}
{{- if .Values.gitlab.sidekiq.pods -}}
{{-   range $pod := .Values.gitlab.sidekiq.pods -}}
{{-     if and (hasKey $pod "queues") (ne (kindOf $pod.queues) "string") }}
sidekiq:
    The `queues` in pod definition `{{ $pod.name }}` is not a string.
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.sidekiq.queues */}}

{{/*
Ensure that Sidekiq timeout is less than terminationGracePeriodSeconds
*/}}
{{- define "gitlab.checkConfig.sidekiq.timeout" -}}
{{-   range $i, $pod := $.Values.gitlab.sidekiq.pods -}}
{{-     $activeTimeout := int (default $.Values.gitlab.sidekiq.timeout $pod.timeout) }}
{{-     $activeTerminationGracePeriodSeconds := int (default $.Values.gitlab.sidekiq.deployment.terminationGracePeriodSeconds $pod.terminationGracePeriodSeconds) }}
{{-     if gt $activeTimeout $activeTerminationGracePeriodSeconds }}
sidekiq:
  You must set `terminationGracePeriodSeconds` ({{ $activeTerminationGracePeriodSeconds }}) longer than `timeout` ({{ $activeTimeout }}) for pod `{{ $pod.name }}`.
{{-     end }}
{{-   end }}
{{- end -}}
{{/* END gitlab.checkConfig.sidekiq.timeout */}}

{{/*
Ensure that Sidekiq routingRules configuration is in a valid format
*/}}
{{- define "gitlab.checkConfig.sidekiq.routingRules" -}}
{{- $validRoutingRules := true -}}
{{- with $.Values.global.appConfig.sidekiq.routingRules }}
{{-   if not (kindIs "slice" .) }}
{{-     $validRoutingRules = false }}
{{-   else -}}
{{-     range $rule := . }}
{{-       if (not (kindIs "slice" $rule)) }}
{{-         $validRoutingRules = false }}
{{-       else if not (or (eq (len $rule) 2) (eq (len $rule) 3)) }}
{{-         $validRoutingRules = false }}
{{/*      The first item (routing query) must be a string */}}
{{-       else if not (kindIs "string" (index $rule 0)) }}
{{-         $validRoutingRules = false }}
{{/*      The second item (queue name) must be either a string or null */}}
{{-       else if not (or (kindIs "invalid" (index $rule 1)) (kindIs "string" (index $rule 1))) -}}
{{-         $validRoutingRules = false }}
{{-       end -}}
{{-       if (eq (len $rule) 3) }}
{{-         if not (or (kindIs "invalid" (index $rule 2)) (kindIs "string" (index $rule 2))) -}}
{{-           $validRoutingRules = false }}
{{-         end -}}
{{-       end -}}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- if eq false $validRoutingRules }}
sidekiq:
    The Sidekiq's routing rules list must be an ordered array of tuples of query and corresponding queue.
    See https://docs.gitlab.com/charts/charts/globals.html#sidekiq-routing-rules-settings
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.sidekiq.routingRules */}}

{{/*
Ensure that metrics and health check servers bind different ports
*/}}
{{- define "gitlab.checkConfig.sidekiq.server_ports" -}}
{{- $metricsEnabled := .Values.gitlab.sidekiq.metrics.enabled -}}
{{- $portsMatch := eq (.Values.gitlab.sidekiq.metrics.port | int) (.Values.gitlab.sidekiq.health_checks.port | int) -}}
{{- if and $metricsEnabled $portsMatch }}
sidekiq:
    metrics.port and health_checks.port must not be equal.
    See https://docs.gitlab.com/charts/charts/gitlab/sidekiq/index.html#configuration
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.sidekiq.server_ports */}}
