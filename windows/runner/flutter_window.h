#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <memory>

#include "win32_window.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <shellapi.h>

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void SetupTray(const flutter::MethodCall<flutter::EncodableValue>& method_call,
                 std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void UpdateTray(const flutter::MethodCall<flutter::EncodableValue>& method_call,
                  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void ShowTrayMenu();

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> notification_channel_;
  
  NOTIFYICONDATA nid_ = { sizeof(NOTIFYICONDATA) };
  std::vector<flutter::EncodableMap> current_menu_items_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
