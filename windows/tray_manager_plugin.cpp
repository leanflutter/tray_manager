#include "include/tray_manager/tray_manager_plugin.h"

// This must be included before many other Windows headers.
#include <stdio.h>
#include <windows.h>

#include <shellapi.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <codecvt>
#include <map>
#include <memory>
#include <sstream>

#define WM_MYMESSAGE (WM_USER + 1)

namespace
{
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>,
                std::default_delete<flutter::MethodChannel<flutter::EncodableValue>>>
    channel = nullptr;

class TrayManagerPlugin : public flutter::Plugin
{
  public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

    TrayManagerPlugin(flutter::PluginRegistrarWindows *registrar);

    virtual ~TrayManagerPlugin();

  private:
    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> g_converter;

    flutter::PluginRegistrarWindows *registrar;
    NOTIFYICONDATA nid;
    NOTIFYICONIDENTIFIER niif;
    HMENU hMenu;
    bool tray_icon_setted = false;

    // The ID of the WindowProc delegate registration.
    int window_proc_id = -1;

    void TrayManagerPlugin::_CreateContextMenu(HMENU menu, flutter::EncodableMap args);

    // Called for top-level WindowProc delegation.
    std::optional<LRESULT> TrayManagerPlugin::HandleWindowProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);
    HWND TrayManagerPlugin::GetMainWindow();
    void TrayManagerPlugin::Destroy(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
    void TrayManagerPlugin::SetIcon(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
    void TrayManagerPlugin::SetContextMenu(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                                           std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
    void TrayManagerPlugin::PopUpContextMenu(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                                             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
    void TrayManagerPlugin::GetBounds(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                                      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

// static
void TrayManagerPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar)
{
    channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "tray_manager", &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<TrayManagerPlugin>(registrar);

    channel->SetMethodCallHandler([plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
    });

    registrar->AddPlugin(std::move(plugin));
}

TrayManagerPlugin::TrayManagerPlugin(flutter::PluginRegistrarWindows *registrar) : registrar(registrar)
{
    window_proc_id =
        registrar->RegisterTopLevelWindowProcDelegate([this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
            return HandleWindowProc(hwnd, message, wparam, lparam);
        });
}

TrayManagerPlugin::~TrayManagerPlugin()
{
    registrar->UnregisterTopLevelWindowProcDelegate(window_proc_id);
}

void TrayManagerPlugin::_CreateContextMenu(HMENU menu, flutter::EncodableMap args)
{
    flutter::EncodableList items = std::get<flutter::EncodableList>(args.at(flutter::EncodableValue("items")));

    int count = GetMenuItemCount(menu);
    for (int i = 0; i < count; i++)
    {
        // always remove at 0 because they shift every time
        RemoveMenu(menu, 0, MF_BYPOSITION);
    }

    for (flutter::EncodableValue item_value : items)
    {
        flutter::EncodableMap item_map = std::get<flutter::EncodableMap>(item_value);
        int id = std::get<int>(item_map.at(flutter::EncodableValue("id")));
        std::string title = std::get<std::string>(item_map.at(flutter::EncodableValue("title")));
        bool is_enabled = std::get<bool>(item_map.at(flutter::EncodableValue("isEnabled")));
        bool is_separator_item = std::get<bool>(item_map.at(flutter::EncodableValue("isSeparatorItem")));

        UINT_PTR item_id = id;

        if (is_separator_item)
        {
            AppendMenuW(hMenu, MF_SEPARATOR, item_id, NULL);
        }
        else
        {
            UINT uFlags = MF_STRING;
            if (!is_enabled)
            {
                uFlags |= MF_GRAYED;
            }

            flutter::EncodableList sub_items =
                std::get<flutter::EncodableList>(item_map.at(flutter::EncodableValue("items")));

            if (sub_items.size() > 0)
            {
                uFlags |= MF_POPUP;
                HMENU sub_menu = ::CreatePopupMenu();
                _CreateContextMenu(sub_menu, item_map);
                item_id = reinterpret_cast<UINT_PTR>(sub_menu);
            }

            AppendMenuW(menu, uFlags, item_id, g_converter.from_bytes(title).c_str());
        }
    }
}

std::optional<LRESULT> TrayManagerPlugin::HandleWindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    std::optional<LRESULT> result;
    if (message == WM_DESTROY)
    {
        if (tray_icon_setted)
        {
            Shell_NotifyIcon(NIM_DELETE, &nid);
            DestroyIcon(nid.hIcon);
        }
    }
    else if (message == WM_COMMAND)
    {
        flutter::EncodableMap eventData = flutter::EncodableMap();
        eventData[flutter::EncodableValue("id")] = flutter::EncodableValue((int)wParam);

        channel->InvokeMethod("onTrayMenuItemClick", std::make_unique<flutter::EncodableValue>(eventData));
    }
    else if (message == WM_MYMESSAGE)
    {
        switch (lParam)
        {
        case WM_LBUTTONUP:
            channel->InvokeMethod("onTrayIconMouseDown", std::make_unique<flutter::EncodableValue>(nullptr));
            break;
        case WM_RBUTTONUP:
            channel->InvokeMethod("onTrayIconRightMouseDown", std::make_unique<flutter::EncodableValue>(nullptr));
            break;
        default:
            return DefWindowProc(hWnd, message, wParam, lParam);
        };
    }
    return result;
}

HWND TrayManagerPlugin::GetMainWindow()
{
    return ::GetAncestor(registrar->GetView()->GetNativeWindow(), GA_ROOT);
}

void TrayManagerPlugin::Destroy(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                                std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
    Shell_NotifyIcon(NIM_DELETE, &nid);
    DestroyIcon(nid.hIcon);
    tray_icon_setted = false;

    result->Success(flutter::EncodableValue(true));
}

void TrayManagerPlugin::SetIcon(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                                std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
    const flutter::EncodableMap &args = std::get<flutter::EncodableMap>(*method_call.arguments());

    std::string iconPath = std::get<std::string>(args.at(flutter::EncodableValue("iconPath")));

    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;

    HICON hIcon =
        static_cast<HICON>(LoadImage(nullptr, (LPCWSTR)(converter.from_bytes(iconPath).c_str()), IMAGE_ICON,
                                     GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON), LR_LOADFROMFILE));

    if (tray_icon_setted)
    {
        nid.hIcon = hIcon;
        Shell_NotifyIcon(NIM_MODIFY, &nid);
    }
    else
    {
        nid.cbSize = sizeof(NOTIFYICONDATA);
        nid.hWnd = GetMainWindow();
        // nid.uID = 100;
        nid.uCallbackMessage = WM_MYMESSAGE;
        nid.hIcon = hIcon;
        nid.uFlags = NIF_MESSAGE | NIF_ICON;
        Shell_NotifyIcon(NIM_ADD, &nid);
        hMenu = CreatePopupMenu();
    }

    niif.cbSize = sizeof(NOTIFYICONIDENTIFIER);
    niif.hWnd = nid.hWnd;
    niif.uID = nid.uID;
    niif.guidItem = GUID_NULL;

    tray_icon_setted = true;

    result->Success(flutter::EncodableValue(true));
}

void TrayManagerPlugin::SetContextMenu(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                                       std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
    const flutter::EncodableMap &args = std::get<flutter::EncodableMap>(*method_call.arguments());

    flutter::EncodableList menuItemList = std::get<flutter::EncodableList>(args.at(flutter::EncodableValue("items")));

    hMenu = CreatePopupMenu();
    _CreateContextMenu(hMenu, args);

    result->Success(flutter::EncodableValue(true));
}

void TrayManagerPlugin::PopUpContextMenu(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                                         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
    HWND hWnd = GetMainWindow();

    double x, y;

    // RECT rect;
    // Shell_NotifyIconGetRect(&niif, &rect);

    // x = rect.left + ((rect.right - rect.left) / 2);
    // y = rect.top + ((rect.bottom - rect.top) / 2);

    POINT cursorPos;
    GetCursorPos(&cursorPos);
    x = cursorPos.x;
    y = cursorPos.y;

    SetForegroundWindow(hWnd);
    TrackPopupMenu(hMenu, TPM_BOTTOMALIGN | TPM_LEFTALIGN, static_cast<int>(x), static_cast<int>(y), 0, hWnd, NULL);
    result->Success(flutter::EncodableValue(true));
}

void TrayManagerPlugin::GetBounds(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                                  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
    const flutter::EncodableMap &args = std::get<flutter::EncodableMap>(*method_call.arguments());

    double devicePixelRatio = std::get<double>(args.at(flutter::EncodableValue("devicePixelRatio")));

    RECT rect;
    Shell_NotifyIconGetRect(&niif, &rect);
    flutter::EncodableMap resultMap = flutter::EncodableMap();

    double x = rect.left / devicePixelRatio * 1.0f;
    double y = rect.top / devicePixelRatio * 1.0f;
    double width = (rect.right - rect.left) / devicePixelRatio * 1.0f;
    double height = (rect.bottom - rect.top) / devicePixelRatio * 1.0f;

    resultMap[flutter::EncodableValue("x")] = flutter::EncodableValue(x);
    resultMap[flutter::EncodableValue("y")] = flutter::EncodableValue(y);
    resultMap[flutter::EncodableValue("width")] = flutter::EncodableValue(width);
    resultMap[flutter::EncodableValue("height")] = flutter::EncodableValue(height);

    result->Success(flutter::EncodableValue(resultMap));
}

void TrayManagerPlugin::HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                                         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
    if (method_call.method_name().compare("destroy") == 0)
    {
        Destroy(method_call, std::move(result));
    }
    else if (method_call.method_name().compare("setIcon") == 0)
    {
        SetIcon(method_call, std::move(result));
    }
    else if (method_call.method_name().compare("setContextMenu") == 0)
    {
        SetContextMenu(method_call, std::move(result));
    }
    else if (method_call.method_name().compare("popUpContextMenu") == 0)
    {
        PopUpContextMenu(method_call, std::move(result));
    }
    else if (method_call.method_name().compare("getBounds") == 0)
    {
        GetBounds(method_call, std::move(result));
    }
    else
    {
        result->NotImplemented();
    }
}

} // namespace

void TrayManagerPluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar)
{
    TrayManagerPlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarManager::GetInstance()->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
