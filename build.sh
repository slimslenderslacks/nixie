clj -T:build uber
$GRAALVM_HOME/bin/native-image -jar target/nixie-standalone.jar nixie -H:-CheckToolchain -H:+ReportExceptionStackTraces --native-image-info --no-fallback --initialize-at-build-time --verbose -J-Xmx8g --enable-http --enable-https -H:ReflectionConfigurationFiles=reflect-config.json
