// Made by Yuvraj Solanki, Daniel J. Parker
// Created 24/07/2025
// A simple app which allows you input your study hours and extra-curricular hours
// Inputs: Study hours, age, gender, extra-curricular hours, sleephours
// Outputs: star rating, suggestion text
// 24/07/2025 - v1
// 28/07/2025 - v1.1
// 29/07/2025 - v2
// 30/07/2025 - v2.1

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
                            suggestionText = "add getGeminiSuggestions() later this just for testing so i dont waste api"
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

    // MARK: - Rating Calculation

    struct IdealProfile {
        let idealStudyHours: Double
        let idealSleepHours: Double
        let idealExtracurricularHours: Double
    }

    func calculateRating(ageString: String, studyHoursDaily: Double, extracurricularHoursWeekly: Double, sleepHoursDaily: Double) -> Double {
        guard let age = Double(ageString) else { return 0.0 }
        let ideal = getIdealProfile(for: age)
        let studyScore = calculateBellCurveScore(value: studyHoursDaily, ideal: ideal.idealStudyHours, width: 2.0)
        let extracurricularScore = calculateBellCurveScore(value: extracurricularHoursWeekly, ideal: ideal.idealExtracurricularHours, width: 4.0)

        let sleepDifference = sleepHoursDaily - ideal.idealSleepHours
        let sleepScore: Double
        if sleepDifference >= 0 {
            sleepScore = calculateBellCurveScore(value: sleepHoursDaily, ideal: ideal.idealSleepHours, width: 1.5)
        } else {
            let penalty = pow(sleepDifference, 2)
            sleepScore = max(0, 1.0 - penalty / 9.0)
        }

        let totalScore = (studyScore * 0.4) + (sleepScore * 0.4) + (extracurricularScore * 0.2)
        return max(0.0, min(totalScore * 5.0, 5.0))
    }

    func getIdealProfile(for age: Double) -> IdealProfile {
        switch age {
        case 14: return IdealProfile(idealStudyHours: 1.0, idealSleepHours: 9.0, idealExtracurricularHours: 0.6875)
        case 15: return IdealProfile(idealStudyHours: 1.5, idealSleepHours: 9.0, idealExtracurricularHours: 0.6948051949)
        case 16: return IdealProfile(idealStudyHours: 2.5, idealSleepHours: 8.5, idealExtracurricularHours: 0.7067669173)
        case 17, 18: return IdealProfile(idealStudyHours: 3.5, idealSleepHours: 8.5, idealExtracurricularHours: 0.7067669173)
        default: return IdealProfile(idealStudyHours: 1.5, idealSleepHours: 9.0, idealExtracurricularHours: 5.0)
        }
    }

    func calculateBellCurveScore(value: Double, ideal: Double, width: Double) -> Double {
        let exponent = -pow(value - ideal, 2) / (2 * pow(width, 2))
        return exp(exponent)
    }
}

struct CalendarViewInline: View {
    @State private var selectedDate = Date()

    var body: some View {
        VStack(spacing: 20) {
            Text("Select a Date")
                .font(.title2.bold())

            DatePicker("Calendar", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .padding()

            Text("You selected: \(selectedDate.formatted(date: .long, time: .omitted))")
                .padding()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding()
    }
}

struct CalendarPlannerView: View {
    @State private var studyBlocks: [Date] = []
    @State private var selectedDate = Date()

    var body: some View {
        VStack {
            DatePicker("Pick a Day", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()

            List {
                ForEach(timeSlots(for: selectedDate), id: \.self) { time in
                    HStack {
                        Text(formattedTime(time))
                        Spacer()
                        if studyBlocks.contains(time) {
                            Image(systemName: "checkmark.square.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "square")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleBlock(for: time)
                    }
                }
            }
        }
        .navigationTitle("Study Planner")
    }

    func timeSlots(for date: Date) -> [Date] {
        var slots: [Date] = []
        let calendar = Calendar.current
        let startHour = 6
        let endHour = 22
        for hour in startHour..<endHour {
            if let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) {
                slots.append(date)
            }
        }
        return slots
    }

    func toggleBlock(for time: Date) {
        if let index = studyBlocks.firstIndex(where: { Calendar.current.isDate($0, equalTo: time, toGranularity: .hour) }) {
            studyBlocks.remove(at: index)
        } else {
            studyBlocks.append(time)
        }
    }

    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}
