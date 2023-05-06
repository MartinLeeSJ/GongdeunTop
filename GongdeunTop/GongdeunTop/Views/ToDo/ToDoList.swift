//
//  ToDoList.swift
//  GongdeunTop
//
//  Created by Martin on 2023/03/16.
//

import SwiftUI


struct ToDoList: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject var todoStore = ToDoStore()
    @StateObject var timerViewModel = TimerManager()
    
    @State private var isDeleteAlertOn: Bool = false
    
    @State private var isAddSheetOn: Bool = false
    @State private var isSetTimeViewOn: Bool = false
    
    var body: some View {
        NavigationView{
            ZStack {
                themeManager.getThemeColorInPriority(of: .background)
                    .ignoresSafeArea(.all)
                GeometryReader { geo in
                    VStack {
                        List(todoStore.todos, selection: $todoStore.multiSelection) { todo in
                            ToDoRow(todo: todo)
                                .listRowBackground(Color.clear)
                        }
                        .frame(height: geo.size.height * (todoStore.isEditing ? 0.89 : 0.84))
                        .listStyle(.plain)
                        .environment(\.editMode, .constant(todoStore.isEditing ? EditMode.active : EditMode.inactive))
                        .toolbar {
                            toolbarContent()
                        }
                        
                        Divider()
                        
                        if todoStore.isEditing == false {
                            toDoListDashboard(geo: geo)
                        }
                        else {
                            editToDosButtons()
                        }
                    }
                }
                .navigationTitle("Today's ToDos")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    todoStore.subscribeTodos()
                }
                .onDisappear {
                    todoStore.unsubscribeTodos()
                }
            }
        }
        
        
    }
}


//MARK: - ToDoListDashBoard
extension ToDoList {
    var todoCount: Int {
        todoStore.todos.count
    }
    
    var numOfSessions: Int {
        timerViewModel.numOfSessions
    }
    
    var totalTime: Int {
        timerViewModel.getTotalMinute()
    }
    
    @ViewBuilder
    func toDoListDashboard(geo: GeometryProxy) -> some View {
        VStack {
            dashboardBanner
            
            HStack {
                Button {
                    isSetTimeViewOn.toggle()
                } label: {
                    Text("Set Time")
                        .frame(width: geo.size.width / 2 - 33, height: 36)
                }
                .sheet(isPresented: $isSetTimeViewOn) {
                    SetTimeForm(viewModel: timerViewModel)
                        .presentationDetents([.medium])
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.getThemeColorInPriority(of: .solid))
                
                Spacer()
                
                NavigationLink {
                    SessionsTimer(timerManager: timerViewModel,
                                  todos: todoStore.todos,
                                  currentTodo: todoStore.todos.first)
                } label: {
                    Text("Start")
                        .frame(width: geo.size.width / 2 - 33, height: 36)
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.getThemeColorInPriority(of: .solid))
            }
            .padding(6)
        }
        .animation(.easeIn, value: todoStore.isEditing)
    }
    
    var dashboardBanner: some View {
        HAlignment(alignment: .center) {
            Text("todo_counts \(todoCount)") + Text("sessions\(numOfSessions)") + Text("totalTime\(totalTime)")
        }
        .font(.caption)
    }
}

//MARK: - EditToDosButtons
extension ToDoList {
    var multiSelecitonCount: Int {
        todoStore.multiSelection.count
    }
    
    @ViewBuilder
    func editToDosButtons() -> some View {
        HStack {
            Button {
                isDeleteAlertOn.toggle()
            } label: {
                Text("Delete")
            }
            .alert("Delete", isPresented: $isDeleteAlertOn) {
                Button {
                    isDeleteAlertOn.toggle()
                } label: {
                    Text("Cancel")
                }
                
                Button {
                    todoStore.deleteTodos()
                    isDeleteAlertOn.toggle()
                } label: {
                    Text("Delete")
                }
            } message: {
                Text("really_delete? \(multiSelecitonCount)")
            }

            Spacer()
            
            Button {
                todoStore.completeTodos()
            } label: {
                Text("Complete Todo")
            }
            
        }
        .tint(themeManager.getThemeColorInPriority(of: .accent))
        .disabled(todoStore.multiSelection.isEmpty)
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
    }
}

//MARK: - Toolbar
extension ToDoList {
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                withAnimation {
                    todoStore.isEditing.toggle()
                }
            } label: {
                Text(todoStore.isEditing ? "Done" : "Edit")
            }
        }
        
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                isAddSheetOn = true
            } label: {
                Label("Add", systemImage: "plus.circle.fill")
            }
            .sheet(isPresented: $isAddSheetOn) {
                SetToDoForm()
            }
            .tint(themeManager.getThemeColorInPriority(of: .accent))
        }
    }
}


struct ToDoView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.locale, .init(identifier: "en"))
    }
}
