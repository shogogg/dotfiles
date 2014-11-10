export ANDROID_HOME=/opt/local/android-sdk-macosx
export ANDROID_SDK_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
path=(
  ${ANDROID_HOME}/tools(N-/)
  ${ANDROID_HOME}/platform-tools(N-/)
  $path
)
