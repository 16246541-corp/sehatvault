#include "flutter_window.h"

#include <optional>
#include <iostream>

#include "flutter/generated_plugin_registrant.h"

#define WM_TRAY_ICON (WM_USER + 1)

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "com.sehatlocker/system_tray",
      &flutter::StandardMethodCodec::GetInstance());

  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() == "initTray") {
          SetupTray(call, std::move(result));
        } else if (call.method_name() == "updateTray") {
          UpdateTray(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  notification_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "com.sehatlocker/desktop_notifications",
      &flutter::StandardMethodCodec::GetInstance());

  notification_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() == "isDoNotDisturbEnabled") {
            QUERY_USER_NOTIFICATION_STATE state;
            if (SHQueryUserNotificationState(&state) == S_OK) {
                // QUNS_BUSY, QUNS_RUNNING_D3D_FULL_SCREEN, QUNS_PRESENTATION_MODE are effectively DND
                bool is_dnd = (state == QUNS_BUSY || state == QUNS_PRESENTATION_MODE || state == QUNS_RUNNING_D3D_FULL_SCREEN);
                result->Success(flutter::EncodableValue(is_dnd));
            } else {
                result->Success(flutter::EncodableValue(false));
            }
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::SetupTray(const flutter::MethodCall<flutter::EncodableValue>& method_call,
                             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  nid_.hWnd = GetNativeWindow();
  nid_.uID = 1;
  nid_.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  nid_.uCallbackMessage = WM_TRAY_ICON;
  nid_.hIcon = LoadIcon(GetModuleHandle(NULL), IDI_APPLICATION);
  
  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (args) {
    auto tooltip_it = args->find(flutter::EncodableValue("tooltip"));
    if (tooltip_it != args->end()) {
        std::string tooltip = std::get<std::string>(tooltip_it->second);
        std::wstring wtooltip(tooltip.begin(), tooltip.end());
        wcsncpy_s(nid_.szTip, wtooltip.c_str(), _countof(nid_.szTip));
    }
  }

  Shell_NotifyIcon(NIM_ADD, &nid_);
  result->Success();
}

void FlutterWindow::UpdateTray(const flutter::MethodCall<flutter::EncodableValue>& method_call,
                              std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (!args) {
    result->Error("INVALID_ARGUMENTS", "Arguments must be a map");
    return;
  }

  auto tooltip_it = args->find(flutter::EncodableValue("tooltip"));
  if (tooltip_it != args->end()) {
      std::string tooltip = std::get<std::string>(tooltip_it->second);
      std::wstring wtooltip(tooltip.begin(), tooltip.end());
      wcsncpy_s(nid_.szTip, wtooltip.c_str(), _countof(nid_.szTip));
  }

  auto menu_it = args->find(flutter::EncodableValue("menuItems"));
  if (menu_it != args->end()) {
      current_menu_items_.clear();
      const auto& items = std::get<flutter::EncodableList>(menu_it->second);
      for (const auto& item : items) {
          current_menu_items_.push_back(std::get<flutter::EncodableMap>(item));
      }
  }

  Shell_NotifyIcon(NIM_MODIFY, &nid_);
  result->Success();
}

void FlutterWindow::ShowTrayMenu() {
    HMENU hMenu = CreatePopupMenu();
    for (size_t i = 0; i < current_menu_items_.size(); ++i) {
        const auto& item = current_menu_items_[i];
        auto type_it = item.find(flutter::EncodableValue("type"));
        if (type_it != item.end() && std::get<std::string>(type_it->second) == "separator") {
            AppendMenu(hMenu, MF_SEPARATOR, 0, NULL);
            continue;
        }

        std::string label = std::get<std::string>(item.at(flutter::EncodableValue("label")));
        std::wstring wlabel(label.begin(), label.end());
        bool enabled = std::get<bool>(item.at(flutter::EncodableValue("enabled")));
        
        UINT flags = MF_STRING;
        if (!enabled) flags |= MF_GRAYED;
        
        AppendMenu(hMenu, flags, i + 1000, wlabel.c_str());
    }

    POINT pt;
    GetCursorPos(&pt);
    SetForegroundWindow(GetNativeWindow());
    int id = TrackPopupMenu(hMenu, TPM_RETURNCMD | TPM_NONOTIFY, pt.x, pt.y, 0, GetNativeWindow(), NULL);
    
    if (id >= 1000) {
        size_t index = id - 1000;
        std::string action_id = std::get<std::string>(current_menu_items_[index].at(flutter::EncodableValue("id")));
        channel_->InvokeMethod("onTrayMenuItemClick", std::make_unique<flutter::EncodableValue>(action_id));
    }
    
    DestroyMenu(hMenu);
}

void FlutterWindow::OnDestroy() {
  Shell_NotifyIcon(NIM_DELETE, &nid_);
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_TRAY_ICON:
      if (lparam == WM_RBUTTONUP || lparam == WM_LBUTTONUP) {
          ShowTrayMenu();
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
