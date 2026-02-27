import SwiftUI
import SwiftData
import Charts

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let severity: Double
    let risk: Double
}

struct SymptomJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomLog.date, order: .reverse) private var logs: [SymptomLog]
    @State private var showingLogSheet = false
    @State private var selectedLog: SymptomLog?
    
    private var chartData: [ChartDataPoint] {
        logs.sorted(by: { $0.date < $1.date }).map { log in
            ChartDataPoint(
                date: log.date,
                // FIXED: They are already Ints, so we just add them directly!
                severity: Double(log.sneezing + log.itchyEyes + log.congestion),
                risk: (log.historicalRiskScore ?? 0.0) / 10.0 
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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
                    
                    if chartData.count >= 2 {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Symptom vs. Pollen Correlation")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Chart {
                                ForEach(chartData) { point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Score", point.severity)
                                    )
                                    .foregroundStyle(by: .value("Type", "Symptoms"))
                                    .symbol(by: .value("Type", "Symptoms"))
                                    .interpolationMethod(.monotone)
                                }
                                
                                ForEach(chartData) { point in
                                    AreaMark(
                                        x: .value("Date", point.date),
                                        y: .value("Score", point.risk)
                                    )
                                    .foregroundStyle(by: .value("Type", "Pollen Risk"))
                                    .opacity(0.2)
                                    .interpolationMethod(.monotone)
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
                    }
                    
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
                        } else {
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

// MARK: - Subcomponents
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
                    // FIXED: Using the computed properties that return the Enum
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
                    // FIXED: Using the computed properties to get the .label string
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
