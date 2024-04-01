//
//  PersonalInfoViewController.swift
//  BMICalculator
//
//  Created by Sachintha on 2021-12-16.
//

import UIKit
import CoreData

class PersonalInfoViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var txtName: UITextField!
    @IBOutlet var txtAge: UITextField!
    @IBOutlet var txtGender: UITextField!
    @IBOutlet var txtWeight: UITextField!
    @IBOutlet var txtHeight: UITextField!
    @IBOutlet var lblWeight: UILabel!
    @IBOutlet var lblHeight: UILabel!
    @IBOutlet var btnBack: UIButton!
    var isMetric: Bool = true;
    var appContext: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate;
        appContext = appDelegate.persistentContainer.viewContext;
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BMIRecord");
        
        do {
            let results = try appContext.fetch(fetchRequest) as! [NSManagedObject];
            if(results.count > 0) {
                btnBack.isHidden = false;
            } else {
                btnBack.isHidden = true;
            }
        } catch {
            print("Couldn't fetch the records.");
        }
        
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil);
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        txtName.delegate = self;
        txtAge.delegate = self;
        txtGender.delegate = self;
        txtWeight.delegate = self;
        txtHeight.delegate = self;
        
        lblWeight.text = "Weight (Kilograms)";
        lblHeight.text = "Height (Meters)";
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= 100
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true);
    }

    // Toggle Metric, Imperial
    @IBAction func metricToggle(_ sender: UISwitch) {
        self.isMetric = sender.isOn;
        
        if(sender.isOn) {
            lblWeight.text = "Weight (Kilograms)";
            lblHeight.text = "Height (Meters)";
        } else {
            lblWeight.text = "Weight (Pounds)";
            lblHeight.text = "Height (Inches)";
        }
    }
    
    func calculateBMIValue(isMetric:Bool, weight: Double, height: Double) -> Double {
        if(isMetric) {
            return weight/(height * height);
        } else {
            return (weight * 703)/(height * height);
        }
    }
    
    func getBMIDescription(bmiValue: Double) -> String {
        if(bmiValue < 16) {
            return "Severe Thinness";
        } else if (bmiValue >= 16 && bmiValue < 17) {
            return "Moderate Thinness";
        } else if (bmiValue >= 17 && bmiValue < 18.5) {
            return "Mild Thinness";
        } else if (bmiValue >= 18.5 && bmiValue < 25) {
            return "Normal";
        } else if (bmiValue >= 25 && bmiValue < 30) {
            return "Overweight";
        } else if (bmiValue >= 30 && bmiValue < 35) {
            return "Obese Class I";
        } else if (bmiValue >= 30 && bmiValue < 40) {
            return "Obese Class II";
        } else {
            return "Obese Class III";
        }
    }
    
    // Calculate the BMI Value
    @IBAction func onPressCalc(_ sender: UIButton) {
        let name = txtName.text?.trimmingCharacters(in: .whitespaces);
        let age = Int(txtAge.text!);
        let gender = txtGender.text?.trimmingCharacters(in: .whitespaces);
        let weight = Double(txtWeight.text!);
        let height = Double(txtHeight.text!);
        
        if(name!.isEmpty || gender!.isEmpty || age == nil ||  weight == nil || height == nil) {
            self.showValidationError();
            return;
        }
        
        let bmiValue = calculateBMIValue(isMetric: self.isMetric, weight: weight!, height: height!);
        let bmiDescription = self.getBMIDescription(bmiValue: bmiValue);

        // Persist the record in core data
        let entity = NSEntityDescription.entity(forEntityName: "BMIRecord", in: appContext);
        let newRecord = NSManagedObject(entity: entity!, insertInto: appContext);
        
        newRecord.setValue(UUID(), forKey: "id")
        newRecord.setValue(name, forKey: "name");
        newRecord.setValue(age, forKey: "age");
        newRecord.setValue(gender, forKey: "gender");
        newRecord.setValue(self.isMetric, forKey: "isMetric");
        newRecord.setValue(weight, forKey: "weight");
        newRecord.setValue(height, forKey: "height");
        newRecord.setValue(bmiValue, forKey: "bmiValue");
        newRecord.setValue(bmiDescription, forKey: "bmiDescription");
        newRecord.setValue(Date(), forKey: "updatedDate");
        
        do {
            try appContext.save();
            let alert = UIAlertController(title: "BMI Calculator", message: "You are in category of \"" + bmiDescription + "\"", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Done", comment: "OK Action"), style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true);
            }));
            self.present(alert, animated: true, completion: nil);
        } catch {
            let alert = UIAlertController(title: "BMI Calculator Error", message: "Something went wrong\nPlease try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Action"), style: .default, handler: { _ in
                NSLog("The \"Error OK\" alert occured.");
            }));
            self.present(alert, animated: true, completion: nil);
        }
    }
    
    func showValidationError() {
        let alert = UIAlertController(title: "BMI Calculator Error", message: "Please enter valid data to entries.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Action"), style: .default, handler: { _ in
            NSLog("The \"Error OK\" alert occured.");
        }));
        self.present(alert, animated: true, completion: nil);
    }
    
    @objc func dismissKeyboard() {
      view.endEditing(true)
    }
    
    // Dismiss the keyboard after enter each text entry
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        self.view.endEditing(true)
        return true;
    }
}
