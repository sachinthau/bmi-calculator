//
//  TrackingViewController.swift
//  BMICalculator
//
//  Created by Sachintha on 2021-12-16.
//

import UIKit
import CoreData

class TrackingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    var listOfBMIRecords: [NSManagedObject] = []
    var appContext: NSManagedObjectContext!
    var isFirstime: Bool = true;
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate;
        appContext = appDelegate.persistentContainer.viewContext;
        
        self.reloadBMIRecords();
        
        tableView.delegate = self;
        tableView.dataSource = self;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if(!self.isFirstime) {
            self.reloadBMIRecords();
        }
        
        self.isFirstime = false;
    }
    
    func reloadBMIRecords() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BMIRecord");
        
        do {
            listOfBMIRecords = try appContext.fetch(fetchRequest) as! [NSManagedObject];
            tableView.reloadData();
        } catch {
            print("Couldn't fetch the data at now.");
        }
        
        do {
            listOfBMIRecords = try appContext.fetch(fetchRequest) as! [NSManagedObject];
            if(listOfBMIRecords.count > 0) {
                if(tableView.delegate != nil) {
                    tableView.reloadData();
                }
            } else {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "dataEnterScreen") as! PersonalInfoViewController
                self.navigationController?.pushViewController(vc, animated: true);
            }
        } catch {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "dataEnterScreen") as! PersonalInfoViewController
            self.navigationController?.pushViewController(vc, animated: true);
        }
    }
    
    func deleteBMIRecord(index: Int) {
        let uuid = listOfBMIRecords[index].value(forKey: "id") as? UUID;
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BMIRecord");
        fetchRequest.predicate = NSPredicate(format: "id = %@", uuid!.uuidString);
        
        do {
            let selectedObjects = try appContext.fetch(fetchRequest);
            let objectToDelete = selectedObjects[0] as! NSManagedObject;
            appContext.delete(objectToDelete);
            
            do {
                try appContext.save();
                self.reloadBMIRecords();
            } catch {
                print("Couldn't delete the record.");
            }
        } catch {
            print("Couldn't fetch the record.");
        }
    }
    
    func updateBMIRecord(index: Int, weight: Double) {
        let uuid = listOfBMIRecords[index].value(forKey: "id") as? UUID;
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BMIRecord");
        fetchRequest.predicate = NSPredicate(format: "id = %@", uuid!.uuidString);
        
        do {
            let selectedObjects = try appContext.fetch(fetchRequest);
            let objectToUpdate = selectedObjects[0] as! NSManagedObject;
            
            // Get height and isMetric
            let isMetric = objectToUpdate.value(forKey: "isMetric") as! Bool;
            let height = objectToUpdate.value(forKey: "isMetric") as! Double;
            
            let personalInfoVC = PersonalInfoViewController();
            
            // Recalculate the BMI
            let newBMIValue = personalInfoVC.calculateBMIValue(isMetric: isMetric, weight: weight, height: height);
            let newBMIDescription = personalInfoVC.getBMIDescription(bmiValue: newBMIValue);
            
            // Update the details
            objectToUpdate.setValue(weight, forKey: "weight");
            objectToUpdate.setValue(newBMIValue, forKey: "bmiValue");
            objectToUpdate.setValue(newBMIDescription, forKey: "bmiDescription");
            objectToUpdate.setValue(Date(), forKey: "updatedDate");
            
            do {
                try appContext.save();
                self.reloadBMIRecords();
            } catch {
                print("Couldn't update the record.");
            }
        } catch {
            print("Couldn't fetch the record.");
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1; // No sections
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfBMIRecords.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: "BMIDetailCell", for: indexPath);
        
        
        let bmiValue = listOfBMIRecords[indexPath.row].value(forKey: "bmiValue") as? Double;
        let bmiDescription = listOfBMIRecords[indexPath.row].value(forKey: "bmiDescription") as? String;
        let isMetric = listOfBMIRecords[indexPath.row].value(forKey: "isMetric") as! Bool;
        let weight = listOfBMIRecords[indexPath.row].value(forKey: "weight") as! Double;
        let updatedDate = listOfBMIRecords[indexPath.row].value(forKey: "updatedDate") as! Date;
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd";
        
        tableCell.textLabel?.text = "BMI: " + String(format: "%.2f", bmiValue!) + " (" + bmiDescription! + ")";
        tableCell.detailTextLabel?.text = String(format: "%.2f", weight) + (isMetric ? " kg" : " lbs") + "\t(" + dateFormatter.string(from: updatedDate) + ")";
        
        return tableCell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let weight = listOfBMIRecords[indexPath.row].value(forKey: "weight") as! Double;
        
        let alert = UIAlertController(title: "BMI Calculator", message: "Enter new weight", preferredStyle: .alert)
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = "70"
            textField.text = String(format: "%.2f", weight)
            textField.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (action:UIAlertAction) in
            guard let textField =  alert.textFields?.first else {
                return
            }
            
            // Check the the weight value is not empty
            if let newWeight = textField.text, !newWeight.isEmpty {
                self.updateBMIRecord(index: indexPath.row, weight: Double(newWeight)!);
            };
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteBMIRecord(index: indexPath.row);
        }
    }
}
