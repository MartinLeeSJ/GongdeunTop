//
//  TargetManager.swift
//  GongdeunTop
//
//  Created by Martin on 2023/05/15.
//

import Foundation
import Combine

import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

final class TargetManager: ObservableObject {
    @Published var target: Target
    @Published var modified: Bool = false

    private let database = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init(target: Target = Target(title: "",
                                 subtitle: "",
                                 createdAt: Date.now,
                                 startDate: Date.now,
                                 dueDate: Date.now,
                                 todos: [],
                                 achievement: 0,
                                 memoirs: "")) {
        self.target = target
        self.$target
            .dropFirst()
            .sink { [weak self] target in
                self?.modified = true
            }
            .store(in: &self.cancellables)
    }
    
    private func addTarget(_ target: Target) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if target.id == nil {
            do {
                try database.collection("Members")
                    .document(uid)
                    .collection("Target")
                    .addDocument(from: target)
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func updateTarget(_ target: Target) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let id = target.id else { return }
        
        do {
            try database
                .collection("Members")
                .document(uid)
                .collection("Target")
                .document(id)
                .setData(from: target)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func removeTarget() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let id = target.id else { return }
        let memberRef = database.collection("Members").document(uid)
        let batch = database.batch()
        
        for todo in target.todos {
            batch.updateData(["relatedTarget" : nil ?? ""],
                             forDocument: memberRef.collection("ToDo").document(todo))
        }
        
        batch.deleteDocument(memberRef.collection("Target").document(id))
        
        do {
            try await batch.commit()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func addOrUpdateTarget() {
        if let _ = self.target.id {
            updateTarget(self.target)
        } else {
            addTarget(self.target)
        }
    }
    
    //MARK: - UI Handler
    func handleDoneTapped() {
        addOrUpdateTarget()
    }
    
    func handleDeleteTapped() {
        Task {
            await removeTarget()
        }
    }
}
