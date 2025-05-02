import Flutter
import UIKit
import PythonKit

public class PythonBridgePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.playpulse/python", binaryMessenger: registrar.messenger())
        let instance = PythonBridgePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initializePython":
            initializePython(result: result)
        case "executePython":
            executePython(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initializePython(result: @escaping FlutterResult) {
        do {
            let bundle = Bundle.main
            guard let pythonPath = bundle.path(forResource: "python", ofType: nil) else {
                throw NSError(domain: "PythonBridgeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Python directory not found"])
            }
            
            // Set Python paths
            setenv("PYTHONHOME", pythonPath, 1)
            setenv("PYTHONPATH", "\(pythonPath):\(FileManager.default.temporaryDirectory.path)", 1)
            
            // Initialize Python
            Python.initialize()
            
            result(true)
        } catch {
            result(FlutterError(code: "PYTHON_INIT_ERROR", message: "Failed to initialize Python: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func executePython(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let moduleName = args["module"] as? String,
              let functionName = args["function"] as? String else {
            result(FlutterError(code: "ARGUMENT_ERROR", message: "Invalid arguments", details: nil))
            return
        }
        
        let functionArgs = args["args"] as? [Any] ?? []
        
        do {
            // Import Python module
            let sys = Python.import("sys")
            guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path else {
                throw NSError(domain: "PythonBridgeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
            }
            
            let pythonDir = "\(documentsPath)/python"
            sys.path.append(pythonDir)
            
            // Import the specified module
            let module = Python.import(moduleName)
            
            // Call the specified function with arguments
            var pyResult: PythonObject
            if functionArgs.isEmpty {
                pyResult = module[dynamicMember: functionName]()
            } else {
                // Convert Swift args to Python args
                let pyArgs = functionArgs.map { swiftToPython($0) }
                pyResult = module[dynamicMember: functionName](args: pyArgs)
            }
            
            // Convert Python result to Swift
            let swiftResult = pythonToSwift(pyResult)
            result(swiftResult)
        } catch {
            result(FlutterError(code: "PYTHON_EXEC_ERROR", message: "Failed to execute Python code: \(error.localizedDescription)", details: nil))
        }
    }
    
    // Helper function to convert Swift objects to Python objects
    private func swiftToPython(_ value: Any) -> PythonObject {
        if let string = value as? String {
            return Python.str(string)
        } else if let number = value as? Int {
            return Python.int(number)
        } else if let number = value as? Double {
            return Python.float(number)
        } else if let bool = value as? Bool {
            return Python.bool(bool)
        } else if let array = value as? [Any] {
            let pyList = Python.list()
            for item in array {
                pyList.append(swiftToPython(item))
            }
            return pyList
        } else if let dict = value as? [String: Any] {
            let pyDict = Python.dict()
            for (key, val) in dict {
                pyDict[key] = swiftToPython(val)
            }
            return pyDict
        } else {
            return Python.None
        }
    }
    
    // Helper function to convert Python objects to Swift objects
    private func pythonToSwift(_ value: PythonObject) -> Any {
        if Python.isinstance(value, Python.str) {
            return String(value)!
        } else if Python.isinstance(value, Python.int) {
            return Int(value)!
        } else if Python.isinstance(value, Python.float) {
            return Double(value)!
        } else if Python.isinstance(value, Python.bool) {
            return Bool(value)!
        } else if Python.isinstance(value, Python.list) || Python.isinstance(value, Python.tuple) {
            var array: [Any] = []
            for item in value {
                array.append(pythonToSwift(item))
            }
            return array
        } else if Python.isinstance(value, Python.dict) {
            var dict: [String: Any] = [:]
            for (key, val) in value.items() {
                if let keyStr = String(key) {
                    dict[keyStr] = pythonToSwift(val)
                }
            }
            return dict
        } else {
            return String(describing: value)!
        }
    }
}