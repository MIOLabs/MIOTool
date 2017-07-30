//
//  CreateModelSubclass.swift
//  MIOTool
//
//  Created by GodShadow on 20/05/2017.
//
//

import Foundation

func CreateModelSubClasses() -> Command? {
    
    var fileName:String? = NextArg()
    
    if fileName == nil {
        fileName = "/datamodel.xml"
    }
    
    return CreateModelSubClassesCommand(withFilename: fileName!);
}

class CreateModelSubClassesCommand : Command, XMLParserDelegate {
    
    var fileContent:String = "";
    var filename:String = "";
    
    var modelPath:String?;
    var modelFilename:String;
    
    init(withFilename filename:String) {
        
        self.modelFilename = filename;
    }
    
    override func execute() {
        
        modelPath = ModelPath();
        let modelFilePath = modelPath! + modelFilename;
        
        let parser = XMLParser(contentsOf:URL.init(fileURLWithPath:modelFilePath))
        if (parser != nil) {
            parser!.delegate = self;
            parser!.parse();
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        if (elementName == "entity") {
            
            let filename = attributeDict["name"];
            let classname = attributeDict["representedClassName"]
            
            openModelEntity(filename:filename!, classname:classname!);
        }
        else if (elementName == "attribute") {
            
            let name = attributeDict["name"];
            let type = attributeDict["attributeType"];
            let optional = attributeDict["optional"] ?? "YES";
            let defaultValue = attributeDict["defaultValueString"];
            
            appendAttribute(name:name!, type:type!, optional:optional, defaultValue: defaultValue)
        }
        else if (elementName == "relationship") {
            
            let name = attributeDict["name"];
            let optional = attributeDict["optional"] ?? "YES";
            let destinationEntity = attributeDict["destinationEntity"];
            let toMany = attributeDict["toMany"] ?? "NO"
            
            appendRelationship(name:name!, destinationEntity:destinationEntity!, toMany:toMany, optional:optional)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    
        if (elementName == "entity") {
            closeModelEntity()
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
    
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
    
    }
    
    private func openModelEntity(filename:String, classname:String) {
    
        self.filename = "/\(filename)ManagedObject.ts";
        let cn = classname + "ManagedObject";
        
        fileContent = "\n";
        fileContent += "// Generated class \(cn)\n";
        fileContent += "\n";
        fileContent += "class \(cn) extends MIOManagedObject {\n";
    }
    
    private func appendAttribute(name:String, type:String, optional:String, defaultValue:String?) {

        var dv:String;
        var t = ":" + type;
        
        if (defaultValue == nil) {
            dv = " = null;";
        }
        else {
            if (type == "String") {
                dv = " = '\(defaultValue!)';"
            }
            else if (type == "Number") {
                dv = " = \(defaultValue!);"
            }
            else if (type == "Array") {
                t = "";
                dv = " = [];"
            }
            else if (type == "Dictionary") {
                t = "";
                dv = " = {};"
            }
            else {
                dv = ";"
            }
        }
        
        fileContent += "\n";
        fileContent += "    // Property: \(name)\n";
        // Var
        fileContent += "    private _\(name)\(t)\(dv)\n";
        // Setter
        fileContent += "    set \(name)(value\(t)) {\n";
        fileContent += "        this.setValue('_\(name)', value);\n";
        fileContent += "    }\n";
    
        // Getter
        fileContent += "    get \(name)()\(t) {\n";
        fileContent += "        return this.getValue('_\(name)');\n";
        fileContent += "    }\n";
        
        // Getter raw value
        fileContent += "    get \(name)RawValue()\(t) {\n";
        fileContent += "        return this._\(name);\n";
        fileContent += "    }\n";
    }
    
    private func appendRelationship(name:String, destinationEntity:String, toMany:String, optional:String) {
    
        if (toMany == "NO") {
            appendAttribute(name:name, type:destinationEntity, optional:optional, defaultValue:nil);
        }
        else{
            
            fileContent += "\n";
            
            let first = String(name.characters.prefix(1));
            let cname = first.uppercased() + String(name.characters.dropFirst());
            
            fileContent += "    // Relationship: \(name)\n";
            // Var
            fileContent += "    private _\(name) = [\(destinationEntity)];\n";
            // Getter
            fileContent += "    get \(name)():[\(destinationEntity)]  {\n";
            fileContent += "        return this.getValue('_\(name)');\n";
            fileContent += "    }\n";
            // Add
            fileContent += "    add\(cname)Object(value:\(destinationEntity)) {\n";
            fileContent += "        this.addObject('_\(name)', value);\n";
            fileContent += "    }\n";
            // Remove
            fileContent += "    remove\(cname)Object(value:\(destinationEntity)) {\n";
            fileContent += "        this.removeObject('_\(name)', value);\n";
            fileContent += "    }\n";
            // Add objects
            fileContent += "    add\(cname)(value:[\(destinationEntity)]) {\n";
            fileContent += "        this.addObjects('_\(name)', value);\n";
            fileContent += "    }\n";
            // Remove objects
            fileContent += "    remove\(cname)(value:\(destinationEntity)) {\n";
            fileContent += "        this.removeObjects('_\(name)', value);\n";
            fileContent += "    }\n";
        }
        
    }
    
    private func closeModelEntity() {
    
        fileContent += "}\n";
        
        let path = modelPath! + filename;
        //Write to disc
        WriteTextFile(content:fileContent, path:path);
    }

}

