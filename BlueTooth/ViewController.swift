
//
//  ViewController.swift
//  BlueTooth
//
//  Created by apple on 16/1/1.
//  Copyright © 2016年 apple. All rights reserved.
//

import UIKit
import CoreBluetooth

let MOVE = "Oxff550700020501ffff00"
let BACK = "Oxff5507000205ff0001ff"


class ViewController: UIViewController,CBCentralManagerDelegate,CBPeripheralDelegate{

    
    var centralManager:CBCentralManager!
    var preipheral:CBPeripheral!
    var character:CBCharacteristic!
    var camera:CVCamera!
    var moveData:NSData!
    var backData:NSData!
    
    @IBOutlet weak var img: UIImageView!
    
    @IBOutlet weak var cameraBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let centralQueue = dispatch_queue_create("com.test", DISPATCH_QUEUE_SERIAL)
        
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        
        camera = CVCamera(cameraView: img)
        
        moveData = camera.hexString(MOVE)
        backData = camera.hexString(BACK)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "writeDataToMbot", name: "fingerNumber", object: nil)
    }
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    func writeDataToMbot(){
    
        print(camera.fingerTipsNum)
        
        if camera.fingerTipsNum > 2{
            preipheral.writeValue(moveData, forCharacteristic: character, type: CBCharacteristicWriteType.WithoutResponse)
        }else if camera.fingerTipsNum == 0{
            preipheral.writeValue(backData, forCharacteristic: character, type: CBCharacteristicWriteType.WithoutResponse)
        }
    
    }
    
    
    
    
    @IBAction func scan(sender: AnyObject) {
       centralManager.scanForPeripheralsWithServices([], options: nil)
    }
    
    @IBAction func connect(sender: AnyObject) {
        camera.startCapture()
    }

    func centralManagerDidUpdateState(central: CBCentralManager) {
        
    }
   
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
       
        print(peripheral)
        
        preipheral = peripheral
        preipheral.delegate = self
        
        centralManager.connectPeripheral(peripheral, options: nil)
       
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {

        centralManager.stopScan()
        print("connent")
        preipheral.discoverServices([])
        
        cameraBtn.enabled = true
    }
    
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
      
        let services = preipheral.services
        for service in services! {
//            print(service)
            peripheral.discoverCharacteristics([], forService: service)
        }
        
        
    }
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        print("character")
//        print(service.characteristics)
        
        
        for charac in service.characteristics!{
//            print(charac.UUID)
            if charac.UUID == CBUUID(string: "FFE3") {
               character = charac
            }
            preipheral.setNotifyValue(true, forCharacteristic:charac)
        }
        
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("value ======")
//
//        print(characteristic)
//        print(characteristic.value)
 
    }

    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("write")
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

