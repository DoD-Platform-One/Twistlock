### Elasticsearch configuration

Before running the configuration, be sure to have [Defender installed](overview.md#install-defender-from-the-console-ui).

create an index pattern for fluentd if not already created

```
logstash-*
```

Build filter for twistlock namespace

```
{
  "query": {
    "match_phrase": {
      "kubernetes.namespace_name": "twistlock"
    }
  }
}
```

There should be 4 pods in the twistlock namespace

```
kubectl get pods -n twistlock
NAME                                READY   STATUS    RESTARTS   AGE
twistlock-console-random-number      1/1     Running   0          3h13m
twistlock-defender-random-number     1/1     Running   0          5s
twistlock-defender-random-number     1/1     Running   0          5s
twistlock-defender-random-number     1/1     Running   0          5s
```

:warning: **CAUTION**:
If you only have one pod in the twistlock namespace, the defender did not install properly or at all. Run the steps to install defender again before continuing on.

Here are some examples of a filter for specific containers

twistlock-console

```
{
  "query": {
    "match_phrase": {
      kubernetes.container_name:twistlock-console
    }
  }
}
```

twistlock-defender

```
{
  "query": {
    "match_phrase": {
      kubernetes.labels.app:twistlock-defender
    }
  }
}
```

In the KQL field you can text search within a source field such as twistlock-defender

```
kubernetes.labels.app: "twistlock-defender"
```

```
kubernetes.namespace_name:twistlock kubernetes.labels.app:twistlock-defender stream:stdout log: F [31m ERRO 2020-07-14T19:13:25.646 defender.go:331 [0m Failed to initialize GeoLite2 db: open /prisma-static-data/GeoLite2-Country.mmdb: no such file or directory docker.container_id:c0f14b6ba111ef0af3761484dd77a19a5a9f054a4853f757d303be838cad6e6a kubernetes.container_name:twistlock-defender kubernetes.pod_name:twistlock-defender-ds-dtdjv kubernetes.container_image:registry-auth.twistlock.com/tw_bbzc81abegfiqtnruvspkazws2ze0dby/twistlock/defender:defender_20_04_169 kubernetes.container_image_id:registry-
```

```
kubernetes.container_name:twistlock-console
```

```
kubernetes.container_name:twistlock-console kubernetes.namespace_name:twistlock stream:stdout log: F [31m ERRO 2020-07-14T20:01:10.932 kubernetes_profile_resolver.go:38 [0m Failed to fetch Istio resources in 863da02e-15f2-d3da-f74d-0256f77292ad: 1 error occurred: docker.container_id:8303db1aa9e2a694b5db5a454c07127944ee0a4799f3e15f190eaa0eec53ca63 kubernetes.pod_name:twistlock-console-7d77c954d-lnjxp kubernetes.container_image:registry.dso.mil/platform-one/apps/twistlock/console:20.04.169 kubernetes.container_image_id:registry.dso.mil/platform-one/apps/twistlock/console@sha256:db77c64af682161c52da2bbee5fb55f38c0bcd46cacdb4c1148f24d094f18a10 kubernetes.pod_id:c979ebe6-f636-41b8-bfff-eab27fd48692
```

```
