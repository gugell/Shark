import Cocoa

let path = "/Users/kaandedeoglu/Code/Noluyo/Noluyo/Images.xcassets/"
precondition(path.hasSuffix(".xcassets") || path.hasSuffix(".xcassets/"), "The path should point to a .xcassets folder")

enum Resource {
    case File(String)
    case Directory((String, [Resource]))
}

func imageResourcesAtPath(path: String) throws -> [Resource] {
    var results = [Resource]()
    let URL = NSURL.fileURLWithPath(path)
    let enumerator = NSFileManager.defaultManager().enumeratorAtURL(URL, includingPropertiesForKeys: [NSURLNameKey, NSURLIsDirectoryKey], options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, errorHandler: nil)
    
    guard let enumeratorObjects = enumerator?.allObjects as? [NSURL] else { return [] }
    
    for fileURL in enumeratorObjects {
        var directoryKey: AnyObject?
        do {
            try fileURL.getResourceValue(&directoryKey, forKey: NSURLIsDirectoryKey)
        }
        
        guard let isDirectory = directoryKey as? NSNumber else { continue }
        
        if isDirectory.integerValue == 1 {
            if fileURL.absoluteString.hasSuffix(".imageset/") {
                let name = fileURL.lastPathComponent!.componentsSeparatedByString(".imageset")[0]
                results.append(.File(name))
            } else if !fileURL.absoluteString.hasSuffix(".appiconset/") {
                do {
                    let folderName = fileURL.lastPathComponent!
                    let subResources = try imageResourcesAtPath(fileURL.relativePath!)
                    results.append(.Directory((folderName, subResources)))
                }
            }
        }
    }
    return results
}

func createEnumDeclarationForResources(resources: [Resource], indentLevel: Int) -> String {
    var resultString = ""
    for singleResource in resources {
        switch singleResource {
        case .File(let name):
            resultString += String(count: 4 * (indentLevel + 1), repeatedValue: Character(" ")) + "case \(name)\n"
        case .Directory(let (name, subResources)):
            let correctedName = name.stringByReplacingOccurrencesOfString(" ", withString: "")
            let indentationString = String(count: 4 * (indentLevel), repeatedValue: Character(" "))
            resultString += "\n" + indentationString + "public enum \(correctedName): String {"	+ "\n"
            resultString += createEnumDeclarationForResources(subResources, indentLevel: indentLevel + 1)
            resultString += indentationString + "}\n\n"
        }
    }
    return resultString
}

func acknowledgementsString() -> String {
    return "//SharkImageNames.swift\n//Generated by Shark"
}

func imageExtensionString() -> String {
    return "extension UIImage {\n    convenience init?<T: RawRepresentable where T.RawValue == String>(shark: T) {\n        self.init(named: shark.rawValue)\n    }\n}"
}

do {
    let result = try imageResourcesAtPath(path)
    let sortedResults = result.sort { first, second in
        switch first {
        case .Directory:
            return true
        case _:
            return false
        }
    }
	  var resultString = ""


    let top = Resource.Directory(("Shark", sortedResults))
        
    let enumString = createEnumDeclarationForResources([top], indentLevel: 0)
    
    resultString += acknowledgementsString()
    resultString += "\n\n"
    resultString += imageExtensionString()
    resultString += "\n"
    resultString += enumString

    print(resultString)
}

