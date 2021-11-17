#include "include/tray_manager/tray_manager_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>
#include <map>
#include <algorithm>
#include <libappindicator/app-indicator.h>

#define TRAY_MANAGER_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), tray_manager_plugin_get_type(), \
                              TrayManagerPlugin))

TrayManagerPlugin *plugin_instance;

AppIndicator *indicator = nullptr;
GtkWidget *menu = nullptr;

struct _TrayManagerPlugin
{
  GObject parent_instance;
  FlPluginRegistrar *registrar;
  FlMethodChannel *channel;
};

G_DEFINE_TYPE(TrayManagerPlugin, tray_manager_plugin, g_object_get_type())

// Gets the window being controlled.
GtkWindow *get_window(TrayManagerPlugin *self)
{
  FlView *view = fl_plugin_registrar_get_view(self->registrar);
  if (view == nullptr)
    return nullptr;

  return GTK_WINDOW(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// internal wrapper for go callback
void _tray_callback(GtkMenuItem *item, gpointer user_data)
{

  gint id = GPOINTER_TO_INT(user_data);

  g_autoptr(FlValue) result_data = fl_value_new_map();
  fl_value_set_string_take(result_data, "id", fl_value_new_int(id));
  fl_method_channel_invoke_method(plugin_instance->channel,
                                  "onTrayMenuItemClick", result_data,
                                  nullptr, nullptr, nullptr);
}

GtkWidget *_create_context_menu(FlValue *items_value)
{
  GtkWidget *menu = gtk_menu_new();
  for (gint i = 0; i < fl_value_get_length(items_value); i++)
  {
    FlValue *menu_item_value = fl_value_get_list_value(items_value, i);
    const int id = fl_value_get_int(fl_value_lookup_string(menu_item_value, "id"));
    const char *title = fl_value_get_string(fl_value_lookup_string(menu_item_value, "title"));
    const bool is_enabled = fl_value_get_bool(fl_value_lookup_string(menu_item_value, "isEnabled"));
    const bool is_separator_item = fl_value_get_bool(fl_value_lookup_string(menu_item_value, "isSeparatorItem"));
    const auto sub_items = fl_value_lookup_string(menu_item_value, "items");

    gint item_id = id;

    if (is_separator_item)
    {
      gtk_menu_shell_append(GTK_MENU_SHELL(menu), gtk_separator_menu_item_new());
    }
    else
    {
      GtkWidget *item = gtk_menu_item_new_with_label(title);
      if (!is_enabled)
        gtk_widget_set_sensitive(item, FALSE);

      g_signal_connect(G_OBJECT(item), "activate", G_CALLBACK(_tray_callback), GINT_TO_POINTER(item_id));

      if (fl_value_get_length(sub_items) > 0)
      {
        GtkWidget *sub_menu = _create_context_menu(sub_items);
        gtk_menu_item_set_submenu(GTK_MENU_ITEM(item), sub_menu);
      }
      gtk_menu_shell_append(GTK_MENU_SHELL(menu), item);
    }
  }
  return menu;
}

static FlMethodResponse *destroy(TrayManagerPlugin *self,
                                 FlValue *args)
{
  if (!(!indicator))
  {
    app_indicator_set_status(indicator, APP_INDICATOR_STATUS_PASSIVE);
  }
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
}

static FlMethodResponse *set_icon(TrayManagerPlugin *self,
                                  FlValue *args)
{
  const char *id = fl_value_get_string(fl_value_lookup_string(args, "id"));
  const char *icon_path = fl_value_get_string(fl_value_lookup_string(args, "iconPath"));

  if (!menu)
    menu = gtk_menu_new();

  if (!indicator)
  {
    indicator = app_indicator_new(id, icon_path, APP_INDICATOR_CATEGORY_APPLICATION_STATUS);

    app_indicator_set_menu(indicator, GTK_MENU(menu));
    gtk_widget_show_all(menu);
  }

  app_indicator_set_status(indicator, APP_INDICATOR_STATUS_ACTIVE);
  app_indicator_set_icon(indicator, icon_path);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
}

static FlMethodResponse *set_context_menu(TrayManagerPlugin *self,
                                          FlValue *args)
{
  FlValue *items_value = fl_value_lookup_string(args, "items");
  menu = _create_context_menu(items_value);

  app_indicator_set_menu(indicator, GTK_MENU(menu));
  gtk_widget_show_all(menu);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
}

// Called when a method call is received from Flutter.
static void tray_manager_plugin_handle_method_call(
    TrayManagerPlugin *self,
    FlMethodCall *method_call)
{
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar *method = fl_method_call_get_name(method_call);
  FlValue *args = fl_method_call_get_args(method_call);

  if (strcmp(method, "destroy") == 0)
  {
    response = destroy(self, args);
  }
  else if (strcmp(method, "setIcon") == 0)
  {
    response = set_icon(self, args);
  }
  else if (strcmp(method, "setContextMenu") == 0)
  {
    response = set_context_menu(self, args);
  }
  else
  {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void tray_manager_plugin_dispose(GObject *object)
{
  G_OBJECT_CLASS(tray_manager_plugin_parent_class)->dispose(object);
}

static void tray_manager_plugin_class_init(TrayManagerPluginClass *klass)
{
  G_OBJECT_CLASS(klass)->dispose = tray_manager_plugin_dispose;
}

static void tray_manager_plugin_init(TrayManagerPlugin *self) {}

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call,
                           gpointer user_data)
{
  TrayManagerPlugin *plugin = TRAY_MANAGER_PLUGIN(user_data);
  tray_manager_plugin_handle_method_call(plugin, method_call);
}

void tray_manager_plugin_register_with_registrar(FlPluginRegistrar *registrar)
{
  TrayManagerPlugin *plugin = TRAY_MANAGER_PLUGIN(
      g_object_new(tray_manager_plugin_get_type(), nullptr));

  plugin->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "tray_manager",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(plugin->channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  plugin_instance = plugin;

  g_object_unref(plugin);
}
