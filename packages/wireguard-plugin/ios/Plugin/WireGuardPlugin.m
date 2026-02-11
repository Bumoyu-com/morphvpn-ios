#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro
CAP_PLUGIN(WireGuardPlugin, "WireGuard",
    CAP_PLUGIN_METHOD(connect, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(disconnect, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getStatus, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(saveConfig, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(deleteConfig, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(listTunnels, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getExtensionLog, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(clearExtensionLog, CAPPluginReturnPromise);
)
