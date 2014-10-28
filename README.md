# Orchestration events generator

Poll for orchestation events and inject for orchestration
APIs that don't provide notifications.

## Usage

```json
{
  "jackal": {
    "orchestration_events": {
      "sources": {
        "input": {
          "type": "actor"
        },
        "output": {
          ...
        }
      },
      "callbacks": [
        "Jackal::OrchestrationEvents::Poll"
      ]
    }
  }
}
```

## Configuration

The fog orchestration model is used for accessing event
information on stacks. Multiple providers and or multiple
regions can be provided by supplying an array of hashes
instead of a single credential hash.

```json
...
"config": {
  "credentials": {
    "provider": "aws",
    "aws_secret_access_key": "KEY",
    "aws_access_key_id": "ID",
    "region": "us-east-1"
  }
}
...
```

## Info

* Repository: https://github.com/carnviore-rb/jackal-orchestration-events
* IRC: Freenode @ #carnivore
