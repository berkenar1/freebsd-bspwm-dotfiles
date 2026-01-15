#include "settings.hpp"

const char* const APP_NAME{"polybar"};
const char* const APP_VERSION{"3.7.2-33-ga5dfcfb6-dev"};

const int SINK_PRIORITY_BAR{1};
const int SINK_PRIORITY_SCREEN{2};
const int SINK_PRIORITY_TRAY{3};
const int SINK_PRIORITY_MODULE{4};

const char* const ALSA_SOUNDCARD{"default"};
const char* const BSPWM_SOCKET_PATH{"/tmp/bspwm_0_0-socket"};
const char* const BSPWM_STATUS_PREFIX{"W"};
const char* const CONNECTION_TEST_IP{"8.8.8.8"};
const char* const PATH_ADAPTER{"/sys/class/power_supply/%adapter%"};
const char* const PATH_BACKLIGHT{"/sys/class/backlight/%card%"};
const char* const PATH_BATTERY{"/sys/class/power_supply/%battery%"};
const char* const PATH_CPU_INFO{"/proc/stat"};
const char* const PATH_MEMORY_INFO{"/proc/meminfo"};
const char* const PATH_MESSAGING_FIFO{"/tmp/polybar_mqueue.%pid%"};
const char* const PATH_TEMPERATURE_INFO{"/sys/class/thermal/thermal_zone%zone%/temp"};
const char* const PATH_THERMAL_ZONE_WILDCARD{"/sys/class/thermal/thermal_zone*"};
const char* const WIRELESS_LIB{"wireless-tools"};

bool version_details(const std::vector<std::string>& args) {
  for (auto&& arg : args) {
    if (arg.compare(0, 3, "-vv") == 0)
      return true;
  }
  return false;
}

// clang-format off
void print_build_info(bool extended) {
  printf("%s %s\n\n", APP_NAME, APP_VERSION);
  printf("Features: %calsa %ccurl %ci3 %cmpd %cnetwork(%s) %cpulseaudio %cxkeyboard\n",
    (ENABLE_ALSA       ? '+' : '-'),
    (ENABLE_CURL       ? '+' : '-'),
    (ENABLE_I3         ? '+' : '-'),
    (ENABLE_MPD        ? '+' : '-'),
    (ENABLE_NETWORK    ? '+' : '-'),
    WIRELESS_LIB,
    (ENABLE_PULSEAUDIO ? '+' : '-'),
    (ENABLE_XKEYBOARD  ? '+' : '-'));
  if (extended) {
    printf("\n");
    printf("X extensions: %crandr (%cmonitors) %ccomposite %cxkb %cxrm %cxcursor\n",
      (WITH_XRANDR            ? '+' : '-'),
      (WITH_XRANDR_MONITORS   ? '+' : '-'),
      (WITH_XCOMPOSITE        ? '+' : '-'),
      (WITH_XKB               ? '+' : '-'),
      (WITH_XRM               ? '+' : '-'),
      (WITH_XCURSOR           ? '+' : '-'));
    printf("\n");
    printf("Build type: Debug\n");
    printf("Compiler: /usr/local/libexec/ccache/clang++\n");
    printf("Compiler flags:  -g -Wall -Wextra -Wpedantic -Wdeprecated-copy-dtor -Wsuggest-override -D_WITH_DPRINTF -Wno-c99-extensions -Wno-error=parentheses-equality -Wno-zero-length-array -DDEBUG -g2 -Og\n");
    printf("Linker flags:  -L/usr/local/lib -Wall -Wextra -Wpedantic -Wdeprecated-copy-dtor -Wsuggest-override -D_WITH_DPRINTF -Wno-c99-extensions -Wno-error=parentheses-equality -Wno-zero-length-array -DDEBUG -g2 -Og  -L/usr/local/lib -Wall -Wextra -Wpedantic -Wdeprecated-copy-dtor -Wsuggest-override -D_WITH_DPRINTF -Wno-c99-extensions -Wno-error=parentheses-equality -Wno-zero-length-array -DDEBUG -g2 -Og\n");
  }
}
// clang-format on

// vim:ft=cpp
