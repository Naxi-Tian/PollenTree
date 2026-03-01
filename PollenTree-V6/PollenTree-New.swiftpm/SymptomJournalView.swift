import SwiftUI
import SwiftData
import Charts

// 1. FIXED DATA MODEL: Prevents infinite redraw crashes!
struct AllergenSeverityData: Identifiable {
    var id: String { allergen } 
    let allergen: String
    let totalSeverity: Int
}

struct SymptomJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomLog.date, order: .reverse) private var logs: [SymptomLog]
    @State private var showingLogSheet = false
    @State private var selectedLog: SymptomLog?
    
    @ObservedObject var viewModel: DashboardViewModel
    
    // 2. Safely grouped data for the Bar Chart
    private var allergenChartData: [AllergenSeverityData] {
        var scores: [String: Int] = [:]
        
        for log in logs {
            if let dominant = log.historicalDominantAllergen {
                let severity = log.sneezing + log.itchyEyes + log.congestion
                scores[dominant.rawValue, default: 0] += severity
            }
        }
        
        return scores.map { AllergenSeverityData(allergen: $0.key, totalSeverity: $0.value) }
            .sorted { $0.totalSeverity > $1.totalSeverity }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    JournalHeader()
                    
                    // Render the safe bar chart if we have data
                    if !allergenChartData.isEmpty {
                        SymptomCorrelationChart(chartData: allergenChartData)
                    }
                    
                    // Pass the top allergen string directly to the insights card
                    if logs.count >= 3, let topAllergen = allergenChartData.first?.allergen {
                        PersonalInsightsCard(topAllergen: topAllergen)
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
                // The sheet is completely standalone now!
                LogSymptomView(viewModel: viewModel)
            }
            .sheet(item: $selectedLog) { log in
                LogSymptomView(viewModel: viewModel, logToEdit: log)
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
    let chartData: [AllergenSeverityData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Severity by Allergen Type")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(chartData) { data in
                    BarMark(
                        x: .value("Allergen", data.allergen),
                        y: .value("Total Severity", data.totalSeverity)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .cornerRadius(6)
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .padding(.horizontal)
            .accessibilityLabel("Bar chart showing your total symptom severity categorized by pollen type.")
        }
    }
}

struct PersonalInsightsCard: View {
    let topAllergen: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles").foregroundColor(.orange)
                Text("Personal Insights").font(.headline)
            }
            
            Text("Your symptoms are most severe when **\(topAllergen)** levels are high.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(20)
        .padding(.horizontal)
        .accessibilityLabel("Personal Insights: Your symptoms are most severe when \(topAllergen) levels are high.")
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
                            Button {
                                selectedLog = log
                            } label: {
                                Label("Edit Log", systemImage: "pencil")
                            }
                            
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

// ⚠️ THE FIXED LOG VIEW (No heavy dependencies, strictly isolated SwiftData insertion)
struct LogSymptomView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    var logToEdit: SymptomLog?
    
    @State private var date = Date()
    @State private var sneezing: SymptomSeverity = .none
    @State private var itchyEyes: SymptomSeverity = .none
    @State private var congestion: SymptomSeverity = .none
    @State private var notes = ""
    @State private var saveErrorMessage: String?
    
    @ObservedObject var viewModel: DashboardViewModel
    
    init(viewModel: DashboardViewModel, logToEdit: SymptomLog? = nil) {
        self.viewModel = viewModel
        self.logToEdit = logToEdit
        
        if let log = logToEdit {
            _date = State(initialValue: log.date)
            _sneezing = State(initialValue: log.sneezingSeverity)
            _itchyEyes = State(initialValue: log.itchyEyesSeverity)
            _congestion = State(initialValue: log.congestionSeverity)
            _notes = State(initialValue: log.notes)
        }
    }
    
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
                
                if logToEdit != nil {
                    Section {
                        Button(role: .destructive) {
                            if let log = logToEdit {
                                modelContext.delete(log)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Entry")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(logToEdit == nil ? "New Entry" : "Edit Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let log = logToEdit {
                            log.date = date
                            log.sneezing = sneezing.rawValue
                            log.itchyEyes = itchyEyes.rawValue
                            log.congestion = congestion.rawValue
                            log.notes = notes
                        } else {
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
                        }
                        
                        do {
                            try modelContext.save()
                            
                            // Trigger learning logic safely
                            DispatchQueue.main.async {
                                // We need to fetch the latest logs to learn from
                                let descriptor = FetchDescriptor<SymptomLog>()
                                if let latestLogs = try? modelContext.fetch(descriptor) {
                                    viewModel.learnFromLogs(latestLogs)
                                }
                            }
                            
                            dismiss()
                        } catch {
                            saveErrorMessage = "We couldn’t save your log right now. Please try again."
                        }
                    }
                }
            }
            .alert("Save Failed", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { saveErrorMessage = nil }
            } message: {
                Text(saveErrorMessage ?? "Unknown error")
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
