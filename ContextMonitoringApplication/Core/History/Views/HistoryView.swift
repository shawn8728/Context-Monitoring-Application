//
//  HistoryView.swift
//  ContextMonitoringApplication
//
//  Created by Shawn Wang on 9/7/23.
//

import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    var body: some View {
        List {
            ForEach(items) { item in
                NavigationLink {
                    VStack{
                        Text("Symptoms at \(item.timestamp!, formatter: itemFormatter)")
                        
                        Group{
                            Text("Respiratory Rate: \(item.respiratory_rate)")
                            Text("Heart Rate: \(item.heart_rate)")
                        }
                        
                        Group{
                            Text("Nausea Rating: \(item.nausea)")
                            Text("Headache Rating:  \(item.headache)")
                            Text("Diarrhea Rating: \(item.diarrhea)")
                            Text("Sore Throat Rating: \(item.soar_throat)")
                            Text("Fever Rating: \(item.fever)")
                            Text("Muscle Ache Rating: \(item.muscle_ache)")
                            Text("Loss of Smell or Taste Rating: \(item.loss_of_smell_or_taste)")
                            Text("Cough Rating: \(item.cough)")
                            Text("Shortness of Breath Rating: \(item.shortness_of_breath)")
                            Text("Feeling Tired: \(item.feeling_tired)")
                        }
                    }
                } label: {
                    Text(item.timestamp!, formatter: itemFormatter)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                EditButton()
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
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

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
