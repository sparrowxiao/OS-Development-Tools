import Cocoa


//decode Contents.json
struct AppIcons : Decodable{
    let images: [image]
}

struct image: Decodable{
    var idiom : String
    var size : String
    var scale : String
}


//resize the image
func resize(image: NSImage, w: Int, h: Int) -> Data {
    
    //get the meta data from initial image
    let cgImage_data = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    let initialbitmapRep = NSBitmapImageRep.init(cgImage: cgImage_data!)
    //
    let info_bitmap_bitsperpixel = initialbitmapRep.bitsPerPixel
    let info_bitmap_samplesperpixel = initialbitmapRep.samplesPerPixel
    let info_bitmap_bitspersample = info_bitmap_bitsperpixel / info_bitmap_samplesperpixel
    
    //create new size for new image
    let newSize = NSMakeRect(0, 0,CGFloat(w),CGFloat(h))
    //create new bitmap representaion
    let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
        bitsPerSample: info_bitmap_bitspersample, samplesPerPixel: info_bitmap_samplesperpixel, hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)
    
    //start to draw
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep!)
    
    //#2 drawing way
    initialbitmapRep.draw(in: NSMakeRect(0, 0, newSize.width, newSize.height))
    //done
    NSGraphicsContext.restoreGraphicsState()
    
    
    //covert to Data
    let pngData : Data = bitmapRep!.representation(using: .png, properties: [:])!
    return pngData
}

let url_path = Bundle.main.url(forResource: "Contents", withExtension: "json")

let openPanel = NSOpenPanel()
openPanel.allowsMultipleSelection = false
openPanel.canChooseDirectories = false
openPanel.canCreateDirectories = false
openPanel.canChooseFiles = true
openPanel.allowedFileTypes = ["png"]

openPanel.begin{ (result) -> Void in
    if result.rawValue == NSApplication.ModalResponse.OK.rawValue{
        let image_path = openPanel.urls[0]
        let image_dir = image_path.deletingLastPathComponent()
        let ns_image = NSImage.init(contentsOf: image_path)
        let ns_img_width = ns_image?.size.width
        let ns_img_height = ns_image?.size.height
        if (Int(ns_img_width!) < 1024) || (Int(ns_img_width!) != Int(ns_img_height!)){
            print("please select the png file larger than 1024*1024!")
            return
        }
        do {
            
            let data_JSON = try Data.init(contentsOf: url_path!)
            
            let json_decoder = JSONDecoder()
            let json_Data = try json_decoder.decode(AppIcons.self, from: data_JSON)
            
            for image in json_Data.images {
                
                //for each image struct, we can get the values of it
                var x_letter_index =  image.size.firstIndex(of: "x") ?? image.size.endIndex
                let width = Double(image.size[..<x_letter_index])
                
                x_letter_index = image.scale.firstIndex(of: "x") ?? image.scale.endIndex
                let scale = Double(image.scale[..<x_letter_index])
                
                //real size to convert
                let int_width : Int  = Int(width! * scale!)
                let int_height : Int = int_width
                
                
                //save all the icon file
                //resize
                let pngData = resize(image: ns_image!, w: int_width, h: int_height)
                
                //compose the name of the file
                let str_fileName = "AppIcon-"+image.idiom+"-"+image.size+"@"+image.scale+".png"
                let newImage_path = image_dir.appendingPathComponent(str_fileName)
                
                //save the file
                try pngData.write(to: newImage_path, options: Data.WritingOptions.atomic)
                print("Icon is generated successfully!")
                
            }//FOR LOOP
            
        } catch {
            print("error:\(error)")
        }
        
    }else if result.rawValue == NSApplication.ModalResponse.cancel.rawValue{
        print("user cancelled")
    }
}

