// Chromium sub-process entry (renderer, GPU, network, ...). One binary, copied
// into the 5 "nhetrinh-b Helper (*)" bundles macOS Chromium requires.
#include "include/cef_app.h"
#include "include/wrapper/cef_library_loader.h"

int main(int argc, char* argv[]) {
  CefScopedLibraryLoader loader;
  if (!loader.LoadInHelper()) return 1;
  CefMainArgs args(argc, argv);
  return CefExecuteProcess(args, nullptr, nullptr);
}
