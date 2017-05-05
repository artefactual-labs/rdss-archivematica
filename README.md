# rdss-archivematica

Integration repo for the RDSS fork of Archivematica.

## Source management

Currently, it is expected that the user clones the corresponding git
repositories manually. They're expected to be located under the `src/`
directory. You can use `make clone` to clone the repositories.

URL | Branch | Components
--- | ------ | ----------
https://github.com/JiscRDSS/archivematica | qa/jisc | MCPServer, MCPClient, Dashboard
https://github.com/JiscRDSS/archivematica-storage-service | qa/jisc | Storage Service
https://github.com/artefactual/archivematica-sampledata | master | Sample data

## Development

Open [the compose/dev folder](compose/dev) to see more details.

## AWS deployment

#### Docker Machine + Amazon EC2

Deployment of the development environment in a single EC2 instance supported by Docker Machine.

Open [the aws/machine folder](aws/machine) to see more details.
