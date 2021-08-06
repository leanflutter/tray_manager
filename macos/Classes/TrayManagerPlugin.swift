import Cocoa
import FlutterMacOS

let kEventOnTrayIconMouseDown = "onTrayIconMouseDown"
let kEventOnTrayIconMouseUp = "onTrayIconMouseUp"
let kEventOnTrayIconRightMouseDown = "onTrayIconRightMouseDown"
let kEventOnTrayIconRightMouseUp = "onTrayIconRightMouseUp"

public class TrayManagerPlugin: NSObject, FlutterPlugin, NSMenuDelegate {
    var channel: FlutterMethodChannel!
    
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    var statusItemMenu: NSMenu = NSMenu()
    
    var _inited: Bool = false;
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "tray_manager", binaryMessenger: registrar.messenger)
        let instance = TrayManagerPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
        case "getFrame":
            getFrame(call, result: result)
            break
        case "setIcon":
            setIcon(call, result: result)
            break
        case "setToolTip":
            setToolTip(call, result: result)
            break
        case "setContextMenu":
            setContextMenu(call, result: result)
            break
        case "popUpContextMenu":
            popUpContextMenu(call, result: result)
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func _init() {
        if let button = statusItem.button {
            button.action = #selector(self.statusItemButtonClicked(sender:))
            button.sendAction(on: [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp])
            button.target = self
            _inited = true
        }
    }
    
    @objc func statusItemButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        var methodName: String?
        
        switch event.type {
        case NSEvent.EventType.leftMouseDown:
            methodName = kEventOnTrayIconMouseDown
            break
        case NSEvent.EventType.leftMouseUp:
            methodName = kEventOnTrayIconMouseUp
            break
        case NSEvent.EventType.rightMouseDown:
            methodName = kEventOnTrayIconRightMouseDown
            break
        case NSEvent.EventType.rightMouseUp:
            methodName = kEventOnTrayIconRightMouseUp
            break
        default:
            break
        }
        if (methodName != nil) {
            channel.invokeMethod(methodName!, arguments: nil, result: nil)
        }
    }
    
    @objc func statusItemMenuButtonClicked(_ sender: Any?) {
        let menuItem = sender as! NSMenuItem
        channel.invokeMethod("MenuItemClicked", arguments: menuItem.tag, result: nil)
    }
    
    public func getFrame(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let origin = statusItem.button?.window?.frame.origin;
        let size =  statusItem.button?.window?.frame.size;
        
        let resultData: NSDictionary = [
            "origin_x": origin!.x,
            "origin_y": origin!.y,
            "size_width": size!.width,
            "size_height": size!.height,
        ]
        result(resultData)
    }
    
    public func setIcon(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if !_inited { _init() }
        
        let args:[String: Any] = call.arguments as! [String: Any]
        let base64Icon: String =  args["base64Icon"] as! String;
        
        let imageData = Data(base64Encoded: base64Icon, options: .ignoreUnknownCharacters)
        let image = NSImage(data: imageData!)
        image!.size = NSSize(width: 16, height: 16)
        image!.isTemplate = true
        
        if let button = statusItem.button {
            button.image = image
        }
        
        result(true)
    }
    
    public func setToolTip(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args:[String: Any] = call.arguments as! [String: Any]
        let toolTip: String =  args["toolTip"] as! String;
        
        if let button = statusItem.button {
            button.toolTip  = toolTip
        }
        
        result(true)
    }
    
    public func setContextMenu(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        statusItemMenu.removeAllItems()
        
        let args:[String: Any] = call.arguments as! [String: Any]
        let menuItems: NSMutableArray = args["menuItems"] as! NSMutableArray;
        
        for item in menuItems {
            let menuItem: NSMenuItem
            
            let itemDict = item as! [String: Any]
            let title: String = itemDict["title"] as? String ?? ""
            let toolTip: String = itemDict["toolTip"] as? String ?? ""
            let isEnabled: Bool = itemDict["isEnabled"] as? Bool ?? true
            let isSeparatorItem: Bool = itemDict["isSeparatorItem"] as! Bool
            
            if (isSeparatorItem) {
                menuItem = NSMenuItem.separator()
            } else {
                menuItem = NSMenuItem()
            }
            
            menuItem.title = title
            menuItem.toolTip = toolTip
            menuItem.isEnabled = isEnabled
            menuItem.action = isEnabled ? #selector(statusItemMenuButtonClicked) : nil
            menuItem.target = self
            
            statusItemMenu.addItem(menuItem)
        }
        result(true)
    }
    
    public func popUpContextMenu(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        statusItem.popUpMenu(statusItemMenu);
        result(true)
    }
}
