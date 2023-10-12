# Video Processing flows with Orkes
This project contains a list of workers for the following video processing use cases

1. Video Transcoding
2. Video Watermarking
3. Automatic Subtitle Generation
4. Thumbnail / Artwork Generation from Videos

## Pre-Requistes
### Installing FFMPEG

#### MacOS
```shell
brew install ffmpeg
```


#### Other Operating Systems
```shell
https://www.hostinger.com/tutorials/how-to-install-ffmpeg
```

## Generating Access Keys
```shell
https://orkes.io/content/access-control-and-security/applications#generating-access-keys
```

## Download this project
```shell
https://github.com/orkes-io/orkes-templates/tree/main/video-processing-flows
```
This is a springboot application. You can build and run projecct using gradle
```shell
gradle clean build
gradle bootRun
```

All the Associated task workers are bundled with this project in the src/main/java/io/orkes/samples/workers folder
When the Spring Boot Application comes up you can see the workers pool the conductor cluster for work in the console

The Conductor cluster details and the access keys are specified in the
src/main/resources/application.properties file

## Download this project
Go to the Conductor UI and run the workflow with the specified inputs as specified in the following documentation pages

TODO: add doc links here



