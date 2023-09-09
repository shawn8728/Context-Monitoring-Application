//
//  SymptomsView.swift
//  ContextMonitoringApplication
//
//  Created by Shawn Wang on 9/6/23.
//

import SwiftUI

struct SymptomsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var heartRate: Int64
    @Binding var respiratoryRate: Int64
    
    @State private var selectedOption = "Nausea"
    @State private var starRating = 0
    @State private var ratedSymptoms: [String: Int] = [:]
    
    let symptoms = ["Nausea", "Headache", "Diarrhea", "Soar Throat", "Fever", "Muscle Ache", "Loss of Smell or Taste", "Cough", "Shortness of Breath", "Felling tired"]
    
    
    var body: some View {
        VStack(spacing: 20){
            Text("Select a symptom")
                .font(.headline)
            
            Picker(selection: $selectedOption, label: Text("Symptoms")) {
                ForEach(symptoms, id: \.self) { symptom in
                    Text(symptom)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            StarRating(rating: $starRating, selectedOption: $selectedOption, ratedSymptoms: $ratedSymptoms)
            
            Button(action:{
                addItem()
                
                ratedSymptoms.removeAll()
            }, label: {
                Text("Upload Symptoms")
            })
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.respiratory_rate = respiratoryRate
            newItem.heart_rate = heartRate
            
            
            for i in ratedSymptoms{
                let transformedKey = i.key.lowercased().replacingOccurrences(of: " ", with: "_")
                print(transformedKey)
                newItem.setValue(i.value, forKey: transformedKey)
            }
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct StarRating: View {
    @Binding var rating: Int
    @Binding var selectedOption: String
    @Binding var ratedSymptoms: [String: Int]
    
    let maxRating = 5
    
    var body: some View {
        let symptomRating = ratedSymptoms[selectedOption.lowercased().replacingOccurrences(of: " ", with: "_")] ?? 0
        
        return HStack {
            ForEach(1..<maxRating+1, id: \.self) { index in
                Image(systemName: index <= symptomRating ? "star.fill" : "star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(index <= symptomRating ? .yellow : .gray)
                    .onTapGesture {
                        self.rating = index
                        ratedSymptoms[selectedOption.lowercased().replacingOccurrences(of: " ", with: "_")] = self.rating
                    }
            }
        }
    }
}

struct SymptomsView_Previews: PreviewProvider {
    @State static var heartRate: Int64 = 0
    @State static var respiratoryRate: Int64 = 0
    
    static var previews: some View {
        SymptomsView(heartRate: $heartRate, respiratoryRate: $respiratoryRate)
    }
}
