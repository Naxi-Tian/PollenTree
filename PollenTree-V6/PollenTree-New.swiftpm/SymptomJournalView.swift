import SwiftUI
import SwiftData
import Charts

struct SymptomJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomLog.date, order: .reverse) private var logs: [SymptomLog]
    @State private var showingLogSheet = false
    @State private var selectedLog: SymptomLog?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Health Journey")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .accessibilityAddTraits(.isHeader)
                        Text("Track symptoms to discover your unique triggers.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Data Visualization Section
                    if logs.count >= 2 {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Symptom vs. Pollen Correlation")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Chart {
                                ForEach(logs.sorted(by: { $0.date < $1.date })) { log in
                                    // Fix 1: Type Mismatch Fix (Double for both)
                                    let totalSeverity = Double(log.sneezing + log.itchyEyes + log.congestion)
                                    
                                    // Symptom Severity Line
                                    LineMark(
                                        x: .value("Date", log.date),
                                        y: .value("Severity", totalSeverity)
                                    )
                                    .foregroundStyle(by: .value("Type", "Symptoms"))
                                    .symbol(by: .value("Type", "Symptoms"))
                                    
                                    // Historical Pollen Risk Area (if available)
                                    if let risk = log.historicalRiskScore {
                                        AreaMark(
                                            x: .value("Date", log.date),
                                            y: .value("Pollen Risk", risk / 10.0) // Scale to match symptom range (0-9)
                                        )
                                        .foregroundStyle(by: .value("Type", "Pollen Risk"))
                                        .opacity(0.2)
                                    }
                                }
                            }
                            // Fix 2: Strict frame height to prevent infinite layout crash
                            .frame(height: 200)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .padding(.horizontal)
                            .chartForegroundStyleScale([
                                "Symptoms": Color.green,
                                "Pollen Risk": Color.orange.opacity(0.5)
                            ])
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Chart showing correlation between your symptoms and pollen risk levels over time.")
                    }
                    
                    // Insights Card
                    if logs.count >= 3 {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.orange)
                                Text("Personal Insights")
                                    .font(.headline)
                            }
                            
                            Text("Your symptoms are most severe when **\(mostReactiveAllergen()?.rawValue ?? "unknown")** levels are high.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Personal Insights: Your symptoms are most severe when \(mostReactiveAllergen()?.rawValue ?? "unknown") levels are high.")
                    }
                    
                    // Log Button
                    Button {
                        showingLogSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Today's Symptoms")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .accessibilityLabel("Log Today's Symptoms")
                    
                    // History Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Logs")
                            .font(.headline)
                            .padding(.horizontal)
                            .accessibilityAddTraits(.isHeader)
                        
                        if logs.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text("No logs yet. Your history will appear here.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("No logs yet. Your history will appear here.")
                        } else {
                            // Fix 3: Remove .onDelete and add contextMenu for deletion
                            ForEach(logs) { log in
                                SymptomLogCard(log: log) {
                                    selectedLog = log
                                }
                                .padding(.horizontal)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelContext.delete(log)
                                    } label: {
                                        Label("Delete Log", systemImage: "trash")
                                    }
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Log for \(log.date.formatted(date: .abbreviated, time: .omitted)). Symptoms: Sneezing \(log.sneezingSeverity.label), Itchy Eyes \(log.itchyEyesSeverity.label), Congestion \(log.congestionSeverity.label).")
                            }
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingLogSheet) {
                LogSymptomView()
            }
            .sheet(item: $selectedLog) { log in
                LogDetailView(log: log)
            }
        }
    }
    
    private func mostReactiveAllergen() -> PollenType? {
        var allergenScores: [PollenType: Int] = [:]
        for log in logs {
            if let dominant = log.historicalDominantAllergen {
                let totalSeverity = log.sneezing + log.itchyEyes + log.congestion
                allergenScores[dominant, default: 0] += totalSeverity
            }
        }
        return allergenScores.max(by: { $0.value < $1.value })?.key
    }
}

struct SymptomLogCard: View {
    let log: SymptomLog
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(.headline, design: .rounded))
                    if let dominant = log.historicalDominantAllergen {
                        Text(dominant.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    SymptomIcon(severity: log.sneezingSeverity, icon: "nose")
                    SymptomIcon(severity: log.itchyEyesSeverity, icon: "eye")
                    SymptomIcon(severity: log.congestionSeverity, icon: "lungs")
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SymptomIcon: View {
    let severity: SymptomSeverity
    let icon: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(severity.color.opacity(0.1))
                .frame(width: 32, height: 32)
            
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(severity.color)
        }
        .opacity(severity == .none ? 0.3 : 1.0)
    }
}

struct LogSymptomView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var date = Date()
    @State private var sneezing: SymptomSeverity = .none
    @State private var itchyEyes: SymptomSeverity = .none
    @State private var congestion: SymptomSeverity = .none
    @State private var notes = ""
    
    // In a real app, we'd use a shared ViewModel, but for simplicity in this view:
    @State private var currentRisk: Double = 45.0
    @State private var currentDominant: PollenType = .birch
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("When & How")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section(header: Text("Symptoms")) {
                    SymptomPicker(title: "Sneezing", selection: $sneezing)
                    SymptomPicker(title: "Itchy Eyes", selection: $itchyEyes)
                    SymptomPicker(title: "Congestion", selection: $congestion)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Capture the risk data at the time of logging
                        let newLog = SymptomLog(
                            date: date,
                            sneezing: sneezing,
                            itchyEyes: itchyEyes,
                            congestion: congestion,
                            notes: notes,
                            historicalRiskScore: currentRisk,
                            historicalDominantAllergen: currentDominant
                        )
                        modelContext.insert(newLog)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

struct SymptomPicker: View {
    let title: String
    @Binding var selection: SymptomSeverity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline)
            Picker(title, selection: $selection) {
                ForEach(SymptomSeverity.allCases) { severity in
                    Text(severity.label).tag(severity)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 4)
    }
}

struct LogDetailView: View {
    let log: SymptomLog
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Summary")) {
                    LabeledContent("Date", value: log.date.formatted(date: .long, time: .omitted))
                    LabeledContent("Sneezing", value: log.sneezingSeverity.label)
                    LabeledContent("Itchy Eyes", value: log.itchyEyesSeverity.label)
                    LabeledContent("Congestion", value: log.congestionSeverity.label)
                }
                
                if !log.notes.isEmpty {
                    Section(header: Text("Notes")) {
                        Text(log.notes)
                    }
                }
            }
            .navigationTitle("Log Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
