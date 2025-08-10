// AUTHOR: Yuvraj Solanki, Daniel J. Parker
// CREATED DATE: 2025-07-24
// DESCRIPTION: A simple app which allows you to input your study hours and extra-curricular hours, which then provides a star rating and suggestions for balance.
// INPUTS: Study hours (daily), age, gender, extra-curricular hours (weekly), sleep hours (daily)
// OUTPUTS: Star rating, suggestion text
// REVISION HISTORY:
//  - 2025-07-24 v1
//  - 2025-07-28 v1.1
//  - 2025-07-29 v2
//  - 2025-07-30 v2.1
//  - 2025-07-31 v3
//  - 2025-07-31 v3.1
//  - 2025-08-01 v3.2
//  - 2025-08-01 v3.3
//  - 2025-08-05 v3.4
//  - 2025-08-08 v3.5
//  - 2025-08-10 v3.6
// ACKNOWLEDGEMENTS: Original idea by D.J. Parker & Y. Solanki; implemented with the use of AI.

import SwiftUI
import Foundation

//MARK: Opening Screen
struct ContentView: View {
    @State private var strStudentAge = ""
    @State private var strStudentGender = "Male"
    @State private var dblStudyHoursDaily: Double = 1
    @State private var dblExtracurricularHoursWeekly: Double = 0.5
    @State private var dblSleepHoursDaily: Double = 7
    @State private var intOverallStarRating = 0
    @State private var strBalanceSuggestionText = ""
    @State private var strInputValidationError: String? = nil
    @State private var blnIsLoadingSuggestions = false
    @State private var blnIsCalendarViewVisible = false
    @State private var blnShowCalendarAndClearControls = false
    @FocusState private var blnIsStudentAgeFieldFocused: Bool

    private let arrAvailableGenders = ["Male", "Female", "Other"]

    private var maxStudyHoursDaily: Double {
        let remaining = 24 - (dblSleepHoursDaily + dblExtracurricularHoursWeekly / 7)
        return min(12, max(0, remaining))
    }
    private var maxSleepHoursDaily: Double {
        let remaining = 24 - (dblStudyHoursDaily + dblExtracurricularHoursWeekly / 7)
        return min(12, max(0, remaining))
    }
    private var maxExtracurricularWeekly: Double {
        let remainingDaily = 24 - (dblStudyHoursDaily + dblSleepHoursDaily)
        return min(84, max(0, remainingDaily * 7))
    }
    private func normalizeTotals() {
        if dblStudyHoursDaily > maxStudyHoursDaily { dblStudyHoursDaily = maxStudyHoursDaily }
        if dblSleepHoursDaily > maxSleepHoursDaily { dblSleepHoursDaily = maxSleepHoursDaily }
        if dblExtracurricularHoursWeekly > maxExtracurricularWeekly { dblExtracurricularHoursWeekly = maxExtracurricularWeekly }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    titleView
                    personalInfoCard
                    routineCard
                    checkBalanceButton
                    resultsSection
                }
                .padding()
            }
            .navigationTitle("Study Cuddie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if blnShowCalendarAndClearControls {
                        Button {
                            blnIsCalendarViewVisible = true
                        } label: {
                            Image(systemName: "calendar")
                                .foregroundColor(.purple)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if blnShowCalendarAndClearControls {
                        Button("Clear", action: resetAllInputs)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationDestination(isPresented: $blnIsCalendarViewVisible) {
                CalendarPlannerView()
            }
        }
    }

    // MARK: Title
    private var titleView: some View {
        HStack {
            Spacer()
            Text("Study Cuddie")
                .font(.custom("Revalia", size: 40))
                .foregroundColor(.black)
            Spacer()
        }
        .padding(.top)
    }

    private func CardView<Content: View>(
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 2)
            content()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 3)
        .padding(.horizontal)
    }

    private var personalInfoCard: some View {
        CardView(title: "Personal Info") {
            TextField("Age", text: $strStudentAge)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($blnIsStudentAgeFieldFocused)
                .onChange(of: strStudentAge) { newValue in
                    strStudentAge = newValue.filter { $0.isNumber }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { blnIsStudentAgeFieldFocused = false }
                    }
                }

            Picker("Gender", selection: $strStudentGender) {
                ForEach(arrAvailableGenders, id: \.self) { g in Text(g) }
            }
            .pickerStyle(SegmentedPickerStyle())
            .tint(.purple)
        }
    }

    private var routineCard: some View {
        CardView(title: "Your Routine") {
            Stepper(value: $dblStudyHoursDaily, in: 0...maxStudyHoursDaily, step: 0.1) {
                Text("Study (daily): \(String(format: "%.1f", dblStudyHoursDaily)) h")
            }
            .onChange(of: dblStudyHoursDaily) { _ in normalizeTotals() }
            Stepper(value: $dblExtracurricularHoursWeekly, in: 0...maxExtracurricularWeekly, step: 0.1) {
                Text("Extracurricular (weekly): \(String(format: "%.1f", dblExtracurricularHoursWeekly)) h")
            }
            .onChange(of: dblExtracurricularHoursWeekly) { _ in normalizeTotals() }
            Stepper(value: $dblSleepHoursDaily, in: 0...maxSleepHoursDaily, step: 0.5) {
                Text("Sleep (daily): \(String(format: "%.1f", dblSleepHoursDaily)) h")
            }
            .onChange(of: dblSleepHoursDaily) { _ in normalizeTotals() }
            let remaining = max(0, 24 - (dblStudyHoursDaily + dblSleepHoursDaily + dblExtracurricularHoursWeekly / 7))
            Text("Remaining today: \(String(format: "%.2f", remaining)) h")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Calculate Button
    private var checkBalanceButton: some View {
        Button(action: computeWorkLifeBalance) {
            Text("Check Balance")
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(appThemeGradient)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }

    private var resultsSection: some View {
        Group {
            if let strError = strInputValidationError {
                Text(strError)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.horizontal)
            }
            if blnIsLoadingSuggestions {
                ProgressView("Getting suggestions…")
                    .padding()
                    .tint(.purple)
            }
            if intOverallStarRating >= 0 {
                CardView(title: "Rating") {
                    VStack(spacing: 8) {
                        Text(String(repeating: "★", count: intOverallStarRating))
                            .font(.largeTitle)
                            .foregroundColor(.purple)
                        Text("\(intOverallStarRating) out of 5")
                            .font(.headline)
                            .foregroundColor(.purple.opacity(0.8))
                        if !strBalanceSuggestionText.isEmpty {
                            Text(strBalanceSuggestionText)
                                .padding(.top, 5)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }

    private func computeWorkLifeBalance() {
        strInputValidationError = nil
        strBalanceSuggestionText = ""
        blnIsCalendarViewVisible = false
        blnShowCalendarAndClearControls = false

        guard let intAgeVal = Int(strStudentAge), (10...18).contains(intAgeVal) else {
            strInputValidationError = "Please enter a valid age between 10 and 18."
            return
        }

        blnIsLoadingSuggestions = true
        blnIsCalendarViewVisible = false
        blnShowCalendarAndClearControls = true

        intOverallStarRating = Int(
            calculateRating(
                strAge: strStudentAge,
                dblStudyHoursDaily: dblStudyHoursDaily,
                dblExtracurricularHoursWeekly: dblExtracurricularHoursWeekly,
                dblSleepHoursDaily: dblSleepHoursDaily
            )
        )

        if intOverallStarRating < 5 {
            fetchGeminiSuggestions()
        } else {
            strBalanceSuggestionText = "Great job! You have an excellent work-life balance."
            blnIsLoadingSuggestions = false
        }
    }

    private func resetAllInputs() {
        strStudentAge = ""
        strStudentGender = "Male"
        dblStudyHoursDaily = 1
        dblExtracurricularHoursWeekly = 0.5
        dblSleepHoursDaily = 7
        intOverallStarRating = 0
        strBalanceSuggestionText = ""
        strInputValidationError = nil
        blnIsLoadingSuggestions = false
        blnIsCalendarViewVisible = false
        blnShowCalendarAndClearControls = false
    }

    // MARK: Gemini API
    private func fetchGeminiSuggestions() {
        let strPrompt = """
        A student aged \(strStudentAge), gender \(strStudentGender), studies for \(dblStudyHoursDaily) hours/day, \
        does \(dblExtracurricularHoursWeekly) hours/week of extracurriculars, and sleeps \
        \(dblSleepHoursDaily) hours daily. Provide concise suggestions to improve their work-life balance.
        """

        guard let strApiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !strApiKey.isEmpty else {
            DispatchQueue.main.async {
                strBalanceSuggestionText = "Missing GEMINI_API_KEY in Info.plist."
                blnIsLoadingSuggestions = false
            }
            return
        }

        var urlComponents = URLComponents(
            string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
        )!
        urlComponents.queryItems = [URLQueryItem(name: "key", value: strApiKey)]

        let dictBody: [String: Any] = [
            "contents": [["parts": [["text": strPrompt]]]]
        ]
        guard let urlRequestUrl = urlComponents.url,
              let httpBody = try? JSONSerialization.data(withJSONObject: dictBody) else {
            DispatchQueue.main.async {
                strBalanceSuggestionText = "Failed to build Gemini request."
                blnIsLoadingSuggestions = false
            }
            return
        }

        var urlRequest = URLRequest(url: urlRequestUrl)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = httpBody
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            defer { DispatchQueue.main.async { blnIsLoadingSuggestions = false } }

            if let error = error {
                DispatchQueue.main.async {
                    strBalanceSuggestionText = "Network error: \(error.localizedDescription)"
                }
                return
            }
            guard let http = response as? HTTPURLResponse,
                  let data = data else {
                DispatchQueue.main.async {
                    strBalanceSuggestionText = "No response from Gemini."
                }
                return
            }
            if http.statusCode >= 400 {
                let strBody = String(data: data, encoding: .utf8) ?? ""
                DispatchQueue.main.async {
                    strBalanceSuggestionText = "Gemini error: \(strBody)"
                }
                return
            }
            do {
                let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let candidates = obj?["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    DispatchQueue.main.async { strBalanceSuggestionText = text }
                } else {
                    DispatchQueue.main.async {
                        strBalanceSuggestionText = "Unexpected response from Gemini."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    strBalanceSuggestionText = "Failed to parse Gemini response."
                }
            }
        }.resume()
    }
    
    //MARK: - Formula

    private struct AgeProfile {
        let idealStudy: Double
        let idealSleep: Double
        let idealExtra: Double
    }

    private func getAgeBasedProfile(intAge: Int) -> AgeProfile {
        switch intAge {
        case 10...12: return AgeProfile(idealStudy: 1.5, idealSleep: 9.5, idealExtra: 1.0)
        case 13...15: return AgeProfile(idealStudy: 2.5, idealSleep: 9.0, idealExtra: 1.0)
        case 16...18: return AgeProfile(idealStudy: 3.5, idealSleep: 8.5, idealExtra: 1.0)
        default:      return AgeProfile(idealStudy: 2.0, idealSleep: 9.0, idealExtra: 1.0)
        }
    }

    private func bellCurve(dblValue: Double, dblIdeal: Double, dblWidth: Double) -> Double {
        let dblExponent = -pow(dblValue - dblIdeal, 2) / (2 * pow(dblWidth, 2))
        return exp(dblExponent)
    }

    private func calculateRating(
        strAge: String,
        dblStudyHoursDaily: Double,
        dblExtracurricularHoursWeekly: Double,
        dblSleepHoursDaily: Double
    ) -> Double {
        guard let intAge = Int(strAge) else { return 0 }
        let dblExtraDaily = dblExtracurricularHoursWeekly / 7.0
        let profile = getAgeBasedProfile(intAge: intAge)
        let dblStudyScore = bellCurve(dblValue: dblStudyHoursDaily, dblIdeal: profile.idealStudy, dblWidth: 2.0)
        let dblSleepScore = bellCurve(dblValue: dblSleepHoursDaily, dblIdeal: profile.idealSleep, dblWidth: 1.8)
        let dblExtraScore = bellCurve(dblValue: dblExtraDaily, dblIdeal: profile.idealExtra, dblWidth: 1.0)
        var dblTotal = dblSleepScore * 0.45 + dblStudyScore * 0.35 + dblExtraScore * 0.20
        if dblSleepHoursDaily < 6 { dblTotal *= 0.7 }
        if dblStudyHoursDaily > 6 { dblTotal *= 0.75 }
        return max(0, min(5, round(dblTotal * 5)))
    }
}

fileprivate let appThemeGradient = LinearGradient(
    colors: [Color.purple, Color.blue],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// MARK: - Calendar
struct CalendarPlannerView: View {
    @State private var arrStudyBlocks: [TimeBlock] = []
    @State private var datSelectedDate = Date()
    @State private var objSelectedSubject: Subject = Subject.defaultSubjects.first!
    @State private var blnShowAddBlock = false
    @State private var objEditingBlock: TimeBlock? = nil
    @State private var arrSubjects: [Subject] = Subject.defaultSubjects
    @State private var blnShowManageSubjects = false

    private let intDayStartHour = 6
    private let intDayEndHour = 22
    private let dblCellWidth: CGFloat = 60
    private let dblRowHeight: CGFloat = 40

    var body: some View {
        NavigationStack {
            VStack {
                datePickerSection
                subjectPickerSection
                calendarGridSection
                addBlockButton
                summarySection
            }
            .navigationTitle("Study Planner")
            .tint(.purple)
        }
    }

    private var datePickerSection: some View {
        DatePicker("Pick a Day", selection: $datSelectedDate, displayedComponents: [.date])
            .datePickerStyle(GraphicalDatePickerStyle())
            .tint(.purple)
            .padding()
    }

    private var subjectPickerSection: some View {
        HStack {
            Picker("Subject", selection: $objSelectedSubject) {
                ForEach(arrSubjects) { subject in
                    Text(subject.name).tag(subject)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .tint(.purple)

            Circle()
                .fill(objSelectedSubject.color)
                .frame(width: 24, height: 24)

            Spacer()

            Button { blnShowManageSubjects = true } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundStyle(appThemeGradient)
            }
            .sheet(isPresented: $blnShowManageSubjects) {
                ManageSubjectsView(subjects: $arrSubjects, selectedSubject: $objSelectedSubject)
            }
        }
        .padding(.horizontal)
    }

    private var calendarGridSection: some View {
        ScrollView([.vertical, .horizontal], showsIndicators: false) {
            VStack(spacing: 0) {
                hourLabelsRow
                timelineRow
            }
            .padding(.horizontal, 16)
        }
    }

    private var hourLabelsRow: some View {
        HStack(spacing: 1) {
            Text("")
                .frame(width: 50)
            ForEach(intDayStartHour..<intDayEndHour, id: \.self) { hour in
                Text("\(hour):00")
                    .font(.caption)
                    .frame(width: dblCellWidth, alignment: .leading)
                    .padding(.leading, 1)
            }
        }
        .background(Color(.systemGray6))
    }

    private var timelineRow: some View {
        HStack(spacing: 1) {
            Text(datSelectedDate.formatted(date: .abbreviated, time: .omitted))
                .frame(width: 50)
                .font(.caption)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))

            ZStack(alignment: .topLeading) {
                HStack(spacing: 1) {
                    ForEach(intDayStartHour..<intDayEndHour, id: \.self) { _ in
                        Rectangle()
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                            .frame(width: dblCellWidth, height: dblRowHeight)
                    }
                }

                ForEach(arrStudyBlocks) { block in
                    if Calendar.current.isDate(block.date, inSameDayAs: datSelectedDate) {
                        BlockView(block: block, cellWidth: dblCellWidth, rowHeight: dblRowHeight)
                            .offset(x: CGFloat(block.startHour - intDayStartHour) * dblCellWidth)
                            .onTapGesture { objEditingBlock = block }
                    }
                }
            }
        }
    }

    private var addBlockButton: some View {
        Button(action: { blnShowAddBlock = true }) {
            Label("Add Study Block", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(appThemeGradient)
                .cornerRadius(10)
        }
        .padding()
        .sheet(isPresented: $blnShowAddBlock) {
            AddEditBlockView(
                date: datSelectedDate,
                subjects: arrSubjects,
                blockToEdit: nil,
                onSave: addOrUpdateStudyBlock,
                onDelete: nil
            )
        }
        .sheet(item: $objEditingBlock) { block in
            AddEditBlockView(
                date: datSelectedDate,
                subjects: arrSubjects,
                blockToEdit: block,
                onSave: addOrUpdateStudyBlock,
                onDelete: deleteStudyBlock
            )
        }
    }

    private var summarySection: some View {
        SummaryView(blocks: arrStudyBlocks.filter { Calendar.current.isDate($0.date, inSameDayAs: datSelectedDate) })
            .padding()
    }

    private func addOrUpdateStudyBlock(_ block: TimeBlock) {
        if let idx = arrStudyBlocks.firstIndex(where: { $0.id == block.id }) {
            arrStudyBlocks[idx] = block
        } else {
            arrStudyBlocks.append(block)
        }
    }

    private func deleteStudyBlock(_ block: TimeBlock) {
        arrStudyBlocks.removeAll { $0.id == block.id }
    }
}

struct Subject: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var color: Color
    static let defaultSubjects: [Subject] = [
        Subject(name: "Methods", color: .red),
        Subject(name: "English", color: .green),
        Subject(name: "Science", color: .purple),
        Subject(name: "Art", color: .yellow),
        Subject(name: "Languages", color: .blue)
    ]
}

struct TimeBlock: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let startHour: Int
    let durationHours: Int
    let subject: Subject
}

struct BlockView: View {
    let block: TimeBlock
    let cellWidth: CGFloat
    let rowHeight: CGFloat

    var body: some View {
        let width = CGFloat(block.durationHours) * cellWidth
        VStack(spacing: 0) {
            Text(block.subject.name)
                .font(.caption2)
                .bold()
                .foregroundColor(.white)
                .padding(.horizontal, 2)
                .padding(.vertical, 1)
            Spacer()
        }
        .frame(width: width, height: rowHeight, alignment: .topLeading)
        .background(block.subject.color.opacity(0.8))
        .cornerRadius(4)
    }
}

struct SummaryView: View {
    let blocks: [TimeBlock]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Summary")
                .font(.headline)
            ForEach(calcSubjectTotals()) { entry in
                HStack(spacing: 8) {
                    Circle()
                        .fill(entry.subject.color)
                        .frame(width: 12, height: 12)
                    Text("\(entry.subject.name): \(entry.hours) hr(s)")
                        .font(.subheadline)
                }
            }
        }
    }

    private func calcSubjectTotals() -> [SubjectTotal] {
        var dict: [Subject: Int] = [:]
        for block in blocks {
            dict[block.subject, default: 0] += block.durationHours
        }
        return dict.map { SubjectTotal(subject: $0.key, hours: $0.value) }
    }
}

struct SubjectTotal: Identifiable {
    var id: Subject.ID { subject.id }
    let subject: Subject
    let hours: Int
}

struct AddEditBlockView: View {
    let date: Date
    let subjects: [Subject]
    @State private var intStartHour: Int
    @State private var intDurationHours: Int
    @State private var objSubject: Subject
    private let objBlockId: UUID?

    var onSave: (TimeBlock) -> Void
    var onDelete: ((TimeBlock) -> Void)?
    @Environment(\.presentationMode) var presentation

    init(
        date: Date,
        subjects: [Subject],
        blockToEdit: TimeBlock?,
        onSave: @escaping (TimeBlock) -> Void,
        onDelete: ((TimeBlock) -> Void)?
    ) {
        self.date = date
        self.subjects = subjects
        if let block = blockToEdit {
            _intStartHour = State(initialValue: block.startHour)
            _intDurationHours = State(initialValue: block.durationHours)
            _objSubject = State(initialValue: block.subject)
            objBlockId = block.id
        } else {
            _intStartHour = State(initialValue: 6)
            _intDurationHours = State(initialValue: 1)
            _objSubject = State(initialValue: subjects.first!)
            objBlockId = nil
        }
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Subject", selection: $objSubject) {
                    ForEach(subjects) { subj in
                        Text(subj.name).tag(subj)
                    }
                }
                Stepper("Start Hour: \(intStartHour):00", value: $intStartHour, in: 6...21)
                Stepper("Duration: \(intDurationHours) hr", value: $intDurationHours, in: 1...6)
                if let onDelete = onDelete, let id = objBlockId {
                    Section {
                        Button(role: .destructive) {
                            onDelete(TimeBlock(id: id, date: getDateAtMidnight(date), startHour: intStartHour, durationHours: intDurationHours, subject: objSubject))
                            presentation.wrappedValue.dismiss()
                        } label: { Text("Delete Block") }
                    }
                }
            }
            .navigationTitle(objBlockId == nil ? "New Study Block" : "Edit Study Block")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newBlock = TimeBlock(id: objBlockId ?? UUID(), date: getDateAtMidnight(date), startHour: intStartHour, durationHours: intDurationHours, subject: objSubject)
                        onSave(newBlock)
                        presentation.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentation.wrappedValue.dismiss() }
                }
            }
        }
    }

    private func getDateAtMidnight(_ date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return cal.date(from: comps) ?? date
    }
}

struct AddSubjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var subjects: [Subject]
    @Binding var selectedSubject: Subject

    @State private var strNewName: String = ""
    @State private var objSelectedColor: Color = .blue

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Subject Info")) {
                    TextField("Subject Name", text: $strNewName)
                    ColorPicker("Color", selection: $objSelectedColor)
                }
            }
            .navigationTitle("Add Subject")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newSubject = Subject(name: strNewName, color: objSelectedColor)
                        subjects.append(newSubject)
                        selectedSubject = newSubject
                        dismiss()
                    }
                    .disabled(strNewName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditSubjectView: View {
    @Environment(\.dismiss) private var dismiss
    let subject: Subject
    var onSave: (Subject) -> Void

    @State private var strName: String
    @State private var objColor: Color

    init(subject: Subject, onSave: @escaping (Subject) -> Void) {
        self.subject = subject
        self._strName = State(initialValue: subject.name)
        self._objColor = State(initialValue: subject.color)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Edit Subject")) {
                    TextField("Subject Name", text: $strName)
                    ColorPicker("Color", selection: $objColor)
                }
            }
            .navigationTitle("Edit Subject")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updatedSubject = Subject(name: strName, color: objColor)
                        onSave(updatedSubject)
                        dismiss()
                    }
                    .disabled(strName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ManageSubjectsView: View {
    @Binding var subjects: [Subject]
    @Binding var selectedSubject: Subject
    @State private var blnShowAddSubject = false
    @State private var objSubjectToEdit: Subject? = nil
    @Environment(\.presentationMode) var presentation

    var body: some View {
        NavigationStack {
            List {
                ForEach(subjects) { subj in
                    HStack {
                        Circle()
                            .fill(subj.color)
                            .frame(width: 16, height: 16)
                        Text(subj.name)
                        Spacer()
                        if subj == selectedSubject {
                            Image(systemName: "checkmark")
                                .foregroundStyle(appThemeGradient)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedSubject = subj }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            objSubjectToEdit = subj
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.purple)
                    }
                }
                .onDelete { idx in subjects.remove(atOffsets: idx) }
            }
            .navigationTitle("Manage Subjects")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { blnShowAddSubject = true }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { presentation.wrappedValue.dismiss() }
                }
            }
            .sheet(isPresented: $blnShowAddSubject) {
                AddSubjectView(subjects: $subjects, selectedSubject: $selectedSubject)
            }
            .sheet(item: $objSubjectToEdit) { subj in
                EditSubjectView(subject: subj) { updated in
                    if let idx = subjects.firstIndex(where: { $0.id == subj.id }) {
                        subjects[idx] = updated
                        if selectedSubject.id == updated.id {
                            selectedSubject = updated
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
