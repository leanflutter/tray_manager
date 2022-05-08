import Cocoa
import FlutterMacOS

let kEventOnTrayIconMouseDown = "onTrayIconMouseDown"
let kEventOnTrayIconMouseUp = "onTrayIconMouseUp"
let kEventOnTrayIconRightMouseDown = "onTrayIconRightMouseDown"
let kEventOnTrayIconRightMouseUp = "onTrayIconRightMouseUp"
let kEventOnTrayMenuItemClick = "onTrayMenuItemClick"

extension NSRect {
    var topLeft: CGPoint {
        set {
            let screenFrameRect = NSScreen.main!.frame
            origin.x = newValue.x
            origin.y = screenFrameRect.height - newValue.y - size.height
        }
        get {
            let screenFrameRect = NSScreen.main!.frame
            return CGPoint(x: origin.x, y: screenFrameRect.height - origin.y - size.height)
        }
    }
}

public class TrayManagerPlugin: NSObject, FlutterPlugin, NSMenuDelegate {
    var channel: FlutterMethodChannel!
    
    var statusItem: NSStatusItem = NSStatusItem();
    var statusItemMenu: TrayMenu?
    
    var _inited: Bool = false;
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "tray_manager", binaryMessenger: registrar.messenger)
        let instance = TrayManagerPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "destroy":
            destroy(call, result: result)
            break
        case "getBounds":
            getBounds(call, result: result)
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
        statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
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
    
    public func destroy(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSStatusBar.system.removeStatusItem(statusItem)
        _inited = false
        result(true)
    }
    
    public func getBounds(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let frame = statusItem.button?.window?.frame;
        
        let resultData: NSDictionary = [
            "x": frame!.topLeft.x,
            "y": frame!.topLeft.y,
            "width": frame!.size.width,
            "height": frame!.size.height,
        ]
        result(resultData)
    }
    
    public func setIcon(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if !_inited { _init() }
        
        let args:[String: Any] = call.arguments as! [String: Any]
        let base64Icon: String =  args["base64Icon"] as! String;
        let isTemplate: Bool =  args["isTemplate"] as! Bool;
        
        let imageData = Data(base64Encoded: base64Icon, options: .ignoreUnknownCharacters)
        let image = NSImage(data: imageData!)
        image!.size = NSSize(width: 18, height: 18)
        image!.isTemplate = isTemplate
        
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
        let args:[String: Any] = call.arguments as! [String: Any]
        statusItemMenu = TrayMenu(args["menu"] as! [String: Any])
        statusItemMenu?.onMenuItemClick = {
            (menuItem: NSMenuItem) in
            let args: NSDictionary = [
                "id": menuItem.tag,
            ]
            self.channel.invokeMethod(kEventOnTrayMenuItemClick, arguments: args, result: nil)
        }
        statusItemMenu?.delegate = self
        statusItem.menu = statusItemMenu
        result(true)
    }
    
    public func popUpContextMenu(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        statusItem.button?.performClick(nil)
        result(true)
    }
    
    // NSMenuDelegate
    
    public func menuDidClose(_ menu: NSMenu) {
        
    }
}
