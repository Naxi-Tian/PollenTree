import SwiftUI
import SwiftData
import Charts

struct SymptomJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomLog.date, order: .reverse) private var logs: [SymptomLog]
    @State private var showingLogSheet = false
    @State private var selectedLog: SymptomLog?
    
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    JournalHeader()
                    
                    if logs.count >= 2 {
                        SymptomCorrelationChart(logs: logs)
                    }
                    
                    if logs.count >= 3 {
                        PersonalInsightsCard(logs: logs)
                    }
                    
                    LogTodayButton { showingLogSheet = true }
                    
                    RecentLogsSection(logs: logs, selectedLog: $selectedLog)
                }
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingLogSheet) {
                LogSymptomView(viewModel: viewModel)
            }
            .sheet(item: $selectedLog) { log in
                LogDetailView(log: log)
            }
        }
    }
}

// MARK: - Sub-views

struct JournalHeader: View {
    var body: some View {
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
    }
}

struct SymptomCorrelationChart: View {
    let logs: [SymptomLog]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Symptom vs. Pollen Correlation")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(logs.sorted(by: { $0.date < $1.date })) { log in
                    let totalSeverity = Double(log.sneezing + log.itchyEyes + log.congestion)
                    
                    LineMark(
                        x: .value("Date", log.date),
                        y: .value("Severity", totalSeverity)
                    )
                    .foregroundStyle(by: .value("Type", "Symptoms"))
                    .symbol(by: .value("Type", "Symptoms"))
                    
                    if let risk = log.historicalRiskScore {
                        AreaMark(
                            x: .value("Date", log.date),
                            y: .value("Pollen Risk", risk / 10.0)
                        )
                        .foregroundStyle(by: .value("Type", "Pollen Risk"))
                        .opacity(0.2)
                    }
                }
            }
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
}

struct PersonalInsightsCard: View {
    let logs: [SymptomLog]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles").foregroundColor(.orange)
                Text("Personal Insights").font(.headline)
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

struct LogTodayButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Log Today's Symptoms").fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .padding(.horizontal)
        .accessibilityLabel("Log Today's Symptoms")
    }
}

struct RecentLogsSection: View {
    let logs: [SymptomLog]
    @Binding var selectedLog: SymptomLog?
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Logs")
                .font(.headline)
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)
            
            if logs.isEmpty {
                EmptyLogsView()
            } else {
                ForEach(logs) { log in
                    SymptomLogCard(log: log) { selectedLog = log }
                        .padding(.horizontal)
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(log)
                            } label: {
                                Label("Delete Log", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

struct EmptyLogsView: View {
    var body: some View {
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
                        Text(dominant.rawValue).font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                HStack(spacing: 12) {
                    SymptomIcon(severity: log.sneezingSeverity, icon: "nose")
                    SymptomIcon(severity: log.itchyEyesSeverity, icon: "eye")
                    SymptomIcon(severity: log.congestionSeverity, icon: "lungs")
                }
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundColor(.secondary.opacity(0.5))
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
            Circle().fill(severity.color.opacity(0.1)).frame(width: 32, height: 32)
            Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundColor(severity.color)
        }
        .opacity(severity == .none ? 0.3 : 1.0)
    }
}

struct LogSymptomView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query private var logs: [SymptomLog]
    
    @State private var date = Date()
    @State private var sneezing: SymptomSeverity = .none
    @State private var itchyEyes: SymptomSeverity = .none
    @State private var congestion: SymptomSeverity = .none
    @State private var notes = ""
    
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Date")) {
                    DatePicker("Log Date", selection: $date, displayedComponents: .date)
                }
                Section(header: Text("Symptoms")) {
                    SymptomPicker(title: "Sneezing", selection: $sneezing)
                    SymptomPicker(title: "Itchy Eyes", selection: $itchyEyes)
                    SymptomPicker(title: "Congestion", selection: $congestion)
                }
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes).frame(height: 100)
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newLog = SymptomLog(
                            date: date,
                            sneezing: sneezing,
                            itchyEyes: itchyEyes,
                            congestion: congestion,
                            notes: notes,
                            historicalRiskScore: viewModel.assessment.normalizedScore,
                            historicalDominantAllergen: viewModel.assessment.dominantAllergen
                        )
                        modelContext.insert(newLog)
                        
                        // Trigger learning logic safely
                        DispatchQueue.main.async {
                            viewModel.learnFromLogs(logs + [newLog])
                        }
                        
                        dismiss()
                    }
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
                    HStack { Text("Date"); Spacer(); Text(log.date.formatted(date: .long, time: .omitted)).foregroundColor(.secondary) }
                    if let dominant = log.historicalDominantAllergen {
                        HStack { Text("Dominant Allergen"); Spacer(); Text(dominant.rawValue).foregroundColor(.secondary) }
                    }
                    if let risk = log.historicalRiskScore {
                        HStack { Text("Pollen Risk Level"); Spacer(); Text("\(Int(risk))/100").foregroundColor(.secondary) }
                    }
                }
                Section(header: Text("Symptoms")) {
                    SymptomDetailRow(title: "Sneezing", severity: log.sneezingSeverity)
                    SymptomDetailRow(title: "Itchy Eyes", severity: log.itchyEyesSeverity)
                    SymptomDetailRow(title: "Congestion", severity: log.congestionSeverity)
                }
                if !log.notes.isEmpty {
                    Section(header: Text("Notes")) { Text(log.notes).font(.body) }
                }
            }
            .navigationTitle("Log Details")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

struct SymptomDetailRow: View {
    let title: String
    let severity: SymptomSeverity
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(severity.label).foregroundColor(severity.color).fontWeight(.bold)
        }
    }
}
