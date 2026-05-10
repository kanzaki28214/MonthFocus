//
//  ContentView.swift
//  MonthFocus
//
//  Created by Kenshin on 2026/05/10.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("focusTheme") private var storedTheme = FocusTheme.paper.rawValue
    @State private var selectedMonth = Calendar.current.startOfMonth(for: Date())

    private var theme: FocusTheme {
        FocusTheme(rawValue: storedTheme) ?? .paper
    }

    var body: some View {
        TabView {
            CurrentMonthView(selectedMonth: $selectedMonth, theme: theme)
                .tabItem {
                    Label("今月", systemImage: "checklist")
                }

            AddTaskView(selectedMonth: $selectedMonth, theme: theme)
                .tabItem {
                    Label("追加", systemImage: "plus.circle.fill")
                }

            SettingsView(selectedMonth: $selectedMonth, storedTheme: $storedTheme, theme: theme)
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
        .tint(theme.tint)
    }
}

private struct CurrentMonthView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [FocusTask]
    @Binding var selectedMonth: Date
    let theme: FocusTheme

    private var visibleTasks: [FocusTask] {
        tasks
            .filter { Calendar.current.isDate($0.month, equalTo: selectedMonth, toGranularity: .month) }
            .sorted {
                if $0.isCompleted != $1.isCompleted {
                    return !$0.isCompleted
                }

                if $0.priority != $1.priority {
                    return $0.priority < $1.priority
                }

                return $0.createdAt < $1.createdAt
            }
    }

    private var unfinishedCount: Int {
        visibleTasks.filter { !$0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    MonthHeader(selectedMonth: $selectedMonth, theme: theme)

                    HStack(spacing: 12) {
                        StatTile(value: "\(visibleTasks.count)", label: "今月のタスク", theme: theme)
                        StatTile(value: "\(unfinishedCount)", label: "未完了", theme: theme)
                    }

                    if visibleTasks.isEmpty {
                        EmptyTaskView(theme: theme)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(visibleTasks) { task in
                                TaskRow(task: task, theme: theme) {
                                    withAnimation {
                                        modelContext.delete(task)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("Month Focus")
            .toolbarTitleDisplayMode(.inline)
        }
    }
}

private struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedMonth: Date
    let theme: FocusTheme

    @State private var title = ""
    @State private var detail = ""
    @State private var priority = 3
    @State private var targetMonth = Calendar.current.startOfMonth(for: Date())

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("やりたいこと") {
                    TextField("例: 家計簿アプリの画面を作る", text: $title)
                    TextField("詳細", text: $detail, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }

                Section("期間と優先度") {
                    DatePicker("期間", selection: $targetMonth, displayedComponents: .date)

                    Picker("優先度", selection: $priority) {
                        ForEach(1...5, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Button {
                    saveTask()
                } label: {
                    Label("追加", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!canSave)
            }
            .scrollContentBackground(.hidden)
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("やりたいことを追加")
            .toolbarTitleDisplayMode(.inline)
            .onAppear {
                targetMonth = selectedMonth
            }
        }
    }

    private func saveTask() {
        let task = FocusTask(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
            month: targetMonth,
            priority: priority
        )

        withAnimation {
            modelContext.insert(task)
            selectedMonth = Calendar.current.startOfMonth(for: targetMonth)
            title = ""
            detail = ""
            priority = 3
        }
    }
}

private struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var reflections: [MonthReflection]
    @Binding var selectedMonth: Date
    @Binding var storedTheme: String
    let theme: FocusTheme

    @State private var gratitude = ""
    @State private var extensionDecision = ""

    private var currentReflection: MonthReflection? {
        reflections.first {
            Calendar.current.isDate($0.month, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("テーマ") {
                    Picker("テーマ", selection: $storedTheme) {
                        ForEach(FocusTheme.allCases) { theme in
                            Text(theme.title).tag(theme.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("月のまとめ") {
                    DatePicker("対象月", selection: $selectedMonth, displayedComponents: .date)

                    TextField("今月の感謝", text: $gratitude, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)

                    TextField("終了か、延長か", text: $extensionDecision, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)

                    Button {
                        saveReflection()
                    } label: {
                        Label("まとめを保存", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                }

                Section("閲覧") {
                    if reflections.isEmpty {
                        Text("保存された月のまとめはまだありません。")
                            .foregroundStyle(theme.secondaryText)
                    } else {
                        ForEach(sortedReflections) { reflection in
                            ReflectionRow(reflection: reflection, theme: theme)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("設定")
            .toolbarTitleDisplayMode(.inline)
            .onAppear(perform: loadReflection)
            .onChange(of: selectedMonth) {
                selectedMonth = Calendar.current.startOfMonth(for: selectedMonth)
                loadReflection()
            }
        }
    }

    private var sortedReflections: [MonthReflection] {
        reflections.sorted { $0.month > $1.month }
    }

    private func loadReflection() {
        gratitude = currentReflection?.gratitude ?? ""
        extensionDecision = currentReflection?.extensionDecision ?? ""
    }

    private func saveReflection() {
        let month = Calendar.current.startOfMonth(for: selectedMonth)

        if let currentReflection {
            currentReflection.gratitude = gratitude
            currentReflection.extensionDecision = extensionDecision
            currentReflection.updatedAt = Date()
        } else {
            modelContext.insert(
                MonthReflection(
                    month: month,
                    gratitude: gratitude,
                    extensionDecision: extensionDecision
                )
            )
        }

        selectedMonth = month
    }
}

private struct MonthHeader: View {
    @Binding var selectedMonth: Date
    let theme: FocusTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedMonth, format: .dateTime.year().month(.wide))
                .font(.largeTitle.bold())
                .foregroundStyle(theme.text)

            HStack {
                Button {
                    moveMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("今月") {
                    selectedMonth = Calendar.current.startOfMonth(for: Date())
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Button {
                    moveMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func moveMonth(by value: Int) {
        selectedMonth = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) ?? selectedMonth
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let theme: FocusTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
        }
        .foregroundStyle(theme.text)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(theme.card, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct TaskRow: View {
    @Bindable var task: FocusTask
    let theme: FocusTheme
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                withAnimation {
                    task.isCompleted.toggle()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : theme.secondaryText)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? theme.secondaryText : theme.text)

                    Spacer()

                    Text("P\(task.priority)")
                        .font(.caption.bold())
                        .foregroundStyle(theme.tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.tint.opacity(0.14), in: Capsule())
                }

                if !task.detail.isEmpty {
                    Text(task.detail)
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                }
            }

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(theme.card, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct EmptyTaskView: View {
    let theme: FocusTheme

    var body: some View {
        ContentUnavailableView(
            "今月のタスクはありません",
            systemImage: "calendar.badge.plus",
            description: Text("追加タブから、今月やりたいことを入れられます。")
        )
        .foregroundStyle(theme.secondaryText)
        .padding(.top, 40)
    }
}

private struct ReflectionRow: View {
    let reflection: MonthReflection
    let theme: FocusTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reflection.month, format: .dateTime.year().month(.wide))
                .font(.headline)
                .foregroundStyle(theme.text)

            if !reflection.gratitude.isEmpty {
                Label(reflection.gratitude, systemImage: "heart")
            }

            if !reflection.extensionDecision.isEmpty {
                Label(reflection.extensionDecision, systemImage: "arrow.triangle.2.circlepath")
            }
        }
        .foregroundStyle(theme.secondaryText)
        .padding(.vertical, 6)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FocusTask.self, MonthReflection.self], inMemory: true)
}
