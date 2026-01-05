#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(PingPlugin, "Ping",
    CAP_PLUGIN_METHOD(ping, CAPPluginReturnPromise);
)
