// Made by Yuvraj Solanki, Daniel J. Parker
// Created 24/07/2025
// A simple app which allows you input your study hours and extra-curricular hours
// Inputs: Study hours, age, gender, extra-curricular hours, sleephours
// Outputs: star rating, suggestion text
// 24/07/2025 - v1
// 28/07/2025 - v1.1
// 29/07/2025 - v2
// 30/07/2025 - v2.1
// 31/07/2025 - v3
// 31/07/2025 - v3.1
// 01/08/2025 - v3.2
// 05/08/2025 - v3.3

// This code was thought of by DJ. Parker and Y. Solanki and implemented by the use of AI

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var age = ""
    @State private var gender = "Male"
    @State private var studyHours: Double = 1
    @State private var extracurricularHours: Double = 0.5
    @State private var sleepHours: Double = 7
    @State private var starRating = 0
    @State private var suggestionText = ""
    @State private var inputError: String? = nil
    @State private var isLoading = false
    @State private var showCalendar = false
    @FocusState private var isAgeFieldFocused: Bool
    @State private var showCalendarView = false
    
    let genders = ["Male", "Female", "Other"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    HStack {
                        Spacer()
                        Text("Study Cuddie")
                            .font(.custom("Revalia", size: 40))
                            .foregroundColor(Color.black)
                        Spacer()
                    }
                    .padding(.top)
                    
                    CardView(title: "Personal Info") {
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: age) { newValue in
                                age = newValue.filter { $0.isNumber }
                            }
                            .focused($isAgeFieldFocused)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        isAgeFieldFocused = false
                                    }
                                }
                            }
                            .foregroundColor(.black)
                        
                        Picker("Gender", selection: $gender) {
                            ForEach(genders, id: \.self) { Text($0) }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .tint(.purple)
                    }
                    
                    CardView(title: "Your Routine (Daily)") {
                        Stepper(value: $studyHours, in: 0...12, step: 0.1) {
                            Text("Study Hours: \(studyHours, specifier: "%.1f")")
                                .foregroundColor(.black)
                        }
                        Stepper(value: $extracurricularHours, in: 0...12, step: 0.1) {
                            Text("Extracurriculars: \(extracurricularHours, specifier: "%.1f")")
                                .foregroundColor(.black)
                        }
                        Stepper(value: $sleepHours, in: 0...12, step: 0.5) {
                            Text("Sleep: \(sleepHours, specifier: "%.1f")")
                                .foregroundColor(.black)
                        }
                    }
                    
                    Button(action: {
                        inputError = nil
                        suggestionText = ""
                        showCalendar = false
                        
                        guard let ageValue = Int(age), (10...18).contains(ageValue) else {
                            inputError = "Please enter a valid age between 10 and 18."
                            return
                        }
                        
                        isLoading = true
                        showCalendar = true
                        
                        starRating = Int(calculateRating(
                            ageString: age,
                            studyHoursDaily: studyHours,
                            extracurricularHoursWeekly: extracurricularHours,
                            sleepHoursDaily: sleepHours
                        ))
                        
                        if starRating < 5 {
                            getGeminiSuggestions()
                        } else {
                            suggestionText = "Great job! You have an excellent work-life balance."
                            isLoading = false
                        }
                    }) {
                        Text("Check Balance")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.indigo]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    if let error = inputError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.horizontal)
                    }
                    
                    if isLoading {
                        ProgressView("Getting suggestions...")
                            .padding()
                            .tint(.purple)
                    }
                    
                    if starRating > 0 || !suggestionText.isEmpty {
                        CardView(title: "Rating") {
                            VStack(spacing: 8) {
                                Text(String(repeating: "★", count: starRating))
                                    .font(.largeTitle)
                                    .foregroundColor(.purple)
                                Text("\(starRating) out of 5")
                                    .font(.headline)
                                    .foregroundColor(.purple.opacity(0.8))
                                if !suggestionText.isEmpty {
                                    Text(suggestionText)
                                        .padding(.top, 5)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showCalendar {
                        Button(action: {
                            showCalendarView = true
                        }) {
                            Image(systemName: "calendar")
                        }
                        .foregroundColor(.purple)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if starRating > 0 || !suggestionText.isEmpty {
                        Button("Clear") {
                            resetAll()
                        }
                        .foregroundColor(.purple)
                    }
                }
            }
            .navigationDestination(isPresented: $showCalendarView) {
                CalendarPlannerView()
            }
        }
    }
    
    @ViewBuilder
    func CardView<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
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
    
    private func resetAll() {
        age = ""
        gender = "Male"
        studyHours = 1
        extracurricularHours = 0.5
        sleepHours = 7
        starRating = 0
        suggestionText = ""
        inputError = nil
        isLoading = false
        showCalendar = false
        showCalendarView = false
    }
    
    func getGeminiSuggestions() {
        let prompt = """
        A student aged \(age), gender \(gender), studies for \(studyHours) hours, does \(extracurricularHours) hours of extracurriculars, and sleeps \(sleepHours) hours daily. Provide suggestions for improving their work-life balance concisely.
        """
        
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !apiKey.isEmpty else {
            DispatchQueue.main.async {
                self.suggestionText = "Missing GEMINI_API_KEY in Info.plist."
                self.isLoading = false
            }
            return
        }
        
        var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent")!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        let requestBody: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]]
        ]
        
        guard let url = components.url,
              let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            DispatchQueue.main.async {
                self.suggestionText = "Failed to build Gemini request."
                self.isLoading = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer {
                DispatchQueue.main.async { self.isLoading = false }
            }
            
            if let error = error {
                print("🔴 Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.suggestionText = "Network error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let http = response as? HTTPURLResponse else {
                print("🔴 No HTTPURLResponse")
                DispatchQueue.main.async {
                    self.suggestionText = "No HTTP response from Gemini."
                }
                return
            }
            
            print("🟡 HTTP status: \(http.statusCode)")
            
            guard let data = data else {
                print("🔴 Empty response body")
                DispatchQueue.main.async {
                    self.suggestionText = "Empty response from Gemini."
                }
                return
            }
            
            if http.statusCode >= 400 {
                let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                print("🔴 Error body: \(bodyText)")
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let err = dict["error"] as? [String: Any],
                   let msg = err["message"] as? String {
                    DispatchQueue.main.async {
                        self.suggestionText = "Gemini error: \(msg)"
                    }
                } else {
                    DispatchQueue.main.async {
                        self.suggestionText = "Gemini error (\(http.statusCode))."
                    }
                }
                return
            }
            
            do {
                let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let candidates = obj?["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    DispatchQueue.main.async {
                        self.suggestionText = text
                    }
                } else {
                    let raw = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                    print("🟠 Unexpected success body: \(raw)")
                    DispatchQueue.main.async {
                        self.suggestionText = "Unexpected response from Gemini."
                    }
                }
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                print("🔴 JSON parse error: \(error)\nBody: \(raw)")
                DispatchQueue.main.async {
                    self.suggestionText = "Could not parse Gemini response."
                }
            }
        }.resume()
    }
    
    private struct AgeProfile {
        let idealStudy: Double
        let idealSleep: Double
        let idealExtra: Double
    }

    private func getAgeBasedProfile(age: Int) -> AgeProfile {
        switch age {
        case 10...12:
            return AgeProfile(idealStudy: 1.5, idealSleep: 9.5, idealExtra: 1.0)
        case 13...15:
            return AgeProfile(idealStudy: 2.5, idealSleep: 9.0, idealExtra: 1.0)
        case 16...18:
            return AgeProfile(idealStudy: 3.5, idealSleep: 8.5, idealExtra: 1.0)
        default:
            return AgeProfile(idealStudy: 2.0, idealSleep: 9.0, idealExtra: 1.0)
        }
    }

    private func bellCurve(value: Double, ideal: Double, width: Double) -> Double {
        let exponent = -pow(value - ideal, 2) / (2 * pow(width, 2))
        return exp(exponent)
    }

    private func calculateRating(
        ageString: String,
        studyHoursDaily: Double,
        extracurricularHoursWeekly: Double,
        sleepHoursDaily: Double
    ) -> Double {
        guard let age = Int(ageString) else { return 0 }

        let extracurricularDaily = extracurricularHoursWeekly / 7.0
        let profile = getAgeBasedProfile(age: age)

        let studyScore = bellCurve(value: studyHoursDaily, ideal: profile.idealStudy, width: 2.0)
        let sleepScore = bellCurve(value: sleepHoursDaily, ideal: profile.idealSleep, width: 1.8)
        let extraScore = bellCurve(value: extracurricularDaily, ideal: profile.idealExtra, width: 1.0)

        var totalScore = (sleepScore * 0.45) + (studyScore * 0.35) + (extraScore * 0.20)

        if sleepHoursDaily < 6 {
            totalScore *= 0.7
        }
        if studyHoursDaily > 6 {
            totalScore *= 0.75
        }

        return max(0, min(5, round(totalScore * 5)))
    }
    
    struct CalendarPlannerView: View {
        @State private var studyBlocks: [TimeBlock] = []
        @State private var selectedDate = Date()
        @State private var selectedSubject: Subject = Subject.defaultSubjects.first!
        @State private var showAddBlock = false
        @State private var editingBlock: TimeBlock? = nil
        @State private var subjects: [Subject] = Subject.defaultSubjects
        @State private var showManageSubjects = false
        
        private let startHour = 6
        private let endHour = 22
        private let cellWidth: CGFloat = 60
        private let rowHeight: CGFloat = 40
        
        var body: some View {
            NavigationStack {
                VStack {
                    DatePicker("Pick a Day", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding()
                    HStack {
                        Picker("Subject", selection: $selectedSubject) {
                            ForEach(subjects) { subject in
                                Text(subject.name).tag(subject)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Circle()
                            .fill(selectedSubject.color)
                            .frame(width: 24, height: 24)
                        
                        Spacer()
                        
                        Button {
                            showManageSubjects = true
                        } label: {
                            Image(systemName: "pencil.circle")
                        }
                        .sheet(isPresented: $showManageSubjects) {
                            ManageSubjectsView(
                                subjects: $subjects,
                                selectedSubject: $selectedSubject
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollView([.vertical, .horizontal], showsIndicators: false) {
                        VStack(spacing: 0) {
                            HStack(spacing: 1) {
                                Text("")
                                    .frame(width: 50)
                                ForEach(startHour..<endHour, id: \.self) { hour in
                                    Text("\(hour):00")
                                        .font(.caption)
                                        .frame(width: cellWidth, alignment: .leading)
                                        .padding(.leading, 1)
                                }
                            }
                            .background(Color(.systemGray6))
                            
                            HStack(spacing: 1) {
                                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                    .frame(width: 50)
                                    .font(.caption)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                
                                ZStack(alignment: .topLeading) {
                                    HStack(spacing: 1) {
                                        ForEach(startHour..<endHour, id: \.self) { _ in
                                            Rectangle()
                                                .stroke(Color(.systemGray4), lineWidth: 0.5)
                                                .frame(width: cellWidth, height: rowHeight)
                                                .frame(width: cellWidth, height: rowHeight)
                                        }
                                    }
                                    
                                    ForEach(studyBlocks) { block in
                                        if Calendar.current.isDate(block.date, inSameDayAs: selectedDate) {
                                            BlockView(block: block, cellWidth: cellWidth, rowHeight: rowHeight)
                                                .offset(x: CGFloat(block.startHour - startHour) * cellWidth)
                                                .onTapGesture {
                                                    editingBlock = block
                                                }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Button(action: { showAddBlock = true }) {
                        Label("Add Study Block", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                    .padding()
                    .sheet(isPresented: $showAddBlock) {
                        AddEditBlockView(
                            date: selectedDate,
                            subjects: subjects,
                            blockToEdit: nil,
                            onSave: addOrUpdateBlock,
                            onDelete: nil
                        )
                    }
                    .sheet(item: $editingBlock) { block in
                        AddEditBlockView(
                            date: selectedDate,
                            subjects: subjects,
                            blockToEdit: block,
                            onSave: addOrUpdateBlock,
                            onDelete: deleteBlock
                        )
                    }
                    
                    SummaryView(blocks: studyBlocks.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) })
                        .padding()
                }
                .navigationTitle("Study Planner")
            }
        }
        
        private func addOrUpdateBlock(_ block: TimeBlock) {
            if let index = studyBlocks.firstIndex(where: { $0.id == block.id }) {
                studyBlocks[index] = block
            } else {
                studyBlocks.append(block)
            }
        }
        
        private func deleteBlock(_ block: TimeBlock) {
            studyBlocks.removeAll { $0.id == block.id }
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
                ForEach(subjectTotals()) { entry in
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
        
        private func subjectTotals() -> [SubjectTotal] {
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
        @State private var startHour: Int
        @State private var duration: Int
        @State private var subject: Subject
        private let blockID: UUID?
        
        var onSave: (TimeBlock) -> Void
        var onDelete: ((TimeBlock) -> Void)?
        @Environment(\.presentationMode) var presentation
        
        init(date: Date, subjects: [Subject], blockToEdit: TimeBlock?, onSave: @escaping (TimeBlock) -> Void, onDelete: ((TimeBlock) -> Void)?) {
            self.date = date
            self.subjects = subjects
            if let block = blockToEdit {
                _startHour = State(initialValue: block.startHour)
                _duration = State(initialValue: block.durationHours)
                _subject = State(initialValue: block.subject)
                blockID = block.id
            } else {
                _startHour = State(initialValue: 6)
                _duration = State(initialValue: 1)
                _subject = State(initialValue: subjects.first!)
                blockID = nil
            }
            self.onSave = onSave
            self.onDelete = onDelete
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    Picker("Subject", selection: $subject) {
                        ForEach(subjects) { subj in Text(subj.name).tag(subj) }
                    }
                    Stepper("Start Hour: \(startHour):00", value: $startHour, in: 6...21)
                    Stepper("Duration: \(duration) hr", value: $duration, in: 1...6)
                    if let onDelete = onDelete, let id = blockID {
                        Section {
                            Button(role: .destructive) {
                                onDelete(TimeBlock(id: id, date: dateAtMidnight(date), startHour: startHour, durationHours: duration, subject: subject))
                                presentation.wrappedValue.dismiss()
                            } label: { Text("Delete Block") }
                        }
                    }
                }
                .navigationTitle(blockID == nil ? "New Study Block" : "Edit Study Block")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let newBlock = TimeBlock(id: blockID ?? UUID(), date: dateAtMidnight(date), startHour: startHour, durationHours: duration, subject: subject)
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
        
        private func dateAtMidnight(_ date: Date) -> Date {
            let cal = Calendar.current
            let comps = cal.dateComponents([.year, .month, .day], from: date)
            return cal.date(from: comps) ?? date
        }
    }
    
    struct ManageSubjectsView: View {
        @Binding var subjects: [Subject]
        @Binding var selectedSubject: Subject
        @State private var showAddSubject = false
        @State private var subjectToEdit: Subject? = nil
        @Environment(\.presentationMode) var presentation
        
        var body: some View {
            NavigationStack {
                List {
                    ForEach(subjects) { subj in
                        HStack {
                            Circle().fill(subj.color).frame(width: 16, height: 16)
                            Text(subj.name)
                            Spacer()
                            if subj == selectedSubject { Image(systemName: "checkmark") }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSubject = subj
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                subjectToEdit = subj
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete { idx in
                        subjects.remove(atOffsets: idx)
                    }
                }
                .navigationTitle("Manage Subjects")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { showAddSubject = true }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { presentation.wrappedValue.dismiss() }
                    }
                }
                .sheet(isPresented: $showAddSubject) {
                    AddSubjectView(subjects: $subjects, selectedSubject: $selectedSubject)
                }
                .sheet(item: $subjectToEdit) { subj in
                    EditSubjectView(
                        subject: subj,
                        onSave: { updated in
                            if let idx = subjects.firstIndex(where: { $0.id == subj.id }) {
                                subjects[idx] = updated
                                if selectedSubject.id == subj.id {
                                    selectedSubject = updated
                                }
                            }
                        }
                    )
                }
            }
        }
    }
    
    struct AddSubjectView: View {
        @Binding var subjects: [Subject]
        @Binding var selectedSubject: Subject
        @State private var name = ""
        @State private var color: Color = .blue
        @Environment(\.presentationMode) var presentation
        
        var body: some View {
            NavigationStack {
                Form {
                    Section("Subject") {
                        TextField("Name", text: $name)
                        ColorPicker("Color", selection: $color)
                    }
                }
                .navigationTitle("New Subject")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let newSubj = Subject(name: name, color: color)
                            subjects.append(newSubj)
                            selectedSubject = newSubj
                            presentation.wrappedValue.dismiss()
                        }
                        .disabled(name.isEmpty)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { presentation.wrappedValue.dismiss() }
                    }
                }
            }
        }
    }
    
    struct EditSubjectView: View {
        let subject: Subject
        @State private var name: String
        @State private var color: Color
        var onSave: (Subject) -> Void
        @Environment(\.presentationMode) var presentation
        
        init(subject: Subject, onSave: @escaping (Subject) -> Void) {
            self.subject = subject
            _name = State(initialValue: subject.name)
            _color = State(initialValue: subject.color)
            self.onSave = onSave
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    Section("Subject") {
                        TextField("Name", text: $name)
                        ColorPicker("Color", selection: $color)
                    }
                }
                .navigationTitle("Edit Subject")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            var updated = subject
                            updated.name = name
                            updated.color = color
                            onSave(updated)
                            presentation.wrappedValue.dismiss()
                        }
                        .disabled(name.isEmpty)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { presentation.wrappedValue.dismiss() }
                    }
                }
            }
        }
    }
    
    //MARK: Previews
    
    struct CalendarPlannerView_Previews: PreviewProvider {
        static var previews: some View {
            CalendarPlannerView()
        }
    }
}
