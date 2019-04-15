# /etc/profile.d/rstudio-gpu.sh
#
# If running under X2GO, we must disable OpenGL rendering
# or R-Studio will just crash
#

[ -z "$X2GO_AGENT_PID" ] || export RSTUDIO_CHROMIUM_ARGUMENTS="--disable-gpu"
